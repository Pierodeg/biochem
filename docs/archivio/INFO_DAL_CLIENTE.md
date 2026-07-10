# Informazioni necessarie dal cliente — BioChem

> **Data:** 25/06/2026
> **Scopo:** elenco di tutto ciò che serve **sapere o ricevere dal cliente** per completare
> le richieste ancora aperte. Ogni punto indica **cosa sblocca**.
> Documenti collegati: [STATO_E_ROADMAP.md](STATO_E_ROADMAP.md) · [PIANO_FIX_CLIENTE.md](PIANO_FIX_CLIENTE.md)

---

## 🔴 1. G1 — Collegamento risultati analisi → certificato (BLOCCANTE)

È la parte più grande e critica. Senza questi elementi non si può progettare.

- [x] **Struttura Excel**: il cliente ha condiviso un **registro editabile** con più fogli (es. un
      foglio per le analisi primarie, uno per i metalli, ecc.). Serve un "database" che trasferisca
      i dati dal registro al modello di certificato.
- [x] **Come funziona il certificato**: il modello ha una struttura **fissa** (intestazione/layout),
      i **risultati inseriti cambiano** in base alla tipologia di analisi richiesta.
- [x] **Come avviene oggi il collegamento**: **filtro su una colonna a scelta** del foglio registro
      (es. colonna "referente" → Mario Rossi; combinabile con filtro per anno/data). Il cliente lo
      paragona alla **stampa unione di Word** — utile spunto per il meccanismo di import/generazione.
      Non è quindi un aggancio fisso per "numero certificato" o "nome cliente": è un filtro libero
      su colonne del registro.
- [ ] **File Excel vero e proprio** (anche con dati finti) e **modello di certificato** in formato
      file: da recuperare/allegare fisicamente per poter progettare struttura dati e PDF.
- [ ] **Layout del PDF certificato**: intestazione di accreditamento, loghi, diciture obbligatorie
      (non ancora arrivato).

> Sblocca: **G1** (modello dati risultati, import, compilazione assistita, PDF certificato).
> Meccanismo confermato (filtro colonna stile "stampa unione"); **mancano ancora i file** per iniziare l'implementazione.

---

## 🟡 2. D1 — Carta intestata del preventivo

Il PDF di riferimento (`2026_MOD_PREV_GENER.pdf`) c'è già. Restano da chiarire:

- [ ] **Logo** in alta risoluzione (PNG/SVG), se disponibile, per la testata.
- [x] Il codice **`rif. MQ_...`** in testata: è un riferimento al **Manuale di Qualità**. Cambia
      **solo** quando viene aggiornato il manuale, o il logo di qualità (in caso di ente esterno).
      → in pratica è **fisso**, non calcolato per singolo documento.
- [ ] Il cliente accenna a un **modello preventivo eventualmente nuovo/aggiornato** ("forse cambia
      qualcosa in quello nuovo") — **da chiarire/recuperare**: c'è un file più recente rispetto a
      `2026_MOD_PREV_GENER.pdf` da usare come riferimento?

> Sblocca: **D1**. Manca ancora il logo HD e la conferma/il file del modello preventivo aggiornato.

---

## ✅ 3. Decisione — Formato codice preventivo (B1 / D4) — RISOLTO

- [x] Il cliente **va bene con entrambi** i formati (`AAMMGGxxx` progressivo giornaliero **oppure**
      `AAMMGG_ora`). Si mantiene il formato **già implementato** (`AAMMGGxxx`, progressivo
      giornaliero) — nessuna modifica necessaria.

> **B1 / D4 confermati come sono in produzione.**

---

## 🟢 4. E4 — Formato certificazione e storico

- [x] Confermato formato senza barra: **`AANNN`**.
- [x] **Nessun certificato** con il vecchio formato `AA/NNN` → **nessuna migrazione storica** necessaria.
- [ ] ⚠️ **Nuovo problema emerso**: il cliente segnala che si potrebbero **superare i 1000
      certificati/anno**. Il formato attuale usa 3 cifre di progressivo (`NNN`, max 999) →
      **da correggere** prima che il limite venga raggiunto (vedi task tecnico in
      `PIANO_FIX_CLIENTE.md`).

> Sblocca: fix tecnico urgente sul contatore certificazione (capacità oltre 999/anno).

---

## ✅ 5. F1 — Parametri per tipo campione — CONFERMATO, da implementare

- [x] Il cliente conferma: **sì, meglio dividere** per tipo di campione.
- [x] Vuole la **stessa codifica** usata per le tipologie di servizio, con la possibilità per
      l'admin di **aggiungere parametri**.

> Sblocca: **F1** può passare in progettazione/implementazione (nessun input mancante).

---

## 🟢 6. Contenuti per le liste configurabili (H1)

Per popolare le tendine di suggerimenti servono gli **elenchi di valori standard** che usa il cliente:

- [ ] **Oggetti** ricorrenti del preventivo (`preventivo_oggetti`).
- [ ] **Durate contratto** tipiche (`preventivo_durata`).
- [ ] **Periodi intervento** (`preventivo_periodo`).
- [ ] **Note/condizioni** standard d'offerta (`preventivo_note`).
- [ ] Eventuali **categorie/sottocategorie** ricorrenti (es. cliente con più sedi/indirizzi).

> Sblocca: i suggerimenti reali nei campi configurabili (H1).
> Il cliente non ha ancora mandato le liste puntuali; ha solo rimandato al "modello preventivo
> condiviso" (probabile riferimento al punto D1) — **da richiedere ancora in modo specifico**.

---

## ✅ Già ricevuto / deciso

- Dati DaMo (ragione sociale, indirizzo, P.IVA, CU, **IBAN** Banco di Sardegna, REA) — dal PDF.
- Numero personale **+39 349 7644010** + laboratorio **+39 375 8622574** (footer).
- Reset numerazione preventivo: **giornaliero** (decisione presa).
- Nome sezione Impostazioni → **"Configurazione"**; Dati azienda → **solo nel Profilo**.
