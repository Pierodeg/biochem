import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Servizio per la lettura dei dati utente su Firestore
class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Legge il documento `users/{uid}` una volta sola
  ///
  /// Restituisce null se il documento non esiste
  Future<UserModel?> getUserById(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Errore nel recupero del profilo: $e');
    }
  }

  /// Stream del documento utente per aggiornamenti in tempo reale
  ///
  /// Emette null se il documento non esiste o viene eliminato
  Stream<UserModel?> getUserStream(String uid) {
    return _db.collection('users').doc(uid).snapshots().map(
          (doc) => doc.exists ? UserModel.fromFirestore(doc) : null,
        );
  }
}
