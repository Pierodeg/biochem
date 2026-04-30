import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/service_providers.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../models/appuntamento_model.dart';

class CalendarioPage extends ConsumerStatefulWidget {
  const CalendarioPage({super.key});

  @override
  ConsumerState<CalendarioPage> createState() => _CalendarioPageState();
}

class _CalendarioPageState extends ConsumerState<CalendarioPage> {
  bool _vistaSettimana = false;
  DateTime _giornoSelezionato = DateTime.now();
  DateTime _meseCorrente = DateTime.now();

  final _formatter = DateFormat('dd/MM/yyyy', 'it');
  final _formatterGiorno = DateFormat('EEEE d MMMM', 'it');

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 600;
    final isAdmin =
        ref.watch(currentUserProvider).valueOrNull?.isAdmin ?? false;
    final appuntamentiAsync =
        ref.watch(_appuntamentiMeseProvider(_meseCorrente));

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: AppColors.glassDarkest,
              title: const Text('Calendario',
                  style: TextStyle(color: AppColors.textOnDark)),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Sett.',
                          style: TextStyle(
                              color: AppColors.textOnDarkSecondary,
                              fontSize: 12)),
                      Switch(
                        value: !_vistaSettimana,
                        onChanged: (v) => setState(() => _vistaSettimana = !v),
                        activeColor: AppColors.accentGreenDark,
                        activeTrackColor:
                            AppColors.primary.withValues(alpha: 0.40),
                        inactiveThumbColor: AppColors.textOnDarkSecondary,
                        inactiveTrackColor: AppColors.glassBorder,
                      ),
                      const Text('Mese',
                          style: TextStyle(
                              color: AppColors.textOnDarkSecondary,
                              fontSize: 12)),
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
      floatingActionButton: !isDesktop && isAdmin
          ? FloatingActionButton(
              heroTag: 'fab_calendario',
              backgroundColor: AppColors.primary.withValues(alpha: 0.85),
              foregroundColor: Colors.white,
              onPressed: () => context.push('/calendario/nuovo'),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  // ─── MOBILE ───────────────────────────────────────────────────────────────

  Widget _buildMobileLayout(
      AsyncValue<List<AppuntamentoModel>> appuntamentiAsync, bool isAdmin) {
    return appuntamentiAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accentGreenDark)),
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
        Container(
          decoration: BoxDecoration(
            color: AppColors.glassCard,
            border: Border(
              bottom: BorderSide(color: AppColors.glassBorder, width: 0.5),
            ),
          ),
          child: _buildTableCalendar(eventiPerGiorno, false),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Text(
                _formatterGiorno.format(_giornoSelezionato),
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textOnDark,
                    fontSize: 14),
              ),
              const SizedBox(width: 8),
              if (eventiGiornoSel.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.40),
                        width: 0.5),
                  ),
                  child: Text(
                    '${eventiGiornoSel.length}',
                    style: const TextStyle(
                        color: AppColors.accentGreenDark,
                        fontSize: 11,
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
                          color: AppColors.textOnDarkMuted, fontSize: 14)),
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

  // ─── DESKTOP ──────────────────────────────────────────────────────────────

  Widget _buildDesktopLayout(
      AsyncValue<List<AppuntamentoModel>> appuntamentiAsync, bool isAdmin) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
          child: Row(
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                      value: false,
                      label: Text('Mese'),
                      icon: Icon(Icons.calendar_month_outlined, size: 16)),
                  ButtonSegment(
                      value: true,
                      label: Text('Settimana'),
                      icon: Icon(Icons.view_week_outlined, size: 16)),
                ],
                selected: {_vistaSettimana},
                onSelectionChanged: (s) =>
                    setState(() => _vistaSettimana = s.first),
                style: SegmentedButton.styleFrom(
                  backgroundColor: AppColors.glassCard,
                  foregroundColor: AppColors.textOnDarkSecondary,
                  selectedBackgroundColor:
                      AppColors.primary.withValues(alpha: 0.30),
                  selectedForegroundColor: AppColors.accentGreenDark,
                  side: BorderSide(color: AppColors.glassBorder, width: 0.5),
                ),
              ),
              const Spacer(),
              if (isAdmin)
                FilledButton.icon(
                  onPressed: () => context.push('/calendario/nuovo'),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nuovo'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.30),
                    foregroundColor: AppColors.accentGreenDark,
                    side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.50),
                        width: 0.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
            ],
          ),
        ),
        Container(
            height: 0.5,
            color: AppColors.glassBorder,
            margin: const EdgeInsets.symmetric(horizontal: 24)),
        Expanded(
          child: appuntamentiAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(
                    color: AppColors.accentGreenDark)),
            error: (e, _) => Center(
                child: Text('Errore: $e',
                    style: const TextStyle(color: AppColors.error))),
            data: (appuntamenti) {
              final eventiPerGiorno = _raggrupaPerGiorno(appuntamenti);
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _vistaSettimana
                        ? _buildVistaSettimana(eventiPerGiorno, true)
                        : _buildVistaMeseDesktop(eventiPerGiorno),
                  ),
                  _buildPannelloLaterale(eventiPerGiorno),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVistaMeseDesktop(
      Map<DateTime, List<AppuntamentoModel>> eventiPerGiorno) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.glassCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.glassBorder, width: 0.5),
        ),
        padding: const EdgeInsets.all(12),
        child: _buildTableCalendar(eventiPerGiorno, true),
      ),
    );
  }

  // ─── TableCalendar condiviso ──────────────────────────────────────────────

  Widget _buildTableCalendar(
      Map<DateTime, List<AppuntamentoModel>> eventiPerGiorno, bool isDesktop) {
    return TableCalendar<AppuntamentoModel>(
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
      onPageChanged: (focusedDay) => setState(() => _meseCorrente = focusedDay),
      calendarStyle: CalendarStyle(
        todayDecoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.30),
          shape: BoxShape.circle,
          border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.60), width: 0.5),
        ),
        todayTextStyle: const TextStyle(
            color: AppColors.accentGreenDark, fontWeight: FontWeight.w700),
        selectedDecoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.50),
          shape: BoxShape.circle,
        ),
        selectedTextStyle:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        defaultTextStyle: const TextStyle(color: AppColors.textOnDark),
        weekendTextStyle: const TextStyle(color: AppColors.textOnDarkSecondary),
        outsideTextStyle: const TextStyle(color: AppColors.textOnDarkMuted),
        markerDecoration: const BoxDecoration(
          color: AppColors.accentGreenDark,
          shape: BoxShape.circle,
        ),
      ),
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, day, events) {
          if (events.isEmpty) return const SizedBox.shrink();

          if (isDesktop) {
            // Desktop: badge con testo "N eventi"
            final colorePrincipale = _coloreEvento(events.first);
            final colori = events
                .map(_coloreEvento)
                .map((c) => c.toARGB32())
                .toSet()
                .take(3)
                .map(Color.new)
                .toList();
            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    // Sfondo più opaco per leggibilità
                    color: colorePrincipale.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                        color: colorePrincipale.withValues(alpha: 0.70),
                        width: 1),
                  ),
                  child: Text(
                    events.length == 1 ? '1 evento' : '${events.length} eventi',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      // Testo sempre bianco per massima leggibilità
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
                if (colori.length > 1)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: colori
                        .map((colore) => Container(
                              width: 7,
                              height: 7,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: colore,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 0.5),
                              ),
                            ))
                        .toList(),
                  ),
              ],
            );
          } else {
            // Mobile: pallini colorati
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
                children: colori
                    .map((colore) => Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: colore,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 0.5),
                          ),
                        ))
                    .toList(),
              ),
            );
          }
        },
      ),
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textOnDark),
        leftChevronIcon:
            Icon(Icons.chevron_left, color: AppColors.textOnDarkSecondary),
        rightChevronIcon:
            Icon(Icons.chevron_right, color: AppColors.textOnDarkSecondary),
      ),
      daysOfWeekStyle: const DaysOfWeekStyle(
        weekdayStyle: TextStyle(
            fontSize: 11,
            color: AppColors.textOnDarkSecondary,
            fontWeight: FontWeight.w500),
        weekendStyle: TextStyle(
            fontSize: 11,
            color: AppColors.textOnDarkMuted,
            fontWeight: FontWeight.w500),
      ),
      rowHeight: isDesktop ? 100 : 52,
    );
  }

  // ─── Vista settimana ──────────────────────────────────────────────────────

  Widget _buildVistaSettimana(
      Map<DateTime, List<AppuntamentoModel>> eventiPerGiorno, bool isDesktop) {
    final lunedi = _inizioSettimana(_giornoSelezionato);
    final giorni = List.generate(7, (i) => lunedi.add(Duration(days: i)));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left,
                    color: AppColors.textOnDarkSecondary),
                onPressed: () => setState(() => _giornoSelezionato =
                    _giornoSelezionato.subtract(const Duration(days: 7))),
              ),
              Expanded(
                child: Text(
                  '${_formatter.format(lunedi)} — ${_formatter.format(lunedi.add(const Duration(days: 6)))}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textOnDark,
                      fontSize: 14),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right,
                    color: AppColors.textOnDarkSecondary),
                onPressed: () => setState(() => _giornoSelezionato =
                    _giornoSelezionato.add(const Duration(days: 7))),
              ),
            ],
          ),
        ),
        Container(height: 0.5, color: AppColors.glassBorder),
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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: isOggi
                  ? AppColors.primary.withValues(alpha: 0.30)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: isOggi
                  ? Border.all(
                      color: AppColors.primary.withValues(alpha: 0.50),
                      width: 0.5)
                  : null,
            ),
            child: Text(
              DateFormat('EEEE d', 'it').format(giorno),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isOggi
                    ? AppColors.accentGreenDark
                    : AppColors.textOnDarkSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ),
        if (eventi.isEmpty)
          const Padding(
            padding: EdgeInsets.only(left: 20, bottom: 10),
            child: Text('Nessun appuntamento',
                style: TextStyle(
                    color: AppColors.textOnDarkMuted,
                    fontSize: 12,
                    fontStyle: FontStyle.italic)),
          )
        else
          ...eventi.map((e) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                child: _buildEventoCard(e),
              )),
        Container(
            height: 0.5,
            color: AppColors.glassBorderSubtle,
            margin: const EdgeInsets.symmetric(horizontal: 16)),
      ],
    );
  }

  // ─── Pannello laterale ────────────────────────────────────────────────────

  Widget _buildPannelloLaterale(
      Map<DateTime, List<AppuntamentoModel>> eventiPerGiorno) {
    final eventi = eventiPerGiorno[_normalizzaData(_giornoSelezionato)] ?? [];
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: AppColors.glassDarkest,
        border: Border(
          left: BorderSide(color: AppColors.glassBorder, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _formatterGiorno.format(_giornoSelezionato),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textOnDark,
                        fontSize: 13),
                  ),
                ),
                if (eventi.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.40),
                          width: 0.5),
                    ),
                    child: Text(
                      '${eventi.length}',
                      style: const TextStyle(
                          color: AppColors.accentGreenDark,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),
          Container(height: 0.5, color: AppColors.glassBorder),
          Expanded(
            child: eventi.isEmpty
                ? const Center(
                    child: Text('Nessun appuntamento',
                        style: TextStyle(
                            color: AppColors.textOnDarkMuted, fontSize: 13)),
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

  // ─── Evento card — FIX bordo sinistro colorato senza errore borderRadius ──

  Widget _buildEventoCard(AppuntamentoModel app) {
    final colore = _coloreEvento(app);
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _mostraDettaglioEvento(app),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 3),
        // ClipRRect per il borderRadius
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Bordo sinistro colorato (senza borderRadius problem)
                Container(
                  width: 4,
                  color: app.completato ? AppColors.textOnDarkMuted : colore,
                ),
                // Contenuto card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: app.completato
                          ? AppColors.glassDark
                          : colore.withValues(alpha: 0.10),
                      border: Border.all(
                          color: AppColors.glassBorderSubtle, width: 0.5),
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
                                      ? AppColors.textOnDarkMuted
                                      : AppColors.textOnDark,
                                  decoration: app.completato
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: colore.withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                          color: colore.withValues(alpha: 0.50),
                                          width: 0.5),
                                    ),
                                    child: Text(
                                      AppuntamentoModel.labelTipo(app.tipo),
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: colore,
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat('HH:mm').format(app.dataInizio),
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textOnDarkSecondary),
                                  ),
                                  if (app.tecnico != null &&
                                      app.tecnico!.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    const Icon(Icons.person_outline,
                                        size: 11,
                                        color: AppColors.textOnDarkMuted),
                                    const SizedBox(width: 2),
                                    Flexible(
                                      child: Text(
                                        app.tecnico!,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color:
                                                AppColors.textOnDarkSecondary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (app.notificaAbilitata)
                          const Icon(Icons.notifications_outlined,
                              size: 14, color: AppColors.textOnDarkMuted),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _mostraDettaglioEvento(AppuntamentoModel app) {
    final colore = _coloreEvento(app);
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: const Color(0xFF0A2A1A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.glassBorder, width: 0.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header colorato
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                decoration: BoxDecoration(
                  color: colore.withValues(alpha: 0.20),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  border: Border(
                    bottom: BorderSide(
                        color: colore.withValues(alpha: 0.40), width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colore,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            app.titolo,
                            style: const TextStyle(
                              color: AppColors.textOnDark,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: colore.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: colore.withValues(alpha: 0.50),
                                  width: 0.5),
                            ),
                            child: Text(
                              AppuntamentoModel.labelTipo(app.tipo),
                              style: TextStyle(
                                  fontSize: 11,
                                  color: colore,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Bottone modifica
                    IconButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        context.push('/calendario/${app.id}');
                      },
                      icon: const Icon(Icons.edit_outlined,
                          color: AppColors.textOnDarkSecondary, size: 20),
                      tooltip: 'Modifica',
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close,
                          color: AppColors.textOnDarkMuted, size: 20),
                      tooltip: 'Chiudi',
                    ),
                  ],
                ),
              ),

              // Corpo con informazioni
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _infoRigaDialog(
                      Icons.calendar_today_outlined,
                      'Data inizio',
                      DateFormat('EEEE d MMMM y', 'it').format(app.dataInizio),
                    ),
                    _dividerDialog(),
                    _infoRigaDialog(
                      Icons.access_time_outlined,
                      'Orario',
                      '${DateFormat('HH:mm').format(app.dataInizio)} → ${DateFormat('HH:mm').format(app.dataFine)}',
                    ),
                    if (app.clienteNome != null &&
                        app.clienteNome!.isNotEmpty) ...[
                      _dividerDialog(),
                      _infoRigaDialog(
                        Icons.business_outlined,
                        'Cliente',
                        app.clienteNome!,
                      ),
                    ],
                    if (app.tecnico != null && app.tecnico!.isNotEmpty) ...[
                      _dividerDialog(),
                      _infoRigaDialog(
                        Icons.person_outline,
                        'Tecnico',
                        app.tecnico!,
                      ),
                    ],
                    if (app.descrizione.isNotEmpty) ...[
                      _dividerDialog(),
                      _infoRigaDialog(
                        Icons.notes_outlined,
                        'Note',
                        app.descrizione,
                      ),
                    ],
                    _dividerDialog(),
                    _infoRigaDialog(
                      app.completato
                          ? Icons.check_circle_outline
                          : Icons.radio_button_unchecked,
                      'Stato',
                      app.completato ? 'Completato' : 'In attesa',
                      valueColor: app.completato
                          ? AppColors.accentGreenDark
                          : AppColors.textOnDarkSecondary,
                    ),
                    if (app.notificaAbilitata) ...[
                      _dividerDialog(),
                      _infoRigaDialog(
                        Icons.notifications_outlined,
                        'Notifica',
                        app.notificaGiorniPrima == 0
                            ? 'Stesso giorno'
                            : '${app.notificaGiorniPrima} giorni prima',
                        valueColor: AppColors.accentBlueDark,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRigaDialog(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textOnDarkSecondary),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textOnDarkMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: valueColor ?? AppColors.textOnDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dividerDialog() {
    return Container(
      height: 0.5,
      color: AppColors.glassBorderSubtle,
      margin: const EdgeInsets.symmetric(vertical: 2),
    );
  }

  // ─── Utility ──────────────────────────────────────────────────────────────

  Map<DateTime, List<AppuntamentoModel>> _raggrupaPerGiorno(
      List<AppuntamentoModel> appuntamenti) {
    final mappa = <DateTime, List<AppuntamentoModel>>{};
    for (final app in appuntamenti) {
      final chiave = _normalizzaData(app.dataInizio);
      mappa.putIfAbsent(chiave, () => []).add(app);
    }
    return mappa;
  }

  DateTime _normalizzaData(DateTime data) =>
      DateTime(data.year, data.month, data.day);

  DateTime _inizioSettimana(DateTime data) =>
      data.subtract(Duration(days: data.weekday - 1));

  Color _colorePerTipo(String tipo) {
    switch (tipo) {
      case 'reg_lab':
        return const Color(0xFF7DB8F4);
      case 'pest':
        return AppColors.accentGreenDark;
      case 'lettura_piastre':
        return const Color(0xFFF4C875);
      case 'richiamo':
        return const Color(0xFFFFAA6B);
      case 'generico':
      default:
        return const Color(0xFFAAAAAA);
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

// ─── Provider ─────────────────────────────────────────────────────────────────

final _appuntamentiMeseProvider =
    StreamProvider.family<List<AppuntamentoModel>, DateTime>(
        (ref, meseCorrente) {
  final service = ref.watch(appuntamentiServiceProvider);
  return service.getAppuntamentiMese(meseCorrente.year, meseCorrente.month);
});
