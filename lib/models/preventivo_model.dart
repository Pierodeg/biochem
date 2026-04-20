import 'package:cloud_firestore/cloud_firestore.dart';

// NOTA Firestore:
//   Collection 'preventivi'       → documenti PreventivoModel
//   contatori/preventivi_YYYY     → { ultimo: 0 }  (YYYY = anno corrente)

// ─── Riga servizio ────────────────────────────────────────────────────────────

/// Singola riga del preventivo (voce di servizio dal listino).
class PreventivoRiga {
  /// Codice servizio (es. "P_DSF2")
  final String codice;

  /// Descrizione del servizio
  final String descrizione;

  /// Giornata esecuzione (non più per riga — mantenuto per compatibilità)
  final String giornata;

  /// Prezzo unitario (cad)
  final double prezzoUnitario;

  /// Quantità (num)
  final int quantita;

  /// Sconto percentuale (sct %)
  final double scontoPerc;

  /// Importo calcolato: (prezzoUnitario - prezzoUnitario*scontoPerc/100) * quantita
  /// Corrisponde a "tot" nel documento
  final double importo;

  const PreventivoRiga({
    required this.codice,
    required this.descrizione,
    this.giornata = '',
    required this.prezzoUnitario,
    required this.quantita,
    required this.scontoPerc,
    required this.importo,
  });

  /// Costo annuo/servizio calcolato (cst an/ser):
  /// prezzo unitario scontato * quantita
  double get costoAnnoServizio =>
      quantita > 0 ? importo : (prezzoUnitario - prezzoUnitario * scontoPerc / 100);

  factory PreventivoRiga.fromMap(Map<String, dynamic> m) => PreventivoRiga(
        codice: m['codice'] as String? ?? '',
        descrizione: m['descrizione'] as String? ?? '',
        giornata: m['giornata'] as String? ?? '',
        prezzoUnitario: (m['prezzoUnitario'] as num?)?.toDouble() ?? 0.0,
        quantita: (m['quantita'] as num?)?.toInt() ?? 0,
        scontoPerc: (m['scontoPerc'] as num?)?.toDouble() ?? 0.0,
        importo: (m['importo'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toMap() => {
        'codice': codice,
        'descrizione': descrizione,
        'giornata': giornata,
        'prezzoUnitario': prezzoUnitario,
        'quantita': quantita,
        'scontoPerc': scontoPerc,
        'importo': importo,
      };
}

// ─── Modello preventivo ───────────────────────────────────────────────────────

/// Modello per un preventivo commerciale BioChem.
/// Corrisponde al documento `preventivi/{id}` in Firestore.
class PreventivoModel {
  final String id;

  // ── Intestazione documento ─────────────────────────────────────────────────
  /// Numero progressivo per anno (es. 1, 2, 3…)
  final int numeroPrev;

  /// Data di emissione
  final DateTime data;

  /// Ora di emissione (es. "12:40")
  final String ora;

  /// ID Firestore del cliente collegato
  final String codiceCliente;

  // ── Dati azienda — colonna sinistra ───────────────────────────────────────
  final String committente;
  final String indirizzoCommittente;
  final String cap;
  final String citta;
  final String provincia;
  final String codiceFiscale;
  final String codiceUnivoco;

  // ── Spett. / destinatario — colonna destra ────────────────────────────────
  /// Spett. (ragione sociale destinatario)
  final String spett;

  /// Alla cortese att. di (referente destinatario)
  final String allaCorteseDi;

  /// Indirizzo destinatario
  final String indirizzoSpett;

  /// Città/CAP destinatario
  final String cittaSpett;

  /// P.I. destinatario
  final String piSpett;

  /// CU destinatario
  final String cuSpett;

  // ── Indirizzo servizio e oggetto ──────────────────────────────────────────
  /// Indirizzo dove viene eseguito il servizio
  final String indirizzoServizio;

  /// Oggetto del preventivo
  final String oggetto;

  // ── Dettaglio servizi ─────────────────────────────────────────────────────
  /// Giornata/esecuzione (es. FERIALE, FESTIVO) — campo unico sopra tabella
  final String giornataEsecuzione;

  /// Tipologia servizi (es. Pest Control, Analisi Lab)
  final String tipologiaServizi;

  /// Righe della tabella servizi
  final List<PreventivoRiga> righe;

  // ── Condizioni ────────────────────────────────────────────────────────────
  /// Modalità di pagamento (es. "≥ 60 giorni da esecuzione")
  final String pagamento;

  /// Durata contratto (es. "non specificata")
  final String durataContratto;

  /// Rinnovo a scadenza (es. "Sì", "No")
  final String rinnovoScadenza;

  /// Periodo intervento
  final String periodoIntervento;

  /// Validità offerta (es. "30 giorni")
  final String validita;

  // ── Note ─────────────────────────────────────────────────────────────────
  final String note;

  // ── Coordinate bancarie ───────────────────────────────────────────────────
  /// IBAN (es. "IT13J0101585100000070694786")
  final String iban;

  /// Intestato a
  final String intestatoA;

  /// Causale pagamento (auto-generata se vuota: numeroPrev + ora)
  final String causale;

  // ── Totali ────────────────────────────────────────────────────────────────
  /// Somma importi righe (senza IVA — il documento non mostra IVA separata)
  final double imponibile;

  /// Totale documento
  final double totale;

  // ── Stato ─────────────────────────────────────────────────────────────────
  final bool isDraft;
  final DateTime createdAt;

  const PreventivoModel({
    required this.id,
    required this.numeroPrev,
    required this.data,
    this.ora = '',
    required this.codiceCliente,
    required this.committente,
    required this.indirizzoCommittente,
    required this.cap,
    required this.citta,
    required this.provincia,
    required this.codiceFiscale,
    required this.codiceUnivoco,
    this.spett = '',
    this.allaCorteseDi = '',
    this.indirizzoSpett = '',
    this.cittaSpett = '',
    this.piSpett = '',
    this.cuSpett = '',
    this.indirizzoServizio = '',
    this.oggetto = '',
    this.giornataEsecuzione = '',
    this.tipologiaServizi = '',
    required this.righe,
    this.pagamento = '',
    this.durataContratto = '',
    this.rinnovoScadenza = '',
    this.periodoIntervento = '',
    this.validita = '',
    this.note = '',
    this.iban = '',
    this.intestatoA = '',
    this.causale = '',
    required this.imponibile,
    required this.totale,
    this.isDraft = false,
    required this.createdAt,
  });

  /// Numero formattato per display rapido: AAMMGG001
  String get numeroFormattato {
    if (numeroPrev == 0) return 'Bozza';
    final aa = data.year % 100;
    final mm = data.month.toString().padLeft(2, '0');
    final gg = data.day.toString().padLeft(2, '0');
    return '$aa$mm$gg${numeroPrev.toString().padLeft(3, '0')}';
  }

  /// Numero leggibile per UI lista: es. "PREV-2026-001"
  String get numeroLeggibile {
    if (numeroPrev == 0) return 'Bozza';
    return 'PREV-${data.year}-${numeroPrev.toString().padLeft(3, '0')}';
  }

  factory PreventivoModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    final rawRighe = d['righe'] as List<dynamic>? ?? [];
    final righe = rawRighe
        .whereType<Map<String, dynamic>>()
        .map(PreventivoRiga.fromMap)
        .toList();

    return PreventivoModel(
      id: doc.id,
      numeroPrev: (d['numeroPrev'] as num?)?.toInt() ?? 0,
      data: (d['data'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ora: d['ora'] as String? ?? '',
      codiceCliente: d['codiceCliente'] as String? ?? '',
      committente: d['committente'] as String? ?? '',
      indirizzoCommittente: d['indirizzoCommittente'] as String? ?? '',
      cap: d['cap'] as String? ?? '',
      citta: d['citta'] as String? ?? '',
      provincia: d['provincia'] as String? ?? '',
      codiceFiscale: d['codiceFiscale'] as String? ?? '',
      codiceUnivoco: d['codiceUnivoco'] as String? ?? '',
      spett: d['spett'] as String? ?? '',
      allaCorteseDi: d['allaCorteseDi'] as String? ?? '',
      indirizzoSpett: d['indirizzoSpett'] as String? ?? '',
      cittaSpett: d['cittaSpett'] as String? ?? '',
      piSpett: d['piSpett'] as String? ?? '',
      cuSpett: d['cuSpett'] as String? ?? '',
      indirizzoServizio: d['indirizzoServizio'] as String? ?? '',
      oggetto: d['oggetto'] as String? ?? '',
      giornataEsecuzione: d['giornataEsecuzione'] as String? ?? '',
      tipologiaServizi: d['tipologiaServizi'] as String? ?? '',
      righe: righe,
      pagamento: d['pagamento'] as String? ?? '',
      durataContratto: d['durataContratto'] as String? ?? '',
      rinnovoScadenza: d['rinnovoScadenza'] as String? ?? '',
      periodoIntervento: d['periodoIntervento'] as String? ?? '',
      validita: d['validita'] as String? ?? '',
      note: d['note'] as String? ?? '',
      iban: d['iban'] as String? ?? '',
      intestatoA: d['intestatoA'] as String? ?? '',
      causale: d['causale'] as String? ?? '',
      imponibile: (d['imponibile'] as num?)?.toDouble() ?? 0.0,
      totale: (d['totale'] as num?)?.toDouble() ?? 0.0,
      isDraft: d['isDraft'] as bool? ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'numeroPrev': numeroPrev,
        'data': Timestamp.fromDate(data),
        'ora': ora,
        'codiceCliente': codiceCliente,
        'committente': committente,
        'indirizzoCommittente': indirizzoCommittente,
        'cap': cap,
        'citta': citta,
        'provincia': provincia,
        'codiceFiscale': codiceFiscale,
        'codiceUnivoco': codiceUnivoco,
        'spett': spett,
        'allaCorteseDi': allaCorteseDi,
        'indirizzoSpett': indirizzoSpett,
        'cittaSpett': cittaSpett,
        'piSpett': piSpett,
        'cuSpett': cuSpett,
        'indirizzoServizio': indirizzoServizio,
        'oggetto': oggetto,
        'giornataEsecuzione': giornataEsecuzione,
        'tipologiaServizi': tipologiaServizi,
        'righe': righe.map((r) => r.toMap()).toList(),
        'pagamento': pagamento,
        'durataContratto': durataContratto,
        'rinnovoScadenza': rinnovoScadenza,
        'periodoIntervento': periodoIntervento,
        'validita': validita,
        'note': note,
        'iban': iban,
        'intestatoA': intestatoA,
        'causale': causale,
        'imponibile': imponibile,
        'totale': totale,
        'isDraft': isDraft,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  @override
  String toString() =>
      'PreventivoModel(id: $id, numero: $numeroLeggibile, committente: $committente)';
}
