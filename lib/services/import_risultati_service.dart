import 'dart:typed_data';
import '../features/laboratorio/famiglie_analisi.dart';
import '../models/risultato_analisi_model.dart';

class ImportRisultatiResult {
  final List<RisultatoAnalisi> righe;
  final List<String> errori;
  final List<String> colonneNonTrovate;

  const ImportRisultatiResult({
    this.righe = const [],
    this.errori = const [],
    this.colonneNonTrovate = const [],
  });
}

/// Parser CSV generico per i risultati delle analisi.
///
/// Mappa le colonne del CSV alle colonne della famiglia **per intestazione**
/// (confronto normalizzato, senza distinzione maiuscole/accenti/spazi).
///
/// ⚠️ Mapping **provvisorio**: va confermato quando il cliente fornisce un
/// CSV d'esempio reale per la sezione (vedi PIANO_GENERALE.md, punti aperti).
class ImportRisultatiService {
  ImportRisultatiResult parsaCSV(Uint8List bytes, FamigliaAnalisi famiglia) {
    final testo = String.fromCharCodes(bytes)
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');
    final righe = testo.split('\n').where((r) => r.trim().isNotEmpty).toList();

    if (righe.length < 2) {
      return const ImportRisultatiResult(errori: ['File vuoto o senza dati']);
    }

    final header = _splitRiga(righe.first);
    final headerNorm = header.map(_norm).toList();

    int trovaCol(List<String> candidati) {
      for (final c in candidati) {
        final cn = _norm(c);
        final i = headerNorm.indexWhere((h) => h == cn || h.contains(cn));
        if (i >= 0) return i;
      }
      return -1;
    }

    final iCert = trovaCol(['cert numb', 'certificato', 'certificazione']);
    final iCodA = trovaCol(['cod a', 'coda']);
    final iComm = trovaCol(['committente', 'cliente']);

    // Mappa colonna famiglia → indice colonna CSV.
    final mapCol = <ColonnaAnalisi, int>{};
    final nonTrovate = <String>[];
    for (final col in famiglia.colonne) {
      final cn = _norm(col.label);
      final i = headerNorm.indexWhere((h) => h == cn || h.contains(cn));
      if (i >= 0) {
        mapCol[col] = i;
      } else {
        nonTrovate.add(col.label);
      }
    }

    final risultati = <RisultatoAnalisi>[];
    final errori = <String>[];

    for (int r = 1; r < righe.length; r++) {
      final cols = _splitRiga(righe[r]);
      String at(int i) =>
          (i >= 0 && i < cols.length) ? cols[i].trim() : '';

      final certNumb = at(iCert);
      final codA = at(iCodA);
      final committente = at(iComm);

      // Salta righe totalmente vuote di identificazione.
      if (certNumb.isEmpty && codA.isEmpty && committente.isEmpty) continue;

      final valori = <String, String>{};
      for (final entry in mapCol.entries) {
        final v = at(entry.value);
        if (v.isNotEmpty) valori[entry.key.key] = v;
      }

      risultati.add(RisultatoAnalisi(
        id: '',
        certNumb: certNumb,
        codA: codA,
        committente: committente,
        valori: valori,
        createdAt: DateTime.now(),
      ));
    }

    if (risultati.isEmpty) {
      errori.add('Nessuna riga dati valida trovata');
    }

    return ImportRisultatiResult(
      righe: risultati,
      errori: errori,
      colonneNonTrovate: nonTrovate,
    );
  }

  List<String> _splitRiga(String riga) {
    // Supporta separatore ',' o ';' (Excel italiano esporta spesso ';').
    final sep = riga.contains(';') && !riga.contains(',') ? ';' : ',';
    return riga.split(sep);
  }

  String _norm(String s) {
    var t = s.toLowerCase().trim();
    const accents = {
      'à': 'a', 'á': 'a', 'è': 'e', 'é': 'e', 'ì': 'i', 'í': 'i',
      'ò': 'o', 'ó': 'o', 'ù': 'u', 'ú': 'u',
    };
    accents.forEach((k, v) => t = t.replaceAll(k, v));
    return t.replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}
