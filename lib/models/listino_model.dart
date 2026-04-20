// Struttura Firestore: impostazioni/preventivo_listino
// {
//   tipologie: {
//     "A":  { nome: "Analisi Lab",       ordine: 0 },
//     "V":  { nome: "Tecnici Vari",      ordine: 1 },
//     "ND": { nome: "Non specificato",   ordine: 2 }
//   },
//   sottotipi: {
//     "A_DSF": { nome: "Disinfezione",            tipologiaId: "A",  ordine: 0,
//                servizi: [{ codiceUnivoco, descrizione, prezzoUnitario }] },
//     "A_Oli": { nome: "Olii/Matrici organiche",  tipologiaId: "A",  ordine: 1, servizi: [...] },
//     "A_V":   { nome: "Vari",                    tipologiaId: "A",  ordine: 2, servizi: [...] },
//     "A_ND":  { nome: "Non specificato",          tipologiaId: "A",  ordine: 3, servizi: [] },
//     "V_NSC": { nome: "Nolo sale/Corsi",          tipologiaId: "V",  ordine: 0, servizi: [...] },
//     "ND_ND": { nome: "Non specificato",          tipologiaId: "ND", ordine: 0, servizi: [...] }
//   }
// }

// ─── Servizio ─────────────────────────────────────────────────────────────────

/// Singola voce di servizio nel listino a cascata.
class ServizioListino {
  /// Codice univoco (es. "A_DSF6", "V_NSC21")
  final String codiceUnivoco;

  /// Descrizione estesa del servizio
  final String descrizione;

  /// Prezzo unitario in euro
  final double prezzoUnitario;

  const ServizioListino({
    required this.codiceUnivoco,
    required this.descrizione,
    required this.prezzoUnitario,
  });

  factory ServizioListino.fromMap(Map<String, dynamic> m) => ServizioListino(
        codiceUnivoco: m['codiceUnivoco'] as String? ?? '',
        descrizione: m['descrizione'] as String? ?? '',
        prezzoUnitario: (m['prezzoUnitario'] as num?)?.toDouble() ?? 0.0,
      );

  Map<String, dynamic> toMap() => {
        'codiceUnivoco': codiceUnivoco,
        'descrizione': descrizione,
        'prezzoUnitario': prezzoUnitario,
      };

  @override
  bool operator ==(Object other) =>
      other is ServizioListino && other.codiceUnivoco == codiceUnivoco;

  @override
  int get hashCode => codiceUnivoco.hashCode;
}

// ─── Sotto-tipo ───────────────────────────────────────────────────────────────

/// Sotto-tipo del listino (es. "A_DSF" — Disinfezione).
class SottotipoListino {
  /// ID univoco (es. "A_DSF")
  final String id;

  /// Etichetta leggibile (es. "Disinfezione")
  final String nome;

  /// ID della tipologia padre (es. "A")
  final String tipologiaId;

  /// Indice di ordinamento all'interno della tipologia
  final int ordine;

  /// Lista dei servizi contenuti
  final List<ServizioListino> servizi;

  const SottotipoListino({
    required this.id,
    required this.nome,
    this.tipologiaId = '',
    this.ordine = 0,
    required this.servizi,
  });

  factory SottotipoListino.fromMap(String id, Map<String, dynamic> m) {
    final rawServizi = m['servizi'] as List<dynamic>? ?? [];
    return SottotipoListino(
      id: id,
      nome: m['nome'] as String? ?? id,
      tipologiaId: m['tipologiaId'] as String? ?? '',
      ordine: (m['ordine'] as num?)?.toInt() ?? 0,
      servizi: rawServizi
          .whereType<Map<String, dynamic>>()
          .map(ServizioListino.fromMap)
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'nome': nome,
        'tipologiaId': tipologiaId,
        'ordine': ordine,
        'servizi': servizi.map((s) => s.toMap()).toList(),
      };
}

// ─── Tipologia ────────────────────────────────────────────────────────────────

/// Tipologia del listino (es. "A" — Analisi Lab).
class TipologiaListino {
  /// ID univoco (es. "A")
  final String id;

  /// Etichetta leggibile (es. "Analisi Lab")
  final String nome;

  /// Indice di ordinamento globale
  final int ordine;

  /// Prefisso display (usato per colorazione UI, di default uguale a id)
  final String prefisso;

  /// Sotto-tipi incorporati (popolati da getTipologie(), non salvati in Firestore)
  final List<SottotipoListino> sottotipi;

  const TipologiaListino({
    required this.id,
    required this.nome,
    this.ordine = 0,
    this.prefisso = '',
    this.sottotipi = const [],
  });

  /// Tutti i servizi di tutti i sotto-tipi
  List<ServizioListino> get tuttiServizi =>
      sottotipi.expand((st) => st.servizi).toList();

  factory TipologiaListino.fromMap(String id, Map<String, dynamic> m) =>
      TipologiaListino(
        id: id,
        nome: m['nome'] as String? ?? id,
        ordine: (m['ordine'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toMap() => {'nome': nome, 'ordine': ordine};
}

// ─── ListinoV2 ────────────────────────────────────────────────────────────────

/// Intero listino v2 letto da Firestore (snapshot in memoria).
class ListinoV2 {
  final Map<String, TipologiaListino> tipologie;
  final Map<String, SottotipoListino> sottotipi;

  const ListinoV2({
    required this.tipologie,
    required this.sottotipi,
  });

  /// Istanza vuota (usata come valore iniziale)
  static const vuoto = ListinoV2(tipologie: {}, sottotipi: {});

  bool get isEmpty => tipologie.isEmpty;

  /// Tipologie ordinate per [ordine]
  List<TipologiaListino> get tipologieOrdinate {
    final list = tipologie.values.toList()
      ..sort((a, b) => a.ordine.compareTo(b.ordine));
    return list;
  }

  /// Sotto-tipi di una tipologia, ordinati per [ordine]
  List<SottotipoListino> sottoTipiDi(String tipologiaId) {
    return sottotipi.values
        .where((s) => s.tipologiaId == tipologiaId)
        .toList()
      ..sort((a, b) => a.ordine.compareTo(b.ordine));
  }

  factory ListinoV2.fromFirestore(Map<String, dynamic> data) {
    final rawTipo = data['tipologie'] as Map<String, dynamic>? ?? {};
    final rawSotto = data['sottotipi'] as Map<String, dynamic>? ?? {};

    return ListinoV2(
      tipologie: rawTipo.map(
        (id, v) => MapEntry(
            id, TipologiaListino.fromMap(id, v as Map<String, dynamic>)),
      ),
      sottotipi: rawSotto.map(
        (id, v) => MapEntry(
            id, SottotipoListino.fromMap(id, v as Map<String, dynamic>)),
      ),
    );
  }
}
