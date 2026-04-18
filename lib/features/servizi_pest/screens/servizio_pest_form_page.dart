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
import '../../../models/servizio_pest_model.dart';
import '../../../services/cap_service.dart';
import '../../../services/clienti_service.dart';
import '../../../services/servizi_pest_service.dart';
import '../../../widgets/categoria_dropdown.dart';

/// Form per la creazione e modifica di un servizio Pest
///
/// Parametri:
/// - [servizioId] null → modalità creazione, stringa → modalità modifica
///
/// Accessibile SOLO agli utenti con role == 'admin' (protezione nel router).
class ServizioPestFormPage extends ConsumerStatefulWidget {
  final String? servizioId;
  const ServizioPestFormPage({super.key, this.servizioId});

  @override
  ConsumerState<ServizioPestFormPage> createState() =>
      _ServizioPestFormPageState();
}

class _ServizioPestFormPageState
    extends ConsumerState<ServizioPestFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final ServiziPestService _serviziPestService;
  late final ClientiService _clientiService;
  late final CapService _capService;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _erroreCaricamento;
  String? _servizioIdCorrente;
  bool _allowDirectPop = false;
  Map<String, Object?>? _snapshotIniziale;

  // Servizio originale (null = modalità creazione)
  ServizioPestModel? _servizioOriginale;

  // ─── Stato form ────────────────────────────────────────────────────────────

  // Lista clienti per la ricerca
  List<ClienteModel> _clienti = [];

  // Gruppo 1 — Identificazione intervento
  final _clienteDisplayCtrl = TextEditingController();
  String _codiceClienteId = '';
  String? _tipoIntervento;
  String? _numeroIntervento;
  final _codiceDataCtrl = TextEditingController(); // sola lettura
  final _oraCtrl = TextEditingController();
  String? _tecnico;

  // Gruppo 2 — Dati cliente
  final _tipoCommittenteCtrl = TextEditingController();
  final _committenteCtrl = TextEditingController();
  final _indirizzoCommCtrl = TextEditingController();
  final _capCommCtrl = TextEditingController();
  final _cittaCommCtrl = TextEditingController();
  final _provCommCtrl = TextEditingController();
  final _codiceFiscaleCtrl = TextEditingController();
  final _codiceUnivocoCtrl = TextEditingController();
  final _referenteCtrl = TextEditingController();

  // Gruppo 3 — Dati intervento
  final _indirizzoIntervCtrl = TextEditingController();
  final _capCittaProvIntervCtrl = TextEditingController();
  String? _prodotti;
  final _noteAreeCtrl = TextEditingController();
  final _noteAzioniCtrl = TextEditingController();

  // Gruppo 4 — Ulteriori interventi
  String? _ulterioriInterventi;
  DateTime? _dataUlteriore;
  final _dataUlterioreCtrl = TextEditingController();
  final _codiceDataUltCtrl = TextEditingController(); // sola lettura
  final _oraUltCtrl = TextEditingController();
  final _noteAzioniUltCtrl = TextEditingController();

  // Gruppo 5 — Voci economiche
  String? _voceA;
  final _costoACtrl = TextEditingController(text: '0');
  final _nIntervACtrl = TextEditingController(text: '0');
  final _scontoACtrl = TextEditingController(text: '0');
  final _ritenutaACtrl = TextEditingController(text: '0');

  String? _voceB;
  final _costoBCtrl = TextEditingController(text: '0');
  final _nIntervBCtrl = TextEditingController(text: '0');
  final _scontoBCtrl = TextEditingController(text: '0');
  final _ritenutaBCtrl = TextEditingController(text: '0');

  String? _voceC;
  final _costoCCtrl = TextEditingController(text: '0');
  final _nIntervCCtrl = TextEditingController(text: '0');
  final _scontoCCtrl = TextEditingController(text: '0');
  final _ritenutaCCtrl = TextEditingController(text: '0');

  // Campi calcolati (aggiornati da _ricalcola())
  double _parzialeA = 0, _ivaA = 0, _valRitenutaA = 0, _totA = 0;
  double _parzialeB = 0, _ivaB = 0, _valRitenutaB = 0, _totB = 0;
  double _parzialeC = 0, _ivaC = 0, _valRitenutaC = 0, _totC = 0;
  double _parzialeTot = 0, _ivaTot = 0, _ritenute = 0, _totaleDovuto = 0;

  // Gruppo 6 — Amministrativo
  final _ulterioriNoteCtrl = TextEditingController();
  final _contattiCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  final _formatter = DateFormat('dd/MM/yyyy');
  final _moneyFmt =
      NumberFormat.currency(locale: 'it_IT', symbol: '€', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _servizioIdCorrente = widget.servizioId;
    _serviziPestService = ref.read(serviziPestServiceProvider);
    _clientiService = ref.read(clientiServiceProvider);
    _capService = ref.read(capServiceProvider);
    _inizializza();
  }

  @override
  void dispose() {
    _clienteDisplayCtrl.dispose();
    _codiceDataCtrl.dispose();
    _oraCtrl.dispose();
    _tipoCommittenteCtrl.dispose();
    _committenteCtrl.dispose();
    _indirizzoCommCtrl.dispose();
    _capCommCtrl.dispose();
    _cittaCommCtrl.dispose();
    _provCommCtrl.dispose();
    _codiceFiscaleCtrl.dispose();
    _codiceUnivocoCtrl.dispose();
    _referenteCtrl.dispose();
    _indirizzoIntervCtrl.dispose();
    _capCittaProvIntervCtrl.dispose();
    _noteAreeCtrl.dispose();
    _noteAzioniCtrl.dispose();
    _dataUlterioreCtrl.dispose();
    _codiceDataUltCtrl.dispose();
    _oraUltCtrl.dispose();
    _noteAzioniUltCtrl.dispose();
    _costoACtrl.dispose();
    _nIntervACtrl.dispose();
    _scontoACtrl.dispose();
    _ritenutaACtrl.dispose();
    _costoBCtrl.dispose();
    _nIntervBCtrl.dispose();
    _scontoBCtrl.dispose();
    _ritenutaBCtrl.dispose();
    _costoCCtrl.dispose();
    _nIntervCCtrl.dispose();
    _scontoCCtrl.dispose();
    _ritenutaCCtrl.dispose();
    _ulterioriNoteCtrl.dispose();
    _contattiCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  // ─── Inizializzazione ──────────────────────────────────────────────────────

  Future<void> _inizializza() async {
    try {
      // Carica lista clienti per l'autocomplete
      _clienti = await _clientiService.getClienti().first;

      if (widget.servizioId != null) {
        // Modalità modifica: carica i dati esistenti
        final s = await _serviziPestService
            .getServizioPestById(widget.servizioId!);
        if (s != null) {
          _servizioOriginale = s;
          _popolaDaModello(s);
        }
      } else {
        // Modalità creazione: auto-genera codiceData e precompila ora
        _codiceDataCtrl.text =
            await _serviziPestService.generaCodiceData(DateTime.now());
        final now = TimeOfDay.now();
        _oraCtrl.text =
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      _erroreCaricamento = e.toString();
    } finally {
      if (mounted) {
        _snapshotIniziale = _snapshotCorrente();
        setState(() => _isLoading = false);
      }
    }
  }

  /// Popola tutti i controller con i dati del modello (modalità modifica)
  void _popolaDaModello(ServizioPestModel s) {
    _codiceClienteId = s.codiceCliente;
    _clienteDisplayCtrl.text = s.committente;
    _tipoIntervento = s.tipoIntervento.isNotEmpty ? s.tipoIntervento : null;
    _numeroIntervento =
        s.numeroIntervento.isNotEmpty ? s.numeroIntervento : null;
    _codiceDataCtrl.text = s.codiceData;
    _oraCtrl.text = s.ora;
    _tecnico = s.tecnico.isNotEmpty ? s.tecnico : null;

    _tipoCommittenteCtrl.text = s.tipoCommittente;
    _committenteCtrl.text = s.committente;
    _indirizzoCommCtrl.text = s.indirizzoCommittente;
    _capCommCtrl.text = s.cap;
    _cittaCommCtrl.text = s.citta;
    _provCommCtrl.text = s.provincia;
    _codiceFiscaleCtrl.text = s.codiceFiscale;
    _codiceUnivocoCtrl.text = s.codiceUnivoco;
    _referenteCtrl.text = s.referente;

    _indirizzoIntervCtrl.text = s.indirizzoIntervento;
    _capCittaProvIntervCtrl.text = s.capCittaProvIntervento;
    _prodotti = s.prodotti.isNotEmpty ? s.prodotti : null;
    _noteAreeCtrl.text = s.noteAreeIntervento;
    _noteAzioniCtrl.text = s.noteAzioniCorrettive;

    _ulterioriInterventi =
        s.ulterioriInterventi.isNotEmpty ? s.ulterioriInterventi : null;
    _codiceDataUltCtrl.text = s.codiceDataUlteriore;
    _oraUltCtrl.text = s.oraUlteriore;
    _noteAzioniUltCtrl.text = s.noteAzioniCorrettiveUlteriori;

    _voceA = s.voceA.isNotEmpty ? s.voceA : null;
    _costoACtrl.text = s.costoVoceA.toStringAsFixed(2);
    _nIntervACtrl.text = s.nInterventiA.toString();
    _scontoACtrl.text = s.scontoPercA.toStringAsFixed(2);
    _ritenutaACtrl.text = s.ritenutaPercA.toStringAsFixed(2);

    _voceB = s.voceB.isNotEmpty ? s.voceB : null;
    _costoBCtrl.text = s.costoVoceB.toStringAsFixed(2);
    _nIntervBCtrl.text = s.nInterventiB.toString();
    _scontoBCtrl.text = s.scontoPercB.toStringAsFixed(2);
    _ritenutaBCtrl.text = s.ritenutaPercB.toStringAsFixed(2);

    _voceC = s.voceC.isNotEmpty ? s.voceC : null;
    _costoCCtrl.text = s.costoVoceC.toStringAsFixed(2);
    _nIntervCCtrl.text = s.nInterventiC.toString();
    _scontoCCtrl.text = s.scontoPercC.toStringAsFixed(2);
    _ritenutaCCtrl.text = s.ritenutaPercC.toStringAsFixed(2);

    _ulterioriNoteCtrl.text = s.ulterioriNote;
    _contattiCtrl.text = s.contatti;
    _emailCtrl.text = s.email;

    // Ricalcola i valori economici dai dati caricati
    _ricalcola();
  }

  /// Auto-popola i campi del Gruppo 2 dal cliente selezionato
  void _onClienteSelezionato(ClienteModel cliente) {
    setState(() {
      _codiceClienteId = cliente.id;
      _clienteDisplayCtrl.text =
          '${cliente.numeroFormattato} — ${cliente.committente}';
      _tipoCommittenteCtrl.text = cliente.tipoCommittente;
      _committenteCtrl.text = cliente.committente;
      _indirizzoCommCtrl.text = cliente.indirizzo;
      _capCommCtrl.text = cliente.cap;
      _cittaCommCtrl.text = cliente.citta;
      _provCommCtrl.text = cliente.provincia;
      _codiceFiscaleCtrl.text = cliente.pivaCodiceFiscale;
      _codiceUnivocoCtrl.text = cliente.codiceUnivoco;
      _referenteCtrl.text = cliente.referente;
    });
  }

  // ─── Selezione data/ora ────────────────────────────────────────────────────

  Future<void> _selezionaOra(TextEditingController ctrl) async {
    final parti = ctrl.text.split(':');
    final ora = TimeOfDay(
      hour: int.tryParse(parti.isNotEmpty ? parti[0] : '0') ?? 0,
      minute: int.tryParse(parti.length > 1 ? parti[1] : '0') ?? 0,
    );
    final sel = await showTimePicker(context: context, initialTime: ora);
    if (sel != null && mounted) {
      setState(() {
        ctrl.text =
            '${sel.hour.toString().padLeft(2, '0')}:${sel.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _selezionaDataUlteriore() async {
    final sel = await showDatePicker(
      context: context,
      initialDate: _dataUlteriore ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2050),
      locale: const Locale('it'),
    );
    if (sel != null && mounted) {
      final codice = await _serviziPestService.generaCodiceData(sel);
      setState(() {
        _dataUlteriore = sel;
        _dataUlterioreCtrl.text = _formatter.format(sel);
        _codiceDataUltCtrl.text = codice;
      });
    }
  }

  // ─── CAP lookup committente ────────────────────────────────────────────────

  /// Lookup automatico CAP → città + provincia per il committente
  Future<void> _onCapCommChanged(String valore) async {
    final soloDigiti = valore.replaceAll(RegExp(r'\D'), '');
    if (soloDigiti.length == 5) {
      final risultato = await _capService.cercaPerCap(soloDigiti);
      if (risultato != null && mounted) {
        setState(() {
          _cittaCommCtrl.text = risultato.citta;
          _provCommCtrl.text = risultato.provincia;
        });
      }
    }
  }

  // ─── Calcoli economici ─────────────────────────────────────────────────────

  /// Ricalcola in tempo reale tutti i valori del Gruppo 5
  void _ricalcola() {
    double parseDbl(String t) =>
        double.tryParse(t.replaceAll(',', '.')) ?? 0.0;
    double arrotonda(double v) =>
        double.parse(v.toStringAsFixed(2));

    // Voce A
    final cA = parseDbl(_costoACtrl.text);
    final nA = int.tryParse(_nIntervACtrl.text) ?? 0;
    final sA = parseDbl(_scontoACtrl.text);
    final rA = parseDbl(_ritenutaACtrl.text);
    _parzialeA = arrotonda((cA - cA * sA / 100) * nA);
    _ivaA = arrotonda(_parzialeA * 22 / 100);
    _valRitenutaA = arrotonda(-_parzialeA * rA / 100);
    _totA = arrotonda(_parzialeA + _ivaA + _valRitenutaA);

    // Voce B
    final cB = parseDbl(_costoBCtrl.text);
    final nB = int.tryParse(_nIntervBCtrl.text) ?? 0;
    final sB = parseDbl(_scontoBCtrl.text);
    final rB = parseDbl(_ritenutaBCtrl.text);
    _parzialeB = arrotonda((cB - cB * sB / 100) * nB);
    _ivaB = arrotonda(_parzialeB * 22 / 100);
    _valRitenutaB = arrotonda(-_parzialeB * rB / 100);
    _totB = arrotonda(_parzialeB + _ivaB + _valRitenutaB);

    // Voce C
    final cC = parseDbl(_costoCCtrl.text);
    final nC = int.tryParse(_nIntervCCtrl.text) ?? 0;
    final sC = parseDbl(_scontoCCtrl.text);
    final rC = parseDbl(_ritenutaCCtrl.text);
    _parzialeC = arrotonda((cC - cC * sC / 100) * nC);
    _ivaC = arrotonda(_parzialeC * 22 / 100);
    _valRitenutaC = arrotonda(-_parzialeC * rC / 100);
    _totC = arrotonda(_parzialeC + _ivaC + _valRitenutaC);

    // Totali
    _parzialeTot = arrotonda(_parzialeA + _parzialeB + _parzialeC);
    _ivaTot = arrotonda(_ivaA + _ivaB + _ivaC);
    _ritenute = arrotonda(_valRitenutaA + _valRitenutaB + _valRitenutaC);
    _totaleDovuto = arrotonda(_totA + _totB + _totC);

    setState(() {});
  }

  // ─── Salvataggio ──────────────────────────────────────────────────────────

  /// Costruisce il modello dai controller correnti
  ServizioPestModel _costruisciModello({bool isDraft = false}) {
    return ServizioPestModel(
        id: _servizioIdCorrente ?? '',
        codiceCliente: _codiceClienteId,
        tipoIntervento: _tipoIntervento ?? '',
        numeroIntervento: _numeroIntervento ?? '',
        codiceData: _codiceDataCtrl.text.trim(),
        ora: _oraCtrl.text.trim(),
        tecnico: _tecnico ?? '',
        tipoCommittente: _tipoCommittenteCtrl.text.trim(),
        committente: _committenteCtrl.text.trim(),
        indirizzoCommittente: _indirizzoCommCtrl.text.trim(),
        cap: _capCommCtrl.text.trim(),
        citta: _cittaCommCtrl.text.trim(),
        provincia: _provCommCtrl.text.trim(),
        codiceFiscale: _codiceFiscaleCtrl.text.trim(),
        codiceUnivoco: _codiceUnivocoCtrl.text.trim(),
        referente: _referenteCtrl.text.trim(),
        indirizzoIntervento: _indirizzoIntervCtrl.text.trim(),
        capCittaProvIntervento: _capCittaProvIntervCtrl.text.trim(),
        prodotti: _prodotti ?? '',
        noteAreeIntervento: _noteAreeCtrl.text.trim(),
        noteAzioniCorrettive: _noteAzioniCtrl.text.trim(),
        ulterioriInterventi: _ulterioriInterventi ?? '',
        codiceDataUlteriore: _codiceDataUltCtrl.text.trim(),
        oraUlteriore: _oraUltCtrl.text.trim(),
        noteAzioniCorrettiveUlteriori: _noteAzioniUltCtrl.text.trim(),
        voceA: _voceA ?? '',
        costoVoceA: double.tryParse(_costoACtrl.text.replaceAll(',', '.')) ?? 0,
        nInterventiA: int.tryParse(_nIntervACtrl.text) ?? 0,
        scontoPercA: double.tryParse(_scontoACtrl.text.replaceAll(',', '.')) ?? 0,
        parzialeA: _parzialeA,
        ivaA: _ivaA,
        ritenutaPercA: double.tryParse(_ritenutaACtrl.text.replaceAll(',', '.')) ?? 0,
        valRitenutaA: _valRitenutaA,
        totA: _totA,
        voceB: _voceB ?? '',
        costoVoceB: double.tryParse(_costoBCtrl.text.replaceAll(',', '.')) ?? 0,
        nInterventiB: int.tryParse(_nIntervBCtrl.text) ?? 0,
        scontoPercB: double.tryParse(_scontoBCtrl.text.replaceAll(',', '.')) ?? 0,
        parzialeB: _parzialeB,
        ivaB: _ivaB,
        ritenutaPercB: double.tryParse(_ritenutaBCtrl.text.replaceAll(',', '.')) ?? 0,
        valRitenutaB: _valRitenutaB,
        totB: _totB,
        voceC: _voceC ?? '',
        costoVoceC: double.tryParse(_costoCCtrl.text.replaceAll(',', '.')) ?? 0,
        nInterventiC: int.tryParse(_nIntervCCtrl.text) ?? 0,
        scontoPercC: double.tryParse(_scontoCCtrl.text.replaceAll(',', '.')) ?? 0,
        parzialeC: _parzialeC,
        ivaC: _ivaC,
        ritenutaPercC: double.tryParse(_ritenutaCCtrl.text.replaceAll(',', '.')) ?? 0,
        valRitenutaC: _valRitenutaC,
        totC: _totC,
        parzialeTot: _parzialeTot,
        ivaTot: _ivaTot,
        ritenute: _ritenute,
        totaleDovuto: _totaleDovuto,
        ulterioriNote: _ulterioriNoteCtrl.text.trim(),
        contatti: _contattiCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        isDraft: isDraft,
        createdAt: _servizioOriginale?.createdAt ?? DateTime.now());
  }

  Map<String, Object?> _snapshotCorrente() {
    final modello = _costruisciModello(
      isDraft: _servizioOriginale?.isDraft ?? false,
    );
    return {
      'codiceCliente': modello.codiceCliente,
      'tipoIntervento': modello.tipoIntervento,
      'numeroIntervento': modello.numeroIntervento,
      'codiceData': modello.codiceData,
      'ora': modello.ora,
      'tecnico': modello.tecnico,
      'tipoCommittente': modello.tipoCommittente,
      'committente': modello.committente,
      'indirizzoCommittente': modello.indirizzoCommittente,
      'cap': modello.cap,
      'citta': modello.citta,
      'provincia': modello.provincia,
      'codiceFiscale': modello.codiceFiscale,
      'codiceUnivoco': modello.codiceUnivoco,
      'referente': modello.referente,
      'indirizzoIntervento': modello.indirizzoIntervento,
      'capCittaProvIntervento': modello.capCittaProvIntervento,
      'prodotti': modello.prodotti,
      'noteAreeIntervento': modello.noteAreeIntervento,
      'noteAzioniCorrettive': modello.noteAzioniCorrettive,
      'ulterioriInterventi': modello.ulterioriInterventi,
      'codiceDataUlteriore': modello.codiceDataUlteriore,
      'oraUlteriore': modello.oraUlteriore,
      'noteAzioniCorrettiveUlteriori':
          modello.noteAzioniCorrettiveUlteriori,
      'voceA': modello.voceA,
      'costoVoceA': modello.costoVoceA,
      'nInterventiA': modello.nInterventiA,
      'scontoPercA': modello.scontoPercA,
      'ritenutaPercA': modello.ritenutaPercA,
      'voceB': modello.voceB,
      'costoVoceB': modello.costoVoceB,
      'nInterventiB': modello.nInterventiB,
      'scontoPercB': modello.scontoPercB,
      'ritenutaPercB': modello.ritenutaPercB,
      'voceC': modello.voceC,
      'costoVoceC': modello.costoVoceC,
      'nInterventiC': modello.nInterventiC,
      'scontoPercC': modello.scontoPercC,
      'ritenutaPercC': modello.ritenutaPercC,
      'ulterioriNote': modello.ulterioriNote,
      'contatti': modello.contatti,
      'email': modello.email,
    };
  }

  bool get _hasUnsavedChanges {
    final iniziale = _snapshotIniziale;
    if (iniziale == null) return false;
    return iniziale.toString() != _snapshotCorrente().toString();
  }

  bool get _canSaveAsDraft =>
      _servizioIdCorrente == null || (_servizioOriginale?.isDraft ?? false);

  Future<void> _chiudiPagina() async {
    if (!mounted) return;
    setState(() => _allowDirectPop = true);
    context.pop();
  }

  Future<void> _persistiServizio({
    required bool isDraft,
    required bool closeAfterSave,
    bool validate = true,
  }) async {
    if (validate && !(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    try {
      final modello = _costruisciModello(isDraft: isDraft);
      final servizioId =
          await _serviziPestService.salvaServizioPest(modello);
      _servizioIdCorrente = servizioId;
      _servizioOriginale = modello;
      _snapshotIniziale = _snapshotCorrente();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isDraft
                ? 'Intervento Pest salvato come bozza'
                : 'Intervento Pest salvato'),
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
    await _persistiServizio(
      isDraft: false,
      closeAfterSave: false,
    );
  }

  Future<void> _esci() async {
    if (!_hasUnsavedChanges) {
      await _chiudiPagina();
      return;
    }

    final scelta = await showDialog<_SceltaEsci>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Uscire dal form',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text(
          _canSaveAsDraft
              ? 'Vuoi salvare le modifiche prima di uscire o impostare l\'intervento come bozza?'
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
                foregroundColor: AppColors.textSecondary,
              ),
              child: const Text('Salva come bozza'),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, _SceltaEsci.salva),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Salva'),
          ),
        ],
      ),
    );

    if (scelta == null || scelta == _SceltaEsci.annulla) return;

    await _persistiServizio(
      isDraft: scelta == _SceltaEsci.bozza,
      closeAfterSave: true,
      validate: scelta == _SceltaEsci.salva,
    );
  }

  Future<void> _gestisciBackNavigation() async {
    if (_isSaving) return;
    await _esci();
  }

  Future<void> _elimina() async {
    if (_servizioIdCorrente == null) return;

    final conferma = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina intervento'),
        content: Text(
          'Eliminare l\'intervento ${_committenteCtrl.text.trim()}? L\'azione è irreversibile.',
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
      await _serviziPestService.eliminaServizioPest(_servizioIdCorrente!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Intervento eliminato')),
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
    final titolo = _servizioIdCorrente == null
        ? 'Nuovo intervento Pest'
        : 'Modifica intervento Pest';

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
          child: Text(
            'Accesso non autorizzato',
            style: TextStyle(color: AppColors.error),
          ),
        ),
      );
    }

    return PopScope(
      canPop: _allowDirectPop,
      onPopInvoked: (didPop) async {
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
            if (!_isLoading && _servizioIdCorrente != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                tooltip: 'Elimina intervento',
                onPressed: _isSaving ? null : _elimina,
              ),
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
                                padding: EdgeInsets.all(isDesktop ? 24 : 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
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

  // ─── Gruppo 1 — Identificazione intervento ────────────────────────────────

  Widget _buildGruppo1(bool isDesktop) {
    return _buildGruppoCard(
      titolo: 'Identificazione intervento',
      isDesktop: isDesktop,
      children: [
        // Campo cliente con autocomplete
        _buildAutocompleteCliente(),
        const SizedBox(height: 12),
        // Riga: Tipo intervento + N° intervento
        _buildRiga(isDesktop, [
          CategoriaDropdown(
            categoriaId: 'pest_tipi_intervento',
            label: 'Tipo intervento',
            initialValue: _tipoIntervento,
            onChanged: (v) => setState(() => _tipoIntervento = v),
          ),
          CategoriaDropdown(
            categoriaId: 'pest_numero_intervento',
            label: 'N° intervento',
            initialValue: _numeroIntervento,
            onChanged: (v) => setState(() => _numeroIntervento = v),
          ),
        ]),
        const SizedBox(height: 12),
        // Riga: Codice data (readonly) + Ora + Tecnico
        _buildRiga(isDesktop, [
          TextFormField(
            controller: _codiceDataCtrl,
            readOnly: true,
            decoration: _dec('Codice data (AAMMGG)').copyWith(
              filled: true,
              fillColor: AppColors.inputBackground,
              suffixIcon: const Icon(Icons.lock_outline,
                  size: 16, color: AppColors.textDisabled),
            ),
          ),
          GestureDetector(
            onTap: () => _selezionaOra(_oraCtrl),
            child: AbsorbPointer(
              child: TextFormField(
                controller: _oraCtrl,
                decoration: _dec('Ora').copyWith(
                  suffixIcon: const Icon(Icons.access_time,
                      size: 18, color: AppColors.textDisabled),
                ),
              ),
            ),
          ),
          CategoriaDropdown(
            categoriaId: 'pest_tecnici',
            label: 'Tecnico',
            initialValue: _tecnico,
            onChanged: (v) => setState(() => _tecnico = v),
          ),
        ]),
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
          ),
        ]),
        const SizedBox(height: 12),
        TextFormField(
          controller: _indirizzoCommCtrl,
          decoration: _dec('Indirizzo committente'),
        ),
        const SizedBox(height: 12),
        _buildRiga(isDesktop, [
          // CAP con lookup automatico
          TextFormField(
            controller: _capCommCtrl,
            decoration: _dec('CAP'),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(5),
            ],
            onChanged: _onCapCommChanged,
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

  // ─── Gruppo 3 — Dati intervento ───────────────────────────────────────────

  Widget _buildGruppo3(bool isDesktop) {
    return _buildGruppoCard(
      titolo: 'Dati intervento',
      isDesktop: isDesktop,
      children: [
        _buildRiga(isDesktop, [
          TextFormField(
            controller: _indirizzoIntervCtrl,
            decoration: _dec('Indirizzo intervento'),
          ),
          TextFormField(
            controller: _capCittaProvIntervCtrl,
            decoration: _dec('CAP / Città / Provincia intervento'),
          ),
        ]),
        const SizedBox(height: 12),
        CategoriaDropdown(
          categoriaId: 'pest_prodotti',
          label: 'Prodotti',
          initialValue: _prodotti,
          onChanged: (v) => setState(() => _prodotti = v),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _noteAreeCtrl,
          maxLines: 3,
          decoration: _dec('Note aree intervento'),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _noteAzioniCtrl,
          maxLines: 3,
          decoration: _dec('Note azioni correttive'),
        ),
      ],
    );
  }

  // ─── Gruppo 4 — Ulteriori interventi ─────────────────────────────────────

  Widget _buildGruppo4(bool isDesktop) {
    return _buildGruppoCard(
      titolo: 'Ulteriori interventi',
      isDesktop: isDesktop,
      children: [
        CategoriaDropdown(
          categoriaId: 'pest_ulteriori_interventi',
          label: 'Ulteriori interventi',
          initialValue: _ulterioriInterventi,
          onChanged: (v) => setState(() => _ulterioriInterventi = v),
        ),
        const SizedBox(height: 12),
        _buildRiga(isDesktop, [
          // Data ulteriore con date picker (genera codiceDataUlteriore)
          GestureDetector(
            onTap: _selezionaDataUlteriore,
            child: AbsorbPointer(
              child: TextFormField(
                controller: _dataUlterioreCtrl,
                decoration: _dec('Data ulteriore intervento').copyWith(
                  suffixIcon: const Icon(Icons.calendar_today_outlined,
                      size: 18, color: AppColors.textDisabled),
                ),
              ),
            ),
          ),
          TextFormField(
            controller: _codiceDataUltCtrl,
            readOnly: true,
            decoration: _dec('Codice data ulteriore (AAMMGG)').copyWith(
              filled: true,
              fillColor: AppColors.inputBackground,
              suffixIcon: const Icon(Icons.lock_outline,
                  size: 16, color: AppColors.textDisabled),
            ),
          ),
          GestureDetector(
            onTap: () => _selezionaOra(_oraUltCtrl),
            child: AbsorbPointer(
              child: TextFormField(
                controller: _oraUltCtrl,
                decoration: _dec('Ora ulteriore').copyWith(
                  suffixIcon: const Icon(Icons.access_time,
                      size: 18, color: AppColors.textDisabled),
                ),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        TextFormField(
          controller: _noteAzioniUltCtrl,
          maxLines: 3,
          decoration: _dec('Note azioni correttive ulteriori'),
        ),
      ],
    );
  }

  // ─── Gruppo 5 — Voci economiche ───────────────────────────────────────────

  Widget _buildGruppo5(bool isDesktop) {
    return _buildGruppoCard(
      titolo: 'Voci economiche',
      isDesktop: isDesktop,
      children: [
        _buildSezioneVoce(
          etichetta: 'Voce A',
          isDesktop: isDesktop,
          voceSelezionata: _voceA,
          onVoceChanged: (v) => setState(() {
            _voceA = v;
          }),
          costoCtrl: _costoACtrl,
          nIntervCtrl: _nIntervACtrl,
          scontoCtrl: _scontoACtrl,
          ritenutaCtrl: _ritenutaACtrl,
          parziale: _parzialeA,
          iva: _ivaA,
          valRitenuta: _valRitenutaA,
          tot: _totA,
        ),
        const Divider(height: 28, color: AppColors.divider),
        _buildSezioneVoce(
          etichetta: 'Voce B',
          isDesktop: isDesktop,
          voceSelezionata: _voceB,
          onVoceChanged: (v) => setState(() {
            _voceB = v;
          }),
          costoCtrl: _costoBCtrl,
          nIntervCtrl: _nIntervBCtrl,
          scontoCtrl: _scontoBCtrl,
          ritenutaCtrl: _ritenutaBCtrl,
          parziale: _parzialeB,
          iva: _ivaB,
          valRitenuta: _valRitenutaB,
          tot: _totB,
        ),
        const Divider(height: 28, color: AppColors.divider),
        _buildSezioneVoce(
          etichetta: 'Voce C',
          isDesktop: isDesktop,
          voceSelezionata: _voceC,
          onVoceChanged: (v) => setState(() {
            _voceC = v;
          }),
          costoCtrl: _costoCCtrl,
          nIntervCtrl: _nIntervCCtrl,
          scontoCtrl: _scontoCCtrl,
          ritenutaCtrl: _ritenutaCCtrl,
          parziale: _parzialeC,
          iva: _ivaC,
          valRitenuta: _valRitenutaC,
          tot: _totC,
        ),
        const SizedBox(height: 20),
        _buildRiepilogoTotali(),
      ],
    );
  }

  Widget _buildSezioneVoce({
    required String etichetta,
    required bool isDesktop,
    required String? voceSelezionata,
    required void Function(String) onVoceChanged,
    required TextEditingController costoCtrl,
    required TextEditingController nIntervCtrl,
    required TextEditingController scontoCtrl,
    required TextEditingController ritenutaCtrl,
    required double parziale,
    required double iva,
    required double valRitenuta,
    required double tot,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titolo voce
        Text(
          etichetta,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 10),
        // Dropdown descrizione voce (larghezza piena)
        CategoriaDropdown(
          categoriaId: 'pest_voci_economiche',
          label: 'Descrizione $etichetta',
          initialValue: voceSelezionata,
          onChanged: onVoceChanged,
        ),
        const SizedBox(height: 12),
        // Riga input: costo, n. interventi, sconto%, ritenuta%
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildCampoNumerico('Costo unitario (€)', costoCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _buildCampoNumerico('N° interventi', nIntervCtrl, intero: true)),
              const SizedBox(width: 12),
              Expanded(child: _buildCampoNumerico('Sconto %', scontoCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _buildCampoNumerico('Ritenuta %', ritenutaCtrl)),
            ],
          )
        else
          Column(
            children: [
              _buildCampoNumerico('Costo unitario (€)', costoCtrl),
              const SizedBox(height: 12),
              _buildCampoNumerico('N° interventi', nIntervCtrl, intero: true),
              const SizedBox(height: 12),
              _buildCampoNumerico('Sconto %', scontoCtrl),
              const SizedBox(height: 12),
              _buildCampoNumerico('Ritenuta %', ritenutaCtrl),
            ],
          ),
        const SizedBox(height: 12),
        // Riga calcolati: parziale, IVA, ritenuta, totale voce
        if (isDesktop)
          Row(
            children: [
              Expanded(child: _buildCampoCalcolato('Parziale', parziale)),
              const SizedBox(width: 12),
              Expanded(child: _buildCampoCalcolato('IVA 22%', iva)),
              const SizedBox(width: 12),
              Expanded(child: _buildCampoCalcolato('Ritenuta', valRitenuta)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildCampoCalcolato('Tot $etichetta', tot,
                      highlight: true)),
            ],
          )
        else
          Column(
            children: [
              _buildCampoCalcolato('Parziale', parziale),
              const SizedBox(height: 8),
              _buildCampoCalcolato('IVA 22%', iva),
              const SizedBox(height: 8),
              _buildCampoCalcolato('Ritenuta', valRitenuta),
              const SizedBox(height: 8),
              _buildCampoCalcolato('Tot $etichetta', tot, highlight: true),
            ],
          ),
      ],
    );
  }

  Widget _buildRiepilogoTotali() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLightest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Riepilogo totali',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildVoceTotale('Parziale TOT', _parzialeTot)),
              const SizedBox(width: 12),
              Expanded(child: _buildVoceTotale('IVA totale', _ivaTot)),
              const SizedBox(width: 12),
              Expanded(child: _buildVoceTotale('Ritenute', _ritenute)),
            ],
          ),
          const SizedBox(height: 16),
          // Totale dovuto in grande
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTALE DOVUTO',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.textOnPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  _moneyFmt.format(_totaleDovuto),
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

  // ─── Gruppo 6 — Amministrativo ────────────────────────────────────────────

  Widget _buildGruppo6(bool isDesktop) {
    return _buildGruppoCard(
      titolo: 'Amministrativo',
      isDesktop: isDesktop,
      children: [
        TextFormField(
          controller: _ulterioriNoteCtrl,
          maxLines: 3,
          decoration: _dec('Ulteriori note'),
        ),
        const SizedBox(height: 12),
        _buildRiga(isDesktop, [
          TextFormField(
            controller: _contattiCtrl,
            decoration: _dec('Contatti'),
          ),
          TextFormField(
            controller: _emailCtrl,
            decoration: _dec('Email'),
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return null;
              // Validazione formato email
              final emailRe = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
              if (!emailRe.hasMatch(v.trim())) {
                return 'Formato email non valido';
              }
              return null;
            },
          ),
        ]),
      ],
    );
  }

  // ─── Bottoni ──────────────────────────────────────────────────────────────

  Widget _buildBottoni() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
        color: AppColors.surface,
      ),
      child: Row(
        children: [
          // Annulla
          OutlinedButton(
            onPressed: _isSaving ? null : _chiudiPagina,
            child: const Text('Annulla'),
          ),
          const SizedBox(width: 12),
          // Esci
          Expanded(
            child: OutlinedButton(
              onPressed: _isSaving ? null : _esci,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
              ),
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
          // Salva
          Expanded(
            child: FilledButton(
              onPressed: _isSaving ? null : _salva,
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary),
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

  // ─── Widget riutilizzabili ─────────────────────────────────────────────────

  /// Card gruppo con ExpansionTile — espanso su desktop, chiuso su mobile
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
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
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
                  padding: EdgeInsets.only(
                      bottom: e.key < fields.length - 1 ? 12 : 0),
                  child: e.value,
                ))
            .toList(),
      );
    }
    // Su desktop: fields affiancati con Row + Expanded
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
          : [
              FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
            ],
      onChanged: (_) => _ricalcola(),
    );
  }

  /// Campo calcolato read-only con sfondo colorato
  Widget _buildCampoCalcolato(String label, double valore,
      {bool highlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: highlight
                ? AppColors.primaryLight
                : AppColors.inputBackground,
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

  /// Autocomplete per la selezione del cliente
  Widget _buildAutocompleteCliente() {
    return Autocomplete<ClienteModel>(
      optionsBuilder: (TextEditingValue valore) {
        if (valore.text.isEmpty) return const Iterable<ClienteModel>.empty();
        final q = valore.text.toLowerCase();
        return _clienti.where((c) {
          return c.committente.toLowerCase().contains(q) ||
              c.numeroFormattato.toLowerCase().contains(q);
        });
      },
      displayStringForOption: (c) =>
          '${c.numeroFormattato} — ${c.committente}',
      fieldViewBuilder:
          (ctx, ctrl, focusNode, onSubmit) {
        // Sincronizza il controller esterno
        if (_clienteDisplayCtrl.text.isNotEmpty &&
            ctrl.text != _clienteDisplayCtrl.text) {
          ctrl.text = _clienteDisplayCtrl.text;
        }
        return TextFormField(
          controller: ctrl,
          focusNode: focusNode,
          decoration: _dec('Codice cliente — ricerca per nome o numero'),
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
                            fontSize: 11, color: AppColors.textSecondary)),
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

  InputDecoration _dec(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}

// ─── Helper: formattatore maiuscole ──────────────────────────────────────────

/// Trasforma il testo in maiuscolo (usato per il campo Provincia)
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

enum _SceltaEsci { annulla, bozza, salva }
