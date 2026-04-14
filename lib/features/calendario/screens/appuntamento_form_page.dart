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

/// Form per la creazione e modifica di un appuntamento nel calendario.
///
/// Accessibile SOLO admin.
/// Su mobile: pagina fullscreen.
/// Su desktop: mostrare come pagina fullscreen (il dialog può essere
/// implementato come wrapper in fase 2 se necessario).
class AppuntamentoFormPage extends ConsumerStatefulWidget {
  /// ID dell'appuntamento da modificare. Null = creazione nuovo.
  final String? appuntamentoId;

  const AppuntamentoFormPage({super.key, this.appuntamentoId});

  @override
  ConsumerState<AppuntamentoFormPage> createState() =>
      _AppuntamentoFormPageState();
}

class _AppuntamentoFormPageState
    extends ConsumerState<AppuntamentoFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final AppuntamentiService _appuntamentiService;
  late final ClientiService _clientiService;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDeleting = false;
  String? _erroreCaricamento;

  // Appuntamento originale (null = modalità creazione)
  AppuntamentoModel? _appuntamentoOriginale;

  // ─── Campi form ──────────────────────────────────────────────────────────

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

  // Lista clienti per la ricerca
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
        // Modalità modifica: carica i dati esistenti
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
    // Trova il cliente nel caso sia collegato
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
      // Combina data e ora per dataInizio e dataFine
      final inizio = DateTime(
        _dataInizio.year,
        _dataInizio.month,
        _dataInizio.day,
        _oraInizio.hour,
        _oraInizio.minute,
      );
      final fine = _dataFine != null
          ? DateTime(
              _dataFine!.year,
              _dataFine!.month,
              _dataFine!.day,
              _oraFine?.hour ?? _oraInizio.hour,
              _oraFine?.minute ?? _oraInizio.minute,
            )
          : inizio.add(const Duration(hours: 1)); // default 1 ora

      final app = AppuntamentoModel(
        id: _appuntamentoOriginale?.id ?? '',
        titolo: _titoloCtrl.text.trim(),
        descrizione: _descrizioneCtrl.text.trim(),
        dataInizio: inizio,
        dataFine: fine,
        tipo: _tipo,
        clienteId: _clienteSelezionato?.id,
        clienteNome: _clienteSelezionato?.committente,
        servizioCid:
            _servizioCtrl.text.trim().isNotEmpty ? _servizioCtrl.text.trim() : null,
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appuntamento salvato'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────

  Future<void> _elimina() async {
    final app = _appuntamentoOriginale;
    if (app == null || _isDeleting) return;

    final conferma = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina appuntamento'),
        content: Text(
          'Vuoi eliminare "${app.titolo}"? Questa azione non si puo annullare.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appuntamento eliminato'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore eliminazione: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titolo = widget.appuntamentoId != null
        ? 'Modifica appuntamento'
        : 'Nuovo appuntamento';

    // Verifica ruolo admin
    final userAsync = ref.watch(currentUserProvider);
    if (userAsync.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(titolo)),
        body: const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    final user = userAsync.valueOrNull;
    if (user == null || !user.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: Text(titolo)),
        body: const Center(
          child: Text('Accesso non autorizzato',
              style: TextStyle(color: AppColors.error)),
        ),
      );
    }

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(titolo)),
        body: const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_erroreCaricamento != null) {
      return Scaffold(
        appBar: AppBar(title: Text(titolo)),
        body: Center(
            child: Text('Errore: $_erroreCaricamento',
                style: const TextStyle(color: AppColors.error))),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(titolo),
        leading: IconButton(
          icon: const Icon(Icons.close),
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
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── 1. Titolo ─────────────────────────────────────────
                    TextFormField(
                      controller: _titoloCtrl,
                      decoration: _dec('Titolo *'),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Campo obbligatorio'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // ── 2. Tipo ───────────────────────────────────────────
                    DropdownButtonFormField<String>(
                      initialValue: _tipo,
                      decoration: _dec('Tipo appuntamento *'),
                      items: const [
                        DropdownMenuItem(
                            value: 'reg_lab', child: Text('Reg Lab')),
                        DropdownMenuItem(value: 'pest', child: Text('Pest')),
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
                          // Aggiorna il colore al cambio tipo
                          _colore = AppuntamentoModel.coloreHexDaTipo(v);
                        });
                      },
                      validator: (v) =>
                          v == null ? 'Campo obbligatorio' : null,
                    ),
                    const SizedBox(height: 16),

                    // ── 3. Data e ora inizio ──────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            readOnly: true,
                            controller: TextEditingController(
                                text: _formatter.format(_dataInizio)),
                            onTap: () => _selezionaData(
                              attuale: _dataInizio,
                              onSelezionata: (d) => _dataInizio = d,
                            ),
                            decoration: _dec('Data inizio *').copyWith(
                              suffixIcon: const Icon(Icons.calendar_today,
                                  size: 18, color: AppColors.textDisabled),
                            ),
                            validator: (_) => null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 100,
                          child: TextFormField(
                            readOnly: true,
                            controller: TextEditingController(
                                text: _oraInizio.format(context)),
                            onTap: () => _selezionaOra(
                              attuale: _oraInizio,
                              onSelezionata: (o) => _oraInizio = o,
                            ),
                            decoration: _dec('Ora').copyWith(
                              suffixIcon: const Icon(Icons.access_time,
                                  size: 18, color: AppColors.textDisabled),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── 4. Data e ora fine ────────────────────────────────
                    Row(
                      children: [
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
                            decoration: _dec('Data fine').copyWith(
                              suffixIcon: const Icon(Icons.calendar_today,
                                  size: 18, color: AppColors.textDisabled),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 100,
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
                            decoration: _dec('Ora fine').copyWith(
                              suffixIcon: const Icon(Icons.access_time,
                                  size: 18, color: AppColors.textDisabled),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── 5. Cliente collegato (opzionale) ──────────────────
                    Autocomplete<ClienteModel>(
                      initialValue: TextEditingValue(
                          text: _clienteSelezionato != null
                              ? '${_clienteSelezionato!.numeroFormattato} — ${_clienteSelezionato!.committente}'
                              : ''),
                      optionsBuilder: (textEditingValue) {
                        if (textEditingValue.text.isEmpty) return _clienti;
                        final q = textEditingValue.text.toLowerCase();
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
                          elevation: 4,
                          borderRadius: BorderRadius.circular(8),
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
                                  title: Text(c.committente),
                                  subtitle: Text(c.numeroFormattato),
                                  onTap: () => onSelected(c),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      fieldViewBuilder:
                          (context, fieldCtrl, focusNode, onSubmit) =>
                              TextFormField(
                        controller: fieldCtrl,
                        focusNode: focusNode,
                        decoration: _dec('Cliente collegato (opzionale)'),
                        onChanged: (v) {
                          if (v.isEmpty) {
                            setState(() => _clienteSelezionato = null);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── 6. Servizio collegato (solo per reg_lab e pest) ───
                    if (_tipo == 'reg_lab' || _tipo == 'pest') ...[
                      TextFormField(
                        controller: _servizioCtrl,
                        decoration: _dec('ID Servizio collegato (opzionale)'),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── 7. Tecnico ────────────────────────────────────────
                    TextFormField(
                      controller: _tecnicoCtrl,
                      decoration: _dec('Tecnico'),
                    ),
                    const SizedBox(height: 16),

                    // ── 8. Descrizione/Note ───────────────────────────────
                    TextFormField(
                      controller: _descrizioneCtrl,
                      decoration: _dec('Descrizione / Note'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    // ── 9. Colore ─────────────────────────────────────────
                    _buildSelezioneColore(),
                    const SizedBox(height: 16),

                    // ── 10. Notifiche ─────────────────────────────────────
                    SwitchListTile(
                      title: const Text('Notifica abilitata',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                      value: _notificaAbilitata,
                      onChanged: (v) =>
                          setState(() => _notificaAbilitata = v),
                      activeThumbColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                    ),

                    // Slider giorni anticipo (visibile solo se notifica abilitata)
                    if (_notificaAbilitata) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('Notifica',
                              style: TextStyle(color: AppColors.textSecondary)),
                          Expanded(
                            child: Slider(
                              value: _notificaGiorniPrima.toDouble(),
                              min: 0,
                              max: 7,
                              divisions: 7,
                              label: _notificaGiorniPrima == 0
                                  ? 'Stesso giorno'
                                  : '$_notificaGiorniPrima giorni prima',
                              onChanged: (v) => setState(
                                  () => _notificaGiorniPrima = v.round()),
                              activeColor: AppColors.primary,
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: Text(
                              _notificaGiorniPrima == 0
                                  ? 'Stesso giorno'
                                  : '$_notificaGiorniPrima gg prima',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary),
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),

                    // ── 11. Completato ────────────────────────────────────
                    SwitchListTile(
                      title: const Text('Completato',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                      value: _completato,
                      onChanged: (v) => setState(() => _completato = v),
                      activeThumbColor: AppColors.success,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),

            // ── Bottoni ────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.divider)),
                color: AppColors.surface,
              ),
              child: Row(
                children: [
                  if (widget.appuntamentoId != null) ...[
                    OutlinedButton.icon(
                      onPressed: (_isSaving || _isDeleting) ? null : _elimina,
                      icon: _isDeleting
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.delete_outline),
                      label: const Text('Elimina'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  OutlinedButton(
                    onPressed: (_isSaving || _isDeleting)
                        ? null
                        : () => context.pop(),
                    child: const Text('Annulla'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: (_isSaving || _isDeleting) ? null : _salva,
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary),
                      child: _isSaving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Salva'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget selezione colore con 6 predefiniti
  Widget _buildSelezioneColore() {
    const coloriPredefiniti = [
      '#1565C0', // blu (reg_lab)
      '#00A843', // verde (pest)
      '#E65100', // arancio (lettura_piastre)
      '#BA7517', // ambra (richiamo)
      '#5F5E5A', // grigio (generico)
      '#D32F2F', // rosso
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Colore',
            style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Row(
          children: coloriPredefiniti.map((hex) {
            final isSelected = _colore == hex;
            final color = _hexToColor(hex);
            return GestureDetector(
              onTap: () => setState(() => _colore = hex),
              child: Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(
                          color: AppColors.textPrimary, width: 2.5)
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.5),
                            blurRadius: 6,
                            spreadRadius: 1,
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

  /// Converte un hex color string (#RRGGBB) in Flutter Color
  Color _hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  InputDecoration _dec(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
