# Stato del progetto e roadmap — BioChem

> **Ultimo aggiornamento:** 25/06/2026
> **Scopo:** documento "master" per **riprendere il lavoro in qualsiasi sessione, anche a freddo**.
> Raccoglie stato attuale, lavoro accantonato e backlog futuro.
>
> **Documenti collegati:**
> - [PIANO_FIX_CLIENTE.md](PIANO_FIX_CLIENTE.md) — storico dettagliato di tutte le voci (A–H) con file/riga.
> - [INFO_DAL_CLIENTE.md](INFO_DAL_CLIENTE.md) — cosa serve ricevere/sapere dal cliente.

---

## 0. Come ripartire (lettura rapida)

1. Leggi questo file (stato + roadmap).
2. Per il dettaglio tecnico di una voce → cerca la sigla (es. `H1`, `G1`) in `PIANO_FIX_CLIENTE.md`.
3. Per gli input mancanti dal cliente → `INFO_DAL_CLIENTE.md`.

---

## 1. Contesto tecnico

- **App:** Flutter (web + android + macos + windows + linux). Backend **Firebase** (Firestore + Hosting + Functions).
- **Progetto Firebase:** `biochem-b5d74` · **URL produzione:** https://biochem-b5d74.web.app
- **Deploy (hosting web):**
  ```bash
  flutter build web --release
  firebase deploy --only hosting --project biochem-b5d74
  ```
  ⚠️ In PowerShell, se l'execution policy blocca `firebase.ps1`, usa **`firebase.cmd`**
  (oppure `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`). Per il login: `firebase login`.
- **File chiave:**
  - Form preventivo: `lib/features/preventivo/screens/preventivo_form_page.dart`
  - PDF preventivo: `lib/services/preventivo_pdf_service.dart`
  - Impostazioni (admin): `lib/features/admin/screens/admin_settings_page.dart`
  - Service impostazioni: `lib/services/impostazioni_service.dart`
  - Profilo: `lib/features/profile/widgets/profile_panel.dart`
  - Widget riusabili: `lib/widgets/` (`campo_con_suggerimenti.dart`; `campo_configurabile.dart` è sul branch H1)
  - Dati azienda: `lib/models/dati_azienda_model.dart` (default DaMo)

---

## 2. Stato Git

- **`staging`** → ramo di lavoro, **deployato e pushato** su origin. Contiene tutte le task cliente + fix PDF.
- **`feature/campi-configurabili`** → ramo con il **lavoro H1 accantonato** (pilota Preventivo). Pushato su origin.

**Per riprendere H1:**
```bash
git checkout staging
git pull
git merge feature/campi-configurabili     # oppure cherry-pick dei commit
```
(allineare prima il branch a staging aggiornato)

---

## 3. ✅ In produzione (fatto e deployato)

- **A** Anagrafica: numero cliente univoco (A1), numero più basso disponibile (A2).
- **B** Numerazione preventivo con reset giornaliero (B1).
- **C** Dati cliente nel preventivo (C1–C8): DaMo fornitore default, indirizzo servizio da anagrafica,
  campi oggetto/condizioni/note da elenco + manuale, riga prezzo leggibile da mobile, IBAN read-only, causale=codice.
- **E** Servizi lab (E1–E4): dropdown committente, hint tipologie, tecnico manuale, certificazione `AANNN`.
- **PDF** (fix recenti): **D3** intestazione su ogni pagina · **D2** footer con numero laboratorio ·
  **C6** IBAN + banca stampati · footer/firma letti da `DatiAzienda` (refuso corretto) · **D4** nome file = codice.

---

## 4. ⏸️ Lavoro ACCANTONATO — H1 (pronto da riprendere)

**Dove:** branch `feature/campi-configurabili`.

**Già pronto sul branch:**
- Widget `lib/widgets/campo_configurabile.dart`: cascata **sezione → categoria → (sottocategoria) → suggerimenti**,
  menu a catena automatici, tap sulla casella per i suggerimenti, reset admin con conferma + "ripristina predefinita".
- `ImpostazioniService`: `getFieldBinding` / `salvaFieldBinding` / `rimuoviFieldBinding` + classe `FieldBinding`
  (doc Firestore `impostazioni/field_bindings`).
- `defaultCategoriaId`: i campi già a lista restano pre-configurati e funzionanti.
- Migrazione campi **Preventivo**: oggetto, pagamento, durata, rinnovo, periodo, validità, note.

**Da completare:**
1. Merge del branch su `staging`.
2. **Servizi lab**: migrare `tecnico` e `tipo analisi` a `CampoConfigurabile`.
3. **Ondata 2 — censimento**: mappare e convertire i campi a testo libero/dropdown chiuso nelle altre pagine
   (anagrafiche, pest, ecc.).
4. Popolare su Firestore le liste: `preventivo_oggetti`, `preventivo_durata`, `preventivo_periodo`, `preventivo_note`
   (contenuti da chiedere al cliente — vedi INFO_DAL_CLIENTE.md §6).

---

## 5. 🔜 Backlog futuro (per priorità)

| # | Voce | Priorità | Stato | Bloccato da |
|---|------|----------|-------|-------------|
| **H1** | Campi configurabili su tutte le pagine | 🔴 | 🔄 pilota su branch | — (continuare) |
| **H4** | Dati azienda nel **Profilo** (solo admin) | 🟡 | ⬜ | — |
| **H3** | Rinomina sezione → **"Configurazione"** + redesign | 🟡 | ⬜ | — |
| **H2** | Admin gestisce le macro-sezioni (oggi hardcoded) | 🟡 | 🔄 base esistente | — |
| **D1** | Carta intestata fedele al modello | 🟡 | ⏸️→pronta | logo HD + chiarimenti (INFO §2) |
| **F1** | Parametri per tipo campione (pagina esterna) | 🟡 | ⬜ | conferma cliente (INFO §5) |
| **G1** ⭐ | Collegamento risultati analisi → certificato | 🔴 | ⏸️ | **Excel + modello certificato (INFO §1)** |

**Ordine consigliato di ripresa:** H1 (completare) → H4 → H3 → H2 → D1 → (G1 quando arrivano Excel+modello).

---

## 6. ❓ Decisioni aperte

| Rif. | Decisione | Note |
|------|-----------|------|
| B1 / D4 | Formato codice preventivo: `AAMMGGxxx` vs `AAMMGG_ora` | Influenza testata PDF + nome file. |
| E4 | Storico certificazioni `AA/NNN`: migrare o lasciare | Solo se serve uniformare. |
| F1 / G1 | Codifica condivisa Registro ↔ listino preventivi | Schema codici da definire. |

---

## 7. Convenzioni di lavoro (da rispettare)

- **Commit:** uno per pagina/feature, messaggio in italiano stile conventional (`feat(...)`, `fix(...)`, `docs(...)`).
  Frammentare per tenere la storia pulita.
- **`fieldKey`** dei campi configurabili: `{pagina}_{campo}` (es. `preventivo_oggetto`, `lab_tecnico`).
- **Tracciare sempre** lo stato in `PIANO_FIX_CLIENTE.md` (indice + badge + changelog) quando si tocca una voce.
- **`flutter analyze`** prima di committare (il progetto ha solo `info` di stile preesistenti).
- **Macro-sezioni** (sezione → categoria): ANAGRAFICHE, REG LAB, SERVIZI PEST, PREVENTIVO, FATTURE (+ ALTRE).

---

## 8. Riepilogo "cosa manca al cliente"

Delle richieste del cliente, è rimasto: **D1** (pronta), **F1** (decisione), **G1** (bloccata su Excel+modello),
e l'area **H** (H1 in corso sul branch, H2/H3/H4 da fare). Tutto il resto è **in produzione**.
