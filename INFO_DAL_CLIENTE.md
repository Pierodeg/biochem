# Informazioni necessarie dal cliente — BioChem

> **Data:** 25/06/2026
> **Scopo:** elenco di tutto ciò che serve **sapere o ricevere dal cliente** per completare
> le richieste ancora aperte. Ogni punto indica **cosa sblocca**.
> Documenti collegati: [STATO_E_ROADMAP.md](STATO_E_ROADMAP.md) · [PIANO_FIX_CLIENTE.md](PIANO_FIX_CLIENTE.md)

---

## 🔴 1. G1 — Collegamento risultati analisi → certificato (BLOCCANTE)

È la parte più grande e critica. Senza questi elementi non si può progettare.

- [ ] **File Excel attuale** (anche con dati finti) usato oggi per i certificati: serve per vedere
      struttura reale, colonne, come sono organizzati i parametri per **tipo campione**.
- [ ] **Modello/template del certificato** finale (il documento che il cliente compila).
- [ ] **Come avviene oggi il collegamento** Excel → certificato:
      `CERCA.VERT`/filtri? Tabella pivot? Foglio "database" + foglio "modello"?
- [ ] **Chiave di aggancio**: i dati si collegano per **numero di certificato**, per **nome cliente**,
      o entrambi?
- [ ] **Layout del PDF certificato**: intestazione di accreditamento, loghi, diciture obbligatorie.

> Sblocca: **G1** (modello dati risultati, import, compilazione assistita, PDF certificato).

---

## 🟡 2. D1 — Carta intestata del preventivo

Il PDF di riferimento (`2026_MOD_PREV_GENER.pdf`) c'è già. Restano da chiarire:

- [ ] **Logo** in alta risoluzione (PNG/SVG), se disponibile, per la testata.
- [ ] Il codice **`rif. MQ_20251028_rev00`** in testata: cosa rappresenta? Va **fisso** o deve
      aggiornarsi (es. per revisione modulo)?
- [ ] Conferma se la grafica attuale va bene o ci sono **elementi specifici** del modello da
      replicare fedelmente (disposizione colonne tabella, etichette, fascia footer).

> Sblocca: **D1**.

---

## 🟡 3. Decisione — Formato codice preventivo (B1 / D4)

- [ ] Il codice del preventivo (e il nome file PDF) deve essere:
  - **`AAMMGGxxx`** → progressivo giornaliero (attuale), es. `260625001`, **oppure**
  - **`AAMMGG_ora`** → come nel modello di riferimento, es. `260625_16:00`.

> Sblocca: rifinitura **B1** e **D4** + testata PDF.

---

## 🟢 4. E4 — Formato certificazione e storico

- [ ] Conferma formato senza barra: **`AANNN`** (es. `26001`). ✅ già implementato così.
- [ ] I record **già salvati** con il vecchio formato `AA/NNN`: vanno **uniformati** (migrazione dati)
      o si lasciano com'erano?

> Sblocca: eventuale migrazione storico.

---

## 🟡 5. F1 — Parametri per tipo campione

- [ ] La pagina **Registro** attuale (gestione parametri per campione) è **sufficiente**, o serve una
      vista/gestione dedicata "per tipologia campione" (acque, terreni, olio idraulico…)?
- [ ] Serve una **codifica unica** condivisa tra Registro analisi e listino preventivi? Con quale
      schema di codici? (collegato a G1)

> Sblocca: **F1** e parte di **G1**.

---

## 🟢 6. Contenuti per le liste configurabili (H1)

Per popolare le tendine di suggerimenti servono gli **elenchi di valori standard** che usa il cliente:

- [ ] **Oggetti** ricorrenti del preventivo (`preventivo_oggetti`).
- [ ] **Durate contratto** tipiche (`preventivo_durata`).
- [ ] **Periodi intervento** (`preventivo_periodo`).
- [ ] **Note/condizioni** standard d'offerta (`preventivo_note`).
- [ ] Eventuali **categorie/sottocategorie** ricorrenti (es. cliente con più sedi/indirizzi).

> Sblocca: i suggerimenti reali nei campi configurabili (H1).

---

## ✅ Già ricevuto / deciso

- Dati DaMo (ragione sociale, indirizzo, P.IVA, CU, **IBAN** Banco di Sardegna, REA) — dal PDF.
- Numero personale **+39 349 7644010** + laboratorio **+39 375 8622574** (footer).
- Reset numerazione preventivo: **giornaliero** (decisione presa).
- Nome sezione Impostazioni → **"Configurazione"**; Dati azienda → **solo nel Profilo**.
