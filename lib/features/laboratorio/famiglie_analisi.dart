import 'package:flutter/material.dart';

/// Una colonna di risultato di una famiglia di analisi.
class ColonnaAnalisi {
  /// Chiave stabile salvata su Firestore (slug).
  final String key;

  /// Etichetta mostrata a video / attesa nell'intestazione CSV.
  final String label;

  const ColonnaAnalisi(this.key, this.label);
}

/// Descrittore di una famiglia di analisi (Cationi, Primarie, Anioni, Microbio).
///
/// Fonte unica che guida la sezione generica dei risultati
/// (`RisultatiPage`): stessa lista, stesso form, stesso import CSV,
/// cambiano solo `collection` e `colonne`. (Regola DRY, vedi CLAUDE.md.)
class FamigliaAnalisi {
  final String id;
  final String titolo;
  final IconData icona;

  /// Collection Firestore dei risultati (es. `risultati_cationi`).
  final String collection;

  /// Colonne di valore misurato (le prime 4-5 colonne "campione" — cert numb,
  /// cod A, committente — sono comuni e gestite dal model/form, non qui).
  final List<ColonnaAnalisi> colonne;

  const FamigliaAnalisi({
    required this.id,
    required this.titolo,
    required this.icona,
    required this.collection,
    required this.colonne,
  });

  // ── Cationi metalli (task 5) ────────────────────────────────────────────────
  static const cationi = FamigliaAnalisi(
    id: 'cationi',
    titolo: 'Cationi Metalli',
    icona: Icons.science_outlined,
    collection: 'risultati_cationi',
    colonne: [
      ColonnaAnalisi('sodio', 'Sodio'),
      ColonnaAnalisi('magnesio', 'Magnesio'),
      ColonnaAnalisi('alluminio', 'Alluminio'),
      ColonnaAnalisi('potassio', 'Potassio'),
      ColonnaAnalisi('calcio', 'Calcio'),
      ColonnaAnalisi('cromo_tot', 'Cromo tot'),
      ColonnaAnalisi('manganese', 'Manganese'),
      ColonnaAnalisi('ferro', 'Ferro'),
      ColonnaAnalisi('rame', 'Rame'),
      ColonnaAnalisi('piombo', 'Piombo'),
      ColonnaAnalisi('zinco', 'Zinco'),
      ColonnaAnalisi('durezza', 'Durezza'),
    ],
  );

  // ── Primarie / chimico-fisiche (task 6) ─────────────────────────────────────
  static const primarie = FamigliaAnalisi(
    id: 'primarie',
    titolo: 'Primarie',
    icona: Icons.opacity_outlined,
    collection: 'risultati_primarie',
    colonne: [
      ColonnaAnalisi('colore', 'Colore'),
      ColonnaAnalisi('odore', 'Odore'),
      ColonnaAnalisi('torbidita', 'Torbidità'),
      ColonnaAnalisi('sapore', 'Sapore'),
      ColonnaAnalisi('t_camp', 'T campione'),
      ColonnaAnalisi('t_amb', 'T ambiente'),
      ColonnaAnalisi('ph', 'pH'),
      ColonnaAnalisi('conducibilita', 'Conducibilità'),
      ColonnaAnalisi('nh4', 'NH4+'),
      ColonnaAnalisi('ossidabilita', 'Ossidabilità'),
    ],
  );

  // ── Anioni (task 7) ─────────────────────────────────────────────────────────
  static const anioni = FamigliaAnalisi(
    id: 'anioni',
    titolo: 'Anioni',
    icona: Icons.bubble_chart_outlined,
    collection: 'risultati_anioni',
    colonne: [
      ColonnaAnalisi('fluoruri', 'Fluoruri'),
      ColonnaAnalisi('cloruri', 'Cloruri'),
      ColonnaAnalisi('nitriti', 'Nitriti'),
      ColonnaAnalisi('bromuro', 'Bromuro'),
      ColonnaAnalisi('nitrato', 'Nitrato'),
      ColonnaAnalisi('fosfato', 'Fosfato'),
      ColonnaAnalisi('solfato', 'Solfato'),
      ColonnaAnalisi('cloriti', 'Cloriti'),
      ColonnaAnalisi('clorati', 'Clorati'),
    ],
  );

  // ── Microbiologia (task 9) ──────────────────────────────────────────────────
  static const microbio = FamigliaAnalisi(
    id: 'microbio',
    titolo: 'Microbiologia',
    icona: Icons.coronavirus_outlined,
    collection: 'risultati_microbio',
    colonne: [
      ColonnaAnalisi('mic_org_22', 'Mic. org. vit. 22° 68h'),
      ColonnaAnalisi('mic_org_36', 'Mic. org. 36° 44h'),
      ColonnaAnalisi('batt_coliformi', 'Batteri coliformi'),
      ColonnaAnalisi('ecoli', 'E. coli'),
      ColonnaAnalisi('clostridium', 'Clostridium perf.'),
      ColonnaAnalisi('enterococchi', 'Enterococchi'),
      ColonnaAnalisi('legionella', 'Legionella'),
    ],
  );
}
