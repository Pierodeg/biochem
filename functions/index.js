const { setGlobalOptions } = require("firebase-functions");
const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, Timestamp } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();
setGlobalOptions({ maxInstances: 10, region: "europe-west1" });

const db = getFirestore();
const messaging = getMessaging();

// ─── Utility: formatta data timezone Roma ────────────────────────────────

function formattaData(seconds) {
  return new Date(seconds * 1000).toLocaleDateString("it-IT", {
    day: "2-digit", month: "2-digit", year: "numeric",
    hour: "2-digit", minute: "2-digit",
    timeZone: "Europe/Rome",
  });
}

// ─── Utility: calcola momento notifica ───────────────────────────────────

function calcolaMomentoNotifica(dataInizioSeconds, giorniPrima, minutiPrima) {
  const ms = dataInizioSeconds * 1000;
  const offsetMs = (giorniPrima * 24 * 60 * 60 * 1000) + (minutiPrima * 60 * 1000);
  return new Date(ms - offsetMs);
}

// ─── Utility: invia push FCM a tutti gli admin ───────────────────────────

async function inviaPushAdmin(titolo, corpo, dataPayload = {}) {
  const usersSnap = await db.collection("users")
    .where("role", "==", "admin")
    .get();

  const tokens = [];
  for (const userDoc of usersSnap.docs) {
    const tokensSnap = await db
      .collection("users").doc(userDoc.id)
      .collection("fcm_tokens").get();
    tokensSnap.docs.forEach(t => {
      if (t.data().token) tokens.push(t.data().token);
    });
  }

  if (tokens.length === 0) {
    console.warn("Nessun token FCM trovato");
    return;
  }

  console.log(`Invio push a ${tokens.length} token`);

  const chunks = [];
  for (let i = 0; i < tokens.length; i += 500) {
    chunks.push(tokens.slice(i, i + 500));
  }

  for (const chunk of chunks) {
    try {
      const response = await messaging.sendEachForMulticast({
        tokens: chunk,
        notification: {
          title: titolo,
          body: corpo,
        },
        data: dataPayload,
        android: {
          priority: "high",
          notification: {
            channelId: "biochem_notifiche",
            notificationPriority: "PRIORITY_MAX",
            visibility: "PUBLIC",
            defaultSound: true,
            defaultVibrateTimings: true,
            icon: "ic_launcher",
            color: "#4AE883",
          },
        },
      });
      console.log(`FCM: ${response.successCount} ok, ${response.failureCount} errori`);
      response.responses.forEach((r, i) => {
        if (!r.success) {
          console.error(`Token[${i}] errore: ${r.error?.code} — ${r.error?.message}`);
        }
      });
    } catch (err) {
      console.error("Errore invio FCM:", err);
    }
  }
}

// ─── Utility: crea notifica in-app per tutti gli admin ───────────────────

async function creaNotificaInApp(titolo, corpo, tipo, appuntamentoId, scadenzaSeconds) {
  const usersSnap = await db.collection("users")
    .where("role", "==", "admin")
    .get();

  const batch = db.batch();
  for (const userDoc of usersSnap.docs) {
    const ref = db.collection("notifiche").doc(userDoc.id).collection("items").doc();
    batch.set(ref, {
      titolo,
      corpo,
      tipo: tipo || "generico",
      appuntamentoId: appuntamentoId || "",
      letta: false,
      createdAt: Timestamp.now(),
      scadenza: scadenzaSeconds
        ? new Timestamp(parseInt(scadenzaSeconds), 0)
        : null,
    });
  }
  await batch.commit();
  console.log("Notifica in-app creata per tutti gli admin");
}

// ─── FUNCTION 1: Nuovo appuntamento → programma notifica ─────────────────

exports.onAppuntamentoCreato = onDocumentCreated(
  "appuntamenti/{appuntamentoId}",
  async (event) => {
    const app = event.data.data();
    const appId = event.params.appuntamentoId;

    if (!app.notificaAbilitata || !app.dataInizio) {
      console.log(`App ${appId}: notifica disabilitata o data mancante — skip`);
      return;
    }

    const giorniPrima = app.notificaGiorniPrima || 0;
    const minutiPrima = app.notificaMinutiPrima || 0;
    const momentoNotifica = calcolaMomentoNotifica(
      app.dataInizio._seconds, giorniPrima, minutiPrima
    );

    const dataStr = formattaData(app.dataInizio._seconds);
    const titoloNotifica = `🔔 Promemoria: ${app.titolo}`;
    const corpoNotifica = app.clienteNome
      ? `${dataStr} — ${app.clienteNome}`
      : dataStr;

    await db.collection("notifiche_programmate").doc(appId).set({
      appuntamentoId: appId,
      titolo: app.titolo,
      titoloNotifica,
      corpoNotifica,
      tipo: app.tipo || "generico",
      momentoNotifica: Timestamp.fromDate(momentoNotifica),
      dataInizioSeconds: app.dataInizio._seconds,
      inviata: false,
      createdAt: Timestamp.now(),
    });

    console.log(`Notifica programmata per ${momentoNotifica.toISOString()}`);
  }
);

// ─── FUNCTION 2: Appuntamento modificato → aggiorna notifica programmata ─

exports.onAppuntamentoModificato = onDocumentUpdated(
  "appuntamenti/{appuntamentoId}",
  async (event) => {
    const prima = event.data.before.data();
    const dopo = event.data.after.data();
    const appId = event.params.appuntamentoId;

    const dataInizioCambiata = prima.dataInizio?._seconds !== dopo.dataInizio?._seconds;
    const giorniCambiati = prima.notificaGiorniPrima !== dopo.notificaGiorniPrima;
    const minutiCambiati = prima.notificaMinutiPrima !== dopo.notificaMinutiPrima;
    const notificaDisattivata = prima.notificaAbilitata === true && dopo.notificaAbilitata === false;
    const notificaAttivata = prima.notificaAbilitata === false && dopo.notificaAbilitata === true;
    const tecnicoCambiato = prima.tecnico !== dopo.tecnico;

    // Se la notifica viene disattivata, elimina la programmata
    if (notificaDisattivata) {
      await db.collection("notifiche_programmate").doc(appId).delete();
      console.log(`Notifica programmata eliminata per ${appId}`);
      return;
    }

    // Se cambiano campi rilevanti, aggiorna o crea la notifica programmata
    const aggiornare = dataInizioCambiata || giorniCambiati || minutiCambiati ||
      notificaAttivata || tecnicoCambiato;

    if (!aggiornare || !dopo.notificaAbilitata || !dopo.dataInizio) return;

    const giorniPrima = dopo.notificaGiorniPrima || 0;
    const minutiPrima = dopo.notificaMinutiPrima || 0;
    const momentoNotifica = calcolaMomentoNotifica(
      dopo.dataInizio._seconds, giorniPrima, minutiPrima
    );

    const dataStr = formattaData(dopo.dataInizio._seconds);
    const titoloNotifica = `🔔 Promemoria: ${dopo.titolo}`;
    const corpoNotifica = dopo.clienteNome
      ? `${dataStr} — ${dopo.clienteNome}`
      : dataStr;

    await db.collection("notifiche_programmate").doc(appId).set({
      appuntamentoId: appId,
      titolo: dopo.titolo,
      titoloNotifica,
      corpoNotifica,
      tipo: dopo.tipo || "generico",
      momentoNotifica: Timestamp.fromDate(momentoNotifica),
      dataInizioSeconds: dopo.dataInizio._seconds,
      inviata: false,  // reset — da inviare di nuovo
      createdAt: Timestamp.now(),
    });

    // Push immediato se è cambiata data o tecnico
    if ((dataInizioCambiata || tecnicoCambiato) && dopo.notificaAbilitata) {
      let corpo = dopo.titolo;
      if (dataInizioCambiata) {
        corpo += ` — nuova data: ${formattaData(dopo.dataInizio._seconds)}`;
      }
      if (tecnicoCambiato && dopo.tecnico) {
        corpo += ` — tecnico: ${dopo.tecnico}`;
      }
      await inviaPushAdmin("✏️ Appuntamento modificato", corpo, {
        tipo: dopo.tipo || "generico",
        appuntamentoId: appId,
      });
      await creaNotificaInApp(
        "✏️ Appuntamento modificato", corpo,
        dopo.tipo, appId, String(dopo.dataInizio._seconds)
      );
    }

    console.log(`Notifica riprogrammata per ${momentoNotifica.toISOString()}`);
  }
);

// ─── FUNCTION 3: Ogni minuto — invia notifiche in scadenza ───────────────

exports.elaboraNotificheProgrammate = onSchedule(
  {
    schedule: "* * * * *",  // ogni minuto
    timeZone: "Europe/Rome",
  },
  async () => {
    const ora = Timestamp.now();
    // Finestra: da 2 minuti fa a adesso (per non perdere notifiche)
    const dueMinitiFA = new Timestamp(ora.seconds - 120, 0);

    const snap = await db.collection("notifiche_programmate")
      .where("inviata", "==", false)
      .where("momentoNotifica", ">=", dueMinitiFA)
      .where("momentoNotifica", "<=", ora)
      .get();

    if (snap.empty) return;

    console.log(`Trovate ${snap.docs.length} notifiche da inviare`);

    for (const doc of snap.docs) {
      const n = doc.data();
      try {
        await inviaPushAdmin(n.titoloNotifica, n.corpoNotifica, {
          tipo: n.tipo || "generico",
          appuntamentoId: n.appuntamentoId,
        });
        await creaNotificaInApp(
          n.titoloNotifica, n.corpoNotifica,
          n.tipo, n.appuntamentoId,
          String(n.dataInizioSeconds)
        );
        // Marca come inviata
        await doc.ref.update({ inviata: true });
        console.log(`Notifica inviata per appuntamento ${n.appuntamentoId}`);
      } catch (err) {
        console.error(`Errore invio notifica ${doc.id}:`, err);
      }
    }
  }
);

// ─── FUNCTION 4: Reminder giornaliero alle 08:00 (backup) ────────────────

exports.reminderGiornaliero = onSchedule(
  {
    schedule: "0 8 * * *",
    timeZone: "Europe/Rome",
  },
  async () => {
    const domaniRoma = new Date(
      new Date().toLocaleDateString("en-CA", { timeZone: "Europe/Rome" })
    );
    domaniRoma.setDate(domaniRoma.getDate() + 1);

    const dopodomaniRoma = new Date(domaniRoma);
    dopodomaniRoma.setDate(dopodomaniRoma.getDate() + 1);

    const snap = await db.collection("appuntamenti")
      .where("dataInizio", ">=", Timestamp.fromDate(domaniRoma))
      .where("dataInizio", "<", Timestamp.fromDate(dopodomaniRoma))
      .where("completato", "==", false)
      .get();

    if (snap.empty) return;

    const count = snap.docs.length;
    const titolo = `📅 ${count} ${count === 1 ? 'appuntamento' : 'appuntamenti'} domani`;
    const corpo = snap.docs.map(d => {
      const a = d.data();
      const ora = new Date(a.dataInizio._seconds * 1000)
        .toLocaleTimeString("it-IT", { hour: "2-digit", minute: "2-digit", timeZone: "Europe/Rome" });
      return `${ora} — ${a.titolo}`;
    }).join("\n");

    await inviaPushAdmin(titolo, corpo, { tipo: "reminder" });
    await creaNotificaInApp(titolo, corpo, "reminder", "", "");
  }
);
