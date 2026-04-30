import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/calendario/screens/appuntamento_form_page.dart';
import '../../features/calendario/screens/calendario_page.dart';
import '../../features/home/screens/main_screen.dart';
import '../../features/preventivo/screens/preventivi_page.dart';
import '../../features/preventivo/screens/preventivo_form_page.dart';
import '../../features/servizi_pest/screens/servizi_pest_page.dart';
import '../../features/servizi_pest/screens/servizio_pest_form_page.dart';
import '../../features/home/screens/fatture_page.dart';
import '../../features/anagrafiche/screens/anagrafiche_page.dart';
import '../../features/anagrafiche/screens/cliente_form_page.dart';
import '../../features/admin/screens/admin_settings_page.dart';
import '../../features/servizi_lab/screens/servizi_lab_page.dart';
import '../../features/servizi_lab/screens/servizio_lab_form_page.dart';
import '../../features/registro/screens/registro_page.dart';

final pendingNotificationProvider = StateProvider<String?>((ref) => null);

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ValueNotifier<int>(0);

  ref.listen(authStateProvider, (_, __) => notifier.value++);
  ref.listen(currentUserProvider, (_, __) => notifier.value++);

  final router = GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,

    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isOnSplash = state.matchedLocation == '/';

      if (authState.isLoading) return isOnSplash ? null : '/';

      final isAuthenticated = authState.valueOrNull != null;
      final isOnLogin = state.matchedLocation == '/login';

      if (!isAuthenticated && !isOnLogin) return '/login';
      if (isAuthenticated && (isOnLogin || isOnSplash)) return '/anagrafiche';

      const routeProtetteEsatte = [
        '/admin/impostazioni',
        '/registro',
        '/servizi-lab/nuovo',
        '/servizi-pest/nuovo',
        '/anagrafiche/nuovo',
        '/calendario/nuovo',
        '/preventivo/nuovo',
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
      final isPreventivoEdit =
          state.matchedLocation.startsWith('/preventivo/') &&
          state.matchedLocation != '/preventivo';
      final isRouteProtettaAdmin =
          routeProtetteEsatte.contains(state.matchedLocation) ||
          isServizioLabEdit ||
          isServizioPestEdit ||
          isCalendarioEdit ||
          isPreventivoEdit;

      if (isRouteProtettaAdmin) {
        final userAsync = ref.read(currentUserProvider);
        if (userAsync.isLoading) return null;
        final user = userAsync.valueOrNull;
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
                              : state.matchedLocation.startsWith('/preventivo')
                                  ? '/preventivo'
                                  : '/anagrafiche';

          ref.read(pendingNotificationProvider.notifier).state =
              'Accesso non autorizzato';
          return redirectPath;
        }
      }

      return null;
    },

    routes: [
      // ─── Splash ───────────────────────────────────────────────────────────
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
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
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/anagrafiche',
              builder: (context, state) => const AnagrafichePage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/preventivo',
              builder: (context, state) => const PreventiviPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/servizi-lab',
              builder: (context, state) => const ServiziLabPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/servizi-pest',
              builder: (context, state) => const ServiziPestPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/fatture',
              builder: (context, state) => const FatturePage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/calendario',
              builder: (context, state) => const CalendarioPage(),
            ),
          ]),
        ],
      ),

      // ─── Anagrafiche ──────────────────────────────────────────────────────
      GoRoute(
        path: '/anagrafiche/nuovo',
        builder: (context, state) => const ClienteFormPage(),
      ),
      GoRoute(
        path: '/anagrafiche/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ClienteFormPage(clienteId: id);
        },
      ),

      // ─── Servizi Lab ──────────────────────────────────────────────────────
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

      // ─── Servizi Pest ─────────────────────────────────────────────────────
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

      // ─── Calendario ───────────────────────────────────────────────────────
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

      // ─── Preventivi ───────────────────────────────────────────────────────
      GoRoute(
        path: '/preventivo/nuovo',
        builder: (context, state) => const PreventivoFormPage(),
      ),
      GoRoute(
        path: '/preventivo/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PreventivoFormPage(preventivoId: id);
        },
      ),

      // ─── Admin ────────────────────────────────────────────────────────────
      GoRoute(
        path: '/admin/impostazioni',
        builder: (context, state) => const AdminSettingsPage(),
      ),

      // ─── Registro (admin only) ────────────────────────────────────────────
      GoRoute(
        path: '/registro',
        builder: (context, state) => const RegistroPage(),
      ),
    ],
  );

  ref.onDispose(() {
    notifier.dispose();
    router.dispose();
  });

  return router;
});
