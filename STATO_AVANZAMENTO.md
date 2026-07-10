# STATO AVANZAMENTO — BioChem

> Cruscotto di stato del [PIANO_GENERALE.md](PIANO_GENERALE.md). Aggiornare la riga a ogni task iniziata/completata.
> Legenda: ⬜ da fare · 🔄 in corso · ✅ fatto · ⏸️ bloccata (attende input) · 🧪 in test

**Ultimo aggiornamento:** 10/07/2026

---

## Quadro sintetico

| Area | Descrizione | Stato |
|------|-------------|-------|
| **0** | Setup & documentazione | ✅ |
| **A** | Navigazione & Home (task 2,3) | ✅ |
| **B** | Configurazione (task 4, H2/H3/H4) | 🔄 |
| **C** | Sezioni lab risultati (task 5,6,7,9) | ✅ |
| **D** | Stampa unione (task 8) | ✅ |
| **E** | Certificato PDF (G1) | 🔄 bozza fatta, da rifinire col modello |
| **F** | Campi configurabili (H1) | 🔄 Servizi lab migrato; ondata 2 (altre pagine) resta |
| **G** | Carta intestata (D1) | ⏸️ logo HD |
| **Z** | Permessi admin/dipendente | ⬜ finale, col cliente |

---

## Dettaglio task

### AREA 0 — Setup & documentazione
| # | Task | Stato |
|---|------|-------|
| 0.1 | Cartella `riferimenti/` locale + `.gitignore` (task 1) | ✅ |
| 0.2 | `CLAUDE.md` (regola desktop+mobile) | ✅ |
| 0.3 | `PIANO_GENERALE.md` + `STATO_AVANZAMENTO.md` | ✅ |
| 0.4 | Commit riorganizzazione su `staging` | ✅ |

### AREA A — Navigazione & Home
| # | Task | Stato |
|---|------|-------|
| A1 | Pagina Home (griglia card, desktop/mobile) | ✅ |
| A2 | Landing → Home (router + redirect) | ✅ |
| A3 | Sidebar desktop raggruppata + Home | ✅ |
| A4 | Bottom-nav mobile (Home al posto di Fatture) | ✅ |
| A5 | Svuotare il Profilo | ✅ |

### AREA B — Configurazione
| # | Task | Stato |
|---|------|-------|
| B1 | Rinomina Impostazioni → "Configurazione" | ✅ |
| B2 | Redesign UX gestione dati | 🔄 pass dedicato (da rivedere insieme) |
| B3 | Macro-sezioni gestibili (H2) | 🔄 pass dedicato |
| B4 | Dati azienda in Configurazione (H4) | ✅ già presente (non nel profilo) |

### AREA C — Sezioni Laboratorio
| # | Task | Stato |
|---|------|-------|
| C1 | Cationi Metalli (task 5) | ✅ |
| C2 | Primarie (task 6) | ✅ |
| C3 | Anioni (task 7) | ✅ |
| C4 | Microbiologia (task 9) | ✅ |

> Framework generico condiviso (`laboratorio/`): un solo set model/service/pagina/form/import, guidato da `FamigliaAnalisi`. ⚠️ **Mapping CSV provvisorio** (per intestazione) — da confermare con un CSV d'esempio del cliente.

### AREA D — Stampa unione
| # | Task | Stato |
|---|------|-------|
| D1 | Vista aggregata sola lettura (task 8) | ✅ |

### AREA E/F/G/Z
| # | Task | Stato |
|---|------|-------|
| E1 | Certificato PDF | 🔄 bozza generabile da Stampa unione; layout da rifinire col modello cliente |
| F1 | Estendere campi configurabili (H1) | 🔄 **Servizi lab fatto**: aggiunto `validator` a `CampoConfigurabile`; migrati `tipo analisi` e `tecnico`. Resta l'**ondata 2** (altre pagine — XL). |
| G1 | Carta intestata fedele (D1) | ⏸️ logo HD |
| Z1 | Permessi admin/dipendente | ⬜ finale |

---

## Changelog

| Data | Voce | Stato | Note |
|------|------|-------|------|
| 10/07/2026 | **AREA F — Campi configurabili (Servizi lab)** | 🔄 | Aggiunto supporto `validator` a `CampoConfigurabile` (avvolto in `FormField`), così i campi obbligatori non regrediscono. Migrati **tipo analisi** (da `CategoriaDropdown`) e **tecnico** (da `CampoConSuggerimenti`) a `CampoConfigurabile` con `defaultCategoriaId`. Resta l'ondata 2 sulle altre pagine (XL). `flutter build web`: OK. |
| 10/07/2026 | **AREA E — Certificato PDF (bozza)** | 🔄 | `CertificatoPdfService`: genera un certificato PDF da una riga di Stampa unione (intestazione DaMo + box campione + tabelle parametro/valore per famiglia + firma), riusando l'impianto di `preventivo_pdf_service`. Pulsante "Certificato (bozza)" nelle righe espanse di Stampa unione. ⚠️ **Layout provvisorio** (marcato "BOZZA" nel footer): da rifinire quando arriva il modello certificato del cliente. **F (H1):** migrazione campi lab a `CampoConfigurabile` bloccata — il widget non supporta `validator` e i campi sono obbligatori; prima serve aggiungere validazione al pilota. `flutter build web`: OK. |
| 10/07/2026 | **AREA C + D — Laboratorio & Stampa unione** | ✅ | Framework generico `laboratorio/` (DRY): `FamigliaAnalisi` (descrittore colonne dai file Excel), `RisultatoAnalisi` (model con `valori` map), `RisultatiAnalisiService` (CRUD generico per collection), `ImportRisultatiService` (CSV per intestazione, provvisorio), `RisultatiPage` (lista+ricerca+import) e `RisultatoFormPage` (selezione campione da Reg Lab via bottom-sheet + valori). Le 4 sezioni (Cationi/Primarie/Anioni/Microbio) sono istanze del framework. **Stampa unione**: `StampaUnioneService` unisce Reg Lab + 4 famiglie per `certNumb`; pagina sola lettura con righe espandibili. `flutter analyze`: 0. `flutter build web`: OK. |
| 10/07/2026 | **AREA B — Configurazione (parziale)** | 🔄 | B1 ✅ rinomina visibile "Impostazioni"→"Configurazione" (AppBar + hint nei form; path interno `/admin/impostazioni` invariato). B4 ✅ già soddisfatto: l'editor Dati azienda è nella pagina Configurazione, non nel profilo. **B2 (redesign UX) e B3 (macro-sezioni gestibili) rimandati a un pass dedicato**: sono modifiche ampie/soggettive su una pagina di 2500 righe funzionante, da rivedere insieme all'utente. |
| 10/07/2026 | **AREA A — Navigazione & Home** | ✅ | Nuova Home a griglia di card (`home_page.dart`) guidata dal registro `home_sections.dart` (fonte unica per Home/sidebar/bottom-nav). Landing post-login → `/home`. Sidebar desktop raggruppata (PRINCIPALE/LABORATORIO/AMMINISTRAZIONE) con Home in cima. Bottom-nav mobile: Home (1ª) al posto di Fatture. Profilo svuotato (via Calendario/Registro/Configurazione). 5 sezioni lab + stampa unione create come placeholder "in arrivo" (branch shell pronti). `flutter analyze`: 0 errori/warning. `flutter build web`: OK. |
| 10/07/2026 | **AREA 0 — Setup** | ✅ | Creata `riferimenti/` (gitignored, PII locali). `CLAUDE.md` con regola desktop+mobile a componenti condivisi. `PIANO_GENERALE.md` + `STATO_AVANZAMENTO.md`. Vecchi doc archiviati in `docs/archivio/`. |
