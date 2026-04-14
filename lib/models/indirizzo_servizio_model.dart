import 'package:cloud_firestore/cloud_firestore.dart';

/// Modello per un indirizzo di servizio aggiuntivo del cliente.
///
/// Struttura Firestore: clienti/{clienteId}/indirizzi_servizio/{indirizzoId}
class IndirizzoServizioModel {
  final String id;
  final String indirizzo;
  final String cap;
  final String citta;
  final String provincia;
  final String referente;
  final String note;

  const IndirizzoServizioModel({
    required this.id,
    required this.indirizzo,
    required this.cap,
    required this.citta,
    required this.provincia,
    required this.referente,
    required this.note,
  });

  /// Crea un [IndirizzoServizioModel] da un documento Firestore
  factory IndirizzoServizioModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return IndirizzoServizioModel(
      id: doc.id,
      indirizzo: data['indirizzo'] as String? ?? '',
      cap: data['cap'] as String? ?? '',
      citta: data['citta'] as String? ?? '',
      provincia: data['provincia'] as String? ?? '',
      referente: data['referente'] as String? ?? '',
      note: data['note'] as String? ?? '',
    );
  }

  /// Converte il modello in una mappa per Firestore
  Map<String, dynamic> toMap() {
    return {
      'indirizzo': indirizzo,
      'cap': cap,
      'citta': citta,
      'provincia': provincia,
      'referente': referente,
      'note': note,
    };
  }

  /// Etichetta compatta per la visualizzazione nella lista
  String get etichetta {
    final parti = <String>[];
    if (indirizzo.isNotEmpty) parti.add(indirizzo);
    if (cap.isNotEmpty || citta.isNotEmpty) {
      parti.add([cap, citta].where((s) => s.isNotEmpty).join(' '));
    }
    if (provincia.isNotEmpty) parti.add('(${provincia.toUpperCase()})');
    return parti.join(', ');
  }

  @override
  String toString() => 'IndirizzoServizioModel(id: $id, indirizzo: $indirizzo)';
}
