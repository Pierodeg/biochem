import 'package:cloud_firestore/cloud_firestore.dart';

/// Modello che rappresenta un cliente (anagrafica)
/// Corrisponde al documento `clienti/{id}` in Firestore
class ClienteModel {
  final String id;
  final int numeroCliente;
  final String tipoCommittente;
  final String committente;
  final String indirizzo;
  final String cap;
  final String citta;
  final String provincia;
  final String pivaCodiceFiscale;
  final String codiceUnivoco;
  final String referente;
  final String indirizzoServizio;

  /// CAP dell'indirizzo di servizio principale
  final String capServizio;

  /// Città dell'indirizzo di servizio principale (auto-compilata dal CAP)
  final String cittaServizio;

  /// Provincia dell'indirizzo di servizio principale (auto-compilata dal CAP)
  final String provinciaServizio;

  final String email;
  final String telefono;

  /// Numero di cellulare del referente
  final String cellulare;

  final String pec;
  final DateTime createdAt;

  /// true = il cliente è salvato come bozza (visibile nella lista con badge)
  final bool isDraft;

  const ClienteModel({
    required this.id,
    required this.numeroCliente,
    required this.tipoCommittente,
    required this.committente,
    required this.indirizzo,
    required this.cap,
    required this.citta,
    required this.provincia,
    required this.pivaCodiceFiscale,
    required this.codiceUnivoco,
    required this.referente,
    required this.indirizzoServizio,
    required this.capServizio,
    required this.cittaServizio,
    required this.provinciaServizio,
    required this.email,
    required this.telefono,
    required this.cellulare,
    required this.pec,
    required this.createdAt,
    this.isDraft = false,
  });

  /// Crea un [ClienteModel] da un documento Firestore.
  /// Compatibile con documenti vecchi che usavano 'capCittaPrelievo'
  factory ClienteModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ClienteModel(
      id: doc.id,
      numeroCliente: (data['numeroCliente'] as num?)?.toInt() ?? 0,
      tipoCommittente: data['tipoCommittente'] as String? ?? '',
      committente: data['committente'] as String? ?? '',
      indirizzo: data['indirizzo'] as String? ?? '',
      cap: data['cap'] as String? ?? '',
      citta: data['citta'] as String? ?? '',
      provincia: data['provincia'] as String? ?? '',
      pivaCodiceFiscale: data['pivaCodiceFiscale'] as String? ?? '',
      codiceUnivoco: data['codiceUnivoco'] as String? ?? '',
      referente: data['referente'] as String? ?? '',
      indirizzoServizio: data['indirizzoServizio'] as String? ?? '',
      // Compatibilità backward: legge 'capServizio', fallback a 'capCittaPrelievo'
      capServizio: data['capServizio'] as String? ??
          data['capCittaPrelievo'] as String? ?? '',
      cittaServizio: data['cittaServizio'] as String? ?? '',
      provinciaServizio: data['provinciaServizio'] as String? ?? '',
      email: data['email'] as String? ?? '',
      telefono: data['telefono'] as String? ?? '',
      cellulare: data['cellulare'] as String? ?? '',
      pec: data['pec'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isDraft: data['isDraft'] as bool? ?? false,
    );
  }

  /// Converte il modello in una mappa per Firestore
  Map<String, dynamic> toMap() {
    return {
      'numeroCliente': numeroCliente,
      'tipoCommittente': tipoCommittente,
      'committente': committente,
      'indirizzo': indirizzo,
      'cap': cap,
      'citta': citta,
      'provincia': provincia,
      'pivaCodiceFiscale': pivaCodiceFiscale,
      'codiceUnivoco': codiceUnivoco,
      'referente': referente,
      'indirizzoServizio': indirizzoServizio,
      'capServizio': capServizio,
      'cittaServizio': cittaServizio,
      'provinciaServizio': provinciaServizio,
      'email': email,
      'telefono': telefono,
      'cellulare': cellulare,
      'pec': pec,
      'createdAt': Timestamp.fromDate(createdAt),
      'isDraft': isDraft,
    };
  }

  /// Iniziali del committente per l'avatar (es. "Mario Rossi" → "MR")
  String get initials {
    final trimmed = committente.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  /// Numero cliente formattato con zeri (es. 1 → "#001")
  String get numeroFormattato => '#${numeroCliente.toString().padLeft(3, '0')}';

  @override
  String toString() =>
      'ClienteModel(id: $id, numero: $numeroCliente, committente: $committente)';
}
