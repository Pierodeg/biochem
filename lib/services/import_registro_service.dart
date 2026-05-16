import 'dart:typed_data';
import '../models/registro_parametro_model.dart';

class ImportRegistroResult {
  final String nomePreset;
  final List<RegistroCategoriaModel> categorie;
  final List<String> errori;

  const ImportRegistroResult({
    required this.nomePreset,
    required this.categorie,
    this.errori = const [],
  });
}

class ImportRegistroService {
  ImportRegistroResult parsaCSV(Uint8List bytes) {
    final testo = String.fromCharCodes(bytes).replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final righe = testo.split('\n');

    if (righe.isEmpty) {
      return const ImportRegistroResult(
        nomePreset: '', categorie: [], errori: ['File vuoto'],
      );
    }

    final nomePreset = righe[0].trim();
    final categorie = <RegistroCategoriaModel>[];
    final errori = <String>[];

    String? categoriaCorrente;
    List<RegistroParametroModel> parametriCorrente = [];
    bool prossimaRigaIntestazione = false;
    int rigaIndex = 0;

    for (int i = 1; i < righe.length; i++) {
      final riga = righe[i].trim();
      if (riga.isEmpty) continue;

      if (riga.startsWith('##')) {
        if (categoriaCorrente != null) {
          categorie.add(RegistroCategoriaModel(
            id: rigaIndex.toString(),
            nome: categoriaCorrente,
            parametri: List.from(parametriCorrente),
          ));
          rigaIndex++;
        }
        categoriaCorrente = riga.replaceFirst('##', '').trim();
        parametriCorrente = [];
        prossimaRigaIntestazione = true;
        continue;
      }

      if (prossimaRigaIntestazione) {
        prossimaRigaIntestazione = false;
        continue;
      }

      if (categoriaCorrente == null) {
        errori.add('Riga ${i + 1}: fuori da categoria — ignorata');
        continue;
      }

      final cols = riga.split(',');
      final parametro = cols.isNotEmpty ? cols[0].trim() : '';
      if (parametro.isEmpty) continue;

      parametriCorrente.add(RegistroParametroModel(
        id: '${rigaIndex}_${parametriCorrente.length}',
        parametro: parametro,
        um: cols.length > 1 ? cols[1].trim() : '',
        vl: cols.length > 2 ? cols[2].trim() : '',
        loq: cols.length > 3 ? cols[3].trim() : '',
        i: cols.length > 4 ? cols[4].trim() : '',
        metodoRif: cols.length > 5 ? cols[5].trim() : '',
        categoria: categoriaCorrente,
        ordine: parametriCorrente.length,
      ));
    }

    if (categoriaCorrente != null) {
      categorie.add(RegistroCategoriaModel(
        id: rigaIndex.toString(),
        nome: categoriaCorrente,
        parametri: List.from(parametriCorrente),
      ));
    }

    return ImportRegistroResult(
      nomePreset: nomePreset,
      categorie: categorie,
      errori: errori,
    );
  }
}