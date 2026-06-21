import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cliente_model.dart';

/// Servizio per la gestione delle anagrafiche clienti su Firestore
class ClientiService {
  final CollectionReference _collection =
      FirebaseFirestore.instance.collection('clienti');

  /// Stream real-time di tutti i clienti, ordinati per numero cliente
  Stream<List<ClienteModel>> getClienti() {
    return _collection
        .orderBy('numeroCliente')
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => ClienteModel.fromFirestore(doc)).toList());
  }

  /// Restituisce il più piccolo numero cliente disponibile (>= 1) non ancora
  /// usato, riempiendo gli eventuali "buchi" lasciati da clienti eliminati. (A2)
  Future<int> getPrimoNumeroLibero() async {
    final snap = await _collection.get();
    final usati = <int>{};
    for (final doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final n = (data['numeroCliente'] as num?)?.toInt();
      if (n != null && n > 0) usati.add(n);
    }
    var candidato = 1;
    while (usati.contains(candidato)) {
      candidato++;
    }
    return candidato;
  }

  /// True se [numero] è già assegnato a un cliente diverso da [escludiId].
  /// Usato per garantire l'unicità del numero cliente. (A1)
  Future<bool> numeroEsiste(int numero, {String? escludiId}) async {
    final snap =
        await _collection.where('numeroCliente', isEqualTo: numero).get();
    return snap.docs.any((d) => d.id != escludiId);
  }

  /// Crea un nuovo cliente o aggiorna uno esistente
  /// Se [cliente.id] è vuoto, crea un nuovo documento con ID auto-generato
  Future<String> salvaCliente(ClienteModel cliente) async {
    // A1 — unicità del numero cliente: blocca due clienti con lo stesso numero.
    if (cliente.numeroCliente > 0 &&
        await numeroEsiste(cliente.numeroCliente,
            escludiId: cliente.id.isEmpty ? null : cliente.id)) {
      throw Exception(
        'Numero cliente ${cliente.numeroCliente} già assegnato a un altro cliente.',
      );
    }
    if (cliente.id.isNotEmpty) {
      final esistente = await _collection.doc(cliente.id).get();
      if (esistente.exists) {
        final data = esistente.data() as Map<String, dynamic>?;
        final eraBozza = data?['isDraft'] as bool? ?? false;
        if (!eraBozza && cliente.isDraft) {
          throw Exception(
            'Un cliente definitivo non puo essere riportato in bozza.',
          );
        }
      }
    }

    if (cliente.id.isEmpty) {
      // Creazione nuovo cliente
      final doc = await _collection.add(cliente.toMap());
      return doc.id;
    } else {
      // Aggiornamento cliente esistente
      await _collection.doc(cliente.id).update(cliente.toMap());
      return cliente.id;
    }
  }

  /// Elimina un cliente dato il suo ID
  Future<void> eliminaCliente(String id) async {
    await _collection.doc(id).delete();
  }

  /// Recupera un singolo cliente tramite ID
  Future<ClienteModel?> getClienteById(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return ClienteModel.fromFirestore(doc);
  }

  /// Legge tutti i valori distinti di un campo da Firestore.
  /// Usato per i suggerimenti nei campi Autocomplete.
  Future<List<String>> getSuggerimenti(String campo) async {
    final snap = await _collection.get();
    final valori = snap.docs
        .map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data[campo]?.toString() ?? '';
        })
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList();
    valori.sort();
    return valori;
  }

  /// Legge tutti i suggerimenti per più campi in una sola query Firestore.
  ///
  /// Ritorna una mappa campo → lista di valori distinti ordinati.
  /// Molto più efficiente di chiamare [getSuggerimenti] N volte.
  Future<Map<String, List<String>>> getAllSuggerimenti(
      List<String> campi) async {
    final snap = await _collection.get();
    final risultato = <String, Set<String>>{
      for (final c in campi) c: {},
    };

    for (final doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      for (final campo in campi) {
        final valore = data[campo]?.toString() ?? '';
        if (valore.isNotEmpty) risultato[campo]!.add(valore);
      }
    }

    return {
      for (final entry in risultato.entries)
        entry.key: entry.value.toList()..sort(),
    };
  }
}
