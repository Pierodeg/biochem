# PIANO GENERALE — BioChem

> **Creato:** 10/07/2026 · **Scopo:** piano master unico per riprendere il lavoro in qualsiasi sessione.
> **Stato dettagliato:** [STATO_AVANZAMENTO.md](STATO_AVANZAMENTO.md) · **Regole:** [CLAUDE.md](CLAUDE.md) · **Storico:** [docs/archivio/](docs/archivio/)

---

## 0. Come leggere questo piano

Il lavoro è organizzato in **aree** (0, A–G, Z). Ogni area contiene task numerate. Lo stato ⬜/🔄/✅ di ogni task è tracciato in `STATO_AVANZAMENTO.md`. Regola trasversale su **tutto**: ogni schermata desktop **e** mobile con **componenti condivisi** (vedi CLAUDE.md).

**Contesto.** Le segnalazioni cliente A–E sono in produzione; il pilota H1 "campi configurabili" è in `staging`. Questo piano unisce le **voci vecchie rimaste** con le **9 nuove implementazioni** del cliente, senza doppioni:

| Nuove task cliente | Vecchie voci assorbite |
|--------------------|------------------------|
| 1 (cartella riferimenti) | — |
| 2, 3 (Home + navigazione) | (nuovo) |
| 4 (redesign Impostazioni) | H2, H3, H4 |
| 5–9 (sezioni lab + stampa unione) | F1, G1 |
| — | H1 (in corso), D1 (bloccata) |
| (finale) permessi | (nuovo blocco Z) |

---

## AREA 0 — Setup & documentazione ✅

- **0.1** Cartella `riferimenti/` locale (in `.gitignore`, contiene PII) + mappa task↔file in CLAUDE.md. *(task 1)*
- **0.2** `CLAUDE.md` con la regola desktop+mobile a componenti condivisi.
- **0.3** Questo `PIANO_GENERALE.md` + `STATO_AVANZAMENTO.md`.
- **0.4** Commit della riorganizzazione su `staging`.

---

## AREA A — Navigazione & Home *(task 2 + 3)*

Hub a **griglia di card** (struttura ispirata a `riferimenti/home_*.png`, tema BioChem glass-verde).

- **A1** `lib/features/home/screens/home_page.dart`: griglia card (icona + titolo + sottotitolo). Desktop ~4 colonne con sottotitolo, mobile 2 colonne solo titolo. Un widget con `LayoutBuilder`. 13 sezioni: Anagrafiche, Preventivo, Reg Lab, Cationi Metalli, Primarie, Anioni, Microbiologia, Stampa unione, Servizi Pest, Fatture, Calendario, Registro, Configurazione.
- **A2** Landing → Home: `app_router.dart` branch/route Home; redirect post-login `/anagrafiche` → `/home`.
- **A3** Sidebar desktop raggruppata (`main_screen.dart`): **Home** in cima + gruppi *PRINCIPALE* (Anagrafiche, Preventivo, Servizi Pest, Fatture, Calendario) · *LABORATORIO* (Reg Lab, Primarie, Cationi Metalli, Anioni, Microbiologia, Stampa unione) · *AMMINISTRAZIONE* (Registro, Configurazione).
- **A4** Bottom-nav mobile (`main_screen.dart`): **Home** (1ª) · Anagrafiche · Preventivo · Reg Lab · Servizi Pest. Fatture esce dalla nav (resta card Home).
- **A5** Svuotare il Profilo (`profile_panel.dart`): via Calendario/Registro/Configurazione (ora in sidebar + Home); il profilo mostra solo info account + logout.

---

## AREA B — Configurazione *(task 4 + H2/H3/H4)*

- **B1** Rinomina "Impostazioni" → **"Configurazione"** ovunque (AppBar, etichette sidebar/Home, route).
- **B2** Redesign UX della pagina (`admin_settings_page.dart`): creazione/aggiunta/gestione dati più semplice e chiara.
- **B3** Macro-sezioni gestibili: de-hardcodare `_macroSezioni` (righe 61-116) così l'admin le crea/rinomina; aggiungere le macro delle nuove famiglie lab dove servono liste. *(H2)*
- **B4** Dati azienda (DaMo): poiché il Profilo si svuota (A5), l'editor confluisce in **Configurazione**. *(H4 adattato)*

---

## AREA C — Sezioni Laboratorio / risultati *(task 5, 6, 7, 9)*

Quattro sezioni gemelle. **Pattern comune** (scritto una volta, poi replicato):
- **Model** `lib/models/risultati_<fam>_model.dart` con i campi-risultato del rispettivo foglio Excel.
- **Collection** Firestore dedicata (`risultati_cationi`, `risultati_primarie`, `risultati_anioni`, `risultati_microbio`), chiave logica = `certificazioneNumerica`.
- **Service** CRUD + query per campione (stile `ServiziLabService`).
- **List page** desktop/mobile (pattern `servizi_lab_page.dart`).
- **Form/riga manuale**: si sceglie il campione da **Reg Lab** (`servizi_lab`); le prime 4-5 colonne (cod A, cert numb, committente, date) si auto-compilano dal campione; l'utente inserisce i valori.
- **Import CSV** (pattern `file_picker` + `parsaCSV`/preview di `registro_page.dart`); mapping per intestazione → campi del model.

Colonne per famiglia (dai file):
- **Cationi (5):** Sodio, Magnesio, Alluminio, Potassio, Calcio, Cromo tot, Manganese, Ferro, Rame, Piombo, Zinco, Durezza…
- **Primarie (6):** colore, odore, torbidità, sapore, t camp, t amb, pH, conducibilità, NH4+, ossidabilità…
- **Anioni (7):** fluoruri, cloruri, nitriti, bromuro, nitrato, fosfato, solfato, cloriti, clorati…
- **Microbio (9):** mic. org. 22°/36°, coliformi, E.coli, Clostridium, Enterococchi, Legionella…

> **Popolamento:** manuale + CSV (nessun auto-popolamento). **Mapping CSV** finale quando il cliente fornisce un CSV d'esempio per sezione.

---

## AREA D — Stampa unione *(task 8)*

Sezione **sola lettura**: per ogni certificato aggrega in una riga Reg Lab + Primarie + Cationi + Anioni + Microbiologia (join su `certificazioneNumerica`). Base dati del certificato PDF.
`lib/features/stampa_unione/screens/stampa_unione_page.dart` + service di aggregazione.

---

## AREA E — Certificato PDF *(completa G1)*

Generazione PDF del certificato dai dati aggregati (dopo C+D). Riuso `preventivo_pdf_service.dart` + `DatiAzienda`. **Bloccata parzialmente**: serve il modello certificato dal cliente.

---

## AREA F — Campi configurabili *(H1, in corso)*

Estendere il pilota `CampoConfigurabile` a Servizi lab (tecnico, tipo analisi) e ondata 2; popolare le liste su Firestore.

---

## AREA G — Carta intestata preventivo *(D1, bloccata)*

Allineare l'header PDF al modello. **Bloccata** su logo HD + eventuale modello preventivo aggiornato.

---

## AREA Z — Permessi admin/dipendente *(blocco finale, col cliente)*

Rifacimento trasversale ruoli/permessi (lettura/scrittura, aggiunta dipendenti, azioni consentite). Da progettare col cliente dopo tutto il resto.

---

## Ordine di esecuzione

1. AREA 0 → 2. AREA A → 3. AREA B → 4. AREA C+D → 5. AREA E → 6. AREA F + G → 7. AREA Z.
Dopo l'AREA 0, ogni area di codice è implementata e **verificata** (`flutter analyze` + avvio app) prima della successiva, aggiornando `STATO_AVANZAMENTO.md`.

---

## Input attesi dal cliente (non bloccanti per iniziare)

- **CSV d'esempio** per ciascuna sezione lab (mapping colonne).
- **Modello certificato** (AREA E) e **logo HD** (AREA G).
