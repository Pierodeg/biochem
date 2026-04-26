import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/service_providers.dart';
import '../../models/cliente_model.dart';

enum OrdinamentoAnagrafica {
  numeroCliente('↑ N° cliente'),
  nomeAZ('A→Z Nome'),
  cittaAZ('A→Z Città'),
  tipoAZ('A→Z Tipo committente');

  final String etichetta;
  const OrdinamentoAnagrafica(this.etichetta);
}

class FiltroAnagraficaStato {
  final List<String> tipiSelezionati;
  final List<String> cittaSelezionate;
  final List<String> provinceSelezionate;
  final OrdinamentoAnagrafica ordinamento;

  const FiltroAnagraficaStato({
    this.tipiSelezionati = const [],
    this.cittaSelezionate = const [],
    this.provinceSelezionate = const [],
    this.ordinamento = OrdinamentoAnagrafica.numeroCliente,
  });

  int get filtriAttivi =>
      tipiSelezionati.length +
      cittaSelezionate.length +
      provinceSelezionate.length +
      (ordinamento != OrdinamentoAnagrafica.numeroCliente ? 1 : 0);

  bool get hasFiltri => filtriAttivi > 0;

  FiltroAnagraficaStato copyWith({
    List<String>? tipiSelezionati,
    List<String>? cittaSelezionate,
    List<String>? provinceSelezionate,
    OrdinamentoAnagrafica? ordinamento,
  }) {
    return FiltroAnagraficaStato(
      tipiSelezionati: tipiSelezionati ?? this.tipiSelezionati,
      cittaSelezionate: cittaSelezionate ?? this.cittaSelezionate,
      provinceSelezionate: provinceSelezionate ?? this.provinceSelezionate,
      ordinamento: ordinamento ?? this.ordinamento,
    );
  }

  FiltroAnagraficaStato reset() => const FiltroAnagraficaStato();
}

const _provinceSarde = ['SS', 'CA', 'NU', 'OR', 'SU', 'OT', 'OG', 'VS'];

class FiltroAnagrafica extends ConsumerStatefulWidget {
  final FiltroAnagraficaStato statoFiltro;
  final List<ClienteModel> clienti;
  final ValueChanged<FiltroAnagraficaStato> onFiltroApplicato;
  final bool aperto;

  const FiltroAnagrafica({
    super.key,
    required this.statoFiltro,
    required this.clienti,
    required this.onFiltroApplicato,
    required this.aperto,
  });

  @override
  ConsumerState<FiltroAnagrafica> createState() => _FiltroAnagraficaState();
}

class _FiltroAnagraficaState extends ConsumerState<FiltroAnagrafica>
    with SingleTickerProviderStateMixin {
  AnimationController? _animController;
  Animation<double>? _animazione;

  late FiltroAnagraficaStato _bozza;
  bool _cittaEspanse = false;

  @override
  void initState() {
    super.initState();
    _bozza = widget.statoFiltro;
    _animController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _animazione = CurvedAnimation(
      parent: _animController!,
      curve: Curves.easeInOut,
    );
    if (widget.aperto) _animController!.value = 1.0;
  }

  @override
  void dispose() {
    _animController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(FiltroAnagrafica oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.statoFiltro != widget.statoFiltro) {
      _bozza = widget.statoFiltro;
    }
    // Anima apertura/chiusura
    if (widget.aperto != oldWidget.aperto) {
      if (widget.aperto) {
        _animController?.forward();
      } else {
        _animController?.reverse();
      }
    }
  }

  Future<List<String>> _getTipiCommittente() async {
    final service = ref.read(impostazioniServiceProvider);
    final items = await service.getItems('tipi_committente').first;
    return items;
  }

  List<String> get _cittaDisponibili {
    final citta = widget.clienti
        .map((c) => c.citta.trim())
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return citta;
  }

  void _toggleTipo(String tipo) {
    final lista = List<String>.from(_bozza.tipiSelezionati);
    lista.contains(tipo) ? lista.remove(tipo) : lista.add(tipo);
    setState(() => _bozza = _bozza.copyWith(tipiSelezionati: lista));
  }

  void _toggleCitta(String citta) {
    final lista = List<String>.from(_bozza.cittaSelezionate);
    lista.contains(citta) ? lista.remove(citta) : lista.add(citta);
    setState(() => _bozza = _bozza.copyWith(cittaSelezionate: lista));
  }

  void _toggleProvincia(String prov) {
    final lista = List<String>.from(_bozza.provinceSelezionate);
    lista.contains(prov) ? lista.remove(prov) : lista.add(prov);
    setState(() => _bozza = _bozza.copyWith(provinceSelezionate: lista));
  }

  void _azzera() {
    setState(() {
      _bozza = const FiltroAnagraficaStato();
      _cittaEspanse = false;
    });
    widget.onFiltroApplicato(const FiltroAnagraficaStato());
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
                color: AppColors.primary.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
          ),
          child: _buildContenuto(),
        ),
      ),
    );
  }

  Widget _buildContenuto() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSezioneTitolo('TIPO COMMITTENTE'),
          const SizedBox(height: 6),
          FutureBuilder<List<String>>(
            future: _getTipiCommittente(),
            builder: (context, snap) {
              final tipi = snap.data ?? [];
              return Wrap(
                spacing: 8,
                runSpacing: 4,
                children: tipi
                    .map((t) => _buildChip(
                          label: t,
                          selezionato: _bozza.tipiSelezionati.contains(t),
                          onTap: () => _toggleTipo(t),
                        ))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildSezioneTitolo('CITTÀ'),
          const SizedBox(height: 6),
          _buildChipCitta(),
          const SizedBox(height: 12),
          _buildSezioneTitolo('PROVINCIA'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _provinceSarde
                .map((p) => _buildChip(
                      label: p,
                      selezionato: _bozza.provinceSelezionate.contains(p),
                      onTap: () => _toggleProvincia(p),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          _buildSezioneTitolo('ORDINA PER'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: OrdinamentoAnagrafica.values
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
              TextButton.icon(
                onPressed: _azzera,
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('✕ Azzera tutto'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                ),
              ),
              const Spacer(),
              if (_bozza.filtriAttivi > 0)
                Text(
                  '${_bozza.filtriAttivi} ${_bozza.filtriAttivi == 1 ? 'filtro attivo' : 'filtri attivi'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textOnDarkSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: _applica,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.30),
                  foregroundColor: AppColors.accentGreenDark,
                  side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.50),
                    width: 0.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Applica'),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildChipCitta() {
    final tutte = _cittaDisponibili;
    final visibili =
        _cittaEspanse || tutte.length <= 6 ? tutte : tutte.take(6).toList();
    final rimanenti = tutte.length - 6;

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        ...visibili.map((c) => _buildChip(
              label: c,
              selezionato: _bozza.cittaSelezionate.contains(c),
              onTap: () => _toggleCitta(c),
            )),
        if (!_cittaEspanse && rimanenti > 0)
          GestureDetector(
            onTap: () => setState(() => _cittaEspanse = true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0x1AFFFFFF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0x33FFFFFF),
                  width: 0.5,
                ),
              ),
              child: Text(
                '+ altre $rimanenti',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textOnDark,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSezioneTitolo(String titolo) {
    return Text(
      titolo,
      style: const TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w500,
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
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color:
                selezionato ? AppColors.accentGreenDark : AppColors.textOnDark,
          ),
        ),
      ),
    );
  }
}

// ─── Riga chip filtri attivi ──────────────────────────────────────────────────

class FiltriAttiviRow extends StatelessWidget {
  final FiltroAnagraficaStato stato;
  final ValueChanged<FiltroAnagraficaStato> onRimosso;

  const FiltriAttiviRow({
    super.key,
    required this.stato,
    required this.onRimosso,
  });

  @override
  Widget build(BuildContext context) {
    if (!stato.hasFiltri) return const SizedBox.shrink();

    final chips = <_ChipAttivo>[];

    for (final tipo in stato.tipiSelezionati) {
      chips.add(_ChipAttivo(
        label: tipo,
        onRimovi: () => onRimosso(stato.copyWith(
            tipiSelezionati:
                stato.tipiSelezionati.where((t) => t != tipo).toList())),
      ));
    }
    for (final citta in stato.cittaSelezionate) {
      chips.add(_ChipAttivo(
        label: citta,
        onRimovi: () => onRimosso(stato.copyWith(
            cittaSelezionate:
                stato.cittaSelezionate.where((c) => c != citta).toList())),
      ));
    }
    for (final prov in stato.provinceSelezionate) {
      chips.add(_ChipAttivo(
        label: prov,
        onRimovi: () => onRimosso(stato.copyWith(
            provinceSelezionate:
                stato.provinceSelezionate.where((p) => p != prov).toList())),
      ));
    }
    if (stato.ordinamento != OrdinamentoAnagrafica.numeroCliente) {
      chips.add(_ChipAttivo(
        label: stato.ordinamento.etichetta,
        onRimovi: () => onRimosso(
            stato.copyWith(ordinamento: OrdinamentoAnagrafica.numeroCliente)),
      ));
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: Colors.transparent,
      child: Wrap(spacing: 6, runSpacing: 4, children: chips),
    );
  }
}

class _ChipAttivo extends StatelessWidget {
  final String label;
  final VoidCallback onRimovi;

  const _ChipAttivo({required this.label, required this.onRimovi});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.accentGreenDark,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: AppColors.primary.withValues(alpha: 0.20),
      side: BorderSide(
        color: AppColors.primary.withValues(alpha: 0.40),
        width: 0.5,
      ),
      deleteIcon:
          const Icon(Icons.close, size: 14, color: AppColors.accentGreenDark),
      onDeleted: onRimovi,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

// ─── Utility ──────────────────────────────────────────────────────────────────

List<ClienteModel> applicaFiltroAnagrafica(
    List<ClienteModel> clienti, FiltroAnagraficaStato filtro) {
  var risultato = clienti.where((c) {
    if (filtro.tipiSelezionati.isNotEmpty &&
        !filtro.tipiSelezionati.contains(c.tipoCommittente)) return false;
    if (filtro.cittaSelezionate.isNotEmpty &&
        !filtro.cittaSelezionate.contains(c.citta.trim())) return false;
    if (filtro.provinceSelezionate.isNotEmpty &&
        !filtro.provinceSelezionate.contains(c.provincia.trim().toUpperCase()))
      return false;
    return true;
  }).toList();

  switch (filtro.ordinamento) {
    case OrdinamentoAnagrafica.numeroCliente:
      risultato.sort((a, b) => a.numeroCliente.compareTo(b.numeroCliente));
    case OrdinamentoAnagrafica.nomeAZ:
      risultato.sort((a, b) =>
          a.committente.toLowerCase().compareTo(b.committente.toLowerCase()));
    case OrdinamentoAnagrafica.cittaAZ:
      risultato.sort(
          (a, b) => a.citta.toLowerCase().compareTo(b.citta.toLowerCase()));
    case OrdinamentoAnagrafica.tipoAZ:
      risultato.sort((a, b) => a.tipoCommittente
          .toLowerCase()
          .compareTo(b.tipoCommittente.toLowerCase()));
  }

  return risultato;
}
