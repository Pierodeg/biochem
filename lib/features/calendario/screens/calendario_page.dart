import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/service_providers.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../models/appuntamento_model.dart';

/// Pagina calendario con vista mese/settimana.
///
/// MOBILE (< 600px):
/// - Vista mensile con TableCalendar e pallini colorati
/// - Tap su giorno → lista eventi del giorno sotto il calendario
/// - Vista settimanale: lista per giorno con ora e tipo
/// - FAB "+" solo admin
///
/// DESKTOP (>= 600px):
/// - Griglia mensile full-width con eventi nelle celle
/// - Vista settimanale a colonne
/// - Pannello laterale 300px con dettaglio giorno
/// - Bottone "+ Nuovo" solo admin
class CalendarioPage extends ConsumerStatefulWidget {
  const CalendarioPage({super.key});

  @override
  ConsumerState<CalendarioPage> createState() => _CalendarioPageState();
}

class _CalendarioPageState extends ConsumerState<CalendarioPage> {
  // Vista corrente: mese o settimana
  bool _vistaSettimana = false;

  // Data selezionata nel calendario (tap su giorno)
  DateTime _giornoSelezionato = DateTime.now();

  // Mese attualmente visualizzato
  DateTime _meseCorrente = DateTime.now();

  final _formatter = DateFormat('dd/MM/yyyy', 'it');
  final _formatterGiorno = DateFormat('EEEE d MMMM', 'it');

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 600;
    final isAdmin =
        ref.watch(currentUserProvider).valueOrNull?.isAdmin ?? false;

    // Stream appuntamenti del mese corrente
    final appuntamentiAsync = ref.watch(
      _appuntamentiMeseProvider(_meseCorrente),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      // AppBar solo su mobile (desktop usa header della shell)
      appBar: isDesktop
          ? null
          : AppBar(
              title: const Text('Calendario'),
              actions: [
                // Switch vista mese/settimana
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Sett.',
                          style: TextStyle(
                              color: AppColors.appBarForeground, fontSize: 12)),
                      Switch(
                        value: !_vistaSettimana,
                        onChanged: (v) =>
                            setState(() => _vistaSettimana = !v),
                        activeThumbColor: AppColors.primaryBright,
                        inactiveThumbColor: AppColors.primaryBright,
                      ),
                      const Text('Mese',
                          style: TextStyle(
                              color: AppColors.appBarForeground, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 600) {
            return _buildDesktopLayout(appuntamentiAsync, isAdmin);
          }
          return _buildMobileLayout(appuntamentiAsync, isAdmin);
        },
      ),
      // FAB solo admin su mobile
      floatingActionButton:
          !isDesktop && isAdmin
              ? FloatingActionButton(
                  backgroundColor: AppColors.fabBackground,
                  foregroundColor: AppColors.fabIcon,
                  onPressed: () => context.push('/calendario/nuovo'),
                  child: const Icon(Icons.add),
                )
              : null,
    );
  }

  // ─── LAYOUT MOBILE ────────────────────────────────────────────────────────

  Widget _buildMobileLayout(
      AsyncValue<List<AppuntamentoModel>> appuntamentiAsync, bool isAdmin) {
    return appuntamentiAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(
          child: Text('Errore: $e',
              style: const TextStyle(color: AppColors.error))),
      data: (appuntamenti) {
        final eventiPerGiorno = _raggrupaPerGiorno(appuntamenti);
        return _vistaSettimana
            ? _buildVistaSettimana(eventiPerGiorno, false)
            : _buildVistaMeseMobile(appuntamenti, eventiPerGiorno);
      },
    );
  }

  Widget _buildVistaMeseMobile(List<AppuntamentoModel> appuntamenti,
      Map<DateTime, List<AppuntamentoModel>> eventiPerGiorno) {
    final eventiGiornoSel =
        eventiPerGiorno[_normalizzaData(_giornoSelezionato)] ?? [];
    return Column(
      children: [
        // Calendario mensile
        TableCalendar<AppuntamentoModel>(
          locale: 'it_IT',
          firstDay: DateTime(2020),
          lastDay: DateTime(2035),
          focusedDay: _meseCorrente,
          selectedDayPredicate: (day) =>
              isSameDay(_giornoSelezionato, day),
          calendarFormat: CalendarFormat.month,
          eventLoader: (day) =>
              eventiPerGiorno[_normalizzaData(day)] ?? [],
          onDaySelected: (selected, focused) {
            setState(() {
              _giornoSelezionato = selected;
              _meseCorrente = focused;
            });
          },
          onPageChanged: (focusedDay) {
            setState(() => _meseCorrente = focusedDay);
          },
          calendarStyle: const CalendarStyle(
            todayDecoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            todayTextStyle:
                TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
            selectedDecoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            selectedTextStyle:
                TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            markerDecoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          calendarBuilders: CalendarBuilders(
            // Pallini colorati per tipo evento
            markerBuilder: (context, day, events) {
              if (events.isEmpty) return const SizedBox.shrink();
              final colori = events
                  .map(_coloreEvento)
                  .map((c) => c.toARGB32())
                  .toSet()
                  .take(3)
                  .map(Color.new)
                  .toList();
              return Positioned(
                bottom: 1,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: colori.map((colore) {
                    return Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: colore,
                        shape: BoxShape.circle,
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ),
        ),
        const Divider(height: 1),
        // Lista eventi del giorno selezionato
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Text(
                _formatterGiorno.format(_giornoSelezionato),
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontSize: 14),
              ),
              const SizedBox(width: 8),
              if (eventiGiornoSel.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${eventiGiornoSel.length}',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: eventiGiornoSel.isEmpty
              ? const Center(
                  child: Text('Nessun appuntamento',
                      style: TextStyle(
                          color: AppColors.textDisabled, fontSize: 14)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: eventiGiornoSel.length,
                  itemBuilder: (context, i) =>
                      _buildEventoCard(eventiGiornoSel[i]),
                ),
        ),
      ],
    );
  }

  // ─── LAYOUT DESKTOP ───────────────────────────────────────────────────────

  Widget _buildDesktopLayout(
      AsyncValue<List<AppuntamentoModel>> appuntamentiAsync, bool isAdmin) {
    return Column(
      children: [
        // Header desktop
        Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.divider)),
          ),
          child: Row(
            children: [
              const Text(
                'Calendario',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(width: 24),
              // Switch vista mese/settimana
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('Mese')),
                  ButtonSegment(value: true, label: Text('Settimana')),
                ],
                selected: {_vistaSettimana},
                onSelectionChanged: (s) =>
                    setState(() => _vistaSettimana = s.first),
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: AppColors.primary,
                  selectedForegroundColor: Colors.white,
                ),
              ),
              const Spacer(),
              // Bottone Nuovo solo admin
              if (isAdmin)
                FilledButton.icon(
                  onPressed: () => context.push('/calendario/nuovo'),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nuovo'),
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary),
                ),
            ],
          ),
        ),
        Expanded(
          child: appuntamentiAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary)),
            error: (e, _) => Center(
                child: Text('Errore: $e',
                    style: const TextStyle(color: AppColors.error))),
            data: (appuntamenti) {
              final eventiPerGiorno = _raggrupaPerGiorno(appuntamenti);
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Parte principale (calendario)
                  Expanded(
                    child: _vistaSettimana
                        ? _buildVistaSettimana(eventiPerGiorno, true)
                        : _buildVistaMeseDesktop(appuntamenti, eventiPerGiorno),
                  ),
                  // Pannello laterale dettaglio giorno
                  _buildPannelloLaterale(eventiPerGiorno),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVistaMeseDesktop(List<AppuntamentoModel> appuntamenti,
      Map<DateTime, List<AppuntamentoModel>> eventiPerGiorno) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: TableCalendar<AppuntamentoModel>(
        locale: 'it_IT',
        firstDay: DateTime(2020),
        lastDay: DateTime(2035),
        focusedDay: _meseCorrente,
        selectedDayPredicate: (day) => isSameDay(_giornoSelezionato, day),
        calendarFormat: CalendarFormat.month,
        eventLoader: (day) => eventiPerGiorno[_normalizzaData(day)] ?? [],
        onDaySelected: (selected, focused) {
          setState(() {
            _giornoSelezionato = selected;
            _meseCorrente = focused;
          });
        },
        onPageChanged: (focusedDay) {
          setState(() => _meseCorrente = focusedDay);
        },
        calendarStyle: const CalendarStyle(
          todayDecoration: BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          todayTextStyle:
              TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
          selectedDecoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          selectedTextStyle:
              TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        calendarBuilders: CalendarBuilders(
          // Celle desktop con badge numerico eventi
          markerBuilder: (context, day, events) {
            if (events.isEmpty) return const SizedBox.shrink();
            final colori = events
                .map(_coloreEvento)
                .map((c) => c.toARGB32())
                .toSet()
                .take(3)
                .map(Color.new)
                .toList();
            final colorePrincipale = _coloreEvento(events.first);
            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colorePrincipale.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: colorePrincipale.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    '${events.length} eventi',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: colorePrincipale,
                    ),
                  ),
                ),
                if (colori.length > 1)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: colori
                        .map(
                          (colore) => Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: colore,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                        .toList(),
                  ),
              ],
            );
          },
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
        ),
        rowHeight: 100,
      ),
    );
  }

  /// Vista settimanale: lista appuntamenti raggruppati per giorno
  Widget _buildVistaSettimana(
      Map<DateTime, List<AppuntamentoModel>> eventiPerGiorno, bool isDesktop) {
    // Calcola l'inizio della settimana del giorno selezionato (lunedì)
    final lunedi = _inizioSettimana(_giornoSelezionato);
    final giorni =
        List.generate(7, (i) => lunedi.add(Duration(days: i)));

    return Column(
      children: [
        // Header navigazione settimana
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() => _giornoSelezionato =
                    _giornoSelezionato.subtract(const Duration(days: 7))),
              ),
              Expanded(
                child: Text(
                  '${_formatter.format(lunedi)} — ${_formatter.format(lunedi.add(const Duration(days: 6)))}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setState(() => _giornoSelezionato =
                    _giornoSelezionato.add(const Duration(days: 7))),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: giorni.length,
            itemBuilder: (context, i) {
              final giorno = giorni[i];
              final eventi = eventiPerGiorno[_normalizzaData(giorno)] ?? [];
              return _buildGiornoSettimana(giorno, eventi);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGiornoSettimana(
      DateTime giorno, List<AppuntamentoModel> eventi) {
    final isOggi = isSameDay(giorno, DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isOggi ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  DateFormat('EEEE d', 'it').format(giorno),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isOggi ? Colors.white : AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (eventi.isEmpty)
          const Padding(
            padding: EdgeInsets.only(left: 16, bottom: 8),
            child: Text('Nessun appuntamento',
                style: TextStyle(
                    color: AppColors.textDisabled, fontSize: 12, fontStyle: FontStyle.italic)),
          )
        else
          ...eventi.map((e) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                child: _buildEventoCard(e),
              )),
        const Divider(height: 1),
      ],
    );
  }

  /// Pannello laterale desktop con dettaglio del giorno selezionato
  Widget _buildPannelloLaterale(
      Map<DateTime, List<AppuntamentoModel>> eventiPerGiorno) {
    final eventi = eventiPerGiorno[_normalizzaData(_giornoSelezionato)] ?? [];
    return Container(
      width: 300,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(left: BorderSide(color: AppColors.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _formatterGiorno.format(_giornoSelezionato),
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontSize: 14),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: eventi.isEmpty
                ? const Center(
                    child: Text('Nessun appuntamento',
                        style: TextStyle(
                            color: AppColors.textDisabled, fontSize: 13)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: eventi.length,
                    itemBuilder: (context, i) => _buildEventoCard(eventi[i]),
                  ),
          ),
        ],
      ),
    );
  }

  /// Card singolo appuntamento (usata sia in mobile che desktop)
  Widget _buildEventoCard(AppuntamentoModel app) {
    final colore = _coloreEvento(app);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => context.push('/calendario/${app.id}'),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: app.completato
              ? AppColors.inputBackground
              : colore.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(color: colore, width: 3),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app.titolo,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: app.completato
                          ? AppColors.textDisabled
                          : AppColors.textPrimary,
                      decoration: app.completato
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: colore.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          AppuntamentoModel.labelTipo(app.tipo),
                          style: TextStyle(
                              fontSize: 10,
                              color: colore,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('HH:mm').format(app.dataInizio),
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary),
                      ),
                      if (app.tecnico != null && app.tecnico!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.person_outline,
                            size: 11, color: AppColors.textDisabled),
                        const SizedBox(width: 2),
                        Text(
                          app.tecnico!,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (app.notificaAbilitata)
              const Icon(Icons.notifications_outlined,
                  size: 14, color: AppColors.textDisabled),
          ],
        ),
      ),
    );
  }

  // ─── Utility ──────────────────────────────────────────────────────────────

  /// Raggruppa gli appuntamenti per data (senza orario)
  Map<DateTime, List<AppuntamentoModel>> _raggrupaPerGiorno(
      List<AppuntamentoModel> appuntamenti) {
    final mappa = <DateTime, List<AppuntamentoModel>>{};
    for (final app in appuntamenti) {
      final chiave = _normalizzaData(app.dataInizio);
      mappa.putIfAbsent(chiave, () => []).add(app);
    }
    return mappa;
  }

  /// Normalizza una data rimuovendo ore/minuti/secondi (per uso come chiave mappa)
  DateTime _normalizzaData(DateTime data) =>
      DateTime(data.year, data.month, data.day);

  /// Calcola il lunedì della settimana della data fornita
  DateTime _inizioSettimana(DateTime data) {
    return data.subtract(Duration(days: data.weekday - 1));
  }

  /// Restituisce il Color Flutter per un tipo di appuntamento
  Color _colorePerTipo(String tipo) {
    switch (tipo) {
      case 'reg_lab':
        return const Color(0xFF1565C0);
      case 'pest':
        return const Color(0xFF00A843);
      case 'lettura_piastre':
        return const Color(0xFFE65100);
      case 'richiamo':
        return const Color(0xFFBA7517);
      case 'generico':
      default:
        return const Color(0xFF5F5E5A);
    }
  }

  Color _coloreEvento(AppuntamentoModel app) {
    final hex = app.colore.trim();
    if (RegExp(r'^#?[0-9A-Fa-f]{6}$').hasMatch(hex)) {
      final normalizzato = hex.startsWith('#') ? hex.substring(1) : hex;
      return Color(int.parse('FF$normalizzato', radix: 16));
    }
    return _colorePerTipo(app.tipo);
  }
}

// ─── Provider locale per gli appuntamenti del mese ────────────────────────────

/// Provider che fornisce lo stream degli appuntamenti per un dato mese.
/// Usa .family per ricevere il DateTime del mese come parametro.
final _appuntamentiMeseProvider = StreamProvider.family<
    List<AppuntamentoModel>, DateTime>((ref, meseCorrente) {
  final service = ref.watch(appuntamentiServiceProvider);
  return service.getAppuntamentiMese(meseCorrente.year, meseCorrente.month);
});
