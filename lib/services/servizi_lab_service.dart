import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/appuntamento_model.dart';
import '../models/servizio_lab_model.dart';
import 'appuntamenti_service.dart';

/// Servizio per la gestione dei referti di analisi di laboratorio su Firestore
class ServiziLabService {
  final CollectionReference _collection =
      FirebaseFirestore.instance.collection('servizi_lab');
  final AppuntamentiService _appuntamentiService = AppuntamentiService();

  // ─── Lettura ───────────────────────────────────────────────────────────────

  /// Stream real-time di tutti i servizi lab, ordinati per certificazione
  Stream<List<ServizioLabModel>> getServiziLab() {
    return _collection
        .orderBy('certificazioneNumerica', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ServizioLabModel.fromFirestore(doc))
            .toList());
  }

  /// Recupera un singolo servizio lab tramite ID
  Future<ServizioLabModel?> getServizioLabById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return ServizioLabModel.fromFirestore(doc);
  }

  // ─── Generazione codici ────────────────────────────────────────────────────

  /// Calcola la prossima certificazione in modo atomico nel formato "AA/NNN".
  ///
  /// Usa una transazione Firestore sul documento `contatori/servizi_lab_ANNO`
  /// per evitare race condition. Il contatore riparte da 001 ogni anno.
  Future<String> getNextCertificazione() async {
    final now = DateTime.now();
    final anno = (now.year % 100).toString().padLeft(2, '0');
    final contatore = FirebaseFirestore.instance
        .collection('contatori')
        .doc('servizi_lab_$anno');

    final prossimo =
        await FirebaseFirestore.instance.runTransaction<int>((tx) async {
      final snap = await tx.get(contatore);
      final corrente = (snap.data()?['ultimo'] as int?) ?? 0;
      final prossimo = corrente + 1;
      tx.set(contatore, {'ultimo': prossimo, 'anno': anno},
          SetOptions(merge: true));
      return prossimo;
    });

    return '$anno/${prossimo.toString().padLeft(3, '0')}';
  }

  /// Genera il codice A nel formato AAMMGG
  /// Esempio: data 30/03/2026 → "260330"
  Future<String> generaCodiceA(DateTime data) async {
    final anno = (data.year % 100).toString().padLeft(2, '0');
    final mese = data.month.toString().padLeft(2, '0');
    final giorno = data.day.toString().padLeft(2, '0');
    return '$anno$mese$giorno';
  }

  // ─── Scrittura ─────────────────────────────────────────────────────────────

  /// Salva un servizio lab (crea se id è vuoto, aggiorna altrimenti).
  ///
  /// Integrazione automatica calendario:
  /// se [fineProveGenerali] è valorizzata, crea un appuntamento 'lettura_piastre'
  /// con data = fineProveGenerali + 2 giorni lavorativi.
  Future<String> salvaServizioLab(ServizioLabModel servizio) async {
    final isNuovo = servizio.id.isEmpty;
    var eraBozza = false;

    if (!isNuovo) {
      final esistente = await _collection.doc(servizio.id).get();
      if (esistente.exists) {
        final data = esistente.data() as Map<String, dynamic>?;
        eraBozza = data?['isDraft'] as bool? ?? false;
        if (!eraBozza && servizio.isDraft) {
          throw Exception(
            'Un servizio lab definitivo non puo essere riportato in bozza.',
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

    // Crea automaticamente appuntamento 'lettura_piastre' per i nuovi servizi
    // con data fine prove specificata, anche se il record era stato
    // inizialmente salvato come bozza.
    if (!servizio.isDraft &&
        (isNuovo || eraBozza) &&
        servizio.fineProveGenerali != null) {
      final dataLettura =
          _aggiungiGiorniLavorativi(servizio.fineProveGenerali!, 2);
      final appuntamento = AppuntamentoModel(
        id: '',
        titolo: 'Lettura piastre — ${servizio.committente}',
        descrizione:
            'Lettura piastre automatica per certificazione ${servizio.certificazioneNumerica}',
        dataInizio: dataLettura,
        dataFine: dataLettura.add(const Duration(hours: 1)),
        tipo: 'lettura_piastre',
        clienteId: servizio.codiceCliente.isNotEmpty
            ? servizio.codiceCliente
            : null,
        clienteNome: servizio.committente,
        servizioCid: null, // ID non disponibile in questo momento
        tecnico: servizio.tecnico.isNotEmpty ? servizio.tecnico : null,
        notificaAbilitata: true,
        notificaGiorniPrima: 1,
        completato: false,
        colore: AppuntamentoModel.coloreHexDaTipo('lettura_piastre'),
        creadaDa: 'system',
        createdAt: DateTime.now(),
      );
      await _appuntamentiService.salvaAppuntamento(appuntamento);
    }

    return servizioId;
  }

  /// Aggiunge [giorni] giorni lavorativi (lun-ven) a una data
  DateTime _aggiungiGiorniLavorativi(DateTime data, int giorni) {
    var risultato = data;
    var aggiunti = 0;
    while (aggiunti < giorni) {
      risultato = risultato.add(const Duration(days: 1));
      // Salta sabato (6) e domenica (7)
      if (risultato.weekday != DateTime.saturday &&
          risultato.weekday != DateTime.sunday) {
        aggiunti++;
      }
    }
    return risultato;
  }

  /// Elimina un servizio lab dato il suo ID
  Future<void> eliminaServizioLab(String id) async {
    await _collection.doc(id).delete();
  }
}
