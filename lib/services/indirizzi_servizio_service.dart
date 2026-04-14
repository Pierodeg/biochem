import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/indirizzo_servizio_model.dart';

/// Servizio per la gestione degli indirizzi di servizio multipli di un cliente.
///
/// Struttura Firestore: clienti/{clienteId}/indirizzi_servizio/{indirizzoId}
class IndirizziServizioService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Riferimento alla sotto-collezione indirizzi di un cliente
  CollectionReference<Map<String, dynamic>> _collezione(String clienteId) =>
      _db.collection('clienti').doc(clienteId).collection('indirizzi_servizio');

  /// Stream in tempo reale degli indirizzi di servizio di un cliente.
  /// Ordina per città poi indirizzo.
  Stream<List<IndirizzoServizioModel>> getIndirizzi(String clienteId) {
    return _collezione(clienteId)
        .orderBy('citta')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => IndirizzoServizioModel.fromFirestore(doc))
            .toList());
  }

  /// Salva un indirizzo (crea se [indirizzo.id] è vuoto, aggiorna altrimenti)
  Future<void> salvaIndirizzo(
      String clienteId, IndirizzoServizioModel indirizzo) async {
    if (indirizzo.id.isEmpty) {
      await _collezione(clienteId).add(indirizzo.toMap());
    } else {
      await _collezione(clienteId).doc(indirizzo.id).set(indirizzo.toMap());
    }
  }

  /// Elimina un indirizzo dalla sotto-collezione
  Future<void> eliminaIndirizzo(
      String clienteId, String indirizzoId) async {
    await _collezione(clienteId).doc(indirizzoId).delete();
  }
}
