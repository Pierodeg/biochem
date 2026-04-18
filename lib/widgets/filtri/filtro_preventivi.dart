import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/preventivo_model.dart';

// ─── Stato del filtro ─────────────────────────────────────────────────────────

/// Stato immutabile del filtro preventivi.
/// Supporta: stato bozza/confermato + intervallo di date.
class FiltroPreventiviStato {
  /// null = tutti; true = solo bozze; false = solo confermati
  final bool? isDraft;

  /// Intervallo date basato sul campo 'data' del preventivo
  final DateTimeRange? periodo;

  const FiltroPreventiviStato({this.isDraft, this.periodo});

  int get filtriAttivi =>
      [isDraft, periodo].where((f) => f != null).length;

  bool get hasFiltri => filtriAttivi > 0;

  /// Crea una copia modificando solo i campi specificati.
  /// Passare `() => null` per azzerare un campo nullable.
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

/// Applica lo stato filtro alla lista di preventivi (funzione pura)
List<PreventivoModel> applicaFiltroPreventivi(
    List<PreventivoModel> lista, FiltroPreventiviStato filtro) {
  var risultato = lista;

  if (filtro.isDraft != null) {
    risultato =
        risultato.where((p) => p.isDraft == filtro.isDraft).toList();
  }
  if (filtro.periodo != null) {
    final start = filtro.periodo!.start;
    // Fine giorno dell'ultima data inclusa
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

/// Pannello filtri espandibile per la pagina preventivi.
/// Si anima in altezza tramite [AnimatedCrossFade].
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

class _FiltroPreventiviState extends State<FiltroPreventivi> {
  late FiltroPreventiviStato _bozza;

  @override
  void initState() {
    super.initState();
    _bozza = widget.statoFiltro;
  }

  @override
  void didUpdateWidget(FiltroPreventivi old) {
    super.didUpdateWidget(old);
    // Reimposta la bozza locale quando il pannello viene chiuso
    if (!widget.aperto) _bozza = widget.statoFiltro;
  }

  /// Apre il date range picker per il periodo
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
    );
    if (range != null && mounted) {
      setState(() => _bozza = _bozza.copyWith(periodo: () => range));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      firstChild: const SizedBox(width: double.infinity, height: 0),
      secondChild: _buildContenuto(),
      crossFadeState:
          widget.aperto ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 200),
      sizeCurve: Curves.easeInOut,
    );
  }

  Widget _buildContenuto() {
    final hasPeriodo = _bozza.periodo != null;
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FILTRI',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textDisabled,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Filtro stato (tutti / bozze / confermati)
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<bool?>(
                  initialValue: _bozza.isDraft,
                  decoration: InputDecoration(
                    labelText: 'Stato',
                    filled: true,
                    fillColor: AppColors.inputBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: null, child: Text('Tutti gli stati')),
                    DropdownMenuItem(value: true, child: Text('Solo bozze')),
                    DropdownMenuItem(
                        value: false, child: Text('Solo confermati')),
                  ],
                  onChanged: (v) =>
                      setState(() => _bozza = _bozza.copyWith(isDraft: () => v)),
                ),
              ),

              // Filtro periodo con date picker
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    onPressed: _selezionaPeriodo,
                    icon: const Icon(Icons.calendar_today_outlined, size: 14),
                    label: Text(
                      hasPeriodo
                          ? '${fmt(_bozza.periodo!.start)} – ${fmt(_bozza.periodo!.end)}'
                          : 'Seleziona periodo',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: hasPeriodo
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      side: BorderSide(
                        color:
                            hasPeriodo ? AppColors.primary : AppColors.divider,
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                  if (hasPeriodo) ...[
                    const SizedBox(width: 4),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(
                          () => _bozza = _bozza.copyWith(periodo: () => null)),
                      child: const Icon(Icons.close,
                          size: 16, color: AppColors.error),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Bottoni azione
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () =>
                    setState(() => _bozza = const FiltroPreventiviStato()),
                child: const Text('Azzera'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => widget.onFiltroApplicato(_bozza),
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary),
                child: const Text('Applica'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Riga chip filtri attivi ──────────────────────────────────────────────────

/// Mostra i filtri attivi come chip removibili sotto la barra di ricerca.
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
        label:
            '${fmt(stato.periodo!.start)} – ${fmt(stato.periodo!.end)}',
        onDelete: () => onRimosso(stato.copyWith(periodo: () => null)),
      ));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Wrap(spacing: 6, runSpacing: 4, children: chips),
    );
  }

  Widget _chip({required String label, required VoidCallback onDelete}) {
    return Chip(
      label: Text(label,
          style: const TextStyle(fontSize: 11, color: AppColors.primary)),
      backgroundColor: AppColors.primaryLight,
      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
      deleteIcon:
          const Icon(Icons.close, size: 14, color: AppColors.primary),
      onDeleted: onDelete,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
