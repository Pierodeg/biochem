import 'package:flutter/material.dart';

/// Gruppi in cui sono organizzate le sezioni nel menu laterale desktop.
enum GruppoSezione { principale, laboratorio, amministrazione }

extension GruppoSezioneLabel on GruppoSezione {
  String get label {
    switch (this) {
      case GruppoSezione.principale:
        return 'PRINCIPALE';
      case GruppoSezione.laboratorio:
        return 'LABORATORIO';
      case GruppoSezione.amministrazione:
        return 'AMMINISTRAZIONE';
    }
  }
}

/// Descrittore di una sezione dell'app.
///
/// Fonte unica usata dalla **Home** (griglia di card), dal **menu laterale
/// desktop** (raggruppato) e dalla **bottom-nav mobile**. Aggiungere/spostare
/// una sezione qui la aggiorna ovunque.
class SezioneApp {
  final String id;
  final String titolo;
  final String sottotitolo;
  final IconData icona;
  final String route;
  final GruppoSezione gruppo;

  /// Indice del branch nello `StatefulShellRoute` (in `app_router.dart`).
  /// `null` se la sezione è una route a sé (pushata), es. Registro/Configurazione.
  final int? branchIndex;

  /// Se true, la sezione compare nella bottom-nav mobile.
  final bool inBottomNav;

  /// Solo admin (per ora informativo: i permessi sono l'AREA Z).
  final bool soloAdmin;

  /// Sezione non ancora implementata → mostra placeholder "in costruzione".
  final bool inArrivo;

  const SezioneApp({
    required this.id,
    required this.titolo,
    required this.sottotitolo,
    required this.icona,
    required this.route,
    required this.gruppo,
    this.branchIndex,
    this.inBottomNav = false,
    this.soloAdmin = false,
    this.inArrivo = false,
  });
}

/// Elenco completo delle sezioni dell'app.
///
/// ⚠️ L'ordine e i `branchIndex` dei branch (0..N) devono coincidere con
/// l'ordine dei branch nello `StatefulShellRoute` di `app_router.dart`.
const List<SezioneApp> sezioniApp = [
  // ── Branch dello shell (0..11) ──────────────────────────────────────────────
  SezioneApp(
    id: 'home',
    titolo: 'Home',
    sottotitolo: 'Tutte le sezioni in un colpo d\'occhio',
    icona: Icons.home_outlined,
    route: '/home',
    gruppo: GruppoSezione.principale,
    branchIndex: 0,
    inBottomNav: true,
  ),
  SezioneApp(
    id: 'anagrafiche',
    titolo: 'Anagrafiche',
    sottotitolo: 'Clienti e indirizzi di servizio',
    icona: Icons.people_outline,
    route: '/anagrafiche',
    gruppo: GruppoSezione.principale,
    branchIndex: 1,
    inBottomNav: true,
  ),
  SezioneApp(
    id: 'preventivo',
    titolo: 'Preventivo',
    sottotitolo: 'Crea e gestisci i preventivi',
    icona: Icons.description_outlined,
    route: '/preventivo',
    gruppo: GruppoSezione.principale,
    branchIndex: 2,
    inBottomNav: true,
  ),
  SezioneApp(
    id: 'reg_lab',
    titolo: 'Reg Lab',
    sottotitolo: 'Registrazione campioni e certificati',
    icona: Icons.biotech_outlined,
    route: '/servizi-lab',
    gruppo: GruppoSezione.laboratorio,
    branchIndex: 3,
    inBottomNav: true,
  ),
  SezioneApp(
    id: 'servizi_pest',
    titolo: 'Servizi Pest',
    sottotitolo: 'Interventi di disinfestazione',
    icona: Icons.pest_control,
    route: '/servizi-pest',
    gruppo: GruppoSezione.principale,
    branchIndex: 4,
    inBottomNav: true,
  ),
  SezioneApp(
    id: 'fatture',
    titolo: 'Fatture',
    sottotitolo: 'Consulta le fatture',
    icona: Icons.receipt_long_outlined,
    route: '/fatture',
    gruppo: GruppoSezione.principale,
    branchIndex: 5,
  ),
  SezioneApp(
    id: 'calendario',
    titolo: 'Calendario',
    sottotitolo: 'Appuntamenti e scadenze',
    icona: Icons.calendar_month_outlined,
    route: '/calendario',
    gruppo: GruppoSezione.principale,
    branchIndex: 6,
  ),
  SezioneApp(
    id: 'cationi',
    titolo: 'Cationi Metalli',
    sottotitolo: 'Risultati analisi cationi e metalli',
    icona: Icons.science_outlined,
    route: '/cationi',
    gruppo: GruppoSezione.laboratorio,
    branchIndex: 7,
    inArrivo: true,
  ),
  SezioneApp(
    id: 'primarie',
    titolo: 'Primarie',
    sottotitolo: 'Risultati analisi chimico-fisiche',
    icona: Icons.opacity_outlined,
    route: '/primarie',
    gruppo: GruppoSezione.laboratorio,
    branchIndex: 8,
    inArrivo: true,
  ),
  SezioneApp(
    id: 'anioni',
    titolo: 'Anioni',
    sottotitolo: 'Risultati analisi anioni',
    icona: Icons.bubble_chart_outlined,
    route: '/anioni',
    gruppo: GruppoSezione.laboratorio,
    branchIndex: 9,
    inArrivo: true,
  ),
  SezioneApp(
    id: 'microbio',
    titolo: 'Microbiologia',
    sottotitolo: 'Risultati analisi microbiologiche',
    icona: Icons.coronavirus_outlined,
    route: '/microbio',
    gruppo: GruppoSezione.laboratorio,
    branchIndex: 10,
    inArrivo: true,
  ),
  SezioneApp(
    id: 'stampa_unione',
    titolo: 'Stampa unione',
    sottotitolo: 'Dati aggregati per certificato',
    icona: Icons.table_view_outlined,
    route: '/stampa-unione',
    gruppo: GruppoSezione.laboratorio,
    branchIndex: 11,
    inArrivo: true,
  ),

  // ── Route a sé (pushate, fuori dallo shell) ─────────────────────────────────
  SezioneApp(
    id: 'registro',
    titolo: 'Registro',
    sottotitolo: 'Template parametri per tipo campione',
    icona: Icons.menu_book_outlined,
    route: '/registro',
    gruppo: GruppoSezione.amministrazione,
    soloAdmin: true,
  ),
  SezioneApp(
    id: 'configurazione',
    titolo: 'Configurazione',
    sottotitolo: 'Liste e dati che popolano i form',
    icona: Icons.tune_outlined,
    route: '/admin/impostazioni',
    gruppo: GruppoSezione.amministrazione,
    soloAdmin: true,
  ),
];

/// Sezioni che compaiono nella bottom-nav mobile, in ordine.
List<SezioneApp> get sezioniBottomNav =>
    sezioniApp.where((s) => s.inBottomNav).toList();

/// Sezioni di un dato gruppo, per il menu laterale desktop.
List<SezioneApp> sezioniDelGruppo(GruppoSezione g) =>
    sezioniApp.where((s) => s.gruppo == g && s.id != 'home').toList();
