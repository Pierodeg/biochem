import 'package:firebase_auth/firebase_auth.dart';

/// Servizio per le operazioni di autenticazione Firebase
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Stream che emette l'utente corrente (null se non loggato)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Utente Firebase attualmente autenticato
  User? get currentUser => _auth.currentUser;

  /// Accede con email e password
  ///
  /// Lancia [FirebaseAuthException] in caso di errore
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Esegue il logout dell'utente corrente
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Traduce i codici di errore Firebase in messaggi italiani leggibili
  static String getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Nessun account trovato con questa email.';
      case 'wrong-password':
        return 'Password non corretta.';
      case 'invalid-credential':
        return 'Credenziali non valide. Controlla email e password.';
      case 'user-disabled':
        return 'Questo account è stato disabilitato.';
      case 'too-many-requests':
        return 'Troppi tentativi falliti. Riprova tra qualche minuto.';
      case 'network-request-failed':
        return 'Errore di rete. Verifica la connessione internet.';
      case 'invalid-email':
        return 'Formato email non valido.';
      case 'operation-not-allowed':
        return 'Operazione non consentita. Contatta l\'amministratore.';
      default:
        return 'Si è verificato un errore. Riprova.';
    }
  }
}
