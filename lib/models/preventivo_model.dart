import 'package:cloud_firestore/cloud_firestore.dart';

// NOTA: Firestore da creare se non esiste:
//   Collection 'preventivi'          → documenti PreventivoModel
//   contatori/preventivi_YYYY        → { ultimo: 0 }  (YYYY = anno corrente)

// ─── Riga servizio del preventivo ─────────────────────────────────────────────

/// Singola riga del preventivo (voce di servizio dal listino).
/// Salvata come Map nel campo 'righe' del documento preventivo.
class PreventivoRiga {
  /// Codice del servizio (es. "P_DSF2")
  final String codice;

  /// Descrizione del servizio
  final String descrizione;

  /// Giornata di esecuzione (da preventivo_giornata)
  final String giornata;

  /// Prezzo unitario (auto-compilato dal listino, modificabile)
  final double prezzoUnitario;

  /// Quantità (numero di interventi)
  final int quantita;

  /// Sconto percentuale applicato
  final double scontoPerc;

  /// Importo calcolato: (prezzoUnitario - prezzoUnitario*sconto/100) * quantita
  final double importo;

  const PreventivoRiga({
    required this.codice,
    required this.descrizione,
    required this.giornata,
    required this.prezzoUnitario,
    required this.quantita,
    required this.scontoPerc,
    required this.importo,
  });

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

/// Modello per un preventivo commerciale.
/// Corrisponde al documento `preventivi/{id}` in Firestore.
class PreventivoModel {
  final String id;

  // ── Identificazione ────────────────────────────────────────────────────────
  /// Numero progressivo per anno (es. 1, 2, 3…)
  final int numeroPrev;

  /// Data di emissione del preventivo
  final DateTime data;

  /// ID Firestore del cliente (snapshot al momento del salvataggio)
  final String codiceCliente;

  // ── Dati cliente (snapshot da anagrafica) ─────────────────────────────────
  final String tipoCommittente;
  final String committente;
  final String indirizzoCommittente;
  final String cap;
  final String citta;
  final String provincia;
  final String codiceFiscale;
  final String codiceUnivoco;
  final String referente;

  // ── Righe servizi ─────────────────────────────────────────────────────────
  final List<PreventivoRiga> righe;

  // ── Condizioni ────────────────────────────────────────────────────────────
  /// Da preventivo_validita: "30 giorni", "60 giorni", "90 giorni"
  final String validita;

  /// Da preventivo_pagamento: "Bonifico", "Contanti", …
  final String modalitaPagamento;

  /// Da preventivo_rinnovo: "Sì", "No"
  final String rinnovo;

  // ── Totali ────────────────────────────────────────────────────────────────
  /// Aliquota IVA in percentuale (es. 22.0)
  final double percIva;

  /// Somma degli importi di tutte le righe
  final double imponibile;

  /// imponibile * percIva / 100
  final double importoIva;

  /// imponibile + importoIva
  final double totale;

  // ── Extra ─────────────────────────────────────────────────────────────────
  final String note;
  final bool isDraft;
  final DateTime createdAt;

  const PreventivoModel({
    required this.id,
    required this.numeroPrev,
    required this.data,
    required this.codiceCliente,
    required this.tipoCommittente,
    required this.committente,
    required this.indirizzoCommittente,
    required this.cap,
    required this.citta,
    required this.provincia,
    required this.codiceFiscale,
    required this.codiceUnivoco,
    required this.referente,
    required this.righe,
    required this.validita,
    required this.modalitaPagamento,
    required this.rinnovo,
    required this.percIva,
    required this.imponibile,
    required this.importoIva,
    required this.totale,
    required this.note,
    this.isDraft = false,
    required this.createdAt,
  });

  /// Numero formattato per la UI: PREV-2026-001
  String get numeroFormattato {
    return 'PREV-${data.year}-${numeroPrev.toString().padLeft(3, '0')}';
  }

  factory PreventivoModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    // Deserializza le righe dalla lista di Map
    final rawRighe = d['righe'] as List<dynamic>? ?? [];
    final righe = rawRighe
        .whereType<Map<String, dynamic>>()
        .map(PreventivoRiga.fromMap)
        .toList();

    return PreventivoModel(
      id: doc.id,
      numeroPrev: (d['numeroPrev'] as num?)?.toInt() ?? 0,
      data: (d['data'] as Timestamp?)?.toDate() ?? DateTime.now(),
      codiceCliente: d['codiceCliente'] as String? ?? '',
      tipoCommittente: d['tipoCommittente'] as String? ?? '',
      committente: d['committente'] as String? ?? '',
      indirizzoCommittente: d['indirizzoCommittente'] as String? ?? '',
      cap: d['cap'] as String? ?? '',
      citta: d['citta'] as String? ?? '',
      provincia: d['provincia'] as String? ?? '',
      codiceFiscale: d['codiceFiscale'] as String? ?? '',
      codiceUnivoco: d['codiceUnivoco'] as String? ?? '',
      referente: d['referente'] as String? ?? '',
      righe: righe,
      validita: d['validita'] as String? ?? '',
      modalitaPagamento: d['modalitaPagamento'] as String? ?? '',
      rinnovo: d['rinnovo'] as String? ?? '',
      percIva: (d['percIva'] as num?)?.toDouble() ?? 22.0,
      imponibile: (d['imponibile'] as num?)?.toDouble() ?? 0.0,
      importoIva: (d['importoIva'] as num?)?.toDouble() ?? 0.0,
      totale: (d['totale'] as num?)?.toDouble() ?? 0.0,
      note: d['note'] as String? ?? '',
      isDraft: d['isDraft'] as bool? ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'numeroPrev': numeroPrev,
        'data': Timestamp.fromDate(data),
        'codiceCliente': codiceCliente,
        'tipoCommittente': tipoCommittente,
        'committente': committente,
        'indirizzoCommittente': indirizzoCommittente,
        'cap': cap,
        'citta': citta,
        'provincia': provincia,
        'codiceFiscale': codiceFiscale,
        'codiceUnivoco': codiceUnivoco,
        'referente': referente,
        'righe': righe.map((r) => r.toMap()).toList(),
        'validita': validita,
        'modalitaPagamento': modalitaPagamento,
        'rinnovo': rinnovo,
        'percIva': percIva,
        'imponibile': imponibile,
        'importoIva': importoIva,
        'totale': totale,
        'note': note,
        'isDraft': isDraft,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  @override
  String toString() =>
      'PreventivoModel(id: $id, numero: $numeroFormattato, committente: $committente)';
}
