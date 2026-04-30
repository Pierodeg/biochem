import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/service_providers.dart';
import '../../models/servizio_lab_model.dart';

enum OrdinamentoRegLab {
  dataRecente('↓ Data recente'),
  dataMenoRecente('↑ Data meno recente'),
  certificazione('N° certificazione'),
  committenteAZ('Committente A→Z');

  final String etichetta;
  const OrdinamentoRegLab(this.etichetta);
}

class FiltroRegLabStato {
  final List<String> tipiAnalisiSelezionati;
  final List<String> statiFatturazione;
  final String? annoSelezionato;
  final String committenteQuery;
  final OrdinamentoRegLab ordinamento;

  const FiltroRegLabStato({
    this.tipiAnalisiSelezionati = const [],
    this.statiFatturazione = const [],
    this.annoSelezionato,
    this.committenteQuery = '',
    this.ordinamento = OrdinamentoRegLab.dataRecente,
  });

  int get filtriAttivi =>
      tipiAnalisiSelezionati.length +
      statiFatturazione.length +
      (annoSelezionato != null ? 1 : 0) +
      (committenteQuery.isNotEmpty ? 1 : 0) +
      (ordinamento != OrdinamentoRegLab.dataRecente ? 1 : 0);

  bool get hasFiltri => filtriAttivi > 0;

  FiltroRegLabStato copyWith({
    List<String>? tipiAnalisiSelezionati,
    List<String>? statiFatturazione,
    Object? annoSelezionato = _sentinel,
    String? committenteQuery,
    OrdinamentoRegLab? ordinamento,
  }) {
    return FiltroRegLabStato(
      tipiAnalisiSelezionati:
          tipiAnalisiSelezionati ?? this.tipiAnalisiSelezionati,
      statiFatturazione: statiFatturazione ?? this.statiFatturazione,
      annoSelezionato: annoSelezionato == _sentinel
          ? this.annoSelezionato
          : annoSelezionato as String?,
      committenteQuery: committenteQuery ?? this.committenteQuery,
      ordinamento: ordinamento ?? this.ordinamento,
    );
  }

  FiltroRegLabStato reset() => const FiltroRegLabStato();
}

const _sentinel = Object();

class FiltroRegLab extends ConsumerStatefulWidget {
  final FiltroRegLabStato statoFiltro;
  final List<ServizioLabModel> servizi;
  final ValueChanged<FiltroRegLabStato> onFiltroApplicato;
  final bool aperto;

  const FiltroRegLab({
    super.key,
    required this.statoFiltro,
    required this.servizi,
    required this.onFiltroApplicato,
    required this.aperto,
  });

  @override
  ConsumerState<FiltroRegLab> createState() => _FiltroRegLabState();
}

class _FiltroRegLabState extends ConsumerState<FiltroRegLab>
    with SingleTickerProviderStateMixin {
  late FiltroRegLabStato _bozza;
  final _committenteCtrl = TextEditingController();
  AnimationController? _animController;
  Animation<double>? _animazione;

  @override
  void initState() {
    super.initState();
    _bozza = widget.statoFiltro;
    _committenteCtrl.text = _bozza.committenteQuery;
    _animController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _animazione =
        CurvedAnimation(parent: _animController!, curve: Curves.easeInOut);
    if (widget.aperto) _animController!.value = 1.0;
  }

  @override
  void didUpdateWidget(FiltroRegLab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.aperto != oldWidget.aperto) {
      widget.aperto
          ? _animController?.forward()
          : _animController?.reverse();
    }
    if (oldWidget.statoFiltro != widget.statoFiltro) {
      _bozza = widget.statoFiltro;
      _committenteCtrl.text = _bozza.committenteQuery;
    }
  }

  @override
  void dispose() {
    _committenteCtrl.dispose();
    _animController?.dispose();
    super.dispose();
  }

  Future<List<String>> _getTipiAnalisi() async {
    final service = ref.read(impostazioniServiceProvider);
    return service.getItems('categorie_analisi').first;
  }

  List<String> get _anniDisponibili {
    final anni = widget.servizi
        .map((s) {
          final cert = s.certificazioneNumerica;
          return cert.length >= 2 ? cert.substring(0, 2) : '';
        })
        .where((a) => a.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    return anni;
  }

  void _toggleTipoAnalisi(String tipo) {
    final lista = List<String>.from(_bozza.tipiAnalisiSelezionati);
    lista.contains(tipo) ? lista.remove(tipo) : lista.add(tipo);
    setState(() => _bozza = _bozza.copyWith(tipiAnalisiSelezionati: lista));
  }

  void _toggleStatoFatturazione(String stato) {
    final lista = List<String>.from(_bozza.statiFatturazione);
    lista.contains(stato) ? lista.remove(stato) : lista.add(stato);
    setState(() => _bozza = _bozza.copyWith(statiFatturazione: lista));
  }

  void _azzera() {
    setState(() {
      _bozza = const FiltroRegLabStato();
      _committenteCtrl.clear();
    });
    widget.onFiltroApplicato(const FiltroRegLabStato());
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
          _buildTitolo('TIPO ANALISI'),
          const SizedBox(height: 6),
          FutureBuilder<List<String>>(
            future: _getTipiAnalisi(),
            builder: (context, snap) {
              final tipi = snap.data ?? [];
              return Wrap(
                spacing: 8,
                runSpacing: 4,
                children: tipi
                    .map((t) => _buildChip(
                          label: t,
                          selezionato:
                              _bozza.tipiAnalisiSelezionati.contains(t),
                          onTap: () => _toggleTipoAnalisi(t),
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
                label: 'FT emessa',
                selezionato: _bozza.statiFatturazione.contains('ft_emessa'),
                onTap: () => _toggleStatoFatturazione('ft_emessa'),
              ),
              _buildChip(
                label: 'FT non emessa',
                selezionato:
                    _bozza.statiFatturazione.contains('ft_non_emessa'),
                onTap: () => _toggleStatoFatturazione('ft_non_emessa'),
              ),
              _buildChip(
                label: 'Pagata',
                selezionato: _bozza.statiFatturazione.contains('pagata'),
                onTap: () => _toggleStatoFatturazione('pagata'),
              ),
              _buildChip(
                label: 'Non pagata',
                selezionato:
                    _bozza.statiFatturazione.contains('non_pagata'),
                onTap: () => _toggleStatoFatturazione('non_pagata'),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildTitolo('ANNO CERTIFICAZIONE'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _anniDisponibili
                .map((a) => _buildChip(
                      label: "'$a",
                      selezionato: _bozza.annoSelezionato == a,
                      onTap: () => setState(() => _bozza = _bozza.copyWith(
                          annoSelezionato:
                              _bozza.annoSelezionato == a ? null : a)),
                      monoSelezione: true,
                    ))
                .toList(),
          ),
          const SizedBox(height: 14),

          _buildTitolo('COMMITTENTE'),
          const SizedBox(height: 6),
          SizedBox(
            width: 280,
            child: TextField(
              controller: _committenteCtrl,
              style: const TextStyle(color: AppColors.textOnDark, fontSize: 13),
              onChanged: (v) => setState(
                  () => _bozza = _bozza.copyWith(committenteQuery: v.trim())),
              decoration: InputDecoration(
                hintText: 'Filtra per nome committente...',
                hintStyle:
                    const TextStyle(color: AppColors.textOnDarkMuted, fontSize: 13),
                filled: true,
                fillColor: const Color(0x1A000000),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      BorderSide(color: AppColors.glassBorder, width: 0.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      BorderSide(color: AppColors.glassBorder, width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      BorderSide(color: AppColors.primary, width: 1),
                ),
                suffixIcon: _bozza.committenteQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            size: 16, color: AppColors.textOnDarkMuted),
                        onPressed: () {
                          _committenteCtrl.clear();
                          setState(() =>
                              _bozza = _bozza.copyWith(committenteQuery: ''));
                        },
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 14),

          _buildTitolo('ORDINA PER'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: OrdinamentoRegLab.values
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

class FiltriAttiviRowRegLab extends StatelessWidget {
  final FiltroRegLabStato stato;
  final ValueChanged<FiltroRegLabStato> onRimosso;

  const FiltriAttiviRowRegLab({
    super.key,
    required this.stato,
    required this.onRimosso,
  });

  @override
  Widget build(BuildContext context) {
    if (!stato.hasFiltri) return const SizedBox.shrink();

    final chips = <Widget>[];

    for (final tipo in stato.tipiAnalisiSelezionati) {
      chips.add(_chipAttivo(
        tipo,
        () => onRimosso(stato.copyWith(
            tipiAnalisiSelezionati: stato.tipiAnalisiSelezionati
                .where((t) => t != tipo)
                .toList())),
      ));
    }
    for (final sf in stato.statiFatturazione) {
      chips.add(_chipAttivo(
        sf.replaceAll('_', ' '),
        () => onRimosso(stato.copyWith(
            statiFatturazione: stato.statiFatturazione
                .where((s) => s != sf)
                .toList())),
      ));
    }
    if (stato.annoSelezionato != null) {
      chips.add(_chipAttivo(
        "'${stato.annoSelezionato}",
        () => onRimosso(stato.copyWith(annoSelezionato: null)),
      ));
    }
    if (stato.committenteQuery.isNotEmpty) {
      chips.add(_chipAttivo(
        stato.committenteQuery,
        () => onRimosso(stato.copyWith(committenteQuery: '')),
      ));
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

// ─── Utility: applica filtro alla lista Reg Lab ───────────────────────────────

List<ServizioLabModel> applicaFiltroRegLab(
    List<ServizioLabModel> servizi, FiltroRegLabStato filtro) {
  var risultato = servizi.where((s) {
    if (filtro.tipiAnalisiSelezionati.isNotEmpty &&
        !filtro.tipiAnalisiSelezionati.contains(s.tipoAnalisi)) {
      return false;
    }
    if (filtro.statiFatturazione.isNotEmpty) {
      bool ok = false;
      for (final sf in filtro.statiFatturazione) {
        if (sf == 'ft_emessa' && s.ft) ok = true;
        if (sf == 'ft_non_emessa' && !s.ft) ok = true;
        if (sf == 'pagata' && s.fatturaPagata) ok = true;
        if (sf == 'non_pagata' && !s.fatturaPagata) ok = true;
      }
      if (!ok) return false;
    }
    if (filtro.annoSelezionato != null) {
      final annoDoc = s.certificazioneNumerica.length >= 2
          ? s.certificazioneNumerica.substring(0, 2)
          : '';
      if (annoDoc != filtro.annoSelezionato) return false;
    }
    if (filtro.committenteQuery.isNotEmpty &&
        !s.committente
            .toLowerCase()
            .contains(filtro.committenteQuery.toLowerCase())) {
      return false;
    }
    return true;
  }).toList();

  switch (filtro.ordinamento) {
    case OrdinamentoRegLab.dataRecente:
      risultato.sort((a, b) =>
          b.inizioProveGenerali.compareTo(a.inizioProveGenerali));
    case OrdinamentoRegLab.dataMenoRecente:
      risultato.sort((a, b) =>
          a.inizioProveGenerali.compareTo(b.inizioProveGenerali));
    case OrdinamentoRegLab.certificazione:
      risultato.sort((a, b) =>
          a.certificazioneNumerica.compareTo(b.certificazioneNumerica));
    case OrdinamentoRegLab.committenteAZ:
      risultato.sort((a, b) =>
          a.committente.toLowerCase().compareTo(b.committente.toLowerCase()));
  }

  return risultato;
}
