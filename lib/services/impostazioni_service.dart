import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/categoria_model.dart';

// NOTA: Documenti Firestore da creare per le sezioni Pest (se non esistono):
//   impostazioni/pest_tipi_intervento       → { nome: "Tipi intervento Pest", hasSottocategorie: false, items: [] }
//   impostazioni/pest_numero_intervento     → { nome: "N° intervento Pest",   hasSottocategorie: false, items: [] }
//   impostazioni/pest_tecnici              → { nome: "Tecnici Pest",          hasSottocategorie: false, items: [] }
//   impostazioni/pest_prodotti             → { nome: "Prodotti Pest",         hasSottocategorie: false, items: [] }
//   impostazioni/pest_ulteriori_interventi  → { nome: "Ulteriori interventi Pest", hasSottocategorie: false, items: [] }
//   impostazioni/pest_voci_economiche       → { nome: "Voci economiche Pest", hasSottocategorie: false, items: [] }
//
// NOTA: Documenti Firestore da creare per la sezione Preventivo (se non esistono):
//   impostazioni/preventivo_listino    → { nome: "Listino servizi", hasSottocategorie: false,
//                                         items: [ { "codice": "P_DSF2", "descrizione": "Disinfezione in ott alla L.82/94 DM 274/97", "prezzoUnitario": 150.0 } ] }
//   impostazioni/preventivo_giornata   → { nome: "Giornata/esecuzione",     hasSottocategorie: false, items: ["FERIALE","FESTIVO","NOTTURNO"] }
//   impostazioni/preventivo_pagamento  → { nome: "Modalità di pagamento",   hasSottocategorie: false,
//                                         items: ["Bonifico","Contanti","Assegno","Anticipo 30% saldo alla esecuzione","Immediato"] }
//   impostazioni/preventivo_validita   → { nome: "Validità preventivo",     hasSottocategorie: false, items: ["30 giorni","60 giorni","90 giorni"] }
//   impostazioni/preventivo_rinnovo    → { nome: "Rinnovo preventivo",      hasSottocategorie: false, items: ["Sì","No"] }
//   NOTA listino: il campo items contiene Map, non stringhe.

/// Servizio per la gestione delle impostazioni applicazione su Firestore
///
/// Struttura Firestore:
/// - Collection: 'impostazioni'
/// - Documenti con ID fisso, struttura a due modalità:
///
///   Lista semplice  → { nome, hasSottocategorie: false, items: [...] }
///   Con sottocategorie → { nome, hasSottocategorie: true, sottocategorie: { "Key": [...] } }
class ImpostazioniService {
  final CollectionReference _collection =
      FirebaseFirestore.instance.collection('impostazioni');

  // ─── Categorie ─────────────────────────────────────────────────────────────

  /// Stream real-time di tutte le categorie, ordinate per nome
  Stream<List<CategoriaModel>> getCategorie() {
    return _collection.snapshots().map((snap) {
      final lista = snap.docs
          .map((doc) => CategoriaModel.fromFirestore(doc))
          .toList();
      lista.sort((a, b) => a.nome.compareTo(b.nome));
      return lista;
    });
  }

  /// Stream real-time di un singolo documento categoria
  Stream<CategoriaModel?> getCategoriaStream(String docId) {
    return _collection.doc(docId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return CategoriaModel.fromFirestore(snap);
    });
  }

  /// Crea una nuova categoria con struttura iniziale vuota
  Future<void> creaCategoria(
      String id, String nome, bool hasSottocategorie) async {
    await _collection.doc(id).set({
      'nome': nome,
      'hasSottocategorie': hasSottocategorie,
      'items': hasSottocategorie ? [] : [],
      'sottocategorie': hasSottocategorie ? <String, dynamic>{} : <String, dynamic>{},
    });
  }

  /// Elimina una categoria (i valori già salvati negli altri documenti non vengono toccati)
  Future<void> eliminaCategoria(String id) async {
    await _collection.doc(id).delete();
  }

  /// Cambia la modalità (lista semplice ↔ con sottocategorie) e re-inizializza i dati
  Future<void> toggleSottocategorie(String categoriaId, bool valore) async {
    if (valore) {
      // Passa a modalità sottocategorie: azzera items e inizializza mappa vuota
      await _collection.doc(categoriaId).update({
        'hasSottocategorie': true,
        'sottocategorie': <String, dynamic>{},
        'items': [],
      });
    } else {
      // Torna a lista semplice: rimuove sottocategorie e inizializza items vuoti
      await _collection.doc(categoriaId).update({
        'hasSottocategorie': false,
        'items': [],
        'sottocategorie': <String, dynamic>{},
      });
    }
  }

  // ─── Lista semplice ────────────────────────────────────────────────────────

  /// Stream real-time degli items di una categoria senza sottocategorie
  Stream<List<String>> getItems(String categoriaId) {
    return _collection.doc(categoriaId).snapshots().map((snap) {
      if (!snap.exists) return <String>[];
      final data = snap.data() as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>? ?? [];
      return items.cast<String>();
    });
  }

  /// Aggiunge un item alla lista (usa arrayUnion per evitare duplicati)
  Future<void> aggiungiItem(String categoriaId, String item) async {
    await _collection.doc(categoriaId).set(
      {'items': FieldValue.arrayUnion([item])},
      SetOptions(merge: true),
    );
  }

  /// Rimuove un item dalla lista
  Future<void> eliminaItem(String categoriaId, String item) async {
    await _collection.doc(categoriaId).update({
      'items': FieldValue.arrayRemove([item]),
    });
  }

  // ─── Sottocategorie ────────────────────────────────────────────────────────

  /// Stream real-time della mappa sottocategorie
  Stream<Map<String, List<String>>> getSottocategorie(String categoriaId) {
    return _collection.doc(categoriaId).snapshots().map((snap) {
      if (!snap.exists) return {};
      final data = snap.data() as Map<String, dynamic>;
      final rawSotto = data['sottocategorie'] as Map<String, dynamic>? ?? {};
      return rawSotto.map((k, v) {
        final lista = (v as List<dynamic>?)?.cast<String>() ?? [];
        return MapEntry(k, lista);
      });
    });
  }

  /// Aggiunge una nuova sottocategoria vuota
  Future<void> aggiungiSottocategoria(
      String categoriaId, String nomeSotto) async {
    await _collection.doc(categoriaId).update({
      'sottocategorie.$nomeSotto': <String>[],
    });
  }

  /// Elimina una sottocategoria e tutti i suoi elementi
  Future<void> eliminaSottocategoria(
      String categoriaId, String nomeSotto) async {
    await _collection.doc(categoriaId).update({
      'sottocategorie.$nomeSotto': FieldValue.delete(),
    });
  }

  /// Aggiunge un elemento a una sottocategoria esistente
  Future<void> aggiungiElemento(
      String categoriaId, String nomeSotto, String elemento) async {
    await _collection.doc(categoriaId).update({
      'sottocategorie.$nomeSotto': FieldValue.arrayUnion([elemento]),
    });
  }

  /// Rimuove un elemento da una sottocategoria
  Future<void> eliminaElemento(
      String categoriaId, String nomeSotto, String elemento) async {
    await _collection.doc(categoriaId).update({
      'sottocategorie.$nomeSotto': FieldValue.arrayRemove([elemento]),
    });
  }

  // ─── Listino preventivo (items come lista di Map) ────────────────────────────

  /// Stream real-time delle voci del listino preventivo.
  /// Ogni voce è una Map con i campi: codice, descrizione, prezzoUnitario.
  Stream<List<Map<String, dynamic>>> getVociListino(String categoriaId) {
    return _collection.doc(categoriaId).snapshots().map((snap) {
      if (!snap.exists) return <Map<String, dynamic>>[];
      final data = snap.data() as Map<String, dynamic>;
      final rawItems = data['items'] as List<dynamic>? ?? [];
      // Considera solo le voci di tipo Map (ignora eventuali stringhe residue)
      return rawItems.whereType<Map<String, dynamic>>().toList();
    });
  }

  /// Aggiunge una voce Map al listino.
  /// Usa arrayUnion per evitare duplicati esatti.
  Future<void> aggiungiVoceListino(
      String categoriaId, Map<String, dynamic> voce) async {
    await _collection.doc(categoriaId).set(
      {'items': FieldValue.arrayUnion([voce])},
      SetOptions(merge: true),
    );
  }

  /// Elimina la voce del listino all'indice specificato.
  /// Usa read-modify-write perché arrayRemove con indice non è supportato.
  Future<void> eliminaVoceListinoPerIndice(
      String categoriaId, int indice) async {
    final doc = await _collection.doc(categoriaId).get();
    if (!doc.exists) return;
    final data = doc.data() as Map<String, dynamic>;
    final items = List<dynamic>.from(data['items'] as List<dynamic>? ?? []);
    if (indice < 0 || indice >= items.length) return;
    items.removeAt(indice);
    await _collection.doc(categoriaId).update({'items': items});
  }
}
