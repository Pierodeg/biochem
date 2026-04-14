import 'package:flutter/foundation.dart';

// NOTA FASE 2:
// Per attivare le notifiche push su web occorre:
// 1. Aggiungere firebase_messaging: ^15.x.x al pubspec.yaml
// 2. Creare web/firebase-messaging-sw.js con la configurazione FCM
// 3. Configurare la VAPID key per le Web Push API
// 4. Ripristinare l'implementazione completa di questo servizio
//
// Su mobile (Android/iOS) la piattaforma non richiede Service Worker
// e può usare direttamente firebase_messaging.

/// Servizio placeholder per le notifiche push FCM.
///
/// L'implementazione completa (con firebase_messaging) è rimandata a Fase 2.
/// Al momento tutti i metodi sono no-op per consentire la build web.
class PushNotificationService {
  /// Inizializza il servizio notifiche push.
  ///
  /// No-op finché firebase_messaging non viene configurato per il web.
  static Future<void> initialize() async {
    debugPrint(
      '[PushNotificationService] Notifiche push non disponibili in questa versione (Fase 2)',
    );
  }

  /// Rimuove il token FCM del dispositivo corrente (es. al logout).
  ///
  /// No-op finché firebase_messaging non viene configurato per il web.
  static Future<void> rimuoviToken() async {}
}
