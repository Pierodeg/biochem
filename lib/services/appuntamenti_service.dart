import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appuntamento_model.dart';

/// Servizio per la gestione degli appuntamenti nel calendario su Firestore.
/// Collection: 'appuntamenti'
class AppuntamentiService {
  final CollectionReference _collection =
      FirebaseFirestore.instance.collection('appuntamenti');

  // ─── Lettura ───────────────────────────────────────────────────────────────

  /// Stream real-time di tutti gli appuntamenti, ordinati per data inizio
  Stream<List<AppuntamentoModel>> getAppuntamenti() {
    return _collection
        .orderBy('dataInizio')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => AppuntamentoModel.fromFirestore(doc))
            .toList());
  }

  /// Stream degli appuntamenti di un mese specifico
  Stream<List<AppuntamentoModel>> getAppuntamentiMese(int anno, int mese) {
    final inizio = DateTime(anno, mese, 1);
    final fine = DateTime(anno, mese + 1, 1);
    return _collection
        .where('dataInizio', isGreaterThanOrEqualTo: Timestamp.fromDate(inizio))
        .where('dataInizio', isLessThan: Timestamp.fromDate(fine))
        .orderBy('dataInizio')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => AppuntamentoModel.fromFirestore(doc))
            .toList());
  }

  /// Stream degli appuntamenti di una settimana (da [inizio] a [inizio + 7 giorni])
  Stream<List<AppuntamentoModel>> getAppuntamentiSettimana(DateTime inizio) {
    final fine = inizio.add(const Duration(days: 7));
    return _collection
        .where('dataInizio', isGreaterThanOrEqualTo: Timestamp.fromDate(inizio))
        .where('dataInizio', isLessThan: Timestamp.fromDate(fine))
        .orderBy('dataInizio')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => AppuntamentoModel.fromFirestore(doc))
            .toList());
  }

  /// Carica un singolo appuntamento per ID direttamente da Firestore
  Future<AppuntamentoModel?> getAppuntamentoById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return AppuntamentoModel.fromFirestore(doc);
  }

  // ─── Scrittura ─────────────────────────────────────────────────────────────

  /// Salva un appuntamento (crea se [app.id] è vuoto, aggiorna altrimenti)
  Future<void> salvaAppuntamento(AppuntamentoModel app) async {
    if (app.id.isEmpty) {
      await _collection.add(app.toMap());
    } else {
      await _collection.doc(app.id).update(app.toMap());
    }
  }

  /// Elimina un appuntamento dato il suo ID
  Future<void> eliminaAppuntamento(String id) async {
    await _collection.doc(id).delete();
  }

  /// Marca un appuntamento come completato
  Future<void> completaAppuntamento(String id) async {
    await _collection.doc(id).update({'completato': true});
  }

  // ─── Query avanzate ────────────────────────────────────────────────────────

  /// Restituisce gli appuntamenti non completati nei prossimi [giorni] giorni.
  /// Usato per generare notifiche in-app proattive.
  ///
  /// Il filtro su `completato` viene applicato in Dart invece che in Firestore
  /// per evitare la necessità di un indice composito (completato + dataInizio).
  Future<List<AppuntamentoModel>> getAppuntamentiInScadenza(int giorni) async {
    final ora = DateTime.now();
    // Partiamo dall'inizio della giornata per includere appuntamenti di oggi
    // con orario già passato (utile per notificaGiorniPrima = 0).
    final oggiMezzanotte =
        DateTime(ora.year, ora.month, ora.day);
    final limite = oggiMezzanotte.add(Duration(days: giorni));
    final snap = await _collection
        .where('dataInizio', isGreaterThanOrEqualTo: Timestamp.fromDate(oggiMezzanotte))
        .where('dataInizio', isLessThanOrEqualTo: Timestamp.fromDate(limite))
        .orderBy('dataInizio')
        .get();
    return snap.docs
        .map((doc) => AppuntamentoModel.fromFirestore(doc))
        .where((app) => !app.completato)
        .toList();
  }
}
