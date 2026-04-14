import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'services/notifiche_avvio_service.dart';
import 'services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inizializza Firebase con la configurazione specifica della piattaforma
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inizializza il servizio notifiche push FCM.
  // Richiede permessi e registra il token del dispositivo in Firestore.
  // L'invio effettivo delle notifiche avviene tramite Cloud Functions (Fase 2).
  await PushNotificationService.initialize();

  // Inizializza la localizzazione italiana per la formattazione delle date
  await initializeDateFormatting('it', null);

  // Controllo giornaliero appuntamenti in scadenza per le notifiche in-app.
  // Viene eseguito in background: non blocca l'avvio dell'app.
  // Aspetta che l'utente sia autenticato prima di procedere.
  FirebaseAuth.instance.authStateChanges().listen((user) {
    if (user != null) {
      NotificheAvvioService().verificaScadenze(user.uid);
    }
  });

  // ProviderScope è il root di Riverpod — deve avvolgere tutta l'app
  runApp(const ProviderScope(child: BiochemApp()));
}

/// Root dell'applicazione Biochem
class BiochemApp extends ConsumerWidget {
  const BiochemApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Il router reagisce automaticamente ai cambi di stato auth
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Biochem',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Lingua di fallback per i widget Material (es. tooltip, dialog)
      locale: const Locale('it', 'IT'),
      supportedLocales: const [
        Locale('it', 'IT'),
        Locale('en', 'US'),
      ],
    );
  }
}
