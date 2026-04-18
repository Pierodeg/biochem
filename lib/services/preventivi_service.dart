import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/preventivo_model.dart';

// NOTA: Documenti Firestore da inizializzare:
//   Collection 'preventivi'   → documenti PreventivoModel
//   contatori/preventivi_YYYY → { ultimo: 0 }  (crea per ogni anno)

/// Servizio per la gestione dei preventivi su Firestore
class PreventiviService {
  final CollectionReference _collection =
      FirebaseFirestore.instance.collection('preventivi');
  final CollectionReference _contatori =
      FirebaseFirestore.instance.collection('contatori');

  // ─── Lettura ───────────────────────────────────────────────────────────────

  /// Stream real-time di tutti i preventivi, ordinati per data di creazione
  Stream<List<PreventivoModel>> getPreventivi() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => PreventivoModel.fromFirestore(doc))
            .toList());
  }

  /// Recupera un singolo preventivo tramite ID
  Future<PreventivoModel?> getPreventivoById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return PreventivoModel.fromFirestore(doc);
  }

  // ─── Generazione numero progressivo ───────────────────────────────────────

  /// Genera il numero progressivo per anno usando una transazione Firestore.
  /// Il contatore è in `contatori/preventivi_YYYY` → campo `ultimo`.
  Future<int> generaNumeroPrev(DateTime data) async {
    final anno = data.year;
    final docRef = _contatori.doc('preventivi_$anno');

    return FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      final ultimo = snap.exists
          ? ((snap.data() as Map<String, dynamic>)['ultimo'] as num?)
                  ?.toInt() ??
              0
          : 0;
      final nuovo = ultimo + 1;
      tx.set(docRef, {'ultimo': nuovo}, SetOptions(merge: true));
      return nuovo;
    });
  }

  // ─── Scrittura ─────────────────────────────────────────────────────────────

  /// Salva un preventivo (crea se id è vuoto, aggiorna altrimenti).
  ///
  /// Vincolo: un preventivo definitivo non può essere riportato in bozza.
  Future<String> salvaPreventivo(PreventivoModel preventivo) async {
    final isNuovo = preventivo.id.isEmpty;

    if (!isNuovo) {
      // Verifica che non si stia retrocedendo da definitivo a bozza
      final esistente = await _collection.doc(preventivo.id).get();
      if (esistente.exists) {
        final data = esistente.data() as Map<String, dynamic>?;
        final eraBozza = data?['isDraft'] as bool? ?? false;
        if (!eraBozza && preventivo.isDraft) {
          throw Exception(
            'Un preventivo definitivo non può essere riportato in bozza.',
          );
        }
      }
    }

    if (isNuovo) {
      final doc = await _collection.add(preventivo.toMap());
      return doc.id;
    } else {
      await _collection.doc(preventivo.id).update(preventivo.toMap());
      return preventivo.id;
    }
  }

  /// Elimina un preventivo dato il suo ID
  Future<void> eliminaPreventivo(String id) async {
    await _collection.doc(id).delete();
  }
}
