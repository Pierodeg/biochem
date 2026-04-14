import 'package:cloud_firestore/cloud_firestore.dart';

/// Modello che rappresenta un utente dell'applicazione
/// Corrisponde al documento `users/{uid}` in Firestore
class UserModel {
  final String uid;
  final String email;
  final String displayName;

  /// Ruolo dell'utente: "admin" oppure "dipendente"
  final String role;

  final DateTime createdAt;
  final bool isActive;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.createdAt,
    required this.isActive,
  });

  /// Crea un [UserModel] da un documento Firestore
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: data['uid'] as String? ?? doc.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      role: data['role'] as String? ?? 'dipendente',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  /// Converte il modello in una mappa per Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }

  /// Restituisce true se l'utente ha ruolo admin
  bool get isAdmin => role == 'admin';

  /// Iniziali da mostrare nell'avatar (es. "Mario Rossi" → "MR")
  String get initials {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  /// Etichetta leggibile del ruolo
  String get roleLabel => isAdmin ? 'Admin' : 'Dipendente';

  @override
  String toString() =>
      'UserModel(uid: $uid, email: $email, role: $role, isActive: $isActive)';
}
