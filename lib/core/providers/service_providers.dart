import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/appuntamenti_service.dart';
import '../../services/cap_service.dart';
import '../../services/clienti_service.dart';
import '../../services/impostazioni_service.dart';
import '../../services/indirizzi_servizio_service.dart';
import '../../services/listino_service.dart';
import '../../services/notifiche_service.dart';
import '../../services/preventivi_service.dart';
import '../../services/preventivo_pdf_service.dart';
import '../../services/servizi_lab_service.dart';
import '../../services/servizi_pest_service.dart';

// ─── Provider condivisi per i service ────────────────────────────────────────
//
// Usare questi provider invece di istanziare i service direttamente nei widget,
// in modo da avere un'unica istanza condivisa per tutto il ProviderScope.

/// Singleton del servizio clienti (Firestore collection 'clienti')
final clientiServiceProvider =
    Provider<ClientiService>((ref) => ClientiService());

/// Singleton del servizio impostazioni (Firestore collection 'impostazioni')
final impostazioniServiceProvider =
    Provider<ImpostazioniService>((ref) => ImpostazioniService());

/// Singleton del servizio servizi lab (Firestore collection 'servizi_lab')
final serviziLabServiceProvider =
    Provider<ServiziLabService>((ref) => ServiziLabService());

/// Singleton del servizio servizi pest (Firestore collection 'servizi_pest')
final serviziPestServiceProvider =
    Provider<ServiziPestService>((ref) => ServiziPestService());

/// Singleton del servizio indirizzi servizio (sotto-collezione clienti)
final indirizziServizioServiceProvider =
    Provider<IndirizziServizioService>((ref) => IndirizziServizioService());

/// Singleton del servizio CAP (lookup da assets JSON, con cache in memoria)
final capServiceProvider = Provider<CapService>((ref) => CapService());

/// Singleton del servizio appuntamenti (Firestore collection 'appuntamenti')
final appuntamentiServiceProvider =
    Provider<AppuntamentiService>((ref) => AppuntamentiService());

/// Singleton del servizio notifiche in-app (Firestore notifiche/{uid}/items)
final notificheServiceProvider =
    Provider<NotificheService>((ref) => NotificheService());

/// Singleton del servizio preventivi (Firestore collection 'preventivi')
final preventiviServiceProvider =
    Provider<PreventiviService>((ref) => PreventiviService());

/// Singleton del service per la generazione PDF dei preventivi
final preventivoPdfServiceProvider =
    Provider<PreventivoPdfService>((ref) => PreventivoPdfService());

/// Singleton del servizio listino a cascata v2 (impostazioni/preventivo_listino_v2)
final listinoServiceProvider =
    Provider<ListinoService>((ref) => ListinoService());
