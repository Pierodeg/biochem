# Alcune domande per completare l'app — BioChem

Ciao! Per finire le ultime parti dell'applicazione mi servono alcune informazioni e qualche file.
Dove puoi, rispondi pure direttamente sotto ogni punto. Grazie!

---

## 1. Certificati di analisi (la parte più importante)

Per far sì che l'app generi i certificati come fai oggi, mi servono:

- **Il file Excel** che usi attualmente per gestire i dati delle analisi (va benissimo anche con
  **dati finti/di esempio**). Mi serve solo per capire com'è organizzato.
  > _Risposta:_ Condiviso un registro editabile, con più fogli (es. uno per le analisi primarie,
  > uno per i metalli, ecc.). ⚠️ **Il file vero e proprio non è ancora arrivato qui — da recuperare.**

- **Il modello di certificato** che compili (il documento finale che consegni al cliente).
  > _Risposta:_ Ha una struttura di base sempre uguale; i risultati inseriti cambiano in base alla
  > tipologia di analisi richiesta. ⚠️ **File del modello non ancora arrivato — da recuperare.**

- Come **colleghi oggi i dati al certificato**? Per esempio: scrivi un numero di certificato o un
  nome cliente e l'Excel riempie il modello? Usi filtri o formule?
  > _Risposta:_ Filtro su una colonna a scelta del foglio registro (es. colonna "referente" →
  > Mario Rossi, eventualmente combinato con un filtro per anno). Il cliente lo paragona alla
  > "stampa unione" di Word.

- Il collegamento avviene tramite **numero di certificato**, **nome del cliente**, o **entrambi**?
  > _Risposta:_ Non è un aggancio fisso: è un filtro libero su qualsiasi colonna del registro
  > (referente, anno, ecc.), non solo numero certificato o nome cliente.

---

## 2. Carta intestata del preventivo

- Hai il **logo** in buona qualità (file immagine)? Se sì, puoi allegarlo.
  > _Risposta / allegato:_ ⏳ non ancora arrivato.

- In alto nel preventivo c'è un codice tipo **"rif. MQ_20251028_rev00"**: cosa indica?
  Deve restare **sempre uguale** o cambiare di volta in volta?
  > _Risposta:_ È un riferimento al Manuale di Qualità. Cambia solo quando viene aggiornato il
  > manuale o il logo di qualità (in caso di ente esterno) — quindi resta **fisso** normalmente.

- La carta intestata attuale ti va bene così com'è, oppure ci sono **dettagli da sistemare**
  rispetto al tuo modello?
  > _Risposta:_ Rimanda al modello preventivo già condiviso, accennando che "forse cambia
  > qualcosa in quello nuovo" — ⚠️ **da chiarire**: esiste un modello aggiornato più recente di
  > `2026_MOD_PREV_GENER.pdf`?

---

## 3. Numero del preventivo

Come preferisci che sia il **codice del preventivo** (e il nome del file PDF)?

- [x] **Numero progressivo del giorno** → esempio: `260625001`
- [x] **Data + ora** → esempio: `260625_16:00`

> _Preferenza:_ Vanno bene entrambi → si mantiene il formato già in uso (progressivo del giorno).

---

## 4. Numero del certificato (servizi di laboratorio)

- Va bene il numero **senza barra**, esempio **`26001`**? (così è ora)
  > _Conferma:_ Sì, confermato — tenendo conto che si potrebbero **superare i 1000 certificati
  > all'anno** (⚠️ il formato attuale a 3 cifre non ci arriva, va corretto).

- I certificati **già salvati** con il vecchio formato (es. `26/001`): vuoi **sistemarli** per
  uniformarli, oppure li lasciamo come sono?
  > _Risposta:_ Non ci sono certificati con il vecchio formato — nessuna migrazione necessaria.

---

## 5. Analisi per tipo di campione

- La pagina dove gestisci oggi i parametri delle analisi ti **basta così**, oppure vorresti una
  gestione divisa per **tipo di campione** (acque, terreni, oli, ecc.)?
  > _Risposta:_ Sì, meglio dividere per tipo campione, seguendo la stessa codifica delle tipologie
  > di servizio, con la possibilità di aggiungere parametri.

---

## 6. Elenchi per i menu a tendina

Per velocizzare la compilazione, l'app può proporti delle scelte già pronte. Mi mandi gli elenchi
che usi più spesso?

- **Oggetti** tipici del preventivo (le descrizioni che scrivi più spesso):
  > _Elenco:_

- **Durate del contratto** più comuni:
  > _Elenco:_

- **Periodi di intervento** abituali:
  > _Elenco:_

- **Note / condizioni** standard che inserisci nelle offerte:
  > _Elenco:_

> ⏳ Non ancora ricevuti elenchi puntuali — il cliente ha rimandato al "modello preventivo
> condiviso"; da richiedere di nuovo in modo specifico.

---

Grazie mille! Con queste informazioni posso completare le ultime parti. 🙌
