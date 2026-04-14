import 'package:cloud_firestore/cloud_firestore.dart';

// NOTA: Creare su Firestore i seguenti documenti (se non esistono):
//   impostazioni/categorie_analisi      → items: []
//   impostazioni/campioni_riferimento   → items: []
//   impostazioni/prelevato_da           → items: []
//   impostazioni/modalita_prelievo      → items: []
//   impostazioni/rif_normativa          → items: []

/// Modello per un servizio di analisi di laboratorio
/// Corrisponde al documento `servizi_lab/{id}` in Firestore
class ServizioLabModel {
  final String id;

  // ── Gruppo 1 — Identificazione e analisi ───────────────────────────────────
  /// ID Firestore del cliente (snapshot al momento del salvataggio)
  final String codiceCliente;
  final String tipoAnalisi;
  /// Formato "AA/NNN" es. "26/001"
  final String certificazioneNumerica;
  /// Formato AAMMGG es. "260330"
  final String codiceA;
  /// Formato HH:mm
  final String ora;

  // ── Gruppo 2 — Date e tempistiche ─────────────────────────────────────────
  final DateTime inizioProveGenerali;
  final DateTime? fineProveGenerali;
  final DateTime? dataEmissione;

  // ── Gruppo 3 — Dati cliente (snapshot da anagrafica) ──────────────────────
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

  // ── Gruppo 5 — Contatti cliente (snapshot da anagrafica) ──────────────────
  final String email;
  final String telefono;
  final String pec;

  // ── Gruppo 6 — Amministrativo ─────────────────────────────────────────────
  /// Tecnico responsabile dell'analisi (da categoria 'lab_tecnici')
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

  /// Crea un [ServizioLabModel] da un documento Firestore
  factory ServizioLabModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ServizioLabModel(
      id: doc.id,
      codiceCliente: data['codiceCliente'] as String? ?? '',
      tipoAnalisi: data['tipoAnalisi'] as String? ?? '',
      certificazioneNumerica: data['certificazioneNumerica'] as String? ?? '',
      codiceA: data['codiceA'] as String? ?? '',
      ora: data['ora'] as String? ?? '',
      inizioProveGenerali:
          (data['inizioProveGenerali'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fineProveGenerali:
          (data['fineProveGenerali'] as Timestamp?)?.toDate(),
      dataEmissione:
          (data['dataEmissione'] as Timestamp?)?.toDate(),
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

  /// Converte il modello in una mappa per Firestore
  Map<String, dynamic> toMap() {
    return {
      'codiceCliente': codiceCliente,
      'tipoAnalisi': tipoAnalisi,
      'certificazioneNumerica': certificazioneNumerica,
      'codiceA': codiceA,
      'ora': ora,
      'inizioProveGenerali': Timestamp.fromDate(inizioProveGenerali),
      'fineProveGenerali':
          fineProveGenerali != null ? Timestamp.fromDate(fineProveGenerali!) : null,
      'dataEmissione':
          dataEmissione != null ? Timestamp.fromDate(dataEmissione!) : null,
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
