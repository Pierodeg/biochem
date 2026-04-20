import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/listino_model.dart';

// Regola Firestore: il documento preventivo_listino è in impostazioni/
// ed è già coperto dalla regola esistente:
//   match /impostazioni/{docId} {
//     allow read: if isAuth();
//     allow write: if isAdmin();
//   }

/// Servizio per la gestione del listino servizi a cascata.
///
/// Documento Firestore: impostazioni/preventivo_listino
/// Struttura:
///   {
///     tipologie: { "P": { nome, ordine }, ... }
///     sottotipi:  { "P_DSF": { nome, tipologiaId, ordine, servizi: [...] }, ... }
///   }
///
/// IMPORTANTE — operazioni su mappe annidate:
///   Per aggiornare una singola chiave in tipologie o sottotipi si usa la
///   dot-notation con update() (es. 'tipologie.P').
///   L'approccio set(merge:true) con mappa annidata è ERRATO perché Firestore
///   rimpiazza l'intera mappa invece di aggiornare solo la chiave.
class ListinoService {
  final DocumentReference _doc = FirebaseFirestore.instance
      .collection('impostazioni')
      .doc('preventivo_listino');

  // ─── Lettura ────────────────────────────────────────────────────────────────

  /// Stream real-time del listino completo
  Stream<ListinoV2> getListino() {
    return _doc.snapshots().map((snap) {
      if (!snap.exists) return ListinoV2.vuoto;
      return ListinoV2.fromFirestore(snap.data() as Map<String, dynamic>);
    });
  }

  /// One-shot — ritorna le tipologie ordinate con i sotto-tipi già incorporati
  Future<List<TipologiaListino>> getTipologie() async {
    final snap = await _doc.get();
    if (!snap.exists) return [];
    final listino = ListinoV2.fromFirestore(snap.data() as Map<String, dynamic>);
    return listino.tipologieOrdinate
        .map((t) => TipologiaListino(
              id: t.id,
              nome: t.nome,
              ordine: t.ordine,
              sottotipi: listino.sottoTipiDi(t.id),
            ))
        .toList();
  }

  // ─── Utility interna ────────────────────────────────────────────────────────

  Future<void> _assicuraEsistenza() async {
    final snap = await _doc.get();
    if (!snap.exists) {
      await _doc.set({
        'tipologie': <String, dynamic>{},
        'sottotipi': <String, dynamic>{},
      });
    }
  }

  // ─── Salva lista tipologie ──────────────────────────────────────────────────

  /// Converte una List<TipologiaListino> nella struttura Firestore e salva.
  Future<void> salvaTipologie(List<TipologiaListino> tipologie) async {
    final Map<String, dynamic> tipologieMap = {};
    final Map<String, dynamic> sottotipiMap = {};

    for (int i = 0; i < tipologie.length; i++) {
      final t = tipologie[i];
      tipologieMap[t.id] = {'nome': t.nome, 'ordine': i};

      for (int j = 0; j < t.sottotipi.length; j++) {
        final s = t.sottotipi[j];
        sottotipiMap[s.id] = {
          'nome': s.nome,
          'tipologiaId': t.id,
          'ordine': j,
          'servizi': s.servizi.map((srv) => srv.toMap()).toList(),
        };
      }
    }

    await _doc.set({'tipologie': tipologieMap, 'sottotipi': sottotipiMap});
  }

  // ─── Tipologie ──────────────────────────────────────────────────────────────

  /// Crea o sovrascrive una tipologia (dot-notation → nessun effetto sulle altre)
  Future<void> aggiornaTipologia(TipologiaListino t) async {
    await _assicuraEsistenza();
    await _doc.update({'tipologie.${t.id}': t.toMap()});
  }

  /// Elimina una tipologia e tutti i suoi sotto-tipi (read-modify-write)
  Future<void> eliminaTipologia(String tipologiaId) async {
    final snap = await _doc.get();
    if (!snap.exists) return;
    final data = Map<String, dynamic>.from(
        snap.data() as Map<String, dynamic>);

    final tipologie = Map<String, dynamic>.from(
        data['tipologie'] as Map<String, dynamic>? ?? {});
    tipologie.remove(tipologiaId);

    final sottotipi = Map<String, dynamic>.from(
        data['sottotipi'] as Map<String, dynamic>? ?? {});
    sottotipi.removeWhere(
        (_, v) => (v as Map<String, dynamic>)['tipologiaId'] == tipologiaId);

    await _doc.update({'tipologie': tipologie, 'sottotipi': sottotipi});
  }

  // ─── Sotto-tipi ─────────────────────────────────────────────────────────────

  /// Crea o sovrascrive un sotto-tipo (dot-notation → nessun effetto sugli altri)
  Future<void> aggiornaSottotipo(SottotipoListino s) async {
    await _assicuraEsistenza();
    await _doc.update({'sottotipi.${s.id}': s.toMap()});
  }

  /// Elimina un sotto-tipo e tutti i suoi servizi
  Future<void> eliminaSottotipo(String sottotipoId) async {
    await _assicuraEsistenza();
    await _doc.update({'sottotipi.$sottotipoId': FieldValue.delete()});
  }

  // ─── Servizi ────────────────────────────────────────────────────────────────

  /// Aggiunge un servizio alla lista del sotto-tipo (read-modify-write)
  Future<void> aggiungiServizio(
    List<TipologiaListino> tipologie,
    String tipologiaId,
    String sottotipoId,
    ServizioListino servizio,
  ) async {
    final snap = await _doc.get();
    if (!snap.exists) return;
    final data = Map<String, dynamic>.from(snap.data() as Map<String, dynamic>);
    final sottotipiMap = Map<String, dynamic>.from(
        data['sottotipi'] as Map<String, dynamic>? ?? {});
    final sotto = Map<String, dynamic>.from(
        sottotipiMap[sottotipoId] as Map<String, dynamic>? ?? {});
    final servizi = List<dynamic>.from(sotto['servizi'] as List<dynamic>? ?? []);

    servizi.add(servizio.toMap());
    sotto['servizi'] = servizi;
    sottotipiMap[sottotipoId] = sotto;
    await _doc.update({'sottotipi': sottotipiMap});
  }

  /// Elimina un servizio tramite codiceUnivoco (read-modify-write)
  Future<void> eliminaServizio(
    List<TipologiaListino> tipologie,
    String tipologiaId,
    String sottotipoId,
    String codiceUnivoco,
  ) async {
    final snap = await _doc.get();
    if (!snap.exists) return;
    final data = Map<String, dynamic>.from(snap.data() as Map<String, dynamic>);
    final sottotipiMap = Map<String, dynamic>.from(
        data['sottotipi'] as Map<String, dynamic>? ?? {});
    final sotto = Map<String, dynamic>.from(
        sottotipiMap[sottotipoId] as Map<String, dynamic>? ?? {});
    final servizi = List<dynamic>.from(sotto['servizi'] as List<dynamic>? ?? []);

    servizi.removeWhere(
        (s) => (s as Map<String, dynamic>)['codiceUnivoco'] == codiceUnivoco);
    sotto['servizi'] = servizi;
    sottotipiMap[sottotipoId] = sotto;
    await _doc.update({'sottotipi': sottotipiMap});
  }

  /// Aggiorna nome e prezzo di un singolo servizio (read-modify-write)
  Future<void> aggiornaServizio(
    List<TipologiaListino> tipologie,
    String tipologiaId,
    String sottotipoId,
    String codiceUnivoco,
    String nuovoNome,
    double nuovoPrezzo,
  ) async {
    final snap = await _doc.get();
    if (!snap.exists) return;
    final data = Map<String, dynamic>.from(snap.data() as Map<String, dynamic>);
    final sottotipiMap = Map<String, dynamic>.from(
        data['sottotipi'] as Map<String, dynamic>? ?? {});
    final sotto = Map<String, dynamic>.from(
        sottotipiMap[sottotipoId] as Map<String, dynamic>? ?? {});
    final servizi = List<dynamic>.from(sotto['servizi'] as List<dynamic>? ?? []);

    final idx = servizi.indexWhere(
        (s) => (s as Map<String, dynamic>)['codiceUnivoco'] == codiceUnivoco);
    if (idx < 0) return;
    (servizi[idx] as Map<String, dynamic>)['descrizione'] = nuovoNome;
    (servizi[idx] as Map<String, dynamic>)['prezzoUnitario'] = nuovoPrezzo;
    sotto['servizi'] = servizi;
    sottotipiMap[sottotipoId] = sotto;
    await _doc.update({'sottotipi': sottotipiMap});
  }
}
