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

  /// Restituisce il prossimo numero cliente in modo atomico.
  ///
  /// Usa una transazione Firestore sul documento `contatori/clienti`
  /// per evitare race condition in caso di accessi concorrenti.
  Future<int> getNextNumeroCliente() async {
    final contatore =
        FirebaseFirestore.instance.collection('contatori').doc('clienti');

    return FirebaseFirestore.instance.runTransaction<int>((tx) async {
      final snap = await tx.get(contatore);
      final corrente = (snap.data()?['ultimo'] as int?) ?? 0;
      final prossimo = corrente + 1;
      tx.set(contatore, {'ultimo': prossimo}, SetOptions(merge: true));
      return prossimo;
    });
  }

  /// Crea un nuovo cliente o aggiorna uno esistente
  /// Se [cliente.id] è vuoto, crea un nuovo documento con ID auto-generato
  Future<String> salvaCliente(ClienteModel cliente) async {
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
