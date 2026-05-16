import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/providers/service_providers.dart';

/// Handler per messaggi in background — DEVE essere top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background: ${message.messageId}');
}

class FcmService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final ProviderContainer _container;

  // Riferimento al router — impostato dopo inizializzazione
  static GoRouter? _router;

  FcmService(this._container);

  static void setRouter(GoRouter router) {
    _router = router;
  }

  static const String _channelId = 'biochem_notifiche';
  static const String _channelName = 'Notifiche BioChem';
  static const String _channelDesc = 'Notifiche appuntamenti e promemoria';

  /// Registra SOLO il background handler.
  /// Deve essere chiamato in main() prima di runApp(), è leggero e sincrono.
  static void registraBackgroundHandler() {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  /// Inizializzazione pesante (canale, permessi, token, listener).
  /// Va chiamato in fire-and-forget dalla SplashScreen così non blocca la UI.
  Future<void> inizializzaDopoAvvio() async {
    // Inizializza notifiche locali con handler per tap in foreground
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        final payload = details.payload;
        if (payload != null && payload.isNotEmpty) {
          _container.read(pendingAppuntamentoProvider.notifier).state = payload;
          _router?.go('/calendario');
        }
      },
    );

    // Crea canale notifiche Android
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Richiedi permessi
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      await _salvaToken();
      _messaging.onTokenRefresh.listen(_salvaSingoloToken);
    }

    // Gestisci messaggi in foreground
    FirebaseMessaging.onMessage.listen(_gestisciMessaggioForeground);

    // Gestisci tap su notifica quando app era in background
    FirebaseMessaging.onMessageOpenedApp.listen(_gestisciTapNotifica);

    // Controlla se l'app è stata aperta toccando una notifica (era chiusa)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      final appuntamentoId = initialMessage.data['appuntamentoId'];
      if (appuntamentoId != null && appuntamentoId.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 500));
        _container.read(pendingAppuntamentoProvider.notifier).state =
            appuntamentoId;
        _router?.go('/calendario');
      }
    }
  }

  /// Salva il token FCM dell'utente corrente su Firestore
  Future<void> _salvaToken() async {
    final token = await _messaging.getToken();
    if (token == null) return;
    await _salvaSingoloToken(token);
  }

  Future<void> _salvaSingoloToken(String token) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _db
        .collection('users')
        .doc(uid)
        .collection('fcm_tokens')
        .doc(token)
        .set({
      'token': token,
      'platform': defaultTargetPlatform.name.toLowerCase(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Elimina il token quando l'utente fa logout
  Future<void> eliminaToken() async {
    final uid = _auth.currentUser?.uid;
    final token = await _messaging.getToken();
    if (uid == null || token == null) return;

    await _db
        .collection('users')
        .doc(uid)
        .collection('fcm_tokens')
        .doc(token)
        .delete();

    await _messaging.deleteToken();
  }

  /// Mostra notifica locale quando l'app è in foreground
  Future<void> _gestisciMessaggioForeground(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.max,
          priority: Priority.max,
          showWhen: true,
          enableVibration: true,
          playSound: true,
          fullScreenIntent: false,
          visibility: NotificationVisibility.public,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: message.data['appuntamentoId'] ?? '',
    );
  }

  /// Gestisce tap su notifica (app era in background)
  void _gestisciTapNotifica(RemoteMessage message) {
    final appuntamentoId = message.data['appuntamentoId'];
    if (appuntamentoId != null && appuntamentoId.isNotEmpty) {
      _container.read(pendingAppuntamentoProvider.notifier).state =
          appuntamentoId;
      _router?.go('/calendario');
    }
  }
}
