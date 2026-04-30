import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/service_providers.dart';
import '../../models/servizio_pest_model.dart';

enum OrdinamentoPest {
  dataRecente('↓ Data recente'),
  dataMenoRecente('↑ Data meno recente'),
  committenteAZ('Committente A→Z'),
  tipoIntervento('Tipo intervento'),
  tecnico('Tecnico');

  final String etichetta;
  const OrdinamentoPest(this.etichetta);
}

class FiltroServiziPestStato {
  final List<String> tipiInterventoSelezionati;
  final List<String> tecniciSelezionati;
  final List<String> statiFatturazione;
  final List<String> ulterioriInterventi;
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
  ConsumerState<FiltroServiziPest> createState() => _FiltroServiziPestState();
}

class _FiltroServiziPestState extends ConsumerState<FiltroServiziPest>
    with SingleTickerProviderStateMixin {
  late FiltroServiziPestStato _bozza;
  AnimationController? _animController;
  Animation<double>? _animazione;

  @override
  void initState() {
    super.initState();
    _bozza = widget.statoFiltro;
    _animController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _animazione =
        CurvedAnimation(parent: _animController!, curve: Curves.easeInOut);
    if (widget.aperto) _animController!.value = 1.0;
  }

  @override
  void didUpdateWidget(FiltroServiziPest oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.aperto != oldWidget.aperto) {
      widget.aperto
          ? _animController?.forward()
          : _animController?.reverse();
    }
    if (oldWidget.statoFiltro != widget.statoFiltro) {
      _bozza = widget.statoFiltro;
    }
  }

  @override
  void dispose() {
    _animController?.dispose();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    final anim = _animazione;
    if (anim == null) return const SizedBox.shrink();
    return SizeTransition(
      sizeFactor: anim,
      axisAlignment: -1.0,
      child: ClipRect(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border(
              bottom: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.5), width: 1),
            ),
          ),
          child: _buildContenuto(),
        ),
      ),
    );
  }

  Widget _buildContenuto() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTitolo('TIPO INTERVENTO'),
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
                          selezionato:
                              _bozza.tipiInterventoSelezionati.contains(t),
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
          const SizedBox(height: 14),

          _buildTitolo('TECNICO'),
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
                          selezionato: _bozza.tecniciSelezionati.contains(t),
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
          const SizedBox(height: 14),

          _buildTitolo('STATO FATTURAZIONE'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildChip(
                label: 'Fatturato',
                selezionato: _bozza.statiFatturazione.contains('fatturato'),
                onTap: () => _toggle(
                    _bozza.statiFatturazione,
                    'fatturato',
                    (l) => _bozza = _bozza.copyWith(statiFatturazione: l)),
              ),
              _buildChip(
                label: 'Non fatturato',
                selezionato:
                    _bozza.statiFatturazione.contains('non_fatturato'),
                onTap: () => _toggle(
                    _bozza.statiFatturazione,
                    'non_fatturato',
                    (l) => _bozza = _bozza.copyWith(statiFatturazione: l)),
              ),
              _buildChip(
                label: 'Pagato',
                selezionato: _bozza.statiFatturazione.contains('pagato'),
                onTap: () => _toggle(
                    _bozza.statiFatturazione,
                    'pagato',
                    (l) => _bozza = _bozza.copyWith(statiFatturazione: l)),
              ),
              _buildChip(
                label: 'Non pagato',
                selezionato: _bozza.statiFatturazione.contains('non_pagato'),
                onTap: () => _toggle(
                    _bozza.statiFatturazione,
                    'non_pagato',
                    (l) => _bozza = _bozza.copyWith(statiFatturazione: l)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildTitolo('ULTERIORI INTERVENTI'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildChip(
                label: 'Da fare',
                selezionato: _bozza.ulterioriInterventi.contains('da_fare'),
                onTap: () => _toggle(
                    _bozza.ulterioriInterventi,
                    'da_fare',
                    (l) => _bozza = _bozza.copyWith(ulterioriInterventi: l)),
              ),
              _buildChip(
                label: 'Completati',
                selezionato:
                    _bozza.ulterioriInterventi.contains('completati'),
                onTap: () => _toggle(
                    _bozza.ulterioriInterventi,
                    'completati',
                    (l) => _bozza = _bozza.copyWith(ulterioriInterventi: l)),
              ),
              _buildChip(
                label: 'Nessuno',
                selezionato: _bozza.ulterioriInterventi.contains('nessuno'),
                onTap: () => _toggle(
                    _bozza.ulterioriInterventi,
                    'nessuno',
                    (l) => _bozza = _bozza.copyWith(ulterioriInterventi: l)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildTitolo('ORDINA PER'),
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

          Row(
            children: [
              FilledButton(
                onPressed: _azzera,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error.withValues(alpha: 0.25),
                  foregroundColor: const Color(0xFFFF7070),
                  side: BorderSide(
                      color: AppColors.error.withValues(alpha: 0.40),
                      width: 0.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Azzera'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _applica,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.30),
                  foregroundColor: AppColors.accentGreenDark,
                  side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.50),
                      width: 0.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Applica'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTitolo(String titolo) {
    return Text(
      titolo,
      style: const TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w600,
        color: AppColors.textOnDarkMuted,
        letterSpacing: 0.05,
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
          color: selezionato
              ? AppColors.primary.withValues(alpha: 0.35)
              : const Color(0x1AFFFFFF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selezionato
                ? AppColors.primary.withValues(alpha: 0.60)
                : const Color(0x33FFFFFF),
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selezionato
                ? AppColors.accentGreenDark
                : AppColors.textOnDark,
          ),
        ),
      ),
    );
  }
}

// ─── Riga chip filtri attivi ───────────────────────────────────────────────────

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
      chips.add(_chipAttivo(
          t,
          () => onRimosso(stato.copyWith(
              tipiInterventoSelezionati: stato.tipiInterventoSelezionati
                  .where((x) => x != t)
                  .toList()))));
    }
    for (final t in stato.tecniciSelezionati) {
      chips.add(_chipAttivo(
          t,
          () => onRimosso(stato.copyWith(
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
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Wrap(spacing: 6, runSpacing: 4, children: chips),
    );
  }

  Widget _chipAttivo(String label, VoidCallback onDelete) {
    return Chip(
      label: Text(label,
          style: const TextStyle(
              fontSize: 11,
              color: AppColors.accentGreenDark,
              fontWeight: FontWeight.w500)),
      backgroundColor: AppColors.primary.withValues(alpha: 0.20),
      side: BorderSide(
          color: AppColors.primary.withValues(alpha: 0.40), width: 0.5),
      deleteIcon: const Icon(Icons.close,
          size: 14, color: AppColors.accentGreenDark),
      onDeleted: onDelete,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

// ─── Utility: applica filtro ──────────────────────────────────────────────────

List<ServizioPestModel> applicaFiltroServiziPest(
    List<ServizioPestModel> servizi, FiltroServiziPestStato filtro) {
  var risultato = servizi.where((s) {
    if (filtro.tipiInterventoSelezionati.isNotEmpty &&
        !filtro.tipiInterventoSelezionati.contains(s.tipoIntervento)) {
      return false;
    }
    if (filtro.tecniciSelezionati.isNotEmpty &&
        !filtro.tecniciSelezionati.contains(s.tecnico)) {
      return false;
    }
    if (filtro.statiFatturazione.isNotEmpty) {
      bool ok = false;
      for (final sf in filtro.statiFatturazione) {
        if (sf == 'fatturato' && s.totaleDovuto > 0) ok = true;
        if (sf == 'non_fatturato' && s.totaleDovuto <= 0) ok = true;
      }
      if (!ok) return false;
    }
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

  switch (filtro.ordinamento) {
    case OrdinamentoPest.dataRecente:
      risultato.sort((a, b) => b.codiceData.compareTo(a.codiceData));
    case OrdinamentoPest.dataMenoRecente:
      risultato.sort((a, b) => a.codiceData.compareTo(b.codiceData));
    case OrdinamentoPest.committenteAZ:
      risultato.sort((a, b) =>
          a.committente.toLowerCase().compareTo(b.committente.toLowerCase()));
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
