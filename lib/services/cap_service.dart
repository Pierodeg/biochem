import 'dart:convert';
import 'package:flutter/services.dart';

/// Risultato della ricerca per CAP
class CapResult {
  final String citta;
  final String provincia;
  const CapResult({required this.citta, required this.provincia});
}

/// Servizio per la ricerca città/provincia tramite CAP
///
/// Carica il JSON degli CAP della Sardegna una sola volta (singleton lazy)
/// e mette a disposizione il metodo [cercaPerCap].
class CapService {
  // Istanza singleton
  static final CapService _instance = CapService._internal();
  factory CapService() => _instance;
  CapService._internal();

  // Cache dei dati: mappa CAP → primo risultato trovato
  Map<String, CapResult>? _cache;

  /// Carica il JSON se non è già stato caricato
  Future<void> _assicuraCaricato() async {
    if (_cache != null) return;

    final jsonString =
        await rootBundle.loadString('assets/data/cap_sardegna.json');
    final List<dynamic> lista = json.decode(jsonString) as List<dynamic>;

    final mappa = <String, CapResult>{};
    for (final entry in lista) {
      final map = entry as Map<String, dynamic>;
      final cap = map['cap'] as String;
      // Salva solo il primo comune trovato per ogni CAP
      mappa.putIfAbsent(
        cap,
        () => CapResult(
          citta: map['citta'] as String,
          provincia: map['provincia'] as String,
        ),
      );
    }
    _cache = mappa;
  }

  /// Cerca città e provincia dato un CAP.
  /// Restituisce [CapResult] se trovato, altrimenti null.
  Future<CapResult?> cercaPerCap(String cap) async {
    if (cap.length != 5) return null;
    await _assicuraCaricato();
    return _cache![cap];
  }
}
