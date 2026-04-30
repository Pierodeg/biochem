import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/preventivo_model.dart';

// ─── Stato del filtro ─────────────────────────────────────────────────────────

class FiltroPreventiviStato {
  final bool? isDraft;
  final DateTimeRange? periodo;

  const FiltroPreventiviStato({this.isDraft, this.periodo});

  int get filtriAttivi =>
      [isDraft, periodo].where((f) => f != null).length;

  bool get hasFiltri => filtriAttivi > 0;

  FiltroPreventiviStato copyWith({
    bool? Function()? isDraft,
    DateTimeRange? Function()? periodo,
  }) =>
      FiltroPreventiviStato(
        isDraft: isDraft != null ? isDraft() : this.isDraft,
        periodo: periodo != null ? periodo() : this.periodo,
      );
}

// ─── Funzione di filtraggio ───────────────────────────────────────────────────

List<PreventivoModel> applicaFiltroPreventivi(
    List<PreventivoModel> lista, FiltroPreventiviStato filtro) {
  var risultato = lista;

  if (filtro.isDraft != null) {
    risultato =
        risultato.where((p) => p.isDraft == filtro.isDraft).toList();
  }
  if (filtro.periodo != null) {
    final start = filtro.periodo!.start;
    final end = DateTime(
      filtro.periodo!.end.year,
      filtro.periodo!.end.month,
      filtro.periodo!.end.day,
      23, 59, 59,
    );
    risultato = risultato
        .where((p) =>
            !p.data.isBefore(start) && !p.data.isAfter(end))
        .toList();
  }

  return risultato;
}

// ─── Pannello filtri ──────────────────────────────────────────────────────────

class FiltroPreventivi extends StatefulWidget {
  final bool aperto;
  final FiltroPreventiviStato statoFiltro;
  final void Function(FiltroPreventiviStato) onFiltroApplicato;

  const FiltroPreventivi({
    super.key,
    required this.aperto,
    required this.statoFiltro,
    required this.onFiltroApplicato,
  });

  @override
  State<FiltroPreventivi> createState() => _FiltroPreventiviState();
}

class _FiltroPreventiviState extends State<FiltroPreventivi>
    with SingleTickerProviderStateMixin {
  late FiltroPreventiviStato _bozza;
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
  void didUpdateWidget(FiltroPreventivi old) {
    super.didUpdateWidget(old);
    if (widget.aperto != old.aperto) {
      widget.aperto
          ? _animController?.forward()
          : _animController?.reverse();
    }
    if (!widget.aperto) _bozza = widget.statoFiltro;
  }

  @override
  void dispose() {
    _animController?.dispose();
    super.dispose();
  }

  Future<void> _selezionaPeriodo() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: _bozza.periodo ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          ),
      locale: const Locale('it'),
      helpText: 'Seleziona periodo',
      cancelText: 'Annulla',
      confirmText: 'Conferma',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: const Color(0xFF0A2A1A),
            onSurface: AppColors.textOnDark,
          ),
        ),
        child: child!,
      ),
    );
    if (range != null && mounted) {
      setState(() => _bozza = _bozza.copyWith(periodo: () => range));
    }
  }

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
    final hasPeriodo = _bozza.periodo != null;
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTitolo('STATO'),
          const SizedBox(height: 6),
          SizedBox(
            width: 200,
            child: DropdownButtonFormField<bool?>(
              initialValue: _bozza.isDraft,
              dropdownColor: const Color(0xFF0A2A1A),
              style: const TextStyle(color: AppColors.textOnDark, fontSize: 13),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0x1A000000),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                      color: AppColors.glassBorder, width: 0.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                      color: AppColors.glassBorder, width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      BorderSide(color: AppColors.primary, width: 1),
                ),
              ),
              items: const [
                DropdownMenuItem(
                    value: null,
                    child: Text('Tutti gli stati')),
                DropdownMenuItem(
                    value: true, child: Text('Solo bozze')),
                DropdownMenuItem(
                    value: false, child: Text('Solo confermati')),
              ],
              onChanged: (v) =>
                  setState(() => _bozza = _bozza.copyWith(isDraft: () => v)),
            ),
          ),
          const SizedBox(height: 14),
          _buildTitolo('PERIODO'),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: _selezionaPeriodo,
                icon: Icon(Icons.calendar_today_outlined,
                    size: 14,
                    color: hasPeriodo
                        ? AppColors.accentGreenDark
                        : AppColors.textOnDarkSecondary),
                label: Text(
                  hasPeriodo
                      ? '${fmt(_bozza.periodo!.start)} – ${fmt(_bozza.periodo!.end)}'
                      : 'Seleziona periodo',
                  style: TextStyle(
                    fontSize: 12,
                    color: hasPeriodo
                        ? AppColors.accentGreenDark
                        : AppColors.textOnDarkSecondary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: hasPeriodo
                      ? AppColors.accentGreenDark
                      : AppColors.textOnDarkSecondary,
                  side: BorderSide(
                    color: hasPeriodo
                        ? AppColors.primary.withValues(alpha: 0.50)
                        : AppColors.glassBorder,
                    width: 0.5,
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              if (hasPeriodo) ...[
                const SizedBox(width: 6),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(
                      () => _bozza = _bozza.copyWith(periodo: () => null)),
                  child: Icon(Icons.close,
                      size: 16,
                      color: AppColors.error.withValues(alpha: 0.80)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton(
                onPressed: () =>
                    setState(() => _bozza = const FiltroPreventiviStato()),
                style: FilledButton.styleFrom(
                  backgroundColor:
                      AppColors.error.withValues(alpha: 0.25),
                  foregroundColor: const Color(0xFFFF7070),
                  side: BorderSide(
                      color: AppColors.error.withValues(alpha: 0.40),
                      width: 0.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Azzera'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => widget.onFiltroApplicato(_bozza),
                style: FilledButton.styleFrom(
                  backgroundColor:
                      AppColors.primary.withValues(alpha: 0.30),
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
}

// ─── Riga chip filtri attivi ──────────────────────────────────────────────────

class FiltriAttiviRowPreventivi extends StatelessWidget {
  final FiltroPreventiviStato stato;
  final void Function(FiltroPreventiviStato) onRimosso;

  const FiltriAttiviRowPreventivi({
    super.key,
    required this.stato,
    required this.onRimosso,
  });

  @override
  Widget build(BuildContext context) {
    if (!stato.hasFiltri) return const SizedBox.shrink();

    final chips = <Widget>[];
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';

    if (stato.isDraft != null) {
      chips.add(_chip(
        label: stato.isDraft! ? 'Solo bozze' : 'Solo confermati',
        onDelete: () => onRimosso(stato.copyWith(isDraft: () => null)),
      ));
    }
    if (stato.periodo != null) {
      chips.add(_chip(
        label: '${fmt(stato.periodo!.start)} – ${fmt(stato.periodo!.end)}',
        onDelete: () => onRimosso(stato.copyWith(periodo: () => null)),
      ));
    }

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Wrap(spacing: 6, runSpacing: 4, children: chips),
    );
  }

  Widget _chip({required String label, required VoidCallback onDelete}) {
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
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
