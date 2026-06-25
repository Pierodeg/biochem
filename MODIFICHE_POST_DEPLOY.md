# Modifiche post-deploy — BioChem

> **Data creazione:** 25/06/2026
> **Contesto:** è stato fatto un deploy con le modifiche già richieste e validate dal cliente
> (aree A–E + fix PDF). Questo documento raccoglie **tutto ciò che resta da fare nel/dopo il
> prossimo deploy**. Riferimento principale e storico completo: [PIANO_FIX_CLIENTE.md](PIANO_FIX_CLIENTE.md).

---

## ✅ Cosa è andato in questo deploy (per contesto)

Aree **A** (anagrafica), **B** (numerazione), **C** (dati cliente nel preventivo C1–C8),
**E** (servizi lab E1–E4), e i fix **PDF**:
- **D2** footer con numero laboratorio + numero principale
- **D3** intestazione ripetuta su ogni pagina
- **C6** coordinate IBAN + banca stampate nel PDF (lette da `impostazioni/dati_azienda`)
- footer e firma del PDF letti da `DatiAzienda` (niente più valori hardcoded; corretto refuso firma)
- **D4** nome file PDF = codice preventivo

---

## 🔜 Da fare nel prossimo deploy

### Priorità 1 — Campi configurabili (H1) — **già avviato**

**Stato:** pilota completato ma **accantonato** su branch `feature/campi-configurabili`.

Cosa c'è già pronto sul branch:
- Widget `lib/widgets/campo_configurabile.dart`: cascata **sezione → categoria → (sottocategoria) → suggerimenti** con menu a catena automatici, tap sulla casella per i suggerimenti, reset admin con conferma + "ripristina predefinita".
- `ImpostazioniService`: `getFieldBinding` / `salvaFieldBinding` / `rimuoviFieldBinding` + classe `FieldBinding` (doc `impostazioni/field_bindings`).
- `defaultCategoriaId`: i campi già a lista restano pre-configurati e funzionanti.
- Migrazione campi **Preventivo**: oggetto, pagamento, durata, rinnovo, periodo, validità, note.

**Da completare (Ondata 1 → 2):**
1. Riprendere il branch (`git checkout staging && git merge feature/campi-configurabili`, oppure cherry-pick dei commit).
2. **Servizi lab**: migrare `tecnico` e `tipo analisi` a `CampoConfigurabile`.
3. **Ondata 2 — censimento**: elencare tutti i campi (anagrafiche, pest, ecc.) oggi a testo libero o dropdown chiuso e convertirli, con mappatura campo → categoria.
4. Popolare su Firestore le liste mancanti: `preventivo_oggetti`, `preventivo_durata`, `preventivo_periodo`, `preventivo_note`.

---

### Priorità 2 — Impostazioni & Profilo (H2, H3, H4)

- **H4** — Spostare l'editor **"Dati azienda"** dalla pagina Impostazioni al **Profilo** (decisione presa: *solo* nel Profilo). Scrittura riservata all'admin.
- **H3** — Rinominare la sezione Impostazioni in **"Configurazione"** (AppBar + link nel profilo + route) e rifarne il design/UX.
- **H2** — Rendere gestibili dall'admin anche le **macro-sezioni** (oggi hardcoded) e migliorare il flusso di creazione liste.

---

### Priorità 3 — Voci cliente ancora aperte

- **D1 — Carta intestata fedele al modello** (`2026_MOD_PREV_GENER.pdf`). Ora il riferimento c'è.
  Dettagli da avvicinare: codice modulo `rif. MQ_..._rev00`, etichetta "mod preventivo",
  fascia footer legale completa, layout colonne tabella.
- **F1 — Parametri per tipo campione da pagina esterna.** In gran parte già coperto dalla
  pagina **Registro**; serve conferma del cliente se basta o vuole gestione/filtro dedicati.
- **G1 — ⭐ Collegamento risultati analisi → certificato.** ⏸️ **BLOCCATA**: servono dal cliente
  il **file Excel** dei dati e il **modello di certificato**, più la descrizione del meccanismo
  di collegamento attuale. È la parte più grande e critica per la produzione.

---

## ❓ Decisioni ancora aperte

| Rif. | Decisione | Note |
|------|-----------|------|
| B1 / D4 | **Formato codice preventivo**: `AAMMGGxxx` (attuale, reset giornaliero) **oppure** `AAMMGG_ora` (come nel PDF di riferimento) | Influenza codice in testata + nome file. |
| G1 | Schema di **codifica condivisa** registro analisi ↔ listino preventivi | Da definire insieme a F1. |

---

## 🔧 Nota tecnica per riprendere

- Il lavoro H1 è sul branch **`feature/campi-configurabili`** (basato su `staging` pre-deploy).
- Dopo il deploy, allineare il branch a `staging` aggiornato prima di proseguire.
