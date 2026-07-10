# TEST DA FARE — BioChem

> Checklist di verifica per le aree completate. Prova su **staging** (desktop **e** mobile).
> Spunta `[x]` quando ok; annota sotto il punto eventuali problemi.
> Legenda esito: ⬜ da provare · ✅ ok · ❌ problema (descrivi)

**Ultimo aggiornamento:** 10/07/2026

---

## AREA A — Navigazione & Home

### Desktop
- [ ] All'avvio (dopo login) l'app **atterra sulla Home** (non più su Anagrafiche).
- [ ] La Home mostra una **griglia di card** con tutte le sezioni (icona + titolo + sottotitolo).
- [ ] Il **menu laterale** ha *Home* in cima e i gruppi **PRINCIPALE / LABORATORIO / AMMINISTRAZIONE**.
- [ ] Cliccando una card si apre la sezione giusta; la voce corrispondente nel menu si evidenzia.
- [ ] Le voci **Registro** e **Configurazione** (gruppo AMMINISTRAZIONE) aprono le rispettive pagine con il tasto **indietro**.

### Mobile
- [ ] La **bottom-nav** mostra 5 voci: **Home · Anagrafiche · Preventivo · Reg Lab · Servizi Pest** (Fatture **non** c'è più).
- [ ] La Home mostra la griglia a **2 colonne** (solo titolo).
- [ ] **Fatture** e **Calendario** si raggiungono dalle card in Home.

### Profilo (desktop e mobile)
- [ ] Il pannello Profilo mostra **solo** info account + logout (niente più Calendario/Registro/Impostazioni).

---

## AREA B — Configurazione (B1)

- [ ] La pagina che prima si chiamava **"Impostazioni"** ora si chiama **"Configurazione"** (titolo in alto).
- [ ] Gli avvisi/hint nei form che rimandavano a "Impostazioni → …" ora dicono **"Configurazione → …"** (es. campo listino preventivo, IBAN, categorie analisi).
- [ ] L'editor **Dati azienda (DaMo)** è dentro Configurazione (non nel Profilo).

> B2 (redesign UX) e B3 (macro-sezioni gestibili) sono **da fare in un pass dedicato** — non ancora testabili.

---

## AREA C — Sezioni Laboratorio (Cationi / Primarie / Anioni / Microbiologia)

Ripetere per **ognuna** delle 4 sezioni:
- [ ] La sezione si apre da Home e da menu laterale (gruppo LABORATORIO).
- [ ] Con **"Aggiungi"** si apre il form; **"Scegli"** apre l'elenco dei campioni di **Reg Lab** e, selezionandone uno, si compilano **n° certificato / cod A / committente**.
- [ ] Inserendo alcuni valori e salvando, la riga compare nella lista (n° certificato + committente + `n/tot valori`).
- [ ] Toccando una riga si **rientra in modifica** con i valori salvati.
- [ ] L'**eliminazione** chiede conferma e rimuove la riga.
- [ ] La **ricerca** filtra per committente / n° certificato.
- [ ] **Import CSV**: caricando un CSV compaiono il conteggio righe e le eventuali colonne non trovate; confermando, le righe vengono importate.

> ⚠️ **Import CSV — mapping provvisorio.** Le colonne sono riconosciute per **nome intestazione**. Serve un **CSV d'esempio reale** per confermare/aggiustare i nomi delle colonne attesi.

---

## AREA D — Stampa unione

- [ ] La sezione si apre e mostra **una riga per certificato**, ordinata per n° certificato.
- [ ] Ogni riga mostra committente, cod A e **quante analisi** su 4 sono compilate.
- [ ] Espandendo una riga si vedono i **valori per famiglia** (Primarie/Cationi/Anioni/Microbio); le famiglie non compilate risultano "non compilata".
- [ ] Il pulsante **Ricarica** aggiorna i dati dopo aver inserito nuovi risultati.
- [ ] La ricerca filtra per committente / n° certificato.

---

## Note / problemi riscontrati

_(scrivi qui sotto, indicando l'area e il punto)_
