import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/service_providers.dart';
import '../../models/servizio_lab_model.dart';

/// Opzioni di ordinamento per la lista Reg Lab
enum OrdinamentoRegLab {
  dataRecente('↓ Data recente'),
  dataMenoRecente('↑ Data meno recente'),
  certificazione('N° certificazione'),
  committenteAZ('Committente A→Z');

  final String etichetta;
  const OrdinamentoRegLab(this.etichetta);
}

/// Stato immutabile del filtro Reg Lab
class FiltroRegLabStato {
  final List<String> tipiAnalisiSelezionati;
  final List<String> statiFatturazione; // 'ft_emessa','ft_non_emessa','pagata','non_pagata'
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

// Sentinel per distinguere null esplicito da "non fornito" in copyWith
const _sentinel = Object();

/// Widget filtro per la pagina Reg Lab.
///
/// Si apre/chiude con animazione verticale 300ms tra la search bar e la lista.
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

class _FiltroRegLabState extends ConsumerState<FiltroRegLab> {
  late FiltroRegLabStato _bozza;
  final _committenteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _bozza = widget.statoFiltro;
    _committenteCtrl.text = _bozza.committenteQuery;
  }

  @override
  void didUpdateWidget(FiltroRegLab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.statoFiltro != widget.statoFiltro) {
      _bozza = widget.statoFiltro;
      _committenteCtrl.text = _bozza.committenteQuery;
    }
  }

  @override
  void dispose() {
    _committenteCtrl.dispose();
    super.dispose();
  }

  // ─── Dati dinamici da Firestore ───────────────────────────────────────────

  Future<List<String>> _getTipiAnalisi() async {
    final service = ref.read(impostazioniServiceProvider);
    return service.getItems('categorie_analisi').first;
  }

  /// Anni distinti presenti nei documenti (primi 2 char di certificazioneNumerica)
  List<String> get _anniDisponibili {
    final anni = widget.servizi
        .map((s) {
          final cert = s.certificazioneNumerica;
          return cert.length >= 2 ? cert.substring(0, 2) : '';
        })
        .where((a) => a.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // più recenti prima
    return anni;
  }

  // ─── Toggle ───────────────────────────────────────────────────────────────

  void _toggleTipoAnalisi(String tipo) {
    final lista = List<String>.from(_bozza.tipiAnalisiSelezionati);
    lista.contains(tipo) ? lista.remove(tipo) : lista.add(tipo);
    setState(
        () => _bozza = _bozza.copyWith(tipiAnalisiSelezionati: lista));
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
          // Tipo analisi
          _buildTitolo('Tipo analisi'),
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
          const SizedBox(height: 12),

          // Stato fatturazione
          _buildTitolo('Stato fatturazione'),
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
          const SizedBox(height: 12),

          // Anno certificazione
          _buildTitolo('Anno certificazione'),
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
          const SizedBox(height: 12),

          // Committente (testo libero)
          _buildTitolo('Committente'),
          const SizedBox(height: 6),
          SizedBox(
            width: 280,
            child: TextField(
              controller: _committenteCtrl,
              onChanged: (v) => setState(
                  () => _bozza = _bozza.copyWith(committenteQuery: v.trim())),
              decoration: InputDecoration(
                hintText: 'Filtra per nome committente...',
                filled: true,
                fillColor: AppColors.inputBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                suffixIcon: _bozza.committenteQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _committenteCtrl.clear();
                          setState(() => _bozza =
                              _bozza.copyWith(committenteQuery: ''));
                        },
                      )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Ordina per
          _buildTitolo('Ordina per'),
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

/// Riga chip verdi per i filtri attivi Reg Lab
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

// ─── Utility: applica filtro alla lista Reg Lab ───────────────────────────────

/// Applica [filtro] a [servizi] e restituisce la lista ordinata.
List<ServizioLabModel> applicaFiltroRegLab(
    List<ServizioLabModel> servizi, FiltroRegLabStato filtro) {
  var risultato = servizi.where((s) {
    // Tipo analisi
    if (filtro.tipiAnalisiSelezionati.isNotEmpty &&
        !filtro.tipiAnalisiSelezionati.contains(s.tipoAnalisi)) {
      return false;
    }
    // Stato fatturazione
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
    // Anno certificazione
    if (filtro.annoSelezionato != null) {
      final annoDoc = s.certificazioneNumerica.length >= 2
          ? s.certificazioneNumerica.substring(0, 2)
          : '';
      if (annoDoc != filtro.annoSelezionato) return false;
    }
    // Committente
    if (filtro.committenteQuery.isNotEmpty &&
        !s.committente
            .toLowerCase()
            .contains(filtro.committenteQuery.toLowerCase())) {
      return false;
    }
    return true;
  }).toList();

  // Ordinamento
  switch (filtro.ordinamento) {
    case OrdinamentoRegLab.dataRecente:
      risultato.sort((a, b) =>
          b.inizioProveGenerali.compareTo(a.inizioProveGenerali));
    case OrdinamentoRegLab.dataMenoRecente:
      risultato.sort((a, b) =>
          a.inizioProveGenerali.compareTo(b.inizioProveGenerali));
    case OrdinamentoRegLab.certificazione:
      risultato.sort((a, b) => a.certificazioneNumerica
          .compareTo(b.certificazioneNumerica));
    case OrdinamentoRegLab.committenteAZ:
      risultato.sort((a, b) => a.committente
          .toLowerCase()
          .compareTo(b.committente.toLowerCase()));
  }

  return risultato;
}
