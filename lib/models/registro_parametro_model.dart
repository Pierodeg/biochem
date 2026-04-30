import 'package:cloud_firestore/cloud_firestore.dart';

/// Singolo parametro analitico dentro un preset del Registro
class RegistroParametroModel {
  final String id;
  final String parametro;
  final String um;
  final String vl; // Valore limite
  final String loq; // Limite di quantificazione
  final String i;
  final String metodoRif;
  final String categoria; // es. 'chimico_fisici', 'microbiologici'
  final int ordine;

  const RegistroParametroModel({
    required this.id,
    required this.parametro,
    required this.um,
    required this.vl,
    required this.loq,
    required this.i, 
    required this.metodoRif,
    required this.categoria,
    required this.ordine,
  });

  factory RegistroParametroModel.fromMap(Map<String, dynamic> data, String id) {
    return RegistroParametroModel(
      id: id,
      parametro: data['parametro'] as String? ?? '',
      um: data['um'] as String? ?? '',
      vl: data['vl'] as String? ?? '',
      loq: data['loq'] as String? ?? '',
      i: data['i'] as String? ?? '',
      metodoRif: data['metodoRif'] as String? ?? '',
      categoria: data['categoria'] as String? ?? '',
      ordine: data['ordine'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'parametro': parametro,
    'um': um,
    'vl': vl,
    'loq': loq,
    'i': i,
    'metodoRif': metodoRif,
    'categoria': categoria,
    'ordine': ordine,
  };

  RegistroParametroModel copyWith({
    String? parametro,
    String? um,
    String? vl,
    String? loq,
    String? i, 
    String? metodoRif,
    String? categoria,
    int? ordine,
  }) {
    return RegistroParametroModel(
      id: id,
      parametro: parametro ?? this.parametro,
      um: um ?? this.um,
      vl: vl ?? this.vl,
      loq: loq ?? this.loq,
      i: i ?? this.i,
      metodoRif: metodoRif ?? this.metodoRif,
      categoria: categoria ?? this.categoria,
      ordine: ordine ?? this.ordine,
    );
  }
}

/// Categoria di parametri (es. "Chimico-fisici", "Microbiologici")
class RegistroCategoriaModel {
  final String id;
  final String nome;
  final List<RegistroParametroModel> parametri;

  const RegistroCategoriaModel({
    required this.id,
    required this.nome,
    required this.parametri,
  });

  factory RegistroCategoriaModel.fromMap(Map<String, dynamic> data, String id) {
    final parametriRaw =
        (data['parametri'] as List<dynamic>? ?? []);
    final parametri = parametriRaw
        .asMap()
        .entries
        .map((e) => RegistroParametroModel.fromMap(
            e.value as Map<String, dynamic>, e.key.toString()))
        .toList();
    return RegistroCategoriaModel(
      id: id,
      nome: data['nome'] as String? ?? '',
      parametri: parametri,
    );
  }

  Map<String, dynamic> toMap() => {
    'nome': nome,
    'parametri': parametri.map((p) => p.toMap()).toList(),
  };
}

/// Preset completo del Registro (es. "Registro Acque")
class RegistroPresetModel {
  final String id;
  final String nome;
  final String descrizione;
  final List<RegistroCategoriaModel> categorie;
  final DateTime createdAt;

  const RegistroPresetModel({
    required this.id,
    required this.nome,
    required this.descrizione,
    required this.categorie,
    required this.createdAt,
  });

  factory RegistroPresetModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final categorieRaw =
        (data['categorie'] as List<dynamic>? ?? []);
    final categorie = categorieRaw
        .asMap()
        .entries
        .map((e) => RegistroCategoriaModel.fromMap(
            e.value as Map<String, dynamic>, e.key.toString()))
        .toList();
    return RegistroPresetModel(
      id: doc.id,
      nome: data['nome'] as String? ?? '',
      descrizione: data['descrizione'] as String? ?? '',
      categorie: categorie,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'nome': nome,
    'descrizione': descrizione,
    'categorie': categorie.map((c) => c.toMap()).toList(),
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
