import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appuntamento_model.dart';
import '../models/servizio_pest_model.dart';
import 'appuntamenti_service.dart';

/// Servizio per la gestione degli interventi Pest su Firestore
class ServiziPestService {
  final CollectionReference _collection =
      FirebaseFirestore.instance.collection('servizi_pest');
  final AppuntamentiService _appuntamentiService = AppuntamentiService();

  // ─── Lettura ───────────────────────────────────────────────────────────────

  /// Stream real-time di tutti i servizi pest, ordinati per data di creazione
  Stream<List<ServizioPestModel>> getServiziPest() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ServizioPestModel.fromFirestore(doc))
            .toList());
  }

  /// Recupera un singolo servizio pest tramite ID
  Future<ServizioPestModel?> getServizioPestById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return ServizioPestModel.fromFirestore(doc);
  }

  // ─── Generazione codici ────────────────────────────────────────────────────

  /// Genera il codice data nel formato AAMMGG
  /// Esempio: data 12/04/2026 → "260412"
  Future<String> generaCodiceData(DateTime data) async {
    final anno = (data.year % 100).toString().padLeft(2, '0');
    final mese = data.month.toString().padLeft(2, '0');
    final giorno = data.day.toString().padLeft(2, '0');
    return '$anno$mese$giorno';
  }

  // ─── Scrittura ─────────────────────────────────────────────────────────────

  /// Salva un servizio pest (crea se id è vuoto, aggiorna altrimenti).
  ///
  /// Integrazione automatica calendario:
  /// se ulterioriInterventi != 'NO' e codiceDataUlteriore non è vuoto,
  /// crea automaticamente un appuntamento 'richiamo' con data parsata
  /// dal formato AAMMGG di codiceDataUlteriore.
  Future<String> salvaServizioPest(ServizioPestModel servizio) async {
    final isNuovo = servizio.id.isEmpty;
    var eraBozza = false;

    if (!isNuovo) {
      final esistente = await _collection.doc(servizio.id).get();
      if (esistente.exists) {
        final data = esistente.data() as Map<String, dynamic>?;
        eraBozza = data?['isDraft'] as bool? ?? false;
        if (!eraBozza && servizio.isDraft) {
          throw Exception(
            'Un intervento Pest definitivo non puo essere riportato in bozza.',
          );
        }
      }
    }

    late final String servizioId;
    if (isNuovo) {
      final doc = await _collection.add(servizio.toMap());
      servizioId = doc.id;
    } else {
      await _collection.doc(servizio.id).update(servizio.toMap());
      servizioId = servizio.id;
    }

    // Crea automaticamente appuntamento 'richiamo' per i nuovi servizi
    // con ulteriori interventi pianificati, anche quando una bozza
    // viene confermata in un secondo momento.
    if (!servizio.isDraft &&
        (isNuovo || eraBozza) &&
        servizio.ulterioriInterventi.isNotEmpty &&
        servizio.ulterioriInterventi.toUpperCase() != 'NO' &&
        servizio.codiceDataUlteriore.length == 6) {
      final dataRichiamo = _parsaCodiceData(servizio.codiceDataUlteriore);
      if (dataRichiamo != null) {
        final appuntamento = AppuntamentoModel(
          id: '',
          titolo: 'Richiamo pest — ${servizio.committente}',
          descrizione:
              'Richiamo pianificato per intervento ${servizio.codiceData}. '
              'Ulteriori interventi: ${servizio.ulterioriInterventi}',
          dataInizio: dataRichiamo,
          dataFine: dataRichiamo.add(const Duration(hours: 2)),
          tipo: 'richiamo',
          clienteId: servizio.codiceCliente.isNotEmpty
              ? servizio.codiceCliente
              : null,
          clienteNome: servizio.committente,
          servizioCid: null,
          tecnico: servizio.tecnico.isNotEmpty ? servizio.tecnico : null,
          notificaAbilitata: true,
          notificaGiorniPrima: 2,
          completato: false,
          colore: AppuntamentoModel.coloreHexDaTipo('richiamo'),
          creadaDa: 'system',
          createdAt: DateTime.now(),
        );
        await _appuntamentiService.salvaAppuntamento(appuntamento);
      }
    }

    return servizioId;
  }

  /// Parsa una stringa AAMMGG in DateTime.
  /// Restituisce null se il formato non è valido.
  DateTime? _parsaCodiceData(String codice) {
    if (codice.length != 6) return null;
    try {
      final anno = 2000 + int.parse(codice.substring(0, 2));
      final mese = int.parse(codice.substring(2, 4));
      final giorno = int.parse(codice.substring(4, 6));
      final data = DateTime(anno, mese, giorno);
      // Verifica che la data sia valida
      if (data.month != mese || data.day != giorno) return null;
      return data;
    } catch (_) {
      return null;
    }
  }

  /// Elimina un servizio pest dato il suo ID
  Future<void> eliminaServizioPest(String id) async {
    await _collection.doc(id).delete();
  }
}
