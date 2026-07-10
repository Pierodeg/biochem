import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/risultato_analisi_model.dart';

/// Servizio CRUD generico per i risultati delle analisi di laboratorio.
///
/// La stessa istanza serve tutte le famiglie: la collection è passata come
/// parametro (es. `risultati_cationi`, `risultati_anioni`, …), vedi
/// `FamigliaAnalisi.collection`.
class RisultatiAnalisiService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Stream real-time dei risultati di una collection, dal più recente.
  Stream<List<RisultatoAnalisi>> getRisultati(String collection) {
    return _db
        .collection(collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map(RisultatoAnalisi.fromFirestore).toList());
  }

  /// Salva un risultato (crea se id vuoto, aggiorna altrimenti).
  Future<String> salva(String collection, RisultatoAnalisi r) async {
    if (r.id.isEmpty) {
      final doc = await _db.collection(collection).add(r.toMap());
      return doc.id;
    }
    await _db.collection(collection).doc(r.id).set(r.toMap());
    return r.id;
  }

  /// Salvataggio massivo (import CSV).
  Future<void> salvaBatch(
      String collection, List<RisultatoAnalisi> righe) async {
    final batch = _db.batch();
    final coll = _db.collection(collection);
    for (final r in righe) {
      batch.set(coll.doc(), r.toMap());
    }
    await batch.commit();
  }

  Future<void> elimina(String collection, String id) async {
    await _db.collection(collection).doc(id).delete();
  }
}
