# Piano di risoluzione — Segnalazioni cliente BioChem

> **Data:** 21/06/2026
> **Stato:** bozza operativa — da spuntare man mano
> **Fonte:** segnalazioni cliente (anagrafica, preventivo, PDF, servizi lab, report analitico, collegamento dati Excel)

---

## ⚠️ Convenzione di tracciamento — LEGGERE PRIMA DI LAVORARE

Questo documento è la **memoria condivisa tra sessioni**: il lavoro può essere ripreso in momenti diversi, quindi lo stato deve essere sempre aggiornato qui dentro.

**Ogni volta che una task viene iniziata o completata, AGGIORNARE 3 punti:**

1. La colonna **Stato** nell'[indice priorità](#indice-rapido-priorità).
2. Il badge **`Stato:`** nell'intestazione della singola voce.
3. Una riga nel **[Registro avanzamento](#registro-avanzamento-changelog)** in fondo, con data e nota (cosa è stato fatto, eventuali decisioni prese).

**Stati possibili:**

| Badge | Significato |
|-------|-------------|
| ⬜ **Da fare** | non ancora iniziata |
| 🔄 **In corso** | iniziata, non finita (annotare a che punto si è) |
| ✅ **Fatto** | completata e verificata |
| ⏸️ **In attesa** | bloccata in attesa di un input (vedi tabella input in fondo) |

> Regola d'oro: **se tocchi una voce, lasci traccia.** Meglio una riga in più nel changelog che perdere il filo nella sessione successiva.

---

## Come leggere questo documento

Ogni voce ha:

- **Stato** — avanzamento (vedi convenzione sopra).
- **Stato attuale** — cosa fa oggi il codice (con file e riga).
- **Richiesta** — cosa vuole il cliente.
- **Soluzione proposta** — come lo risolviamo.
- **File coinvolti** — dove mettere le mani.
- **Priorità** — 🔴 Alta · 🟡 Media · 🟢 Bassa
- **Complessità** — S (poche ore) · M (mezza/una giornata) · L (più giorni) · XL (richiede progettazione/dati)

### Legenda aree

| Area | Tema | Voci |
|------|------|------|
| **A** | Anagrafica clienti | A1, A2 |
| **B** | Numerazione preventivo | B1 |
| **C** | Dati cliente dentro il preventivo | C1–C8 |
| **D** | PDF finale del preventivo | D1–D4 |
| **E** | Servizi lab (nuova registrazione) | E1–E4 |
| **F** | Report analitico | F1 |
| **G** | ⭐ Collegamento dati laboratorio → certificato | G1 |

---

## Indice rapido priorità

| # | Voce | Priorità | Compl. | Stato |
|---|------|----------|--------|-------|
| A1 | Numero cliente univoco (no duplicati) | 🔴 | M | ✅ |
| A2 | Auto-assegnazione numero più basso disponibile | 🟡 | M | ✅ |
| B1 | Numerazione preventivo: reset giornaliero o ora | 🟡 | M | ✅ |
| C1 | DaMo fornitore di default + committente da anagrafica | 🔴 | M | ⬜ |
| C2 | Indirizzo servizio selezionabile da anagrafica | 🟡 | M | ⬜ |
| C3 | Oggetto: manuale **o** da elenco servizi | 🟡 | M | ✅ |
| C4 | Riga servizio/prezzo leggibile da telefono (bug UI) | 🔴 | S | ✅ |
| C5 | Condizioni e rinnovo da elenco + manuale | 🟡 | M | ✅ |
| C6 | Coordinate bancarie DaMo di default, modificabili solo da admin | 🟡 | M | ⬜ |
| C7 | Causale di default = codice preventivo | 🟢 | S | ✅ |
| C8 | Note/condizioni offerta da elenco + manuale | 🟢 | M | ✅ |
| D1 | Carta intestata simile all'esempio | 🟡 | M | ⏸️ |
| D2 | Footer: aggiungere numero laboratorio | 🟢 | S | ✅* |
| D3 | Intestazione ripetuta su ogni pagina | 🔴 | S | ✅ |
| D4 | Nome file PDF = codice preventivo | 🔴 | S | ✅ |
| E1 | Dropdown codice cliente: mostrare committente, non città | 🟡 | S | ✅ |
| E2 | Tipo analisi: suggerimento su dove caricare nuove tipologie | 🟢 | S | ✅ |
| E3 | Tecnico: inserimento manuale oltre a elenco | 🟡 | M | ✅ |
| E4 | Numero: eliminare la barra "/" tra anno e progressivo | 🟢 | S | ✅ |
| F1 | Gestione parametri da pagina esterna per tipo campione | 🟡 | M | ⬜ |
| G1 | ⭐ Collegamento risultati analisi → certificato | 🔴 | XL | ⏸️ |

---

## Architettura attuale (sintesi)

Per orientarsi, lo stato dell'app oggi:

- **Anagrafica** → collection `clienti`, contatore `contatori/clienti`. Numero cliente assegnato come `ultimo + 1`, ma **modificabile a mano** nel form.
- **Preventivi** → collection `preventivi`, contatore per anno `contatori/preventivi_YYYY`. Codice = `AAMMGG` + progressivo a 3 cifre dell'anno (`numeroFormattato`).
- **Listino preventivo** → `impostazioni/preventivo_listino` (voci con `codice`, `descrizione`, `prezzoUnitario`).
- **Servizi lab** → collection `servizi_lab`. Certificazione `AA/NNN` (per anno), codice A `AAMMGG`.
- **Registro analisi** → collection `registro_preset`: ogni preset = un insieme di **categorie → parametri** (parametro, U.M., V.L., LoQ, I, metodo), associato a uno o più **campioni di riferimento**. Importabile da CSV (`ImportRegistroService`).
- **Report del certificato** → dentro il servizio lab, i parametri vengono caricati dal preset del registro in base al campione; il tecnico compila il campo `risultato`.
- **Ruoli** → `UserModel.isAdmin` (`role == 'admin'` vs `'dipendente'`). Esiste già una pagina admin (`admin_settings_page.dart`) e le impostazioni (`impostazioni/*`) sono scrivibili solo da admin.

> **Nota chiave:** la parte di *template* del certificato (quali parametri per quale campione) **esiste già** nel Registro. Quello che manca è il **collegamento dei risultati misurati** (vedi G1).

---

## A — Anagrafica clienti

### A1 — Numero cliente univoco 🔴 · M

**Stato:** ✅ Fatto (21/06/2026) — `numeroEsiste()` + controllo in `salvaCliente()`: il salvataggio è bloccato con messaggio se il numero è già usato da un altro cliente.

**Stato attuale.** Il form permette di digitare il numero a mano:
`int customNum = int.tryParse(_numeroClienteCtrl.text)` → se valorizzato viene usato così com'è, senza controllo di unicità ([cliente_form_page.dart:661](lib/features/anagrafiche/screens/cliente_form_page.dart#L661)). `getNextNumeroCliente()` incrementa solo un contatore ([clienti_service.dart:22](lib/services/clienti_service.dart#L22)). Nessun vincolo impedisce due clienti con lo stesso numero.

**Richiesta.** Il numero/codice cliente deve essere **univoco**.

**Soluzione proposta.**
1. Aggiungere in `ClientiService` un metodo `numeroEsiste(int numero, {String? escludiId})` che interroga `clienti` con `where('numeroCliente', isEqualTo: numero)`.
2. In `salvaCliente()` validare l'unicità lato servizio e lanciare eccezione se il numero è già usato da un altro documento (transazione per evitare race condition).
3. Nel form, validatore sul campo numero che blocca il salvataggio e mostra messaggio chiaro ("Numero già assegnato al cliente #…").

**File coinvolti.** [clienti_service.dart](lib/services/clienti_service.dart), [cliente_form_page.dart](lib/features/anagrafiche/screens/cliente_form_page.dart).

---

### A2 — Auto-assegnazione del numero più basso disponibile 🟡 · M

**Stato:** ✅ Fatto (21/06/2026) — `getNextNumeroCliente()` sostituito da `getPrimoNumeroLibero()`: assegna il più piccolo numero ≥ 1 non usato (riempie i buchi). Il form ora lo usa.

**Stato attuale.** `getNextNumeroCliente()` fa `ultimo + 1`: se un cliente viene eliminato, il suo numero **non viene mai riusato** e restano dei "buchi".

**Richiesta.** Nella scelta automatica, assegnare sempre il **numero più basso disponibile** in ordine crescente.

**Soluzione proposta.**
- Sostituire/integrare `getNextNumeroCliente()` con `getPrimoNumeroLibero()`: legge tutti i `numeroCliente` esistenti, li mette in un `Set`, e restituisce il più piccolo intero ≥ 1 non presente.
- Mantenere la transazione per concorrenza; in alternativa, racchiudere lettura + assegnazione in una transazione che rilegge prima di confermare.
- Punto da decidere insieme: il contatore `contatori/clienti` diventa ridondante → si può dismettere o tenere solo come fallback.

**File coinvolti.** [clienti_service.dart](lib/services/clienti_service.dart).

> ⚠️ **Coordinare con A1:** unicità + numero-più-basso vanno implementati insieme nello stesso giro di transazione, altrimenti due salvataggi simultanei possono prendere lo stesso numero.

---

## B — Numerazione preventivo

### B1 — Reset giornaliero o orario del progressivo 🟡 · M

**Stato:** ✅ Fatto (21/06/2026) — scelta: **reset giornaliero**. Contatore `contatori/preventivi_YYYYMMDD`: il progressivo riparte da 1 ogni giorno → codice `AAMMGG` + progressivo del giorno.

**Stato attuale.** Il codice è `AAMMGG` + progressivo a 3 cifre **per anno** (`numeroFormattato`, [preventivo_model.dart:214](lib/models/preventivo_model.dart#L214)). Il contatore è `contatori/preventivi_YYYY` con campo `ultimo` ([preventivi_service.dart:38](lib/services/preventivi_service.dart#L38)). Quindi `xxx` cresce da inizio anno, non riparte ogni giorno.

**Richiesta.** `xxx` va **azzerato quotidianamente**, oppure inserire l'**orario**.

**Soluzione proposta (consigliata: reset giornaliero).**
- Cambiare la chiave del contatore da `preventivi_YYYY` a `preventivi_YYYYMMDD`, così `generaNumeroPrev(data)` riparte da 1 ogni giorno.
- Risultato: codice `AAMMGG` + progressivo giornaliero → es. `260621` + `01` = ordinabile e leggibile.
- **Alternativa** (se preferita): mantenere il progressivo ma aggiungere l'ora al codice/nome file → `AAMMGG_HHMM` (vedi D4, da coordinare).

**Decisione richiesta.** Reset giornaliero **oppure** ora nel codice? Influenza B1 + D4 insieme.

**File coinvolti.** [preventivi_service.dart](lib/services/preventivi_service.dart), [preventivo_model.dart](lib/models/preventivo_model.dart) (`numeroFormattato`).

---

## C — Dati cliente dentro il preventivo

### C1 — DaMo fornitore di default + committente da anagrafica 🔴 · M

**Stato:** ⬜ Da fare

**Stato attuale.** Quando si seleziona un cliente, il form riempie **sia** la colonna sinistra (committente/azienda) **sia** la colonna destra (Spett.) con i dati dello **stesso** cliente ([preventivo_form_page.dart:274-294](lib/features/preventivo/screens/preventivo_form_page.dart#L274)). Anche `intestatoA` (coordinate bancarie) viene impostato al committente del cliente ([:293](lib/features/preventivo/screens/preventivo_form_page.dart#L293)). Risultato: nel PDF il cliente appare su entrambi i lati e non compare DaMo come fornitore.

**Richiesta.** DaMo (noi, azienda fornitrice) deve essere presente **di default**; dall'altra parte il **committente** recuperato da anagrafica.

**Soluzione proposta.**
1. Creare in Firestore un documento impostazioni `impostazioni/dati_azienda` (o `damo_profilo`) con i dati fissi DaMo: ragione sociale, indirizzo, CAP/città, P.IVA, CU, IBAN, intestatario.
2. All'apertura del form, la **colonna fornitore (sinistra)** si precompila con DaMo da quel documento.
3. La selezione del cliente popola **solo** il blocco destinatario/committente (Spett.).
4. I dati DaMo sono modificabili solo da admin (collegato a C6).

**File coinvolti.** [preventivo_form_page.dart](lib/features/preventivo/screens/preventivo_form_page.dart), [preventivo_model.dart](lib/models/preventivo_model.dart), [preventivo_pdf_service.dart](lib/services/preventivo_pdf_service.dart), nuovo documento impostazioni.

> 📝 **Da chiarire:** mi servono i **dati anagrafici completi di DaMo** (ragione sociale esatta, indirizzo, P.IVA, CU, IBAN, intestatario) da inserire come default.

---

### C2 — Indirizzo del servizio selezionabile da anagrafica 🟡 · M

**Stato:** ⬜ Da fare

**Stato attuale.** Nel preventivo l'indirizzo servizio è un campo testo (`_indirizzoServizioCtrl`, precompilato col solo `indirizzoServizio` del cliente). Nei **servizi lab** invece esiste già un dropdown che pesca gli indirizzi dall'anagrafica (`_buildDropdownIndirizzoPrelievo` + `IndirizziServizioService`).

**Richiesta.** Deve potersi **scegliere l'indirizzo del servizio dall'anagrafica**.

**Soluzione proposta.** Riusare il pattern già esistente nei servizi lab: dropdown "Indirizzo servizio" che mostra indirizzo principale + indirizzi servizio del cliente, con possibilità di override manuale.

**File coinvolti.** [preventivo_form_page.dart](lib/features/preventivo/screens/preventivo_form_page.dart), [indirizzi_servizio_service.dart](lib/services/indirizzi_servizio_service.dart) (già pronto).

---

### C3 — Oggetto: inserimento manuale o da elenco servizi 🟡 · M

**Stato:** ✅ Fatto (21/06/2026) — campo oggetto ora `CampoConSuggerimenti` (`preventivo_oggetti`): elenco a tendina + testo libero. ⏳ Da popolare la lista su Firestore.

**Stato attuale.** L'oggetto è solo testo libero (`_oggettoCtrl`, [preventivo_form_page.dart:379](lib/features/preventivo/screens/preventivo_form_page.dart#L379)).

**Richiesta.** L'oggetto deve avere **opzione inserimento manuale** e **opzione caricamento da un elenco servizi**.

**Soluzione proposta.** Campo ibrido (Autocomplete/`DropdownMenu` editabile) che attinge a un elenco gestibile (`impostazioni/preventivo_oggetti` o derivato dal listino) ma consente anche testo libero.

**File coinvolti.** [preventivo_form_page.dart](lib/features/preventivo/screens/preventivo_form_page.dart), [impostazioni_service.dart](lib/services/impostazioni_service.dart).

---

### C4 — Riga servizio/prezzo leggibile da telefono (bug UI) 🔴 · S

**Stato:** ✅ Fatto (21/06/2026) — selettore "Servizio" mobile ora su due righe (descrizione + prezzo in evidenza), `itemHeight: 72` e `selectedItemBuilder` per il campo chiuso.

**Stato attuale.** Nell'elenco di scelta del servizio il testo con il prezzo **non rientra nello schermo da telefono** (overflow). Da verificare nel selettore listino del form preventivo.

**Richiesta.** La riga dell'elenco con il prezzo deve essere **leggibile per intero anche da telefono**.

**Soluzione proposta.** Rivedere il layout della riga (Row → wrapping/`Expanded` + `Flexible`, `overflow: ellipsis` dove serve, prezzo su seconda riga o allineato a destra con larghezza fissa). Test su viewport stretta (~360px).

**File coinvolti.** [preventivo_form_page.dart](lib/features/preventivo/screens/preventivo_form_page.dart) (widget selezione voce listino).

---

### C5 — Condizioni e rinnovo da elenco + manuale 🟡 · M

**Stato:** ✅ Fatto (21/06/2026) — pagamento, durata, **rinnovo**, periodo, validità ora `CampoConSuggerimenti` (elenco + manuale). Rinnovo convertito da dropdown puro a campo editabile (`_rinnovoCtrl`). ⏳ Da popolare `preventivo_durata`/`preventivo_periodo` su Firestore (`preventivo_pagamento`/`preventivo_validita`/`preventivo_rinnovo` già esistono).

**Stato attuale.** `rinnovoScadenza` è già un dropdown (`impostazioni/preventivo_rinnovo`). `pagamento`, `durataContratto`, `validita`, `periodoIntervento` sono testo libero ([preventivo_form_page.dart:383-387](lib/features/preventivo/screens/preventivo_form_page.dart#L383)). Esistono già le liste `preventivo_pagamento` e `preventivo_validita` nelle impostazioni.

**Richiesta.** Le **condizioni** e il **rinnovo** devono essere selezionabili da elenco, con possibilità di **caricamento manuale** per casi particolari.

**Soluzione proposta.** Trasformare i campi condizioni in selettori editabili (lista da `impostazioni/*` + testo libero), sullo stesso pattern di C3.

**File coinvolti.** [preventivo_form_page.dart](lib/features/preventivo/screens/preventivo_form_page.dart), [impostazioni_service.dart](lib/services/impostazioni_service.dart).

---

### C6 — Coordinate bancarie DaMo di default, modificabili solo da admin 🟡 · M

**Stato:** ⬜ Da fare

**Stato attuale.** IBAN e intestatario sono campi liberi del preventivo; `intestatoA` viene erroneamente impostato al cliente (vedi C1). Nel PDF l'IBAN arriva dai campi del preventivo ([preventivo_pdf_service.dart:616](lib/services/preventivo_pdf_service.dart#L616)).

**Richiesta.** Le coordinate bancarie sono **sempre quelle di DaMo**: inserite di default e **modificabili solo dall'amministratore** in un'altra schermata.

**Soluzione proposta.**
1. Spostare IBAN/intestatario nel documento `impostazioni/dati_azienda` (vedi C1).
2. Precompilarli di default nel preventivo in sola lettura per i non-admin.
3. Modifica gestita nella pagina admin (`admin_settings_page.dart`), già protetta da `isAdmin`.

**File coinvolti.** [admin_settings_page.dart](lib/features/admin/screens/admin_settings_page.dart), [preventivo_form_page.dart](lib/features/preventivo/screens/preventivo_form_page.dart), [preventivo_pdf_service.dart](lib/services/preventivo_pdf_service.dart).

---

### C7 — Causale di default = codice preventivo 🟢 · S

**Stato:** ✅ Fatto (21/06/2026) — causale di default ora = `numeroFormattato` (AAMMGGxxx) via nuovo statico `PreventivoModel.formattaNumero`.

**Stato attuale.** La causale, se vuota, è generata come `'${_numeroPrev} ${ora}'` usando il **numero grezzo** (es. `1 12:40`), non il codice formattato ([preventivo_form_page.dart:354-357](lib/features/preventivo/screens/preventivo_form_page.dart#L354)).

**Richiesta.** La causale va inserita di default con lo **stesso codice del preventivo**; possibilità di nota aggiuntiva manuale.

**Soluzione proposta.** Usare `numeroFormattato` (AAMMGGxxx) come causale di default, mantenendo la possibilità di aggiungere/sovrascrivere testo.

**File coinvolti.** [preventivo_form_page.dart](lib/features/preventivo/screens/preventivo_form_page.dart).

---

### C8 — Note / condizioni offerta da elenco + manuale 🟢 · M

**Stato:** ✅ Fatto (21/06/2026) — campo note ora `CampoConSuggerimenti` (`preventivo_note`), multilinea, elenco + manuale. ⏳ Da popolare la lista su Firestore.

**Stato attuale.** Le note ("NOTE VARIE SERVIZI CONDIZIONI OFFERTA") sono testo libero (`_noteCtrl`).

**Richiesta.** Devono poter essere **caricate da un elenco specifico** oppure inserite manualmente.

**Soluzione proposta.** Elenco gestibile di note/condizioni standard (`impostazioni/preventivo_note`) inseribili nel campo, con append/manuale.

**File coinvolti.** [preventivo_form_page.dart](lib/features/preventivo/screens/preventivo_form_page.dart), [impostazioni_service.dart](lib/services/impostazioni_service.dart).

---

## D — PDF finale del preventivo

### D1 — Carta intestata simile all'esempio 🟡 · M

**Stato:** ⏸️ In attesa (serve immagine di riferimento)

**Stato attuale.** L'header è costruito con logo + sito + box "pvr off n°/ora/data/mod" ([preventivo_pdf_service.dart:131](lib/services/preventivo_pdf_service.dart#L131)). Grafica giudicata "non male" dal cliente.

**Richiesta.** La carta intestata deve avvicinarsi il più possibile all'esempio fornito (`2026_MOD_PREV_GENER.pdf`).

**Soluzione proposta.** Allineare intestazione (loghi, dati azienda, disposizione) al modello di riferimento.

> 📝 **Da chiarire / input necessario:** in questo ambiente non riesco a **renderizzare visivamente** il PDF di riferimento (manca il convertitore). Per replicare fedelmente la carta intestata mi serve **un'immagine/screenshot dell'intestazione** dell'esempio, oppure l'ok a ricostruirla da estrazione testo. Senza riferimento visivo questo punto resta parziale.

**File coinvolti.** [preventivo_pdf_service.dart](lib/services/preventivo_pdf_service.dart), `assets/images/`.

---

### D2 — Footer: aggiungere il numero del laboratorio 🟢 · S

**Stato:** ✅* Fatto parzialmente (21/06/2026) — numero laboratorio `+39 375 8622574` aggiunto al footer. ⏳ Manca il **tuo numero personale**: è una costante `_telPersonale` in cima a [preventivo_pdf_service.dart](lib/services/preventivo_pdf_service.dart) — appena me lo dai, lo compilo e diventa ✅ pieno.

**Stato attuale.** Il footer mostra `numeroFormattato — committente` e il numero pagina ([preventivo_pdf_service.dart:753](lib/services/preventivo_pdf_service.dart#L753)); non riporta i numeri di telefono.

**Richiesta.** Nella parte bassa aggiungere il **numero del laboratorio +39 375 8622574** oltre al tuo.

**Soluzione proposta.** Aggiungere al footer (o a una fascia contatti in fondo pagina) i due recapiti: numero personale + laboratorio `+39 375 8622574`.

> 📝 **Da chiarire:** confermare anche il **tuo numero** da affiancare a quello del laboratorio.

**File coinvolti.** [preventivo_pdf_service.dart](lib/services/preventivo_pdf_service.dart) (`_buildFooter`).

---

### D3 — Intestazione ripetuta su ogni pagina 🔴 · S

**Stato:** ✅ Fatto (21/06/2026) — header spostato nel callback `header:` della `MultiPage`, ora si ripete su ogni pagina.

**Stato attuale.** L'header è renderizzato **una sola volta** dentro `build:` della `MultiPage` ([preventivo_pdf_service.dart:84](lib/services/preventivo_pdf_service.dart#L84)), quindi compare solo sulla prima pagina. Solo il `footer:` si ripete.

**Richiesta.** La prima parte della pagina (intestazioni) si deve **ripetere per ogni pagina**.

**Soluzione proposta.** Spostare l'intestazione nel callback `header:` della `MultiPage` (come già fatto per `footer:`), così `pw.MultiPage` la ridisegna su ogni pagina. Togliere l'header dalla lista `build:`.

**File coinvolti.** [preventivo_pdf_service.dart](lib/services/preventivo_pdf_service.dart).

---

### D4 — Nome file PDF = codice preventivo 🔴 · S

**Stato:** ✅ Fatto (21/06/2026) — export rinominato da `preventivo_AAMMGGxxx.pdf` a `AAMMGGxxx.pdf` (web + share). Si affinerà con la decisione di B1 (reset giornaliero/ora).

**Stato attuale.** Il file è esportato come `preventivo_${numeroFormattato}.pdf` (es. `preventivo_260621001.pdf`) ([preventivo_pdf_service.dart:41,46](lib/services/preventivo_pdf_service.dart#L41)).

**Richiesta.** Il nome file deve seguire il codice del preventivo `aammggxx` **oppure** `aammgg_ora`, così i file si ordinano in modo crescente da qualsiasi PC.

**Soluzione proposta.** Rinominare l'export usando direttamente il codice senza prefisso: `${numeroFormattato}.pdf`. Con il reset giornaliero (B1) si ottiene `AAMMGGNN.pdf`; in alternativa `AAMMGG_HHMM.pdf`. Da coordinare con la decisione di B1.

**File coinvolti.** [preventivo_pdf_service.dart](lib/services/preventivo_pdf_service.dart) (`stampaPreventivo`).

---

## E — Servizi lab (nuova registrazione)

### E1 — Dropdown codice cliente: mostrare il committente, non la città 🟡 · S

**Stato:** ✅ Fatto (21/06/2026) — sottotitolo del dropdown cambiato da `numero · città` a solo `numero`; il committente resta il titolo in evidenza.

**Stato attuale.** Nell'Autocomplete il titolo mostra già il committente, ma il **sottotitolo** mostra `numero · città` ([servizio_lab_form_page.dart:1070](lib/features/servizi_lab/screens/servizio_lab_form_page.dart#L1070)). Il file è attualmente modificato (non committato), quindi da verificare lo stato esatto in esecuzione.

**Richiesta.** La voce codice cliente (menu a tendina) deve **associare il nome committente** dell'anagrafica **prima di tutto** (non la città).

**Soluzione proposta.** Garantire che committente sia l'elemento primario in lista; rimuovere/spostare la città in secondo piano (es. sottotitolo = numero, oppure committente in evidenza e città solo come dettaglio finale).

**File coinvolti.** [servizio_lab_form_page.dart](lib/features/servizi_lab/screens/servizio_lab_form_page.dart) (`_buildRicercaCliente`).

---

### E2 — Tipo analisi: suggerimento su dove caricare nuove tipologie 🟢 · S

**Stato:** ✅ Fatto (21/06/2026) — hint sotto il campo: "Per aggiungere nuove tipologie: Impostazioni → Categorie analisi".

**Stato attuale.** "Tipo analisi" è un `CategoriaDropdown(categoriaId: 'categorie_analisi')` ([servizio_lab_form_page.dart:993](lib/features/servizi_lab/screens/servizio_lab_form_page.dart#L993)) che legge gli item da `impostazioni/categorie_analisi`. Le nuove tipologie si aggiungono nella pagina impostazioni admin, ma nel form non c'è un suggerimento.

**Richiesta.** Inserire un **suggerimento su dove caricare nuove tipologie**.

**Soluzione proposta.** Aggiungere un helper text / tooltip / icona "ℹ️" accanto al campo ("Per aggiungere nuove tipologie: Impostazioni → Categorie analisi"), eventualmente con scorciatoia per admin.

**File coinvolti.** [servizio_lab_form_page.dart](lib/features/servizi_lab/screens/servizio_lab_form_page.dart), [categoria_dropdown.dart](lib/widgets/categoria_dropdown.dart).

---

### E3 — Tecnico: inserimento manuale oltre a elenco 🟡 · M

**Stato:** ✅ Fatto (21/06/2026) — campo tecnico ora `CampoConSuggerimenti` (`lab_tecnici`): elenco + inserimento manuale.

**Stato attuale.** "Tecnico" è un `CategoriaDropdown(categoriaId: 'lab_tecnici')` ([servizio_lab_form_page.dart:1004](lib/features/servizi_lab/screens/servizio_lab_form_page.dart#L1004)): `CategoriaDropdown` è **solo selezione**, non consente testo libero.

**Richiesta.** Il tecnico deve poter essere **inserito manualmente** oltre che da elenco.

**Soluzione proposta.** Sostituire il dropdown con un campo editabile (Autocomplete con opzioni da `lab_tecnici` + input libero), oppure estendere `CategoriaDropdown` con una modalità "editabile/aggiungi al volo". La seconda opzione è riusabile anche per E2/C3/C5.

**File coinvolti.** [servizio_lab_form_page.dart](lib/features/servizi_lab/screens/servizio_lab_form_page.dart), [categoria_dropdown.dart](lib/widgets/categoria_dropdown.dart).

---

### E4 — Numero: eliminare la barra "/" tra anno e progressivo 🟢 · S

**Stato:** ✅ Fatto (21/06/2026) — certificazione ora `AANNN` (es. `26001`) invece di `AA/NNN`. ⚠️ I record già salvati restano con la barra: se serve uniformare lo storico va fatta una migrazione a parte.

**Stato attuale.** La certificazione è generata nel formato `AA/NNN` → `'$anno/${prossimo}'` ([servizi_lab_service.dart:54](lib/services/servizi_lab_service.dart#L54)). È questa la "barra tra il 26 e il numero".

**Richiesta.** Se possibile, eliminare la **barra** tra il "26" e il numero.

**Soluzione proposta.** Cambiare il formato in `AANNN` (es. `26001`) o con separatore diverso se serve leggibilità. ⚠️ Valutare l'impatto su dati esistenti e sull'ordinamento (`getServiziLab` ordina per `certificazioneNumerica`): un eventuale cambio formato va gestito con coerenza sui record già salvati.

**File coinvolti.** [servizi_lab_service.dart](lib/services/servizi_lab_service.dart), eventuale migrazione dati.

---

## F — Report analitico

### F1 — Gestione parametri da pagina esterna per tipo campione 🟡 · M

**Stato:** ⬜ Da fare

**Stato attuale.** Esiste **già** la pagina **Registro** ([registro_page.dart](lib/features/registro/screens/registro_page.dart)) che gestisce i preset (categorie → parametri) e li associa ai **campioni di riferimento**; supporta anche import da CSV. Nel form servizio lab i parametri si caricano dal preset in base al campione e si gestiscono via popup.

**Richiesta.** L'aggiunta/esclusione di parametri meglio gestirla da una **pagina esterna** dove sono caricate tutte le analisi disponibili **suddivise per tipologia campione** (acque, terreni, olio idraulico…), possibilmente con la **stessa codifica** dei servizi nei preventivi.

**Soluzione proposta.**
1. Confermare la pagina Registro come "pagina esterna" ufficiale per gestire le analisi per tipo campione (è già così concettualmente).
2. Migliorare la vista "per tipologia campione" (filtro/raggruppamento esplicito per campione).
3. **Codifica unificata:** valutare un codice analisi condiviso tra Registro e listino preventivi (`impostazioni/preventivo_listino`), così la stessa voce ha lo stesso codice ovunque. → Richiede una decisione sullo schema dei codici (vedi G1, sono collegati).

**File coinvolti.** [registro_page.dart](lib/features/registro/screens/registro_page.dart), [registro_service.dart](lib/services/registro_service.dart), [registro_parametro_model.dart](lib/models/registro_parametro_model.dart), [listino_service.dart](lib/services/listino_service.dart).

---

## G — ⭐ Collegamento dati laboratorio → certificato (parte critica)

### G1 — Collegamento dei risultati delle analisi al modello certificato 🔴 · XL

**Stato:** ⏸️ In attesa (servono Excel + modello certificato)

**Contesto (workflow attuale del cliente).** Oggi i dati delle analisi vivono in un **file Excel**: il cliente carica tutti i dati, poi con un **sistema a filtri** inserisce il **numero di certificato** o il **nome cliente** e l'Excel collega i dati al **modello di certificato**. È il pezzo più delicato e **bloccante** per andare in produzione.

**Stato attuale dell'app.**
- ✅ Il **template** del certificato esiste: i parametri per tipo campione sono nel Registro (`registro_preset`) e vengono caricati nel report del servizio lab.
- ⚠️ Manca il **collegamento dei risultati misurati**: oggi nel report il campo `risultato` di ogni parametro si compila **a mano**, parametro per parametro. Non c'è import massivo né "aggancio" dei valori per numero certificato/cliente come fa l'Excel.

**Cosa serve progettare.** Replicare il flusso Excel dentro l'app significa decidere:
1. **Dove vivono i risultati** — una nuova collection (es. `risultati_analisi`) con chiave = numero certificato (e/o cliente), oppure i risultati restano dentro `servizi_lab/{id}.parametriReport[].risultato`.
2. **Come entrano i dati** — tre opzioni, non esclusive:
   - **a)** Inserimento manuale migliorato (griglia tipo foglio di calcolo nel report).
   - **b)** **Import Excel/CSV dei risultati** (estende `ImportRegistroService`): un file con colonne `[n° certificato | parametro | valore | …]` che popola automaticamente i `risultato` del certificato corrispondente.
   - **c)** Aggancio per **filtro** (numero certificato / cliente) che recupera i valori da un dataset importato — la trasposizione diretta del meccanismo Excel.
3. **Codifica condivisa** — i parametri devono avere un identificatore stabile per agganciare valore↔parametro↔campione (collegato a F1).
4. **Generazione del certificato PDF** — esiste già il PDF del preventivo come riferimento di stile, ma il **PDF del certificato** è un deliverable a sé (template, intestazione accreditamento, ecc.).

**Approccio proposto (a tappe).**
- **Fase 1 — Modello dati:** definire collection/schema dei risultati e la chiave di aggancio (numero certificato). Riusare `ParametroReport.risultato`.
- **Fase 2 — Import risultati:** parser Excel/CSV dei risultati → mappatura sui parametri del certificato per numero/cliente. Anteprima prima del salvataggio (come già fatto per l'import registro).
- **Fase 3 — Compilazione assistita:** griglia di editing dei risultati nel report, con valori precompilati dall'import.
- **Fase 4 — PDF certificato:** generazione del documento finale.

> 📝 **Input indispensabile per progettare G1.** Prima di scrivere codice mi serve:
> 1. Il **file Excel** attuale (anche con dati finti) — per vedere struttura, colonne, come sono organizzati i parametri per tipo campione.
> 2. Il **modello di certificato** finale (il template che compili).
> 3. Come avviene oggi il **collegamento**: `CERCA.VERT`/filtri? Tabella pivot? Foglio "database" + foglio "modello"?
>
> Senza questi tre elementi G1 resta in fase di analisi: è la voce che condiziona l'architettura dati di F1 e parte di E.

**File coinvolti (previsti).** Nuovi: modello risultati + servizio import risultati + PDF certificato. Esistenti da estendere: [import_registro_service.dart](lib/services/import_registro_service.dart), [servizio_lab_model.dart](lib/models/servizio_lab_model.dart), [registro_service.dart](lib/services/registro_service.dart).

---

## Roadmap consigliata (ordine di esecuzione)

Raggruppata per dare valore subito e tenere insieme i lavori che si toccano.

**Sprint 1 — Vittorie rapide ad alto impatto (PDF + bug)**
- D3 (header su ogni pagina) · D4 (nome file) · D2 (footer numero lab) · C4 (riga prezzo mobile) · C7 (causale) · E4 (barra certificazione)

**Sprint 2 — Integrità anagrafica + numerazione**
- A1 + A2 (univocità + numero più basso, insieme) · B1 (reset numerazione, decisione richiesta)

**Sprint 3 — Preventivo "intelligente"**
- C1 + C6 (DaMo di default + IBAN admin, condividono `dati_azienda`) · C2 (indirizzo servizio) · C3 + C5 + C8 (campi da elenco + manuale) · E3/E2 (componente dropdown editabile riusabile)

**Sprint 4 — Carta intestata**
- D1 (richiede immagine di riferimento)

**Sprint 5 — Laboratorio e la "parte bella"**
- F1 (pagina esterna parametri + codifica) · E1 (dropdown cliente) · **G1** (collegamento risultati — dopo aver ricevuto Excel + modello certificato)

---

## Input ancora necessari dal cliente / da te

| Rif. | Cosa serve | Stato |
|------|-----------|-------|
| C1 / C6 | Dati anagrafici completi di **DaMo** (ragione sociale, indirizzo, P.IVA, CU, **IBAN**, intestatario) | ⏳ |
| D1 | **Immagine/screenshot** dell'intestazione di riferimento (o ok a ricostruirla da testo) | ⏳ |
| D2 | Conferma del **tuo numero** da affiancare a quello del laboratorio | ⏳ |
| B1 / D4 | Decisione: progressivo **azzerato ogni giorno** *oppure* **ora** nel codice | ⏳ |
| E4 | Conferma formato certificazione senza barra (`26001`?) e gestione storico | ⏳ |
| F1 / G1 | Schema di **codifica** condivisa tra registro analisi e listino preventivi | ⏳ |
| **G1** | **File Excel** dati analisi + **modello certificato** + descrizione del meccanismo di collegamento | ⏳ |

---

## Registro avanzamento (changelog)

> Aggiornare **a ogni task iniziata/completata**: spuntare la riga nell'indice + il badge nella voce, poi aggiungere qui una riga con data, stato e nota. La voce più recente in alto.

| Data | Voce | Stato | Note |
|------|------|-------|------|
| 21/06/2026 | **Sprint 3a** | ✅ | Nuovo widget riusabile `CampoConSuggerimenti` (elenco + manuale). Applicato a C3 (oggetto), C5 (pagamento/durata/rinnovo/periodo/validità), C8 (note). Lab: E3 (tecnico editabile), E2 (hint tipo analisi), E1 (dropdown cliente mostra committente, non città). ⚠️ Da popolare su Firestore le liste `impostazioni/preventivo_{oggetti,durata,periodo,note}` per avere i suggerimenti. `flutter analyze`: 0 errori. |
| 21/06/2026 | **Sprint 2** | ✅ | A1 (unicità numero cliente), A2 (numero più basso disponibile), B1 (numerazione preventivo con reset giornaliero — decisione presa). `flutter analyze`: 0 errori. Branch `fix/segnalazioni-cliente`. |
| 21/06/2026 | **Sprint 1** | ✅ | Completate D3 (header ogni pagina), D4 (nome file), C4 (riga prezzo mobile), C7 (causale=codice), E4 (no barra certificazione). D2 ✅ parziale (manca numero personale). `flutter analyze`: 0 errori (solo info di stile preesistenti). |
| 21/06/2026 | — | 📄 Creato | Analisi del codice e stesura del piano (21 voci, A–G). Tutte ⬜ da fare; D1 e G1 ⏸️ in attesa di input. |

---

*Documento generato come piano operativo. Mantenere aggiornati indice, badge di stato e changelog a ogni intervento — è la memoria del progetto tra una sessione e l'altra.*
