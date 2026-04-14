import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/calendario/screens/appuntamento_form_page.dart';
import '../../features/calendario/screens/calendario_page.dart';
import '../../features/home/screens/main_screen.dart';
import '../../features/home/screens/preventivo_page.dart';
import '../../features/servizi_pest/screens/servizi_pest_page.dart';
import '../../features/servizi_pest/screens/servizio_pest_form_page.dart';
import '../../features/home/screens/fatture_page.dart';
import '../../features/anagrafiche/screens/anagrafiche_page.dart';
import '../../features/anagrafiche/screens/cliente_form_page.dart';
import '../../features/admin/screens/admin_settings_page.dart';
import '../../features/servizi_lab/screens/servizi_lab_page.dart';
import '../../features/servizi_lab/screens/servizio_lab_form_page.dart';

/// Messaggio di notifica in attesa di essere mostrato dalla pagina di destinazione.
/// Usato per comunicare dal redirect del router alla UI con Scaffold.
final pendingNotificationProvider = StateProvider<String?>((ref) => null);

/// Provider del router principale dell'applicazione.
///
/// Struttura:
/// - /               → SplashScreen (attesa auth, nessuna query Firestore)
/// - /login          → LoginScreen (standalone)
/// - StatefulShellRoute  → MainScreen (sidebar/bottom nav)
///     branch 0: /anagrafiche   → AnagrafichePage
///     branch 1: /preventivo    → PreventivoPage
///     branch 2: /servizi-lab   → ServiziLabPage
///     branch 3: /servizi-pest  → ServiziPestPage
///     branch 4: /fatture       → FatturePage
///     branch 5: /calendario    → CalendarioPage
/// - /anagrafiche/nuovo  → ClienteFormPage (fuori dalla shell, full-screen)
/// - /anagrafiche/:id    → ClienteFormPage
/// - /servizi-lab/nuovo  → ServizioLabFormPage (admin only)
/// - /servizi-lab/:id    → ServizioLabFormPage (admin only)
/// - /calendario/nuovo   → AppuntamentoFormPage (admin only)
/// - /calendario/:id     → AppuntamentoFormPage (admin only)
/// - /admin/impostazioni → AdminSettingsPage (admin only)
final routerProvider = Provider<GoRouter>((ref) {
  // Notifier che forza il router a rivalutare il redirect
  // ogni volta che cambia lo stato auth o il profilo utente Firestore
  final notifier = ValueNotifier<int>(0);

  ref.listen(authStateProvider, (_, __) => notifier.value++);
  ref.listen(currentUserProvider, (_, __) => notifier.value++);

  final router = GoRouter(
    // Parte dallo splash: nessuna pagina Firestore viene buildata
    // prima che l'autenticazione sia confermata
    initialLocation: '/',
    refreshListenable: notifier,

    /// Logica di redirect:
    /// - Auth in caricamento                    → /  (splash, aspetta)
    /// - Non autenticato                        → /login
    /// - Autenticato su / o /login              → /anagrafiche
    /// - Route admin senza ruolo admin          → tab di origine + notifica
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isOnSplash = state.matchedLocation == '/';

      // Auth ancora in caricamento: resta sullo splash, non buildare pagine Firestore
      if (authState.isLoading) return isOnSplash ? null : '/';

      final isAuthenticated = authState.valueOrNull != null;
      final isOnLogin = state.matchedLocation == '/login';

      if (!isAuthenticated && !isOnLogin) return '/login';
      if (isAuthenticated && (isOnLogin || isOnSplash)) return '/anagrafiche';

      // Protezione route admin: solo utenti con role == 'admin'
      const routeProtetteEsatte = [
        '/admin/impostazioni',
        '/servizi-lab/nuovo',
        '/servizi-pest/nuovo',
        '/anagrafiche/nuovo',
        '/calendario/nuovo',
      ];
      final isServizioLabEdit =
          state.matchedLocation.startsWith('/servizi-lab/') &&
          state.matchedLocation != '/servizi-lab';
      final isServizioPestEdit =
          state.matchedLocation.startsWith('/servizi-pest/') &&
          state.matchedLocation != '/servizi-pest';
      final isCalendarioEdit =
          state.matchedLocation.startsWith('/calendario/') &&
          state.matchedLocation != '/calendario';
      final isRouteProtettaAdmin =
          routeProtetteEsatte.contains(state.matchedLocation) ||
          isServizioLabEdit ||
          isServizioPestEdit ||
          isCalendarioEdit;

      if (isRouteProtettaAdmin) {
        final userAsync = ref.read(currentUserProvider);

        // Profilo Firestore ancora in caricamento: aspetta rivalutazione
        if (userAsync.isLoading) return null;

        final user = userAsync.valueOrNull;

        // Auth autenticato ma profilo Firestore non ancora arrivato (transizione)
        // → non ancora pronti per valutare il ruolo, aspetta il prossimo ciclo
        if (user == null && isAuthenticated) return null;

        if (user == null || !user.isAdmin) {
          final redirectPath =
              state.matchedLocation.startsWith('/servizi-lab')
                  ? '/servizi-lab'
                  : state.matchedLocation.startsWith('/servizi-pest')
                      ? '/servizi-pest'
                      : state.matchedLocation.startsWith('/calendario')
                          ? '/calendario'
                          : state.matchedLocation.startsWith('/anagrafiche')
                              ? '/anagrafiche'
                              : '/anagrafiche';

          // Notifica la pagina di destinazione tramite provider
          ref.read(pendingNotificationProvider.notifier).state =
              'Accesso non autorizzato';
          return redirectPath;
        }
      }

      return null;
    },

    routes: [
      // ─── Splash (attesa autenticazione Firebase) ──────────────────────────
      // Nessuna query Firestore qui: evita permission-denied durante l'init.
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),

      // ─── Login ────────────────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // ─── Shell con sidebar/bottom nav ─────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainScreen(navigationShell: navigationShell),
        branches: [
          // Branch 0 — Anagrafiche
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/anagrafiche',
              builder: (context, state) => const AnagrafichePage(),
            ),
          ]),
          // Branch 1 — Preventivo
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/preventivo',
              builder: (context, state) => const PreventivoPage(),
            ),
          ]),
          // Branch 2 — Servizi Lab
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/servizi-lab',
              builder: (context, state) => const ServiziLabPage(),
            ),
          ]),
          // Branch 3 — Servizi Pest
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/servizi-pest',
              builder: (context, state) => const ServiziPestPage(),
            ),
          ]),
          // Branch 4 — Fatture
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/fatture',
              builder: (context, state) => const FatturePage(),
            ),
          ]),
          // Branch 5 — Calendario
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/calendario',
              builder: (context, state) => const CalendarioPage(),
            ),
          ]),
        ],
      ),

      // ─── Form clienti (full-screen, fuori dalla shell) ────────────────────
      // /anagrafiche/nuovo → admin only (protetta sopra in routeProtetteEsatte)
      GoRoute(
        path: '/anagrafiche/nuovo',
        builder: (context, state) => const ClienteFormPage(),
      ),
      // /anagrafiche/:id  → accessibile a tutti gli utenti autenticati.
      // I dipendenti vedono il form in modalità read-only (ClienteFormPage
      // legge il ruolo e imposta isReadOnly = !isAdmin). La guardia in
      // _salva() impedisce scritture anche in caso di accesso diretto via URL.
      GoRoute(
        path: '/anagrafiche/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ClienteFormPage(clienteId: id);
        },
      ),

      // ─── Form servizi lab (admin only, fuori dalla shell) ─────────────────
      GoRoute(
        path: '/servizi-lab/nuovo',
        builder: (context, state) => const ServizioLabFormPage(),
      ),
      GoRoute(
        path: '/servizi-lab/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ServizioLabFormPage(servizioId: id);
        },
      ),

      // ─── Form servizi pest (admin only, fuori dalla shell) ───────────────
      GoRoute(
        path: '/servizi-pest/nuovo',
        builder: (context, state) => const ServizioPestFormPage(),
      ),
      GoRoute(
        path: '/servizi-pest/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ServizioPestFormPage(servizioId: id);
        },
      ),

      // ─── Calendario (admin only per nuovo/modifica, fuori dalla shell) ──────
      GoRoute(
        path: '/calendario/nuovo',
        builder: (context, state) => const AppuntamentoFormPage(),
      ),
      GoRoute(
        path: '/calendario/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AppuntamentoFormPage(appuntamentoId: id);
        },
      ),

      // ─── Admin (admin only, fuori dalla shell) ─────────────────────────────
      GoRoute(
        path: '/admin/impostazioni',
        builder: (context, state) => const AdminSettingsPage(),
      ),
    ],
  );

  ref.onDispose(() {
    notifier.dispose();
    router.dispose();
  });

  return router;
});
