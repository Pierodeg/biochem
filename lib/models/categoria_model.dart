import 'package:cloud_firestore/cloud_firestore.dart';

// ─── ISTRUZIONI MIGRAZIONE FIRESTORE ──────────────────────────────────────────
//
// Per ogni documento esistente nella collection 'impostazioni',
// aggiorna i campi come indicato di seguito.
//
// 1. DOCUMENTI DA MIGRARE A LISTA SEMPLICE (hasSottocategorie: false)
//    Documenti: categorie_analisi, campioni_riferimento, prelevato_da,
//               modalita_prelievo, rif_normativa, categorie_preventivo,
//               categorie_lab, categorie_pest
//
//    Aggiungi/aggiorna i seguenti campi (mantieni 'items' esistente):
//    {
//      "nome": "<nome leggibile, es: 'Tipi analisi'>",
//      "hasSottocategorie": false
//    }
//
// 2. DOCUMENTO DA MIGRARE A LISTA CON SOTTOCATEGORIE (hasSottocategorie: true)
//    Documento: tipi_committente
//
//    Struttura da applicare (gli items esistenti vanno spostati in sottocategorie):
//    {
//      "nome": "Tipi committente",
//      "hasSottocategorie": true,        ← aggiungi
//      "sottocategorie": {               ← aggiungi (mappa)
//        "Privato": [],
//        "Azienda": [],
//        "Ente pubblico": []
//      }
//      // rimuovi 'items' se presente
//    }
//    NOTA: se vuoi mantenere tipi_committente come lista semplice,
//    usa hasSottocategorie: false e conserva il campo 'items'.
//
// 3. NUOVI DOCUMENTI (da creare se non esistono):
//    Per creare via Console Firebase: aggiungi il documento con questi campi:
//    {
//      "nome": "<nome categoria>",
//      "hasSottocategorie": false,
//      "items": []
//    }
//
/// Modello per una categoria di impostazioni
///
/// Struttura Firestore (collection 'impostazioni', documento con ID fisso):
///
/// Lista semplice (hasSottocategorie == false):
/// {
///   nome: "Tipi analisi",
///   hasSottocategorie: false,
///   items: ["Analisi acqua", "Analisi aria", ...]
/// }
///
/// Con sottocategorie (hasSottocategorie == true):
/// {
///   nome: "Tipi committente",
///   hasSottocategorie: true,
///   sottocategorie: {
///     "Privato": ["Persona fisica", "Condominio"],
///     "Azienda": ["S.r.l.", "S.p.A."]
///   }
/// }
class CategoriaModel {
  final String id;
  final String nome;
  final bool hasSottocategorie;

  /// Lista voci — usato se [hasSottocategorie] == false
  final List<String> items;

  /// Mappa sottocategoria → lista elementi — usato se [hasSottocategorie] == true
  final Map<String, List<String>> sottocategorie;

  const CategoriaModel({
    required this.id,
    required this.nome,
    required this.hasSottocategorie,
    required this.items,
    required this.sottocategorie,
  });

  /// Crea un [CategoriaModel] da un documento Firestore.
  /// Compatibile con i documenti nella vecchia struttura (solo campo 'items').
  factory CategoriaModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Retrocompatibilità: se 'nome' non esiste usa l'ID come nome leggibile
    final nome = data['nome'] as String? ??
        doc.id.replaceAll('_', ' ').split(' ').map((w) {
          if (w.isEmpty) return w;
          return w[0].toUpperCase() + w.substring(1);
        }).join(' ');

    final hasSottocategorie = data['hasSottocategorie'] as bool? ?? false;

    // Parsing items (lista semplice)
    final rawItems = data['items'] as List<dynamic>? ?? [];
    final items = rawItems.cast<String>();

    // Parsing sottocategorie (mappa annidiata)
    final rawSotto = data['sottocategorie'] as Map<String, dynamic>? ?? {};
    final sottocategorie = rawSotto.map((chiave, valore) {
      final lista = (valore as List<dynamic>?)?.cast<String>() ?? [];
      return MapEntry(chiave, lista);
    });

    return CategoriaModel(
      id: doc.id,
      nome: nome,
      hasSottocategorie: hasSottocategorie,
      items: items,
      sottocategorie: sottocategorie,
    );
  }

  /// Converte il modello in una mappa per Firestore
  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'hasSottocategorie': hasSottocategorie,
      'items': hasSottocategorie ? [] : items,
      'sottocategorie': hasSottocategorie ? sottocategorie : {},
    };
  }

  @override
  String toString() =>
      'CategoriaModel(id: $id, nome: $nome, hasSottocategorie: $hasSottocategorie)';
}
