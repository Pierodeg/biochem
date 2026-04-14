import 'package:cloud_firestore/cloud_firestore.dart';

// NOTA: Creare su Firestore i seguenti documenti (se non esistono):
//   impostazioni/pest_tipi_intervento       → items: []
//   impostazioni/pest_numero_intervento     → items: []
//   impostazioni/pest_tecnici              → items: []
//   impostazioni/pest_prodotti             → items: []
//   impostazioni/pest_ulteriori_interventi  → items: []
//   impostazioni/pest_voci_economiche       → items: []

/// Modello per un intervento Pest Control
/// Corrisponde al documento `servizi_pest/{id}` in Firestore
class ServizioPestModel {
  final String id;

  // ── Gruppo 1 — Identificazione intervento ─────────────────────────────────
  /// ID Firestore del cliente (snapshot al momento del salvataggio)
  final String codiceCliente;
  final String tipoIntervento;  // da pest_tipi_intervento
  final String numeroIntervento; // da pest_numero_intervento
  /// Formato AAMMGG es. "260412"
  final String codiceData;
  /// Formato HH:mm
  final String ora;
  final String tecnico; // da pest_tecnici

  // ── Gruppo 2 — Dati cliente (snapshot da anagrafica) ─────────────────────
  final String tipoCommittente;
  final String committente;
  final String indirizzoCommittente;
  final String cap;
  final String citta;
  final String provincia;
  final String codiceFiscale;
  final String codiceUnivoco;
  final String referente;

  // ── Gruppo 3 — Dati intervento ────────────────────────────────────────────
  final String indirizzoIntervento;
  final String capCittaProvIntervento;
  final String prodotti; // da pest_prodotti
  final String noteAreeIntervento;
  final String noteAzioniCorrettive;

  // ── Gruppo 4 — Ulteriori interventi ──────────────────────────────────────
  final String ulterioriInterventi; // da pest_ulteriori_interventi
  final String codiceDataUlteriore; // AAMMGG auto-generato dalla data scelta
  final String oraUlteriore;
  final String noteAzioniCorrettiveUlteriori;

  // ── Gruppo 5 — Voci economiche A ─────────────────────────────────────────
  final String voceA; // da pest_voci_economiche
  final double costoVoceA;
  final int nInterventiA;
  final double scontoPercA;
  final double parzialeA;   // calcolato: (costo - costo*sconto/100) * nInterv
  final double ivaA;        // calcolato: parziale * 22/100
  final double ritenutaPercA;
  final double valRitenutaA; // calcolato: -parziale * ritenutaPerc/100
  final double totA;         // calcolato: parziale + IVA + ritenuta

  // ── Voci economiche B ─────────────────────────────────────────────────────
  final String voceB;
  final double costoVoceB;
  final int nInterventiB;
  final double scontoPercB;
  final double parzialeB;
  final double ivaB;
  final double ritenutaPercB;
  final double valRitenutaB;
  final double totB;

  // ── Voci economiche C ─────────────────────────────────────────────────────
  final String voceC;
  final double costoVoceC;
  final int nInterventiC;
  final double scontoPercC;
  final double parzialeC;
  final double ivaC;
  final double ritenutaPercC;
  final double valRitenutaC;
  final double totC;

  // ── Totali calcolati ──────────────────────────────────────────────────────
  final double parzialeTot;  // parzialeA + parzialeB + parzialeC
  final double ivaTot;       // ivaA + ivaB + ivaC
  final double ritenute;     // valRitenutaA + valRitenutaB + valRitenutaC
  final double totaleDovuto; // totA + totB + totC

  // ── Gruppo 6 — Amministrativo ─────────────────────────────────────────────
  final String ulterioriNote;
  final String contatti;
  final String email;
  final bool isDraft;

  final DateTime createdAt;

  const ServizioPestModel({
    required this.id,
    required this.codiceCliente,
    required this.tipoIntervento,
    required this.numeroIntervento,
    required this.codiceData,
    required this.ora,
    required this.tecnico,
    required this.tipoCommittente,
    required this.committente,
    required this.indirizzoCommittente,
    required this.cap,
    required this.citta,
    required this.provincia,
    required this.codiceFiscale,
    required this.codiceUnivoco,
    required this.referente,
    required this.indirizzoIntervento,
    required this.capCittaProvIntervento,
    required this.prodotti,
    required this.noteAreeIntervento,
    required this.noteAzioniCorrettive,
    required this.ulterioriInterventi,
    required this.codiceDataUlteriore,
    required this.oraUlteriore,
    required this.noteAzioniCorrettiveUlteriori,
    required this.voceA,
    required this.costoVoceA,
    required this.nInterventiA,
    required this.scontoPercA,
    required this.parzialeA,
    required this.ivaA,
    required this.ritenutaPercA,
    required this.valRitenutaA,
    required this.totA,
    required this.voceB,
    required this.costoVoceB,
    required this.nInterventiB,
    required this.scontoPercB,
    required this.parzialeB,
    required this.ivaB,
    required this.ritenutaPercB,
    required this.valRitenutaB,
    required this.totB,
    required this.voceC,
    required this.costoVoceC,
    required this.nInterventiC,
    required this.scontoPercC,
    required this.parzialeC,
    required this.ivaC,
    required this.ritenutaPercC,
    required this.valRitenutaC,
    required this.totC,
    required this.parzialeTot,
    required this.ivaTot,
    required this.ritenute,
    required this.totaleDovuto,
    required this.ulterioriNote,
    required this.contatti,
    required this.email,
    this.isDraft = false,
    required this.createdAt,
  });

  /// Crea un [ServizioPestModel] da un documento Firestore
  factory ServizioPestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ServizioPestModel(
      id: doc.id,
      codiceCliente: data['codiceCliente'] as String? ?? '',
      tipoIntervento: data['tipoIntervento'] as String? ?? '',
      numeroIntervento: data['numeroIntervento'] as String? ?? '',
      codiceData: data['codiceData'] as String? ?? '',
      ora: data['ora'] as String? ?? '',
      tecnico: data['tecnico'] as String? ?? '',
      tipoCommittente: data['tipoCommittente'] as String? ?? '',
      committente: data['committente'] as String? ?? '',
      indirizzoCommittente: data['indirizzoCommittente'] as String? ?? '',
      cap: data['cap'] as String? ?? '',
      citta: data['citta'] as String? ?? '',
      provincia: data['provincia'] as String? ?? '',
      codiceFiscale: data['codiceFiscale'] as String? ?? '',
      codiceUnivoco: data['codiceUnivoco'] as String? ?? '',
      referente: data['referente'] as String? ?? '',
      indirizzoIntervento: data['indirizzoIntervento'] as String? ?? '',
      capCittaProvIntervento: data['capCittaProvIntervento'] as String? ?? '',
      prodotti: data['prodotti'] as String? ?? '',
      noteAreeIntervento: data['noteAreeIntervento'] as String? ?? '',
      noteAzioniCorrettive: data['noteAzioniCorrettive'] as String? ?? '',
      ulterioriInterventi: data['ulterioriInterventi'] as String? ?? '',
      codiceDataUlteriore: data['codiceDataUlteriore'] as String? ?? '',
      oraUlteriore: data['oraUlteriore'] as String? ?? '',
      noteAzioniCorrettiveUlteriori:
          data['noteAzioniCorrettiveUlteriori'] as String? ?? '',
      voceA: data['voceA'] as String? ?? '',
      costoVoceA: (data['costoVoceA'] as num?)?.toDouble() ?? 0.0,
      nInterventiA: (data['nInterventiA'] as num?)?.toInt() ?? 0,
      scontoPercA: (data['scontoPercA'] as num?)?.toDouble() ?? 0.0,
      parzialeA: (data['parzialeA'] as num?)?.toDouble() ?? 0.0,
      ivaA: (data['ivaA'] as num?)?.toDouble() ?? 0.0,
      ritenutaPercA: (data['ritenutaPercA'] as num?)?.toDouble() ?? 0.0,
      valRitenutaA: (data['valRitenutaA'] as num?)?.toDouble() ?? 0.0,
      totA: (data['totA'] as num?)?.toDouble() ?? 0.0,
      voceB: data['voceB'] as String? ?? '',
      costoVoceB: (data['costoVoceB'] as num?)?.toDouble() ?? 0.0,
      nInterventiB: (data['nInterventiB'] as num?)?.toInt() ?? 0,
      scontoPercB: (data['scontoPercB'] as num?)?.toDouble() ?? 0.0,
      parzialeB: (data['parzialeB'] as num?)?.toDouble() ?? 0.0,
      ivaB: (data['ivaB'] as num?)?.toDouble() ?? 0.0,
      ritenutaPercB: (data['ritenutaPercB'] as num?)?.toDouble() ?? 0.0,
      valRitenutaB: (data['valRitenutaB'] as num?)?.toDouble() ?? 0.0,
      totB: (data['totB'] as num?)?.toDouble() ?? 0.0,
      voceC: data['voceC'] as String? ?? '',
      costoVoceC: (data['costoVoceC'] as num?)?.toDouble() ?? 0.0,
      nInterventiC: (data['nInterventiC'] as num?)?.toInt() ?? 0,
      scontoPercC: (data['scontoPercC'] as num?)?.toDouble() ?? 0.0,
      parzialeC: (data['parzialeC'] as num?)?.toDouble() ?? 0.0,
      ivaC: (data['ivaC'] as num?)?.toDouble() ?? 0.0,
      ritenutaPercC: (data['ritenutaPercC'] as num?)?.toDouble() ?? 0.0,
      valRitenutaC: (data['valRitenutaC'] as num?)?.toDouble() ?? 0.0,
      totC: (data['totC'] as num?)?.toDouble() ?? 0.0,
      parzialeTot: (data['parzialeTot'] as num?)?.toDouble() ?? 0.0,
      ivaTot: (data['ivaTot'] as num?)?.toDouble() ?? 0.0,
      ritenute: (data['ritenute'] as num?)?.toDouble() ?? 0.0,
      totaleDovuto: (data['totaleDovuto'] as num?)?.toDouble() ?? 0.0,
      ulterioriNote: data['ulterioriNote'] as String? ?? '',
      contatti: data['contatti'] as String? ?? '',
      email: data['email'] as String? ?? '',
      isDraft: data['isDraft'] as bool? ?? false,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Converte il modello in una mappa per Firestore
  Map<String, dynamic> toMap() {
    return {
      'codiceCliente': codiceCliente,
      'tipoIntervento': tipoIntervento,
      'numeroIntervento': numeroIntervento,
      'codiceData': codiceData,
      'ora': ora,
      'tecnico': tecnico,
      'tipoCommittente': tipoCommittente,
      'committente': committente,
      'indirizzoCommittente': indirizzoCommittente,
      'cap': cap,
      'citta': citta,
      'provincia': provincia,
      'codiceFiscale': codiceFiscale,
      'codiceUnivoco': codiceUnivoco,
      'referente': referente,
      'indirizzoIntervento': indirizzoIntervento,
      'capCittaProvIntervento': capCittaProvIntervento,
      'prodotti': prodotti,
      'noteAreeIntervento': noteAreeIntervento,
      'noteAzioniCorrettive': noteAzioniCorrettive,
      'ulterioriInterventi': ulterioriInterventi,
      'codiceDataUlteriore': codiceDataUlteriore,
      'oraUlteriore': oraUlteriore,
      'noteAzioniCorrettiveUlteriori': noteAzioniCorrettiveUlteriori,
      'voceA': voceA,
      'costoVoceA': costoVoceA,
      'nInterventiA': nInterventiA,
      'scontoPercA': scontoPercA,
      'parzialeA': parzialeA,
      'ivaA': ivaA,
      'ritenutaPercA': ritenutaPercA,
      'valRitenutaA': valRitenutaA,
      'totA': totA,
      'voceB': voceB,
      'costoVoceB': costoVoceB,
      'nInterventiB': nInterventiB,
      'scontoPercB': scontoPercB,
      'parzialeB': parzialeB,
      'ivaB': ivaB,
      'ritenutaPercB': ritenutaPercB,
      'valRitenutaB': valRitenutaB,
      'totB': totB,
      'voceC': voceC,
      'costoVoceC': costoVoceC,
      'nInterventiC': nInterventiC,
      'scontoPercC': scontoPercC,
      'parzialeC': parzialeC,
      'ivaC': ivaC,
      'ritenutaPercC': ritenutaPercC,
      'valRitenutaC': valRitenutaC,
      'totC': totC,
      'parzialeTot': parzialeTot,
      'ivaTot': ivaTot,
      'ritenute': ritenute,
      'totaleDovuto': totaleDovuto,
      'ulterioriNote': ulterioriNote,
      'contatti': contatti,
      'email': email,
      'isDraft': isDraft,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  String toString() =>
      'ServizioPestModel(id: $id, committente: $committente, tipo: $tipoIntervento)';
}
