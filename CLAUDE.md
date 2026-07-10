# CLAUDE.md — Regole di progetto BioChem

Gestionale aziendale **BioChem / DaMo** — Flutter (web · android · macOS · windows · linux) su **Firebase** (Firestore + Hosting + Functions).
Progetto Firebase: `biochem-b5d74` · Produzione: https://biochem-b5d74.web.app

> **Documenti guida:** [PIANO_GENERALE.md](PIANO_GENERALE.md) (piano master, tutte le aree/task) · [STATO_AVANZAMENTO.md](STATO_AVANZAMENTO.md) (cruscotto stato). Storico archiviato in [`docs/archivio/`](docs/archivio/).

---

## ⚠️ Regola trasversale n°1 — Desktop **e** Mobile con componenti condivisi

**Ogni** schermata/feature va implementata sia per **desktop** sia per **mobile**, con **un solo codice condiviso**. È vietato duplicare la logica in due widget paralleli.

- Un unico widget usa `LayoutBuilder` e commuta il **solo layout** in base a `constraints.maxWidth >= 600` (`_buildDesktopLayout` / `_buildMobileLayout`), come già fanno `main_screen.dart`, `servizi_lab_page.dart`, ecc.
- Stato, provider, validazione, chiamate ai service, modelli → **condivisi**, mai riscritti per piattaforma.
- Se un componente è usato da entrambi, si scrive **una volta** e si riusa. Meno codice possibile.

## Altre regole

- **Commit:** uno per pagina/feature, messaggio in italiano stile conventional (`feat(...)`, `fix(...)`, `docs(...)`). Frammentare per una storia pulita.
- **`flutter analyze`** prima di ogni commit: 0 errori/warning sui file toccati (baseline del progetto: solo `info` di stile preesistenti).
- **Branch:** si lavora solo su **`staging`**. A test superati si allinea `main` e si fa il deploy.
- **Permessi admin/dipendente:** rifacimento rimandato a un blocco finale (AREA Z) — in questa fase **non** si gestiscono permessi.

---

## `riferimenti/` — file di riferimento locali (NON versionati)

La cartella [`riferimenti/`](riferimenti/) è in `.gitignore`: contiene file del cliente con **dati personali reali (PII)** e resta **solo in locale**, mai su GitHub.

Mappa file di riferimento ↔ task (vedi PIANO_GENERALE.md):

| File | Task collegata |
|------|----------------|
| `home_desktop.png`, `home_mobile.png` | AREA A — struttura Home (solo struttura, non lo stile) |
| `cationi metalli.xlsx` | AREA C — task 5 (Cationi Metalli) |
| `primarie.xlsx` | AREA C — task 6 (Primarie) |
| `anioni.xlsx` | AREA C — task 7 (Anioni) |
| `microbiologia.xlsx` | AREA C — task 9 (Microbiologia) |
| `stampa unione.xlsx` | AREA D — task 8 (Stampa unione) |

> I 5 xlsx sono copie dello stesso registro (9 fogli). Chiave di collegamento tra fogli: **`cert numb`** (certificato univoco) + `cod A`(data)`+ora`. Ogni riga = un campione.

---

## Architettura in breve

- **Navigazione:** `lib/core/router/app_router.dart` (go_router, `StatefulShellRoute`) + `lib/features/home/screens/main_screen.dart` (sidebar desktop / bottom-nav mobile).
- **Feature:** `lib/features/<nome>/screens/` · **Model:** `lib/models/` · **Service:** `lib/services/` · **Widget riusabili:** `lib/widgets/`.
- **Import CSV:** `file_picker` + parser stile `ImportRegistroService.parsaCSV` con pagina di preview (vedi `registro_page.dart`).
- **PDF:** `pdf`/`printing`, vedi `preventivo_pdf_service.dart`; dati azienda in `DatiAzienda.damo` (`lib/models/dati_azienda_model.dart`).
- **Reg Lab** = `servizi_lab` (registro campioni/certificati). **Registro** = `registro_preset` (template parametri).
