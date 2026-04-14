import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/service_providers.dart';
import '../../models/servizio_pest_model.dart';

/// Opzioni di ordinamento per la lista Servizi Pest
enum OrdinamentoPest {
  dataRecente('↓ Data recente'),
  dataMenoRecente('↑ Data meno recente'),
  committenteAZ('Committente A→Z'),
  tipoIntervento('Tipo intervento'),
  tecnico('Tecnico');

  final String etichetta;
  const OrdinamentoPest(this.etichetta);
}

/// Stato immutabile del filtro Servizi Pest
class FiltroServiziPestStato {
  final List<String> tipiInterventoSelezionati;
  final List<String> tecniciSelezionati;
  final List<String> statiFatturazione; // 'fatturato','non_fatturato','pagato','non_pagato'
  final List<String> ulterioriInterventi; // 'da_fare','completati','nessuno'
  final OrdinamentoPest ordinamento;

  const FiltroServiziPestStato({
    this.tipiInterventoSelezionati = const [],
    this.tecniciSelezionati = const [],
    this.statiFatturazione = const [],
    this.ulterioriInterventi = const [],
    this.ordinamento = OrdinamentoPest.dataRecente,
  });

  int get filtriAttivi =>
      tipiInterventoSelezionati.length +
      tecniciSelezionati.length +
      statiFatturazione.length +
      ulterioriInterventi.length +
      (ordinamento != OrdinamentoPest.dataRecente ? 1 : 0);

  bool get hasFiltri => filtriAttivi > 0;

  FiltroServiziPestStato copyWith({
    List<String>? tipiInterventoSelezionati,
    List<String>? tecniciSelezionati,
    List<String>? statiFatturazione,
    List<String>? ulterioriInterventi,
    OrdinamentoPest? ordinamento,
  }) {
    return FiltroServiziPestStato(
      tipiInterventoSelezionati:
          tipiInterventoSelezionati ?? this.tipiInterventoSelezionati,
      tecniciSelezionati: tecniciSelezionati ?? this.tecniciSelezionati,
      statiFatturazione: statiFatturazione ?? this.statiFatturazione,
      ulterioriInterventi: ulterioriInterventi ?? this.ulterioriInterventi,
      ordinamento: ordinamento ?? this.ordinamento,
    );
  }

  FiltroServiziPestStato reset() => const FiltroServiziPestStato();
}

/// Widget filtro per la pagina Servizi Pest.
///
/// Si apre/chiude con animazione verticale 300ms.
class FiltroServiziPest extends ConsumerStatefulWidget {
  final FiltroServiziPestStato statoFiltro;
  final List<ServizioPestModel> servizi;
  final ValueChanged<FiltroServiziPestStato> onFiltroApplicato;
  final bool aperto;

  const FiltroServiziPest({
    super.key,
    required this.statoFiltro,
    required this.servizi,
    required this.onFiltroApplicato,
    required this.aperto,
  });

  @override
  ConsumerState<FiltroServiziPest> createState() =>
      _FiltroServiziPestState();
}

class _FiltroServiziPestState extends ConsumerState<FiltroServiziPest> {
  late FiltroServiziPestStato _bozza;

  @override
  void initState() {
    super.initState();
    _bozza = widget.statoFiltro;
  }

  @override
  void didUpdateWidget(FiltroServiziPest oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.statoFiltro != widget.statoFiltro) {
      _bozza = widget.statoFiltro;
    }
  }

  // ─── Dati dinamici ────────────────────────────────────────────────────────

  Future<List<String>> _getTipiIntervento() async {
    return ref
        .read(impostazioniServiceProvider)
        .getItems('pest_tipi_intervento')
        .first;
  }

  Future<List<String>> _getTecnici() async {
    return ref
        .read(impostazioniServiceProvider)
        .getItems('pest_tecnici')
        .first;
  }

  // ─── Toggle ───────────────────────────────────────────────────────────────

  void _toggle(
      List<String> lista, String valore, void Function(List<String>) update) {
    final nuova = List<String>.from(lista);
    nuova.contains(valore) ? nuova.remove(valore) : nuova.add(valore);
    setState(() => update(nuova));
  }

  void _azzera() {
    setState(() => _bozza = const FiltroServiziPestStato());
    widget.onFiltroApplicato(const FiltroServiziPestStato());
  }

  void _applica() => widget.onFiltroApplicato(_bozza);

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: widget.aperto ? null : 0,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      child: widget.aperto ? _buildContenuto() : const SizedBox.shrink(),
    );
  }

  Widget _buildContenuto() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tipo intervento
          _buildTitolo('Tipo intervento'),
          const SizedBox(height: 6),
          FutureBuilder<List<String>>(
            future: _getTipiIntervento(),
            builder: (context, snap) {
              final tipi = snap.data ?? [];
              return Wrap(
                spacing: 8,
                runSpacing: 4,
                children: tipi
                    .map((t) => _buildChip(
                          label: t,
                          selezionato: _bozza.tipiInterventoSelezionati
                              .contains(t),
                          onTap: () => _toggle(
                              _bozza.tipiInterventoSelezionati,
                              t,
                              (l) => _bozza = _bozza.copyWith(
                                  tipiInterventoSelezionati: l)),
                        ))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 12),

          // Tecnico
          _buildTitolo('Tecnico'),
          const SizedBox(height: 6),
          FutureBuilder<List<String>>(
            future: _getTecnici(),
            builder: (context, snap) {
              final tecnici = snap.data ?? [];
              return Wrap(
                spacing: 8,
                runSpacing: 4,
                children: tecnici
                    .map((t) => _buildChip(
                          label: t,
                          selezionato:
                              _bozza.tecniciSelezionati.contains(t),
                          onTap: () => _toggle(
                              _bozza.tecniciSelezionati,
                              t,
                              (l) => _bozza =
                                  _bozza.copyWith(tecniciSelezionati: l)),
                        ))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 12),

          // Stato fatturazione
          _buildTitolo('Stato fatturazione'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildChip(
                label: 'Fatturato',
                selezionato:
                    _bozza.statiFatturazione.contains('fatturato'),
                onTap: () => _toggle(
                    _bozza.statiFatturazione,
                    'fatturato',
                    (l) =>
                        _bozza = _bozza.copyWith(statiFatturazione: l)),
              ),
              _buildChip(
                label: 'Non fatturato',
                selezionato:
                    _bozza.statiFatturazione.contains('non_fatturato'),
                onTap: () => _toggle(
                    _bozza.statiFatturazione,
                    'non_fatturato',
                    (l) =>
                        _bozza = _bozza.copyWith(statiFatturazione: l)),
              ),
              _buildChip(
                label: 'Pagato',
                selezionato:
                    _bozza.statiFatturazione.contains('pagato'),
                onTap: () => _toggle(
                    _bozza.statiFatturazione,
                    'pagato',
                    (l) =>
                        _bozza = _bozza.copyWith(statiFatturazione: l)),
              ),
              _buildChip(
                label: 'Non pagato',
                selezionato:
                    _bozza.statiFatturazione.contains('non_pagato'),
                onTap: () => _toggle(
                    _bozza.statiFatturazione,
                    'non_pagato',
                    (l) =>
                        _bozza = _bozza.copyWith(statiFatturazione: l)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Ulteriori interventi
          _buildTitolo('Ulteriori interventi'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildChip(
                label: 'Da fare',
                selezionato:
                    _bozza.ulterioriInterventi.contains('da_fare'),
                onTap: () => _toggle(
                    _bozza.ulterioriInterventi,
                    'da_fare',
                    (l) => _bozza =
                        _bozza.copyWith(ulterioriInterventi: l)),
              ),
              _buildChip(
                label: 'Completati',
                selezionato:
                    _bozza.ulterioriInterventi.contains('completati'),
                onTap: () => _toggle(
                    _bozza.ulterioriInterventi,
                    'completati',
                    (l) => _bozza =
                        _bozza.copyWith(ulterioriInterventi: l)),
              ),
              _buildChip(
                label: 'Nessuno',
                selezionato:
                    _bozza.ulterioriInterventi.contains('nessuno'),
                onTap: () => _toggle(
                    _bozza.ulterioriInterventi,
                    'nessuno',
                    (l) => _bozza =
                        _bozza.copyWith(ulterioriInterventi: l)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Ordina per
          _buildTitolo('Ordina per'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: OrdinamentoPest.values
                .map((o) => _buildChip(
                      label: o.etichetta,
                      selezionato: _bozza.ordinamento == o,
                      onTap: () => setState(
                          () => _bozza = _bozza.copyWith(ordinamento: o)),
                      monoSelezione: true,
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),

          // Bottoni
          Row(
            children: [
              TextButton.icon(
                onPressed: _azzera,
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('✕ Azzera tutto'),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.error),
              ),
              const Spacer(),
              if (_bozza.filtriAttivi > 0)
                Text(
                  '${_bozza.filtriAttivi} ${_bozza.filtriAttivi == 1 ? 'filtro attivo' : 'filtri attivi'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: _applica,
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.success),
                child: const Text('Applica'),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildTitolo(String titolo) {
    return Text(
      titolo,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool selezionato,
    required VoidCallback onTap,
    bool monoSelezione = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selezionato ? AppColors.primary : AppColors.inputBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selezionato ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selezionato
                ? AppColors.textOnPrimary
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─── Riga chip filtri attivi ───────────────────────────────────────────────────

/// Riga chip verdi per i filtri attivi Servizi Pest
class FiltriAttiviRowPest extends StatelessWidget {
  final FiltroServiziPestStato stato;
  final ValueChanged<FiltroServiziPestStato> onRimosso;

  const FiltriAttiviRowPest({
    super.key,
    required this.stato,
    required this.onRimosso,
  });

  @override
  Widget build(BuildContext context) {
    if (!stato.hasFiltri) return const SizedBox.shrink();

    final chips = <Widget>[];

    for (final t in stato.tipiInterventoSelezionati) {
      chips.add(_chipAttivo(t, () => onRimosso(stato.copyWith(
          tipiInterventoSelezionati: stato.tipiInterventoSelezionati
              .where((x) => x != t)
              .toList()))));
    }
    for (final t in stato.tecniciSelezionati) {
      chips.add(_chipAttivo(t, () => onRimosso(stato.copyWith(
          tecniciSelezionati:
              stato.tecniciSelezionati.where((x) => x != t).toList()))));
    }
    for (final sf in stato.statiFatturazione) {
      chips.add(_chipAttivo(
          sf.replaceAll('_', ' '),
          () => onRimosso(stato.copyWith(
              statiFatturazione: stato.statiFatturazione
                  .where((x) => x != sf)
                  .toList()))));
    }
    for (final ui in stato.ulterioriInterventi) {
      chips.add(_chipAttivo(
          ui.replaceAll('_', ' '),
          () => onRimosso(stato.copyWith(
              ulterioriInterventi: stato.ulterioriInterventi
                  .where((x) => x != ui)
                  .toList()))));
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: AppColors.successLight,
      child: Wrap(spacing: 6, runSpacing: 4, children: chips),
    );
  }

  Widget _chipAttivo(String label, VoidCallback onDelete) {
    return Chip(
      label: Text(label,
          style: const TextStyle(
              fontSize: 12,
              color: AppColors.badgeGreenText,
              fontWeight: FontWeight.w500)),
      backgroundColor: AppColors.badgeGreenBackground,
      side: const BorderSide(color: AppColors.success),
      deleteIcon:
          const Icon(Icons.close, size: 14, color: AppColors.badgeGreenText),
      onDeleted: onDelete,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

// ─── Utility: applica filtro ──────────────────────────────────────────────────

/// Applica [filtro] a [servizi] e restituisce la lista ordinata.
List<ServizioPestModel> applicaFiltroServiziPest(
    List<ServizioPestModel> servizi, FiltroServiziPestStato filtro) {
  var risultato = servizi.where((s) {
    // Tipo intervento
    if (filtro.tipiInterventoSelezionati.isNotEmpty &&
        !filtro.tipiInterventoSelezionati.contains(s.tipoIntervento)) {
      return false;
    }
    // Tecnico
    if (filtro.tecniciSelezionati.isNotEmpty &&
        !filtro.tecniciSelezionati.contains(s.tecnico)) {
      return false;
    }
    // Stato fatturazione — almeno uno dei selezionati deve essere vero
    if (filtro.statiFatturazione.isNotEmpty) {
      bool ok = false;
      for (final sf in filtro.statiFatturazione) {
        if (sf == 'fatturato' && s.totaleDovuto > 0) ok = true;
        if (sf == 'non_fatturato' && s.totaleDovuto <= 0) ok = true;
        // 'pagato'/'non_pagato' non hanno campo diretto nel modello
        // (il modello Pest non ha ft/pagata come lab): skip per ora
      }
      if (!ok) return false;
    }
    // Ulteriori interventi
    if (filtro.ulterioriInterventi.isNotEmpty) {
      bool ok = false;
      final haUlteriori = s.ulterioriInterventi.isNotEmpty;
      for (final ui in filtro.ulterioriInterventi) {
        if (ui == 'da_fare' && haUlteriori) ok = true;
        if (ui == 'completati' && haUlteriori) ok = true;
        if (ui == 'nessuno' && !haUlteriori) ok = true;
      }
      if (!ok) return false;
    }
    return true;
  }).toList();

  // Ordinamento
  switch (filtro.ordinamento) {
    case OrdinamentoPest.dataRecente:
      risultato.sort((a, b) => b.codiceData.compareTo(a.codiceData));
    case OrdinamentoPest.dataMenoRecente:
      risultato.sort((a, b) => a.codiceData.compareTo(b.codiceData));
    case OrdinamentoPest.committenteAZ:
      risultato.sort((a, b) => a.committente
          .toLowerCase()
          .compareTo(b.committente.toLowerCase()));
    case OrdinamentoPest.tipoIntervento:
      risultato.sort((a, b) => a.tipoIntervento
          .toLowerCase()
          .compareTo(b.tipoIntervento.toLowerCase()));
    case OrdinamentoPest.tecnico:
      risultato.sort((a, b) =>
          a.tecnico.toLowerCase().compareTo(b.tecnico.toLowerCase()));
  }

  return risultato;
}
