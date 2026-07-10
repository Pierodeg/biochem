import 'package:cloud_firestore/cloud_firestore.dart';

/// Riga di risultati di una famiglia di analisi (Cationi, Primarie, Anioni,
/// Microbio). Ogni riga corrisponde a **un campione** già registrato in
/// Reg Lab (`servizi_lab`), agganciato tramite [certNumb].
///
/// I valori misurati sono in [valori] (chiave colonna → valore), così lo
/// stesso model serve tutte le famiglie (vedi `FamigliaAnalisi`).
class RisultatoAnalisi {
  final String id;

  /// Numero di certificato del campione (= `certificazioneNumerica` in Reg Lab).
  final String certNumb;

  /// Codice A del campione (AAMMGG).
  final String codA;

  /// Committente del campione (denormalizzato per lista/ricerca).
  final String committente;

  /// Valori misurati: chiave colonna (`ColonnaAnalisi.key`) → valore testuale.
  final Map<String, String> valori;

  final DateTime createdAt;

  const RisultatoAnalisi({
    required this.id,
    required this.certNumb,
    required this.codA,
    required this.committente,
    required this.valori,
    required this.createdAt,
  });

  factory RisultatoAnalisi.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final valoriRaw = (data['valori'] as Map<String, dynamic>? ?? {});
    return RisultatoAnalisi(
      id: doc.id,
      certNumb: data['certNumb'] as String? ?? '',
      codA: data['codA'] as String? ?? '',
      committente: data['committente'] as String? ?? '',
      valori: valoriRaw.map((k, v) => MapEntry(k, v?.toString() ?? '')),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'certNumb': certNumb,
        'codA': codA,
        'committente': committente,
        'valori': valori,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  RisultatoAnalisi copyWith({
    String? certNumb,
    String? codA,
    String? committente,
    Map<String, String>? valori,
  }) {
    return RisultatoAnalisi(
      id: id,
      certNumb: certNumb ?? this.certNumb,
      codA: codA ?? this.codA,
      committente: committente ?? this.committente,
      valori: valori ?? this.valori,
      createdAt: createdAt,
    );
  }
}
