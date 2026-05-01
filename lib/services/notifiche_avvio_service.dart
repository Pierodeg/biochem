import 'package:shared_preferences/shared_preferences.dart';
import '../models/appuntamento_model.dart';
import '../models/notifica_model.dart';
import 'appuntamenti_service.dart';
import 'notifiche_service.dart';

/// Servizio per il controllo giornaliero degli appuntamenti in scadenza
/// e la generazione delle notifiche in-app corrispondenti.
///
/// Viene chiamato all'avvio dell'app (in main.dart) dopo l'inizializzazione Firebase.
/// Usa SharedPreferences per tenere traccia dell'ultimo controllo ed evitare
/// notifiche duplicate nella stessa sessione.
class NotificheAvvioService {
  static const String _prefixKeyUltimoControllo = 'ultimo_controllo_notifiche';
  static const int _giorniDiAnticipo = 3;

  final AppuntamentiService _appuntamentiService;
  final NotificheService _notificheService;

  NotificheAvvioService({
    AppuntamentiService? appuntamentiService,
    NotificheService? notificheService,
  })  : _appuntamentiService =
            appuntamentiService ?? AppuntamentiService(),
        _notificheService =
            notificheService ?? NotificheService();

  /// Controlla gli appuntamenti in scadenza e crea notifiche in-app per l'utente.
  ///
  /// [uid] è l'UID dell'utente correntemente autenticato.
  /// Verifica SharedPreferences per non rieseguire il controllo se già eseguito oggi.
  /// [forceCheck] = true bypassa il gate giornaliero (SharedPreferences).
  /// Usato dopo il salvataggio di un appuntamento per aggiornare subito la campanella.
  Future<void> verificaScadenze(String uid, {bool forceCheck = false}) async {
    try {
    final prefs = await SharedPreferences.getInstance();
    final oggi = DateTime.now();
    final oggiStr = '${oggi.year}-${oggi.month}-${oggi.day}';

    // Chiave per utente per evitare conflitti su dispositivi condivisi
    final keyUltimoControllo = '${_prefixKeyUltimoControllo}_$uid';

    // Evita di eseguire il controllo più volte nello stesso giorno
    // (bypassato quando chiamato esplicitamente dopo un salvataggio)
    if (!forceCheck) {
      final ultimoControllo = prefs.getString(keyUltimoControllo);
      if (ultimoControllo == oggiStr) return;
    }

    try {
      // Carica appuntamenti in scadenza nei prossimi 3 giorni
      final inScadenza = await _appuntamentiService
          .getAppuntamentiInScadenza(_giorniDiAnticipo);

      for (final app in inScadenza) {
        if (!app.notificaAbilitata) continue;

        // Calcola la data in cui la notifica deve essere generata
        final dataNotifica = app.dataInizio
            .subtract(Duration(days: app.notificaGiorniPrima));

        // Genera la notifica solo se la data è oggi o è già passata
        if (dataNotifica.isAfter(oggi)) continue;

        // Verifica che non esista già una notifica per questo appuntamento
        final esiste = await _notificheService
            .esisteNotificaPerAppuntamento(uid, app.id);
        if (esiste) continue;

        // Crea la notifica in-app
        final notifica = NotificaModel(
          id: '',
          titolo: 'Promemoria: ${app.titolo}',
          corpo: _corpoNotifica(app),
          tipo: app.tipo,
          appuntamentoId: app.id,
          letta: false,
          createdAt: DateTime.now(),
          scadenza: app.dataInizio,
        );

        await _notificheService.creaNotifica(uid, notifica);
      }

      // Salva la data dell'ultimo controllo (solo per il check giornaliero)
      if (!forceCheck) {
        await prefs.setString(keyUltimoControllo, oggiStr);
      }
    } catch (_) {
      // Errore silenzioso: l'app funziona anche senza notifiche
    }
    } catch (_) {
      // Errore silenzioso: SharedPreferences o altro errore di init
    }
  }

  /// Costruisce il corpo del messaggio di notifica in base all'appuntamento
  String _corpoNotifica(AppuntamentoModel app) {
    String formatter(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

    final dataStr = formatter(app.dataInizio);

    if (app.clienteNome != null && app.clienteNome!.isNotEmpty) {
      return '${app.clienteNome} — $dataStr';
    }
    return dataStr;
  }
}
