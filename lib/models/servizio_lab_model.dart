import 'package:cloud_firestore/cloud_firestore.dart';

// NOTA: Creare su Firestore i seguenti documenti (se non esistono):
//   impostazioni/categorie_analisi      → items: []
//   impostazioni/campioni_riferimento   → items: []
//   impostazioni/prelevato_da           → items: []
//   impostazioni/modalita_prelievo      → items: []
//   impostazioni/rif_normativa          → items: []

/// Singolo parametro del report analitico — copia locale dal Registro
class ParametroReport {
  final String parametro;
  final String um;
  final String vl;
  final String loq;
  final String i;
  final String metodoRif;
  final String categoria;
  final String risultato; // compilato dal tecnico nel report

  const ParametroReport({
    required this.parametro,
    required this.um,
    required this.vl,
    required this.loq,
    required this.i,
    required this.metodoRif,
    required this.categoria,
    this.risultato = '',
  });

  factory ParametroReport.fromMap(Map<String, dynamic> data) {
    return ParametroReport(
      parametro: data['parametro'] as String? ?? '',
      um: data['um'] as String? ?? '',
      vl: data['vl'] as String? ?? '',
      loq: data['loq'] as String? ?? '',
      i: data['i'] as String? ?? '',
      metodoRif: data['metodoRif'] as String? ?? '',
      categoria: data['categoria'] as String? ?? '',
      risultato: data['risultato'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'parametro': parametro,
        'um': um,
        'vl': vl,
        'loq': loq,
        'i': i,
        'metodoRif': metodoRif,
        'categoria': categoria,
        'risultato': risultato,
      };

  ParametroReport copyWith({
    String? parametro,
    String? um,
    String? vl,
    String? loq,
    String? i,
    String? metodoRif,
    String? categoria,
    String? risultato,
  }) {
    return ParametroReport(
      parametro: parametro ?? this.parametro,
      um: um ?? this.um,
      vl: vl ?? this.vl,
      loq: loq ?? this.loq,
      i: i ?? this.i,
      metodoRif: metodoRif ?? this.metodoRif,
      categoria: categoria ?? this.categoria,
      risultato: risultato ?? this.risultato,
    );
  }
}

/// Modello per un servizio di analisi di laboratorio
/// Corrisponde al documento `servizi_lab/{id}` in Firestore
class ServizioLabModel {
  final String id;

  // ── Gruppo 1 — Identificazione e analisi ──────────────────────────────────
  final String codiceCliente;
  final String tipoAnalisi;
  final String certificazioneNumerica;
  final String codiceA;
  final String ora;

  // ── Gruppo 2 — Date e tempistiche ─────────────────────────────────────────
  final DateTime inizioProveGenerali;
  final DateTime? fineProveGenerali;
  final DateTime? dataEmissione;

  // ── Gruppo 3 — Dati cliente ───────────────────────────────────────────────
  final String tipoCommittente;
  final String committente;
  final String indirizzo;
  final String cap;
  final String citta;
  final String pivaCodiceFiscale;
  final String codiceUnivoco;
  final String referente;

  // ── Gruppo 4 — Campione e prelievo ────────────────────────────────────────
  final String campioneRiferimento;
  final String prelevatoDa;
  final String luogoPrelievo;
  final String capCittaPrelievo;
  final String puntoPresa;
  final String modalitaPrelievo;
  final String rifNormativa;

  // ── Gruppo Report — Parametri analitici (copia locale dal Registro) ───────
  final List<ParametroReport> parametriReport;

  // ── Gruppo 5 — Contatti cliente ───────────────────────────────────────────
  final String email;
  final String telefono;
  final String pec;

  // ── Gruppo 6 — Amministrativo ─────────────────────────────────────────────
  final String tecnico;
  final String notePrezzo;
  final bool ft;
  final bool fatturaPagata;
  final String noteTecniche;
  final bool isDraft;

  final DateTime createdAt;

  const ServizioLabModel({
    required this.id,
    required this.codiceCliente,
    required this.tipoAnalisi,
    required this.certificazioneNumerica,
    required this.codiceA,
    required this.ora,
    required this.inizioProveGenerali,
    this.fineProveGenerali,
    this.dataEmissione,
    required this.tipoCommittente,
    required this.committente,
    required this.indirizzo,
    required this.cap,
    required this.citta,
    required this.pivaCodiceFiscale,
    required this.codiceUnivoco,
    required this.referente,
    required this.campioneRiferimento,
    required this.prelevatoDa,
    required this.luogoPrelievo,
    required this.capCittaPrelievo,
    required this.puntoPresa,
    required this.modalitaPrelievo,
    required this.rifNormativa,
    this.parametriReport = const [],
    required this.email,
    required this.telefono,
    required this.pec,
    required this.notePrezzo,
    required this.ft,
    required this.fatturaPagata,
    required this.tecnico,
    required this.noteTecniche,
    this.isDraft = false,
    required this.createdAt,
  });

  factory ServizioLabModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Deserializza parametriReport
    final parametriRaw =
        (data['parametriReport'] as List<dynamic>? ?? []);
    final parametriReport = parametriRaw
        .map((e) => ParametroReport.fromMap(e as Map<String, dynamic>))
        .toList();

    return ServizioLabModel(
      id: doc.id,
      codiceCliente: data['codiceCliente'] as String? ?? '',
      tipoAnalisi: data['tipoAnalisi'] as String? ?? '',
      certificazioneNumerica:
          data['certificazioneNumerica'] as String? ?? '',
      codiceA: data['codiceA'] as String? ?? '',
      ora: data['ora'] as String? ?? '',
      inizioProveGenerali:
          (data['inizioProveGenerali'] as Timestamp?)?.toDate() ??
              DateTime.now(),
      fineProveGenerali:
          (data['fineProveGenerali'] as Timestamp?)?.toDate(),
      dataEmissione: (data['dataEmissione'] as Timestamp?)?.toDate(),
      tipoCommittente: data['tipoCommittente'] as String? ?? '',
      committente: data['committente'] as String? ?? '',
      indirizzo: data['indirizzo'] as String? ?? '',
      cap: data['cap'] as String? ?? '',
      citta: data['citta'] as String? ?? '',
      pivaCodiceFiscale: data['pivaCodiceFiscale'] as String? ?? '',
      codiceUnivoco: data['codiceUnivoco'] as String? ?? '',
      referente: data['referente'] as String? ?? '',
      campioneRiferimento: data['campioneRiferimento'] as String? ?? '',
      prelevatoDa: data['prelevatoDa'] as String? ?? '',
      luogoPrelievo: data['luogoPrelievo'] as String? ?? '',
      capCittaPrelievo: data['capCittaPrelievo'] as String? ?? '',
      puntoPresa: data['puntoPresa'] as String? ?? '',
      modalitaPrelievo: data['modalitaPrelievo'] as String? ?? '',
      rifNormativa: data['rifNormativa'] as String? ?? '',
      parametriReport: parametriReport,
      email: data['email'] as String? ?? '',
      telefono: data['telefono'] as String? ?? '',
      pec: data['pec'] as String? ?? '',
      notePrezzo: data['notePrezzo'] as String? ?? '',
      ft: data['ft'] as bool? ?? false,
      fatturaPagata: data['fatturaPagata'] as bool? ?? false,
      tecnico: data['tecnico'] as String? ?? '',
      noteTecniche: data['noteTecniche'] as String? ?? '',
      isDraft: data['isDraft'] as bool? ?? false,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'codiceCliente': codiceCliente,
      'tipoAnalisi': tipoAnalisi,
      'certificazioneNumerica': certificazioneNumerica,
      'codiceA': codiceA,
      'ora': ora,
      'inizioProveGenerali': Timestamp.fromDate(inizioProveGenerali),
      'fineProveGenerali': fineProveGenerali != null
          ? Timestamp.fromDate(fineProveGenerali!)
          : null,
      'dataEmissione': dataEmissione != null
          ? Timestamp.fromDate(dataEmissione!)
          : null,
      'tipoCommittente': tipoCommittente,
      'committente': committente,
      'indirizzo': indirizzo,
      'cap': cap,
      'citta': citta,
      'pivaCodiceFiscale': pivaCodiceFiscale,
      'codiceUnivoco': codiceUnivoco,
      'referente': referente,
      'campioneRiferimento': campioneRiferimento,
      'prelevatoDa': prelevatoDa,
      'luogoPrelievo': luogoPrelievo,
      'capCittaPrelievo': capCittaPrelievo,
      'puntoPresa': puntoPresa,
      'modalitaPrelievo': modalitaPrelievo,
      'rifNormativa': rifNormativa,
      'parametriReport': parametriReport.map((p) => p.toMap()).toList(),
      'email': email,
      'telefono': telefono,
      'pec': pec,
      'notePrezzo': notePrezzo,
      'ft': ft,
      'fatturaPagata': fatturaPagata,
      'tecnico': tecnico,
      'noteTecniche': noteTecniche,
      'isDraft': isDraft,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  String toString() =>
      'ServizioLabModel(id: $id, cert: $certificazioneNumerica, committente: $committente)';
}
