import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/service_providers.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../models/cliente_model.dart';
import '../../../models/preventivo_model.dart';
import '../../../services/cap_service.dart';
import '../../../services/clienti_service.dart';
import '../../../services/impostazioni_service.dart';
import '../../../services/preventivi_service.dart';
import '../../../services/preventivo_pdf_service.dart';
import '../../../widgets/categoria_dropdown.dart';

/// Form per la creazione e modifica di un preventivo.
///
/// Parametri:
/// - [preventivoId] null → modalità creazione; stringa → modalità modifica
///
/// Accessibile SOLO agli admin (protezione nel router).
class PreventivoFormPage extends ConsumerStatefulWidget {
  final String? preventivoId;
  const PreventivoFormPage({super.key, this.preventivoId});

  @override
  ConsumerState<PreventivoFormPage> createState() =>
      _PreventivoFormPageState();
}

class _PreventivoFormPageState extends ConsumerState<PreventivoFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final PreventiviService _preventiviService;
  late final ClientiService _clientiService;
  late final CapService _capService;
  late final ImpostazioniService _impostazioniService;
  late final PreventivoPdfService _pdfService;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isGeneratingPdf = false;
  String? _erroreCaricamento;
  String? _preventivoIdCorrente;
  bool _allowDirectPop = false;
  Map<String, Object?>? _snapshotIniziale;

  // Preventivo originale (null = modalità creazione)
  PreventivoModel? _preventivoOriginale;

  // Clienti per autocomplete
  List<ClienteModel> _clienti = [];

  // Voci listino per il dropdown delle righe
  List<Map<String, dynamic>> _vociListino = [];

  // ─── Gruppo 1 — Identificazione ──────────────────────────────────────────

  // Numero progressivo (auto-generato, readonly)
  int? _numeroPrev;
  DateTime _dataPrev = DateTime.now();
  final _dataCtrl = TextEditingController();

  // Cliente selezionato
  final _clienteDisplayCtrl = TextEditingController();
  String _codiceClienteId = '';

  // ─── Gruppo 2 — Dati cliente (snapshot) ──────────────────────────────────

  final _tipoCommittenteCtrl = TextEditingController();
  final _committenteCtrl = TextEditingController();
  final _indirizzoCommCtrl = TextEditingController();
  final _capCommCtrl = TextEditingController();
  final _cittaCommCtrl = TextEditingController();
  final _provCommCtrl = TextEditingController();
  final _codiceFiscaleCtrl = TextEditingController();
  final _codiceUnivocoCtrl = TextEditingController();
  final _referenteCtrl = TextEditingController();

  // ─── Gruppo 3 — Righe servizi ────────────────────────────────────────────

  final List<_RigaController> _righeCtrl = [];

  // ─── Gruppo 4 — Condizioni ────────────────────────────────────────────────

  String? _validita;
  String? _modalitaPagamento;
  String? _rinnovo;

  // ─── Gruppo 5 — Totali ────────────────────────────────────────────────────

  double _percIva = 22.0;
  double _imponibile = 0;
  double _importoIva = 0;
  double _totale = 0;

  // ─── Gruppo 6 — Note ─────────────────────────────────────────────────────

  final _noteCtrl = TextEditingController();

  // ─── Formatter ────────────────────────────────────────────────────────────

  final _dateFmt = DateFormat('dd/MM/yyyy');
  final _moneyFmt =
      NumberFormat.currency(locale: 'it_IT', symbol: '€', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _preventivoIdCorrente = widget.preventivoId;
    _preventiviService = ref.read(preventiviServiceProvider);
    _clientiService = ref.read(clientiServiceProvider);
    _capService = ref.read(capServiceProvider);
    _impostazioniService = ref.read(impostazioniServiceProvider);
    _pdfService = ref.read(preventivoPdfServiceProvider);
    _dataCtrl.text = _dateFmt.format(_dataPrev);
    _inizializza();
  }

  @override
  void dispose() {
    _dataCtrl.dispose();
    _clienteDisplayCtrl.dispose();
    _tipoCommittenteCtrl.dispose();
    _committenteCtrl.dispose();
    _indirizzoCommCtrl.dispose();
    _capCommCtrl.dispose();
    _cittaCommCtrl.dispose();
    _provCommCtrl.dispose();
    _codiceFiscaleCtrl.dispose();
    _codiceUnivocoCtrl.dispose();
    _referenteCtrl.dispose();
    _noteCtrl.dispose();
    for (final r in _righeCtrl) {
      r.dispose();
    }
    super.dispose();
  }

  // ─── Inizializzazione ─────────────────────────────────────────────────────

  Future<void> _inizializza() async {
    try {
      // Carica clienti e listino in parallelo
      final risultati = await Future.wait([
        _clientiService.getClienti().first,
        _impostazioniService.getVociListino('preventivo_listino').first,
      ]);
      _clienti = risultati[0] as List<ClienteModel>;
      _vociListino = risultati[1] as List<Map<String, dynamic>>;

      if (widget.preventivoId != null) {
        // Modalità modifica
        final p =
            await _preventiviService.getPreventivoById(widget.preventivoId!);
        if (p != null) {
          _preventivoOriginale = p;
          _popolaDaModello(p);
        }
      }
      // Modalità creazione: nessun dato da pre-caricare
    } catch (e) {
      _erroreCaricamento = e.toString();
    } finally {
      if (mounted) {
        _snapshotIniziale = _snapshotCorrente();
        setState(() => _isLoading = false);
      }
    }
  }

  /// Popola i controller dal modello esistente (modifica)
  void _popolaDaModello(PreventivoModel p) {
    _numeroPrev = p.numeroPrev;
    _dataPrev = p.data;
    _dataCtrl.text = _dateFmt.format(p.data);
    _codiceClienteId = p.codiceCliente;
    _clienteDisplayCtrl.text = p.committente;

    _tipoCommittenteCtrl.text = p.tipoCommittente;
    _committenteCtrl.text = p.committente;
    _indirizzoCommCtrl.text = p.indirizzoCommittente;
    _capCommCtrl.text = p.cap;
    _cittaCommCtrl.text = p.citta;
    _provCommCtrl.text = p.provincia;
    _codiceFiscaleCtrl.text = p.codiceFiscale;
    _codiceUnivocoCtrl.text = p.codiceUnivoco;
    _referenteCtrl.text = p.referente;

    for (final riga in p.righe) {
      _righeCtrl.add(_RigaController.fromRiga(riga));
    }

    _validita = p.validita.isNotEmpty ? p.validita : null;
    _modalitaPagamento =
        p.modalitaPagamento.isNotEmpty ? p.modalitaPagamento : null;
    _rinnovo = p.rinnovo.isNotEmpty ? p.rinnovo : null;

    _percIva = p.percIva;
    _noteCtrl.text = p.note;
    _ricalcola();
  }

  // ─── Selezione data ────────────────────────────────────────────────────────

  Future<void> _selezionaData() async {
    final sel = await showDatePicker(
      context: context,
      initialDate: _dataPrev,
      firstDate: DateTime(2020),
      lastDate: DateTime(2050),
      locale: const Locale('it'),
    );
    if (sel != null && mounted) {
      setState(() {
        _dataPrev = sel;
        _dataCtrl.text = _dateFmt.format(sel);
      });
    }
  }

  // ─── Selezione cliente ────────────────────────────────────────────────────

  void _onClienteSelezionato(ClienteModel c) {
    setState(() {
      _codiceClienteId = c.id;
      _clienteDisplayCtrl.text = '${c.numeroFormattato} — ${c.committente}';
      _tipoCommittenteCtrl.text = c.tipoCommittente;
      _committenteCtrl.text = c.committente;
      _indirizzoCommCtrl.text = c.indirizzo;
      _capCommCtrl.text = c.cap;
      _cittaCommCtrl.text = c.citta;
      _provCommCtrl.text = c.provincia;
      _codiceFiscaleCtrl.text = c.pivaCodiceFiscale;
      _codiceUnivocoCtrl.text = c.codiceUnivoco;
      _referenteCtrl.text = c.referente;
    });
  }

  // ─── CAP lookup ───────────────────────────────────────────────────────────

  Future<void> _onCapChanged(String valore) async {
    final solo = valore.replaceAll(RegExp(r'\D'), '');
    if (solo.length == 5) {
      final ris = await _capService.cercaPerCap(solo);
      if (ris != null && mounted) {
        setState(() {
          _cittaCommCtrl.text = ris.citta;
          _provCommCtrl.text = ris.provincia;
        });
      }
    }
  }

  // ─── Righe servizi ────────────────────────────────────────────────────────

  void _aggiungiRiga() {
    setState(() => _righeCtrl.add(_RigaController()));
  }

  void _rimuoviRiga(int i) {
    _righeCtrl[i].dispose();
    setState(() {
      _righeCtrl.removeAt(i);
      _ricalcola();
    });
  }

  void _onListinoSelezionato(int i, Map<String, dynamic> voce) {
    final r = _righeCtrl[i];
    final prezzo = (voce['prezzoUnitario'] as num?)?.toDouble() ?? 0.0;
    r.descrizioneCtrl.text = voce['descrizione'] as String? ?? '';
    r.prezzoCtrl.text = prezzo.toStringAsFixed(2);
    r.codice = voce['codice'] as String? ?? '';
    _ricalcola();
  }

  // ─── Calcoli ─────────────────────────────────────────────────────────────

  void _ricalcola() {
    double arrotonda(double v) => double.parse(v.toStringAsFixed(2));
    double parseDbl(String t) =>
        double.tryParse(t.replaceAll(',', '.')) ?? 0.0;

    double imponibile = 0;
    for (final r in _righeCtrl) {
      final prezzo = parseDbl(r.prezzoCtrl.text);
      final qta = int.tryParse(r.qtaCtrl.text) ?? 0;
      final sconto = parseDbl(r.scontoCtrl.text);
      r.importo = arrotonda((prezzo - prezzo * sconto / 100) * qta);
      imponibile += r.importo;
    }
    _imponibile = arrotonda(imponibile);
    _importoIva = arrotonda(_imponibile * _percIva / 100);
    _totale = arrotonda(_imponibile + _importoIva);
    setState(() {});
  }

  // ─── Salvataggio ─────────────────────────────────────────────────────────

  /// Costruisce il modello dai controller correnti
  PreventivoModel _costruisciModello({bool isDraft = false}) {
    double parseDbl(String t) =>
        double.tryParse(t.replaceAll(',', '.')) ?? 0.0;

    final righe = _righeCtrl
        .map((r) => PreventivoRiga(
              codice: r.codice,
              descrizione: r.descrizioneCtrl.text.trim(),
              giornata: r.giornata ?? '',
              prezzoUnitario: parseDbl(r.prezzoCtrl.text),
              quantita: int.tryParse(r.qtaCtrl.text) ?? 0,
              scontoPerc: parseDbl(r.scontoCtrl.text),
              importo: r.importo,
            ))
        .toList();

    return PreventivoModel(
      id: _preventivoIdCorrente ?? '',
      numeroPrev: _numeroPrev ?? 0,
      data: _dataPrev,
      codiceCliente: _codiceClienteId,
      tipoCommittente: _tipoCommittenteCtrl.text.trim(),
      committente: _committenteCtrl.text.trim(),
      indirizzoCommittente: _indirizzoCommCtrl.text.trim(),
      cap: _capCommCtrl.text.trim(),
      citta: _cittaCommCtrl.text.trim(),
      provincia: _provCommCtrl.text.trim(),
      codiceFiscale: _codiceFiscaleCtrl.text.trim(),
      codiceUnivoco: _codiceUnivocoCtrl.text.trim(),
      referente: _referenteCtrl.text.trim(),
      righe: righe,
      validita: _validita ?? '',
      modalitaPagamento: _modalitaPagamento ?? '',
      rinnovo: _rinnovo ?? '',
      percIva: _percIva,
      imponibile: _imponibile,
      importoIva: _importoIva,
      totale: _totale,
      note: _noteCtrl.text.trim(),
      isDraft: isDraft,
      createdAt: _preventivoOriginale?.createdAt ?? DateTime.now(),
    );
  }

  Map<String, Object?> _snapshotCorrente() {
    final m = _costruisciModello(
        isDraft: _preventivoOriginale?.isDraft ?? false);
    return {
      'codiceCliente': m.codiceCliente,
      'data': m.data.toIso8601String(),
      'committente': m.committente,
      'indirizzoCommittente': m.indirizzoCommittente,
      'cap': m.cap,
      'citta': m.citta,
      'provincia': m.provincia,
      'codiceFiscale': m.codiceFiscale,
      'codiceUnivoco': m.codiceUnivoco,
      'referente': m.referente,
      'righe': m.righe.map((r) => r.toMap().toString()).join('|'),
      'validita': m.validita,
      'modalitaPagamento': m.modalitaPagamento,
      'rinnovo': m.rinnovo,
      'percIva': m.percIva,
      'note': m.note,
    };
  }

  bool get _hasUnsavedChanges {
    final iniziale = _snapshotIniziale;
    if (iniziale == null) return false;
    return iniziale.toString() != _snapshotCorrente().toString();
  }

  bool get _canSaveAsDraft =>
      _preventivoIdCorrente == null ||
      (_preventivoOriginale?.isDraft ?? false);

  Future<void> _chiudiPagina() async {
    if (!mounted) return;
    setState(() => _allowDirectPop = true);
    context.pop();
  }

  Future<void> _persistiPreventivo({
    required bool isDraft,
    required bool closeAfterSave,
    bool validate = true,
  }) async {
    if (validate && !(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    try {
      // Genera numeroPrev solo al primo salvataggio definitivo (non bozza)
      if (_numeroPrev == null && !isDraft) {
        _numeroPrev =
            await _preventiviService.generaNumeroPrev(_dataPrev);
      }

      final modello = _costruisciModello(isDraft: isDraft);
      final id = await _preventiviService.salvaPreventivo(modello);
      _preventivoIdCorrente = id;
      _preventivoOriginale = modello.id.isEmpty
          ? PreventivoModel(
              id: id,
              numeroPrev: modello.numeroPrev,
              data: modello.data,
              codiceCliente: modello.codiceCliente,
              tipoCommittente: modello.tipoCommittente,
              committente: modello.committente,
              indirizzoCommittente: modello.indirizzoCommittente,
              cap: modello.cap,
              citta: modello.citta,
              provincia: modello.provincia,
              codiceFiscale: modello.codiceFiscale,
              codiceUnivoco: modello.codiceUnivoco,
              referente: modello.referente,
              righe: modello.righe,
              validita: modello.validita,
              modalitaPagamento: modello.modalitaPagamento,
              rinnovo: modello.rinnovo,
              percIva: modello.percIva,
              imponibile: modello.imponibile,
              importoIva: modello.importoIva,
              totale: modello.totale,
              note: modello.note,
              isDraft: modello.isDraft,
              createdAt: modello.createdAt,
            )
          : modello;
      _snapshotIniziale = _snapshotCorrente();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                isDraft ? 'Preventivo salvato come bozza' : 'Preventivo salvato'),
            backgroundColor:
                isDraft ? AppColors.textSecondary : AppColors.success,
          ),
        );
        if (closeAfterSave) {
          await _chiudiPagina();
        } else {
          setState(() {});
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore durante il salvataggio: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _salva() async {
    await _persistiPreventivo(isDraft: false, closeAfterSave: false);
  }

  Future<void> _esci() async {
    if (!_hasUnsavedChanges) {
      await _chiudiPagina();
      return;
    }

    final scelta = await showDialog<_SceltaEsci>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Uscire dal form',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text(
          _canSaveAsDraft
              ? 'Vuoi salvare le modifiche prima di uscire o impostare il preventivo come bozza?'
              : 'Vuoi salvare le modifiche prima di uscire?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, _SceltaEsci.annulla),
            child: const Text('Rimani'),
          ),
          if (_canSaveAsDraft)
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, _SceltaEsci.bozza),
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary),
              child: const Text('Salva come bozza'),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, _SceltaEsci.salva),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Salva'),
          ),
        ],
      ),
    );

    if (scelta == null || scelta == _SceltaEsci.annulla) return;

    await _persistiPreventivo(
      isDraft: scelta == _SceltaEsci.bozza,
      closeAfterSave: true,
      validate: scelta == _SceltaEsci.salva,
    );
  }

  Future<void> _gestisciBackNavigation() async {
    if (_isSaving) return;
    await _esci();
  }

  // ─── Generazione PDF ─────────────────────────────────────────────────────

  Future<void> _generaPdf() async {
    if (_preventivoIdCorrente == null) return;
    setState(() => _isGeneratingPdf = true);
    try {
      // Usa il modello corrente (anche non salvato) se coincide con quello originale,
      // altrimenti avvisa di salvare prima
      if (_hasUnsavedChanges) {
        if (!mounted) return;
        final conferma = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Modifiche non salvate'),
            content: const Text(
                'Ci sono modifiche non salvate. Il PDF verrà generato con i dati salvati in precedenza.\n\nProcedere?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annulla'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary),
                child: const Text('Genera PDF'),
              ),
            ],
          ),
        );
        if (conferma != true || !mounted) return;
      }
      final modello = _preventivoOriginale;
      if (modello == null) return;
      await _pdfService.stampaPreventivo(modello);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore generazione PDF: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  Future<void> _elimina() async {
    if (_preventivoIdCorrente == null) return;

    final conferma = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina preventivo'),
        content: Text(
          'Eliminare il preventivo di ${_committenteCtrl.text.trim()}? '
          'L\'azione è irreversibile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (conferma != true || !mounted) return;

    try {
      await _preventiviService.eliminaPreventivo(_preventivoIdCorrente!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preventivo eliminato')),
        );
        await _chiudiPagina();
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
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final titolo = _preventivoIdCorrente == null
        ? 'Nuovo preventivo'
        : 'Modifica preventivo';

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

    return PopScope(
      canPop: _allowDirectPop,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _gestisciBackNavigation();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(titolo),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _gestisciBackNavigation,
          ),
          actions: [
            // Bottone PDF — visibile solo su preventivi già salvati
            if (!_isLoading && _preventivoIdCorrente != null) ...[
              _isGeneratingPdf
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: AppColors.primary, strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.picture_as_pdf_outlined,
                          color: AppColors.primary),
                      tooltip: 'Genera PDF',
                      onPressed: _isSaving ? null : _generaPdf,
                    ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                tooltip: 'Elimina preventivo',
                onPressed: _isSaving ? null : _elimina,
              ),
            ],
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : _erroreCaricamento != null
                ? Center(
                    child: Text('Errore: $_erroreCaricamento',
                        style: const TextStyle(color: AppColors.error)))
                : Column(
                    children: [
                      Expanded(
                        child: LayoutBuilder(
                          builder: (ctx, constraints) {
                            final isDesktop = constraints.maxWidth >= 600;
                            return Form(
                              key: _formKey,
                              child: SingleChildScrollView(
                                padding:
                                    EdgeInsets.all(isDesktop ? 24 : 16),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _buildGruppo1(isDesktop),
                                    const SizedBox(height: 16),
                                    _buildGruppo2(isDesktop),
                                    const SizedBox(height: 16),
                                    _buildGruppo3(isDesktop),
                                    const SizedBox(height: 16),
                                    _buildGruppo4(isDesktop),
                                    const SizedBox(height: 16),
                                    _buildGruppo5(isDesktop),
                                    const SizedBox(height: 16),
                                    _buildGruppo6(isDesktop),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      _buildBottoni(),
                    ],
                  ),
      ),
    );
  }

  // ─── Gruppo 1 — Identificazione ──────────────────────────────────────────

  Widget _buildGruppo1(bool isDesktop) {
    // Numero preventivo: "Auto" in creazione, formattato in modifica
    final numeroTesto = _numeroPrev == null
        ? 'Auto'
        : 'PREV-${_dataPrev.year}-${_numeroPrev.toString().padLeft(3, '0')}';

    return _buildGruppoCard(
      titolo: 'Identificazione',
      isDesktop: isDesktop,
      children: [
        _buildRiga(isDesktop, [
          // Numero preventivo (readonly)
          TextFormField(
            initialValue: numeroTesto,
            readOnly: true,
            decoration: _dec('N° preventivo').copyWith(
              filled: true,
              fillColor: AppColors.inputBackground,
              suffixIcon: const Icon(Icons.lock_outline,
                  size: 16, color: AppColors.textDisabled),
            ),
          ),
          // Data con date picker
          GestureDetector(
            onTap: _selezionaData,
            child: AbsorbPointer(
              child: TextFormField(
                controller: _dataCtrl,
                decoration: _dec('Data').copyWith(
                  suffixIcon: const Icon(Icons.calendar_today_outlined,
                      size: 18, color: AppColors.textDisabled),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Campo obbligatorio' : null,
              ),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        // Autocomplete cliente
        _buildAutocompleteCliente(),
      ],
    );
  }

  // ─── Gruppo 2 — Dati cliente ──────────────────────────────────────────────

  Widget _buildGruppo2(bool isDesktop) {
    return _buildGruppoCard(
      titolo: 'Dati cliente',
      isDesktop: isDesktop,
      children: [
        _buildRiga(isDesktop, [
          TextFormField(
            controller: _tipoCommittenteCtrl,
            decoration: _dec('Tipo committente'),
          ),
          TextFormField(
            controller: _committenteCtrl,
            decoration: _dec('Committente'),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Campo obbligatorio' : null,
          ),
        ]),
        const SizedBox(height: 12),
        TextFormField(
          controller: _indirizzoCommCtrl,
          decoration: _dec('Indirizzo'),
        ),
        const SizedBox(height: 12),
        _buildRiga(isDesktop, [
          TextFormField(
            controller: _capCommCtrl,
            decoration: _dec('CAP'),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(5),
            ],
            onChanged: _onCapChanged,
          ),
          TextFormField(
            controller: _cittaCommCtrl,
            decoration: _dec('Città'),
          ),
          TextFormField(
            controller: _provCommCtrl,
            decoration: _dec('Provincia'),
            inputFormatters: [
              LengthLimitingTextInputFormatter(2),
              UpperCaseTextFormatter(),
            ],
          ),
        ]),
        const SizedBox(height: 12),
        _buildRiga(isDesktop, [
          TextFormField(
            controller: _codiceFiscaleCtrl,
            decoration: _dec('C.F. / P.IVA'),
          ),
          TextFormField(
            controller: _codiceUnivocoCtrl,
            decoration: _dec('Codice univoco'),
          ),
          TextFormField(
            controller: _referenteCtrl,
            decoration: _dec('Referente'),
          ),
        ]),
      ],
    );
  }

  // ─── Gruppo 3 — Righe servizi ─────────────────────────────────────────────

  Widget _buildGruppo3(bool isDesktop) {
    return _buildGruppoCard(
      titolo: 'Righe servizi',
      isDesktop: isDesktop,
      children: [
        if (_righeCtrl.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Nessun servizio aggiunto',
                style: TextStyle(color: AppColors.textDisabled),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _righeCtrl.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 24, color: AppColors.divider),
            itemBuilder: (_, i) => _buildRigaServizio(i, isDesktop),
          ),
        const SizedBox(height: 12),
        // Bottone aggiungi riga
        OutlinedButton.icon(
          onPressed: _aggiungiRiga,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Aggiungi servizio'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildRigaServizio(int i, bool isDesktop) {
    final r = _righeCtrl[i];
    // Dropdown listino: mostra descrizione + codice
    final opzioniListino = _vociListino;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Intestazione riga con numero e tasto rimuovi
        Row(
          children: [
            Text(
              'Servizio ${i + 1}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.primary,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline,
                  color: AppColors.error, size: 20),
              tooltip: 'Rimuovi servizio',
              onPressed: () => _rimuoviRiga(i),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Dropdown listino → auto-compila codice, descrizione, prezzo
        DropdownButtonFormField<int>(
          initialValue: null,
          decoration: _dec('Seleziona dal listino (opzionale)'),
          items: opzioniListino.asMap().entries.map((e) {
            final v = e.value;
            return DropdownMenuItem<int>(
              value: e.key,
              child: Text(
                '${v['codice'] ?? ''} — ${v['descrizione'] ?? ''}',
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (idx) {
            if (idx != null) _onListinoSelezionato(i, opzioniListino[idx]);
          },
        ),
        const SizedBox(height: 10),
        // Descrizione (testo libero, pre-compilato dal listino)
        TextFormField(
          controller: r.descrizioneCtrl,
          decoration: _dec('Descrizione servizio'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        // Riga: giornata + prezzo + qta + sconto + importo
        _buildRiga(isDesktop, [
          CategoriaDropdown(
            categoriaId: 'preventivo_giornata',
            label: 'Giornata',
            initialValue: r.giornata,
            onChanged: (v) => setState(() => r.giornata = v),
          ),
          _buildCampoNumerico('Prezzo unitario (€)', r.prezzoCtrl),
          _buildCampoNumerico('Quantità', r.qtaCtrl, intero: true),
          _buildCampoNumerico('Sconto %', r.scontoCtrl),
        ]),
        const SizedBox(height: 10),
        // Importo calcolato
        _buildCampoCalcolato('Importo riga', r.importo, highlight: true),
      ],
    );
  }

  // ─── Gruppo 4 — Condizioni ────────────────────────────────────────────────

  Widget _buildGruppo4(bool isDesktop) {
    return _buildGruppoCard(
      titolo: 'Condizioni',
      isDesktop: isDesktop,
      children: [
        _buildRiga(isDesktop, [
          CategoriaDropdown(
            categoriaId: 'preventivo_validita',
            label: 'Validità offerta',
            initialValue: _validita,
            onChanged: (v) => setState(() => _validita = v),
          ),
          CategoriaDropdown(
            categoriaId: 'preventivo_pagamento',
            label: 'Modalità di pagamento',
            initialValue: _modalitaPagamento,
            onChanged: (v) => setState(() => _modalitaPagamento = v),
          ),
          CategoriaDropdown(
            categoriaId: 'preventivo_rinnovo',
            label: 'Rinnovo automatico',
            initialValue: _rinnovo,
            onChanged: (v) => setState(() => _rinnovo = v),
          ),
        ]),
      ],
    );
  }

  // ─── Gruppo 5 — Totali ────────────────────────────────────────────────────

  Widget _buildGruppo5(bool isDesktop) {
    return _buildGruppoCard(
      titolo: 'Totali',
      isDesktop: isDesktop,
      children: [
        // Aliquota IVA
        SizedBox(
          width: isDesktop ? 200 : double.infinity,
          child: DropdownButtonFormField<double>(
            initialValue: _percIva,
            decoration: _dec('Aliquota IVA'),
            items: const [
              DropdownMenuItem(value: 4.0, child: Text('IVA 4%')),
              DropdownMenuItem(value: 10.0, child: Text('IVA 10%')),
              DropdownMenuItem(value: 22.0, child: Text('IVA 22%')),
            ],
            onChanged: (v) {
              if (v != null) {
                _percIva = v;
                _ricalcola();
              }
            },
          ),
        ),
        const SizedBox(height: 16),
        // Riepilogo imponibile / IVA / totale
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryLightest,
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Riepilogo importi',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                      child: _buildVoceTotale('Imponibile', _imponibile)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildVoceTotale(
                          'IVA ${_percIva.toStringAsFixed(0)}%', _importoIva)),
                ],
              ),
              const SizedBox(height: 16),
              // Totale in evidenza
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTALE',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.textOnPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      _moneyFmt.format(_totale),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: AppColors.textOnPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Gruppo 6 — Note ─────────────────────────────────────────────────────

  Widget _buildGruppo6(bool isDesktop) {
    return _buildGruppoCard(
      titolo: 'Note',
      isDesktop: isDesktop,
      children: [
        TextFormField(
          controller: _noteCtrl,
          maxLines: 4,
          decoration: _dec('Note aggiuntive'),
        ),
      ],
    );
  }

  // ─── Bottoni ─────────────────────────────────────────────────────────────

  Widget _buildBottoni() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
        color: AppColors.surface,
      ),
      child: Row(
        children: [
          OutlinedButton(
            onPressed: _isSaving ? null : _chiudiPagina,
            child: const Text('Annulla'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: _isSaving ? null : _esci,
              style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary),
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: AppColors.textSecondary, strokeWidth: 2))
                  : const Text('Esci'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: _isSaving ? null : _salva,
              style:
                  FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: AppColors.surface, strokeWidth: 2))
                  : const Text('Salva'),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Widget riutilizzabili ────────────────────────────────────────────────

  /// Card gruppo con ExpansionTile
  Widget _buildGruppoCard({
    required String titolo,
    required bool isDesktop,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.divider),
      ),
      color: AppColors.surface,
      child: ExpansionTile(
        initiallyExpanded: isDesktop,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        collapsedShape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          titolo,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
        ),
        children: [
          const Divider(height: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  /// Riga affiancata su desktop, colonna su mobile
  Widget _buildRiga(bool isDesktop, List<Widget> fields) {
    if (!isDesktop || fields.length == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: fields
            .asMap()
            .entries
            .map((e) => Padding(
                  padding:
                      EdgeInsets.only(bottom: e.key < fields.length - 1 ? 12 : 0),
                  child: e.value,
                ))
            .toList(),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: fields
          .asMap()
          .entries
          .expand((e) => [
                if (e.key > 0) const SizedBox(width: 12),
                Expanded(child: e.value),
              ])
          .toList(),
    );
  }

  /// Campo numerico con onChanged che ricalcola
  Widget _buildCampoNumerico(
    String label,
    TextEditingController ctrl, {
    bool intero = false,
  }) {
    return TextFormField(
      controller: ctrl,
      decoration: _dec(label),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: intero
          ? [FilteringTextInputFormatter.digitsOnly]
          : [FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))],
      onChanged: (_) => _ricalcola(),
    );
  }

  /// Campo calcolato read-only con sfondo colorato
  Widget _buildCampoCalcolato(String label, double valore,
      {bool highlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color:
                highlight ? AppColors.primaryLight : AppColors.inputBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: highlight ? AppColors.primary : AppColors.divider,
            ),
          ),
          child: Text(
            _moneyFmt.format(valore),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: highlight ? AppColors.primaryDark : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVoceTotale(String label, double valore) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(
          _moneyFmt.format(valore),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AppColors.primaryDark,
          ),
        ),
      ],
    );
  }

  /// Autocomplete cliente
  Widget _buildAutocompleteCliente() {
    return Autocomplete<ClienteModel>(
      optionsBuilder: (TextEditingValue valore) {
        if (valore.text.isEmpty) return const Iterable<ClienteModel>.empty();
        final q = valore.text.toLowerCase();
        return _clienti.where((c) =>
            c.committente.toLowerCase().contains(q) ||
            c.numeroFormattato.toLowerCase().contains(q));
      },
      displayStringForOption: (c) =>
          '${c.numeroFormattato} — ${c.committente}',
      fieldViewBuilder: (ctx, ctrl, focusNode, onSubmit) {
        if (_clienteDisplayCtrl.text.isNotEmpty &&
            ctrl.text != _clienteDisplayCtrl.text) {
          ctrl.text = _clienteDisplayCtrl.text;
        }
        return TextFormField(
          controller: ctrl,
          focusNode: focusNode,
          decoration:
              _dec('Cliente — ricerca per nome o numero'),
          onFieldSubmitted: (_) => onSubmit(),
        );
      },
      onSelected: _onClienteSelezionato,
      optionsViewBuilder: (ctx, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: min(500, MediaQuery.of(ctx).size.width - 32),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: options.length,
                itemBuilder: (ctx, i) {
                  final c = options.elementAt(i);
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        c.initials,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    title: Text(c.committente,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    subtitle: Text(c.numeroFormattato,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary)),
                    onTap: () => onSelected(c),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
}

// ─── Controller per singola riga servizio ─────────────────────────────────────

/// Raggruppa i controller e lo stato di una riga del preventivo.
class _RigaController {
  String codice;
  String? giornata;
  double importo;

  final TextEditingController descrizioneCtrl;
  final TextEditingController prezzoCtrl;
  final TextEditingController qtaCtrl;
  final TextEditingController scontoCtrl;

  _RigaController({
    this.codice = '',
    this.giornata,
    this.importo = 0.0,
    String descrizione = '',
    String prezzo = '0',
    String qta = '1',
    String sconto = '0',
  })  : descrizioneCtrl = TextEditingController(text: descrizione),
        prezzoCtrl = TextEditingController(text: prezzo),
        qtaCtrl = TextEditingController(text: qta),
        scontoCtrl = TextEditingController(text: sconto);

  factory _RigaController.fromRiga(PreventivoRiga r) => _RigaController(
        codice: r.codice,
        giornata: r.giornata.isNotEmpty ? r.giornata : null,
        importo: r.importo,
        descrizione: r.descrizione,
        prezzo: r.prezzoUnitario.toStringAsFixed(2),
        qta: r.quantita.toString(),
        sconto: r.scontoPerc.toStringAsFixed(2),
      );

  void dispose() {
    descrizioneCtrl.dispose();
    prezzoCtrl.dispose();
    qtaCtrl.dispose();
    scontoCtrl.dispose();
  }
}

// ─── Helper: formattatore maiuscole ──────────────────────────────────────────

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

enum _SceltaEsci { annulla, bozza, salva }
