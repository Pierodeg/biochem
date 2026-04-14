import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notifica_model.dart';

/// Servizio per la gestione delle notifiche in-app per ogni utente.
///
/// Struttura Firestore: notifiche/{uid}/items/{notificaId}
class NotificheService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Riferimento alla sotto-collezione items di un utente
  CollectionReference<Map<String, dynamic>> _items(String uid) =>
      _db.collection('notifiche').doc(uid).collection('items');

  // ─── Lettura ───────────────────────────────────────────────────────────────

  /// Stream real-time delle notifiche dell'utente, ordinate per data decrescente
  Stream<List<NotificaModel>> getNotifiche(String uid) {
    return _items(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => NotificaModel.fromFirestore(doc))
            .toList());
  }

  /// Stream del conteggio notifiche non lette (per il badge)
  Stream<int> getNotificheNonLette(String uid) {
    return _items(uid)
        .where('letta', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // ─── Scrittura ─────────────────────────────────────────────────────────────

  /// Segna una singola notifica come letta
  Future<void> segnaLetta(String uid, String notificaId) async {
    await _items(uid).doc(notificaId).update({'letta': true});
  }

  /// Segna tutte le notifiche dell'utente come lette
  Future<void> segnaLetteTutte(String uid) async {
    final snap =
        await _items(uid).where('letta', isEqualTo: false).get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'letta': true});
    }
    await batch.commit();
  }

  /// Crea una nuova notifica per l'utente
  Future<void> creaNotifica(String uid, NotificaModel notifica) async {
    await _items(uid).add(notifica.toMap());
  }

  /// Elimina una notifica
  Future<void> eliminaNotifica(String uid, String notificaId) async {
    await _items(uid).doc(notificaId).delete();
  }

  // ─── Utility ───────────────────────────────────────────────────────────────

  /// Verifica se esiste già una notifica per un determinato appuntamento.
  /// Usato per evitare notifiche duplicate.
  Future<bool> esisteNotificaPerAppuntamento(
      String uid, String appuntamentoId) async {
    final snap = await _items(uid)
        .where('appuntamentoId', isEqualTo: appuntamentoId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }
}
