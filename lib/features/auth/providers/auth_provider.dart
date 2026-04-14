import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/user_service.dart';

// ─── Provider dei servizi ────────────────────────────────────────────────────

/// Istanza singleton del servizio di autenticazione
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Istanza singleton del servizio utenti Firestore
final userServiceProvider = Provider<UserService>((ref) => UserService());

// ─── Provider dello stato auth ───────────────────────────────────────────────

/// Stream dell'utente Firebase corrente (null = non autenticato)
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Stream del profilo Firestore dell'utente loggato
///
/// Si aggiorna automaticamente quando cambia lo stato di autenticazione
/// o quando il documento Firestore viene modificato
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return ref.watch(userServiceProvider).getUserStream(user.uid);
    },
    // Stream.value(null) invece di Stream.empty(): evita che il provider
    // rimanga in uno stato ambiguo durante il caricamento dell'auth
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

// ─── Notifier per il flusso di login ────────────────────────────────────────

/// Stato del processo di login
class LoginState {
  final bool isLoading;
  final String? errorMessage;

  const LoginState({
    this.isLoading = false,
    this.errorMessage,
  });

  LoginState copyWith({bool? isLoading, String? errorMessage}) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Notifier che gestisce il flusso di login con verifica del profilo Firestore
class LoginNotifier extends StateNotifier<LoginState> {
  final AuthService _authService;
  final UserService _userService;

  LoginNotifier(this._authService, this._userService)
      : super(const LoginState());

  /// Esegue il login:
  /// 1. Autentica con Firebase Auth
  /// 2. Recupera il profilo da Firestore
  /// 3. Verifica che l'account sia attivo
  ///
  /// Lancia un'eccezione con messaggio localizzato in caso di errore
  Future<UserModel> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Autenticazione Firebase
      final credential = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Lettura profilo Firestore
      final user = await _userService.getUserById(credential.user!.uid);

      if (user == null) {
        await _authService.signOut();
        throw Exception(
            'Profilo utente non trovato. Contatta l\'amministratore.');
      }

      // Verifica che l'account sia abilitato
      if (!user.isActive) {
        await _authService.signOut();
        throw Exception(
            'Account disabilitato. Contatta l\'amministratore.');
      }

      state = state.copyWith(isLoading: false);
      return user;
    } on FirebaseAuthException catch (e) {
      final message = AuthService.getErrorMessage(e.code);
      state = state.copyWith(isLoading: false, errorMessage: message);
      throw Exception(message);
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isLoading: false, errorMessage: message);
      rethrow;
    }
  }

  /// Rimuove il messaggio di errore corrente
  void clearError() => state = state.copyWith(errorMessage: null);
}

/// Provider del notifier di login
final loginProvider =
    StateNotifierProvider<LoginNotifier, LoginState>((ref) {
  return LoginNotifier(
    ref.watch(authServiceProvider),
    ref.watch(userServiceProvider),
  );
});
