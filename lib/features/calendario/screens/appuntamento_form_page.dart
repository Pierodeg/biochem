import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/service_providers.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../models/appuntamento_model.dart';
import '../../../models/cliente_model.dart';
import '../../../services/appuntamenti_service.dart';
import '../../../services/clienti_service.dart';

class AppuntamentoFormPage extends ConsumerStatefulWidget {
  final String? appuntamentoId;
  const AppuntamentoFormPage({super.key, this.appuntamentoId});

  @override
  ConsumerState<AppuntamentoFormPage> createState() =>
      _AppuntamentoFormPageState();
}

class _AppuntamentoFormPageState extends ConsumerState<AppuntamentoFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final AppuntamentiService _appuntamentiService;
  late final ClientiService _clientiService;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _gruppo1Aperta = true;
  bool _gruppo2Aperta = true;
  bool _gruppo3Aperta = true;
  bool _gruppo4Aperta = true;
  bool _gruppo5Aperta = true;
  String? _erroreCaricamento;
  AppuntamentoModel? _appuntamentoOriginale;

  final _titoloCtrl = TextEditingController();
  String _tipo = 'generico';
  DateTime _dataInizio = DateTime.now();
  TimeOfDay _oraInizio = TimeOfDay.now();
  DateTime? _dataFine;
  TimeOfDay? _oraFine;
  ClienteModel? _clienteSelezionato;
  final _servizioCtrl = TextEditingController();
  final _tecnicoCtrl = TextEditingController();
  final _descrizioneCtrl = TextEditingController();
  String _colore = '#5F5E5A';
  bool _notificaAbilitata = false;
  int _notificaGiorniPrima = 1;
  bool _completato = false;
  List<ClienteModel> _clienti = [];

  final _formatter = DateFormat('dd/MM/yyyy', 'it');

  @override
  void initState() {
    super.initState();
    _appuntamentiService = ref.read(appuntamentiServiceProvider);
    _clientiService = ref.read(clientiServiceProvider);
    _inizializza();
  }

  @override
  void dispose() {
    _titoloCtrl.dispose();
    _servizioCtrl.dispose();
    _tecnicoCtrl.dispose();
    _descrizioneCtrl.dispose();
    super.dispose();
  }

  Future<void> _inizializza() async {
    try {
      _clienti = await _clientiService.getClienti().first;
      if (widget.appuntamentoId != null) {
        final doc = await _appuntamentiService
            .getAppuntamenti()
            .first
            .then((list) => list.firstWhere(
                (a) => a.id == widget.appuntamentoId,
                orElse: () => throw Exception('Appuntamento non trovato')));
        _appuntamentoOriginale = doc;
        _popolaDaModello(doc);
      }
    } catch (e) {
      _erroreCaricamento = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _popolaDaModello(AppuntamentoModel app) {
    _titoloCtrl.text = app.titolo;
    _tipo = app.tipo;
    _dataInizio = app.dataInizio;
    _oraInizio = TimeOfDay.fromDateTime(app.dataInizio);
    _dataFine = app.dataFine;
    _oraFine = TimeOfDay.fromDateTime(app.dataFine);
    _tecnicoCtrl.text = app.tecnico ?? '';
    _descrizioneCtrl.text = app.descrizione;
    _colore = app.colore;
    _notificaAbilitata = app.notificaAbilitata;
    _notificaGiorniPrima = app.notificaGiorniPrima;
    _completato = app.completato;
    _servizioCtrl.text = app.servizioCid ?? '';
    if (app.clienteId != null) {
      try {
        _clienteSelezionato =
            _clienti.firstWhere((c) => c.id == app.clienteId);
      } catch (_) {}
    }
  }

  Future<void> _selezionaData({
    required DateTime? attuale,
    required void Function(DateTime) onSelezionata,
  }) async {
    final selezionata = await showDatePicker(
      context: context,
      initialDate: attuale ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2050),
      locale: const Locale('it'),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
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
    if (selezionata != null && mounted) {
      setState(() => onSelezionata(selezionata));
    }
  }

  Future<void> _selezionaOra({
    required TimeOfDay? attuale,
    required void Function(TimeOfDay) onSelezionata,
  }) async {
    final selezionata = await showTimePicker(
      context: context,
      initialTime: attuale ?? TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
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
    if (selezionata != null && mounted) {
      setState(() => onSelezionata(selezionata));
    }
  }

  Future<void> _salva() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final uid = ref.read(currentUserProvider).valueOrNull?.uid ?? '';
    setState(() => _isSaving = true);
    try {
      final inizio = DateTime(_dataInizio.year, _dataInizio.month,
          _dataInizio.day, _oraInizio.hour, _oraInizio.minute);
      final fine = _dataFine != null
          ? DateTime(_dataFine!.year, _dataFine!.month, _dataFine!.day,
              _oraFine?.hour ?? _oraInizio.hour,
              _oraFine?.minute ?? _oraInizio.minute)
          : inizio.add(const Duration(hours: 1));

      final app = AppuntamentoModel(
        id: _appuntamentoOriginale?.id ?? '',
        titolo: _titoloCtrl.text.trim(),
        descrizione: _descrizioneCtrl.text.trim(),
        dataInizio: inizio,
        dataFine: fine,
        tipo: _tipo,
        clienteId: _clienteSelezionato?.id,
        clienteNome: _clienteSelezionato?.committente,
        servizioCid: _servizioCtrl.text.trim().isNotEmpty
            ? _servizioCtrl.text.trim()
            : null,
        tecnico: _tecnicoCtrl.text.trim().isNotEmpty
            ? _tecnicoCtrl.text.trim()
            : null,
        notificaAbilitata: _notificaAbilitata,
        notificaGiorniPrima: _notificaGiorniPrima,
        completato: _completato,
        colore: _colore,
        creadaDa: _appuntamentoOriginale?.creadaDa ?? uid,
        createdAt: _appuntamentoOriginale?.createdAt ?? DateTime.now(),
      );

      await _appuntamentiService.salvaAppuntamento(app);
      if (mounted) {
        _showSnackBar('Appuntamento salvato', AppColors.primary);
        context.pop();
      }
    } catch (e) {
      if (mounted) _showSnackBar('Errore: $e', AppColors.error);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _elimina() async {
    final app = _appuntamentoOriginale;
    if (app == null || _isDeleting) return;

    final conferma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0A2A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.glassBorder, width: 0.5),
        ),
        title: const Text('Elimina appuntamento',
            style: TextStyle(
                color: AppColors.textOnDark, fontWeight: FontWeight.w600)),
        content: Text(
          'Vuoi eliminare "${app.titolo}"? Questa azione non si può annullare.',
          style: const TextStyle(color: AppColors.textOnDarkSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla',
                style: TextStyle(color: AppColors.textOnDarkSecondary)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error.withValues(alpha: 0.25),
              foregroundColor: const Color(0xFFFF7070),
              side: BorderSide(
                  color: AppColors.error.withValues(alpha: 0.40), width: 0.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (conferma != true || !mounted) return;
    setState(() => _isDeleting = true);
    try {
      await _appuntamentiService.eliminaAppuntamento(app.id);
      if (mounted) {
        _showSnackBar('Appuntamento eliminato', AppColors.error);
        context.pop();
      }
    } catch (e) {
      if (mounted) _showSnackBar('Errore eliminazione: $e', AppColors.error);
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: color.withValues(alpha: 0.90),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 0.5),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final titolo = widget.appuntamentoId != null
        ? 'Modifica appuntamento'
        : 'Nuovo appuntamento';

    final userAsync = ref.watch(currentUserProvider);
    if (userAsync.isLoading || _isLoading) {
      return _buildScaffold(titolo,
          body: const Center(
              child: CircularProgressIndicator(
                  color: AppColors.accentGreenDark)));
    }

    final user = userAsync.valueOrNull;
    if (user == null || !user.isAdmin) {
      return _buildScaffold(titolo,
          body: const Center(
              child: Text('Accesso non autorizzato',
                  style: TextStyle(color: AppColors.error))));
    }

    if (_erroreCaricamento != null) {
      return _buildScaffold(titolo,
          body: Center(
              child: Text('Errore: $_erroreCaricamento',
                  style: const TextStyle(color: AppColors.error))));
    }

    return _buildScaffold(titolo, body: _buildBody());
  }

  Widget _buildScaffold(String titolo, {required Widget body}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.gradientStart,
            AppColors.gradientMid1,
            AppColors.gradientMid2,
            AppColors.gradientEnd,
          ],
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: AppColors.glassDarkest,
          title: Text(titolo,
              style: const TextStyle(
                  color: AppColors.textOnDark, fontWeight: FontWeight.w600)),
          leading: IconButton(
            icon: const Icon(Icons.close, color: AppColors.textOnDark),
            onPressed: () => context.pop(),
          ),
          actions: [
            if (widget.appuntamentoId != null)
              IconButton(
                tooltip: 'Elimina appuntamento',
                onPressed: (_isSaving || _isDeleting) ? null : _elimina,
                icon: _isDeleting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textOnDark))
                    : Icon(Icons.delete_outline,
                        color: AppColors.error.withValues(alpha: 0.8)),
              ),
          ],
        ),
        body: body,
      ),
    );
  }

  Widget _buildBody() {
    final isDesktop = MediaQuery.of(context).size.width >= 600;
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 80 : 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Gruppo: Informazioni principali
                  _buildGruppo('Informazioni principali', [
                    TextFormField(
                      controller: _titoloCtrl,
                      style: const TextStyle(color: AppColors.textOnDark),
                      decoration: _inputDec('Titolo *'),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Campo obbligatorio'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _tipo,
                      decoration: _inputDec('Tipo appuntamento *'),
                      style: const TextStyle(
                          color: AppColors.textOnDark, fontSize: 14),
                      dropdownColor: const Color(0xFF0A2A1A),
                      iconEnabledColor: AppColors.textOnDarkSecondary,
                      items: const [
                        DropdownMenuItem(
                            value: 'reg_lab', child: Text('Reg Lab')),
                        DropdownMenuItem(
                            value: 'pest', child: Text('Pest')),
                        DropdownMenuItem(
                            value: 'lettura_piastre',
                            child: Text('Lettura piastre')),
                        DropdownMenuItem(
                            value: 'richiamo', child: Text('Richiamo')),
                        DropdownMenuItem(
                            value: 'generico', child: Text('Generico')),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() {
                          _tipo = v;
                          _colore = AppuntamentoModel.coloreHexDaTipo(v);
                        });
                      },
                      validator: (v) =>
                          v == null ? 'Campo obbligatorio' : null,
                    ),
                  ],
                  icona: Icons.info_outline,
                  isAperta: _gruppo1Aperta,
                  onToggle: () => setState(() => _gruppo1Aperta = !_gruppo1Aperta),
                  preview: _titoloCtrl.text,
                  ),
                  const SizedBox(height: 12),

                  // Gruppo: Date e orari
                  _buildGruppo('Date e orari', [
                    Row(children: [
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          controller: TextEditingController(
                              text: _formatter.format(_dataInizio)),
                          onTap: () => _selezionaData(
                            attuale: _dataInizio,
                            onSelezionata: (d) => _dataInizio = d,
                          ),
                          style:
                              const TextStyle(color: AppColors.textOnDark),
                          decoration: _inputDec('Data inizio *').copyWith(
                            suffixIcon: const Icon(Icons.calendar_today,
                                size: 18,
                                color: AppColors.textOnDarkSecondary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 110,
                        child: TextFormField(
                          readOnly: true,
                          controller: TextEditingController(
                              text: _oraInizio.format(context)),
                          onTap: () => _selezionaOra(
                            attuale: _oraInizio,
                            onSelezionata: (o) => _oraInizio = o,
                          ),
                          style:
                              const TextStyle(color: AppColors.textOnDark),
                          decoration: _inputDec('Ora').copyWith(
                            suffixIcon: const Icon(Icons.access_time,
                                size: 18,
                                color: AppColors.textOnDarkSecondary),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          controller: TextEditingController(
                              text: _dataFine != null
                                  ? _formatter.format(_dataFine!)
                                  : ''),
                          onTap: () => _selezionaData(
                            attuale: _dataFine,
                            onSelezionata: (d) => _dataFine = d,
                          ),
                          style:
                              const TextStyle(color: AppColors.textOnDark),
                          decoration: _inputDec('Data fine').copyWith(
                            suffixIcon: const Icon(Icons.calendar_today,
                                size: 18,
                                color: AppColors.textOnDarkSecondary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 110,
                        child: TextFormField(
                          readOnly: true,
                          controller: TextEditingController(
                              text: _oraFine != null
                                  ? _oraFine!.format(context)
                                  : ''),
                          onTap: () => _selezionaOra(
                            attuale: _oraFine,
                            onSelezionata: (o) => _oraFine = o,
                          ),
                          style:
                              const TextStyle(color: AppColors.textOnDark),
                          decoration: _inputDec('Ora fine').copyWith(
                            suffixIcon: const Icon(Icons.access_time,
                                size: 18,
                                color: AppColors.textOnDarkSecondary),
                          ),
                        ),
                      ),
                    ]),
                  ],
                  icona: Icons.calendar_month_outlined,
                  isAperta: _gruppo2Aperta,
                  onToggle: () => setState(() => _gruppo2Aperta = !_gruppo2Aperta),
                  preview: _formatter.format(_dataInizio),
                  ),
                  const SizedBox(height: 12),

                  // Gruppo: Collegamento
                  _buildGruppo('Collegamento', [
                    Autocomplete<ClienteModel>(
                      initialValue: TextEditingValue(
                          text: _clienteSelezionato != null
                              ? '${_clienteSelezionato!.numeroFormattato} — ${_clienteSelezionato!.committente}'
                              : ''),
                      optionsBuilder: (v) {
                        if (v.text.isEmpty) return _clienti;
                        final q = v.text.toLowerCase();
                        return _clienti.where((c) =>
                            c.committente.toLowerCase().contains(q) ||
                            c.numeroCliente.toString().contains(q));
                      },
                      displayStringForOption: (c) =>
                          '${c.numeroFormattato} — ${c.committente}',
                      onSelected: (c) =>
                          setState(() => _clienteSelezionato = c),
                      optionsViewBuilder: (context, onSelected, options) =>
                          Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          color: const Color(0xFF0A2A1A),
                          elevation: 4,
                          borderRadius: BorderRadius.circular(10),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                                maxHeight: 200, maxWidth: 350),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (context, i) {
                                final c = options.elementAt(i);
                                return ListTile(
                                  dense: true,
                                  title: Text(c.committente,
                                      style: const TextStyle(
                                          color: AppColors.textOnDark,
                                          fontSize: 13)),
                                  subtitle: Text(c.numeroFormattato,
                                      style: const TextStyle(
                                          color:
                                              AppColors.textOnDarkSecondary,
                                          fontSize: 11)),
                                  onTap: () => onSelected(c),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      fieldViewBuilder: (context, fieldCtrl, focusNode,
                              onSubmit) =>
                          TextFormField(
                        controller: fieldCtrl,
                        focusNode: focusNode,
                        style:
                            const TextStyle(color: AppColors.textOnDark),
                        decoration:
                            _inputDec('Cliente collegato (opzionale)'),
                        onChanged: (v) {
                          if (v.isEmpty) {
                            setState(() => _clienteSelezionato = null);
                          }
                        },
                      ),
                    ),
                    if (_tipo == 'reg_lab' || _tipo == 'pest') ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _servizioCtrl,
                        style:
                            const TextStyle(color: AppColors.textOnDark),
                        decoration:
                            _inputDec('ID Servizio collegato (opzionale)'),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _tecnicoCtrl,
                      style: const TextStyle(color: AppColors.textOnDark),
                      decoration: _inputDec('Tecnico'),
                    ),
                  ],
                  icona: Icons.link_outlined,
                  isAperta: _gruppo3Aperta,
                  onToggle: () => setState(() => _gruppo3Aperta = !_gruppo3Aperta),
                  preview: _clienteSelezionato?.committente ?? '',
                  ),
                  const SizedBox(height: 12),

                  // Gruppo: Note e colore
                  _buildGruppo('Note e personalizzazione', [
                    TextFormField(
                      controller: _descrizioneCtrl,
                      style: const TextStyle(color: AppColors.textOnDark),
                      decoration: _inputDec('Descrizione / Note'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    _buildSelezioneColore(),
                  ],
                  icona: Icons.edit_note_outlined,
                  isAperta: _gruppo4Aperta,
                  onToggle: () => setState(() => _gruppo4Aperta = !_gruppo4Aperta),
                  preview: _descrizioneCtrl.text,
                  ),
                  const SizedBox(height: 12),

                  // Gruppo: Impostazioni
                  _buildGruppo('Impostazioni', [
                    Row(
                      children: [
                        const Icon(Icons.notifications_outlined,
                            size: 18, color: AppColors.accentGreenDark),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text('Notifica abilitata',
                              style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textOnDark,
                                  fontSize: 14)),
                        ),
                        Switch(
                          value: _notificaAbilitata,
                          onChanged: (v) =>
                              setState(() => _notificaAbilitata = v),
                          activeColor: AppColors.accentGreenDark,
                          activeTrackColor:
                              AppColors.primary.withValues(alpha: 0.40),
                          inactiveThumbColor:
                              AppColors.textOnDarkSecondary,
                          inactiveTrackColor: AppColors.glassDark,
                        ),
                      ],
                    ),
                    if (_notificaAbilitata) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('Anticipo:',
                              style: TextStyle(
                                  color: AppColors.textOnDarkSecondary,
                                  fontSize: 12)),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: AppColors.primary,
                                inactiveTrackColor:
                                    AppColors.glassBorder,
                                thumbColor: AppColors.accentGreenDark,
                                overlayColor: AppColors.primary
                                    .withValues(alpha: 0.20),
                                valueIndicatorColor: AppColors.glassDarkest,
                                valueIndicatorTextStyle: const TextStyle(
                                    color: AppColors.textOnDark),
                              ),
                              child: Slider(
                                value: _notificaGiorniPrima.toDouble(),
                                min: 0,
                                max: 7,
                                divisions: 7,
                                label: _notificaGiorniPrima == 0
                                    ? 'Stesso giorno'
                                    : '$_notificaGiorniPrima gg prima',
                                onChanged: (v) => setState(
                                    () => _notificaGiorniPrima = v.round()),
                              ),
                            ),
                          ),
                          Text(
                            _notificaGiorniPrima == 0
                                ? 'Stesso\ngiorno'
                                : '$_notificaGiorniPrima gg\nprima',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textOnDarkSecondary),
                            textAlign: TextAlign.end,
                          ),
                        ],
                      ),
                    ],
                    Container(
                      height: 0.5,
                      color: AppColors.glassBorderSubtle,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.check_circle_outline,
                            size: 18, color: AppColors.accentGreenDark),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text('Completato',
                              style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textOnDark,
                                  fontSize: 14)),
                        ),
                        Switch(
                          value: _completato,
                          onChanged: (v) =>
                              setState(() => _completato = v),
                          activeColor: AppColors.accentGreenDark,
                          activeTrackColor:
                              AppColors.primary.withValues(alpha: 0.40),
                          inactiveThumbColor:
                              AppColors.textOnDarkSecondary,
                          inactiveTrackColor: AppColors.glassDark,
                        ),
                      ],
                    ),
                  ],
                  icona: Icons.tune_outlined,
                  isAperta: _gruppo5Aperta,
                  onToggle: () => setState(() => _gruppo5Aperta = !_gruppo5Aperta),
                  ),
                ],
              ),
            ),
          ),

          // Barra bottoni
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: BoxDecoration(
              color: AppColors.glassDarkest,
              border: Border(
                  top: BorderSide(
                      color: AppColors.glassBorder, width: 0.5)),
            ),
            child: Row(
              children: [
                if (widget.appuntamentoId != null) ...[
                  OutlinedButton.icon(
                    onPressed:
                        (_isSaving || _isDeleting) ? null : _elimina,
                    icon: _isDeleting
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFFF7070)))
                        : const Icon(Icons.delete_outline),
                    label: const Text('Elimina'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF7070),
                      side: BorderSide(
                          color: AppColors.error.withValues(alpha: 0.40),
                          width: 0.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                OutlinedButton(
                  onPressed: (_isSaving || _isDeleting)
                      ? null
                      : () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textOnDarkSecondary,
                    side: BorderSide(
                        color: AppColors.glassBorder, width: 0.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  child: const Text('Annulla'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: (_isSaving || _isDeleting) ? null : _salva,
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.30),
                      foregroundColor: AppColors.accentGreenDark,
                      side: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.50),
                          width: 0.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.accentGreenDark))
                        : const Text('Salva'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Gruppo card glass ────────────────────────────────────────────────────

  Widget _buildGruppo(
    String titolo,
    List<Widget> children, {
    required IconData icona,
    required bool isAperta,
    required VoidCallback onToggle,
    String preview = '',
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.glassCardMedium,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorderMedium, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          width: 0.5),
                    ),
                    child: Icon(icona,
                        color: AppColors.accentGreenDark, size: 14),
                  ),
                  const SizedBox(width: 8),
                  Text(titolo,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accentGreenDark,
                        letterSpacing: 0.3,
                      )),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AnimatedOpacity(
                      opacity: isAperta ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Text(preview,
                          style: const TextStyle(
                              fontSize: 11, color: Color(0x80FFFFFF)),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          textAlign: TextAlign.end),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isAperta ? 0 : 0.5,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0x14FFFFFF),
                        border: Border.all(
                            color: const Color(0x26FFFFFF), width: 0.5),
                      ),
                      child: const Icon(Icons.keyboard_arrow_up,
                          color: Color(0x80FFFFFF), size: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ClipRect(
            child: AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              sizeCurve: Curves.easeInOut,
              firstCurve: Curves.easeInOut,
              secondCurve: Curves.easeInOut,
              crossFadeState: isAperta
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 0.5,
                    color: const Color(0x26FFFFFF),
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: children,
                    ),
                  ),
                ],
              ),
              secondChild: const SizedBox(width: double.infinity, height: 0),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Selezione colore ─────────────────────────────────────────────────────

  Widget _buildSelezioneColore() {
    const coloriPredefiniti = [
      '#7DB8F4', // blu chiaro (reg_lab)
      '#4AE883', // verde chiaro (pest)
      '#F4C875', // ambra (richiamo)
      '#FFB347', // arancio (lettura_piastre)
      '#99FFFFFF', // grigio (generico)
      '#FF7070', // rosso
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Colore evento',
            style: TextStyle(
                color: AppColors.textOnDarkSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        Row(
          children: coloriPredefiniti.map((hex) {
            final isSelected = _colore == hex ||
                _colore.replaceAll('#', '').toLowerCase() ==
                    hex.replaceAll('#', '').toLowerCase();
            final color = _hexToColor(hex);
            return GestureDetector(
              onTap: () => setState(() => _colore = hex),
              child: Container(
                width: 34,
                height: 34,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(
                          color: Colors.white, width: 2.5)
                      : Border.all(
                          color: Colors.white.withValues(alpha: 0.20),
                          width: 0.5),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.6),
                            blurRadius: 8,
                            spreadRadius: 2,
                          )
                        ]
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    if (h.length == 8) return Color(int.parse(h, radix: 16));
    return Color(int.parse('FF$h', radix: 16));
  }

  InputDecoration _inputDec(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(
        color: AppColors.glassFieldLabelDim, fontSize: 13),
    filled: true,
    fillColor: const Color(0x0DFFFFFF),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.glassBorder, width: 0.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.glassBorder, width: 0.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.error, width: 0.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );
}
