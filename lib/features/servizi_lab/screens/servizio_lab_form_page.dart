import 'package:biochem/services/cap_service.dart';
import 'package:biochem/services/clienti_service.dart';
import 'package:biochem/services/servizi_lab_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/service_providers.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../models/cliente_model.dart';
import '../../../models/indirizzo_servizio_model.dart';
import '../../../models/servizio_lab_model.dart';
import '../../../services/indirizzi_servizio_service.dart';
import '../../../widgets/categoria_dropdown.dart';

/// Form per la creazione e modifica di un servizio lab
///
/// Parametri:
/// - [servizioId] null → modalità creazione, stringa → modalità modifica
///
/// Accessibile SOLO agli utenti con role == 'admin' (protezione nel router).
class ServizioLabFormPage extends ConsumerStatefulWidget {
  final String? servizioId;
  const ServizioLabFormPage({super.key, this.servizioId});

  @override
  ConsumerState<ServizioLabFormPage> createState() =>
      _ServizioLabFormPageState();
}

class _ServizioLabFormPageState extends ConsumerState<ServizioLabFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final ServiziLabService _serviziLabService;
  late final ClientiService _clientiService;
  late final CapService _capService;
  late final IndirizziServizioService _indirizziServizioService;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _erroreCaricamento;
  String? _servizioIdCorrente;
  bool _allowDirectPop = false;
  Map<String, Object?>? _snapshotIniziale;

  // Servizio originale caricato in modalità modifica (null = creazione)
  ServizioLabModel? _servizioOriginale;

  // ─── Stato form ────────────────────────────────────────────────────────────

  // Clienti disponibili per la ricerca
  List<ClienteModel> _clienti = [];

  // Gruppo 1 — Identificazione e analisi
  final _clienteDisplayCtrl = TextEditingController(); // testo visualizzato
  String _codiceClienteId = ''; // ID Firestore del cliente selezionato
  String? _tipoAnalisi;
  final _certificazioneCtrl = TextEditingController(); // sola lettura
  final _codiceACtrl = TextEditingController(); // sola lettura
  final _oraCtrl = TextEditingController();

  // Gruppo 2 — Date e tempistiche
  DateTime _inizioProve = DateTime.now();
  DateTime? _fineProve;
  DateTime? _dataEmissione;
  final _inizioProveCtrl = TextEditingController();
  final _fineProveCtrl = TextEditingController();
  final _dataEmissioneCtrl = TextEditingController();

  // Gruppo 3 — Dati cliente
  final _tipoCommittenteCtrl = TextEditingController();
  final _committenteCtrl = TextEditingController();
  final _indirizzoCtrl = TextEditingController();
  final _capClienteCtrl = TextEditingController();
  final _cittaCtrl = TextEditingController();
  final _pivaCtrl = TextEditingController();
  final _codiceUnivocoCtrl = TextEditingController();
  final _referenteCtrl = TextEditingController();

  // Gruppo 4 — Campione e prelievo
  String? _campioneRiferimento;
  String? _prelevatoDa;
  final _luogoPrelievoCtrl = TextEditingController();
  final _capCittaPrelievoCtrl = TextEditingController();
  final _puntoPresaCtrl = TextEditingController();
  String? _modalitaPrelievo;
  String? _rifNormativa;

  // Gruppo 5 — Contatti
  final _emailCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _pecCtrl = TextEditingController();

  // Gruppo 4 extra — Indirizzi di servizio del cliente selezionato
  // Lista caricata quando viene selezionato un cliente
  List<IndirizzoServizioModel> _indirizziServizio = [];
  // ID opzione dropdown: 'principale' | ID dell'IndirizzoServizioModel | null
  String? _indirizzoPrelievoId;
  // Cliente correntemente selezionato (per caricare indirizzi)
  ClienteModel? _clienteSelezionato;

  // Gruppo 4 extra — Tecnico responsabile analisi
  String? _tecnico;

  // Gruppo 6 — Amministrativo
  final _notePrezzoCtrl = TextEditingController();
  bool _ft = false;
  bool _fatturaPagata = false;
  final _noteTecnicheCtrl = TextEditingController();

  final _formatter = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _servizioIdCorrente = widget.servizioId;
    _serviziLabService = ref.read(serviziLabServiceProvider);
    _clientiService = ref.read(clientiServiceProvider);
    _capService = ref.read(capServiceProvider);
    _indirizziServizioService = ref.read(indirizziServizioServiceProvider);
    _inizializza();
  }

  @override
  void dispose() {
    _clienteDisplayCtrl.dispose();
    _certificazioneCtrl.dispose();
    _codiceACtrl.dispose();
    _oraCtrl.dispose();
    _inizioProveCtrl.dispose();
    _fineProveCtrl.dispose();
    _dataEmissioneCtrl.dispose();
    _tipoCommittenteCtrl.dispose();
    _committenteCtrl.dispose();
    _indirizzoCtrl.dispose();
    _capClienteCtrl.dispose();
    _cittaCtrl.dispose();
    _pivaCtrl.dispose();
    _codiceUnivocoCtrl.dispose();
    _referenteCtrl.dispose();
    _luogoPrelievoCtrl.dispose();
    _capCittaPrelievoCtrl.dispose();
    _puntoPresaCtrl.dispose();
    _emailCtrl.dispose();
    _telefonoCtrl.dispose();
    _pecCtrl.dispose();
    _notePrezzoCtrl.dispose();
    _noteTecnicheCtrl.dispose();
    super.dispose();
  }

  Future<void> _inizializza() async {
    try {
      // Carica lista clienti per l'autocomplete
      _clienti = await _clientiService.getClienti().first;

      if (widget.servizioId != null) {
        // Modalità modifica: carica i dati esistenti
        final s =
            await _serviziLabService.getServizioLabById(widget.servizioId!);
        if (s != null) {
          _servizioOriginale = s;
          _popolaDaModello(s);
        }
      } else {
        // Modalità creazione: auto-genera codici e precompila ora
        _certificazioneCtrl.text =
            await _serviziLabService.getNextCertificazione();
        _codiceACtrl.text =
            await _serviziLabService.generaCodiceA(DateTime.now());
        final now = TimeOfDay.now();
        _oraCtrl.text =
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        _inizioProveCtrl.text = _formatter.format(_inizioProve);
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
  void _popolaDaModello(ServizioLabModel s) {
    _codiceClienteId = s.codiceCliente;
    _clienteDisplayCtrl.text = s.committente;
    _tipoAnalisi = s.tipoAnalisi.isNotEmpty ? s.tipoAnalisi : null;
    _certificazioneCtrl.text = s.certificazioneNumerica;
    _codiceACtrl.text = s.codiceA;
    _oraCtrl.text = s.ora;

    _inizioProve = s.inizioProveGenerali;
    _inizioProveCtrl.text = _formatter.format(_inizioProve);
    _fineProve = s.fineProveGenerali;
    _fineProveCtrl.text =
        _fineProve != null ? _formatter.format(_fineProve!) : '';
    _dataEmissione = s.dataEmissione;
    _dataEmissioneCtrl.text =
        _dataEmissione != null ? _formatter.format(_dataEmissione!) : '';

    _tipoCommittenteCtrl.text = s.tipoCommittente;
    _committenteCtrl.text = s.committente;
    _indirizzoCtrl.text = s.indirizzo;
    _capClienteCtrl.text = s.cap;
    _cittaCtrl.text = s.citta;
    _pivaCtrl.text = s.pivaCodiceFiscale;
    _codiceUnivocoCtrl.text = s.codiceUnivoco;
    _referenteCtrl.text = s.referente;

    _campioneRiferimento =
        s.campioneRiferimento.isNotEmpty ? s.campioneRiferimento : null;
    _prelevatoDa = s.prelevatoDa.isNotEmpty ? s.prelevatoDa : null;
    _luogoPrelievoCtrl.text = s.luogoPrelievo;
    _capCittaPrelievoCtrl.text = s.capCittaPrelievo;
    _puntoPresaCtrl.text = s.puntoPresa;
    _modalitaPrelievo =
        s.modalitaPrelievo.isNotEmpty ? s.modalitaPrelievo : null;
    _rifNormativa = s.rifNormativa.isNotEmpty ? s.rifNormativa : null;

    _emailCtrl.text = s.email;
    _telefonoCtrl.text = s.telefono;
    _pecCtrl.text = s.pec;

    _tecnico = s.tecnico.isNotEmpty ? s.tecnico : null;
    _notePrezzoCtrl.text = s.notePrezzo;
    _ft = s.ft;
    _fatturaPagata = s.fatturaPagata;
    _noteTecnicheCtrl.text = s.noteTecniche;
  }

  /// Auto-popola i campi cliente (gruppi 3 e 5) dal cliente selezionato.
  /// Carica anche gli indirizzi di servizio per il dropdown Gruppo 4.
  void _onClienteSelezionato(ClienteModel cliente) {
    setState(() {
      _codiceClienteId = cliente.id;
      _clienteSelezionato = cliente;
      _clienteDisplayCtrl.text =
          '${cliente.numeroFormattato} — ${cliente.committente}';
      // Gruppo 3
      _tipoCommittenteCtrl.text = cliente.tipoCommittente;
      _committenteCtrl.text = cliente.committente;
      _indirizzoCtrl.text = cliente.indirizzo;
      _capClienteCtrl.text = cliente.cap;
      _cittaCtrl.text = cliente.citta;
      _pivaCtrl.text = cliente.pivaCodiceFiscale;
      _codiceUnivocoCtrl.text = cliente.codiceUnivoco;
      _referenteCtrl.text = cliente.referente;
      // Gruppo 5
      _emailCtrl.text = cliente.email;
      _telefonoCtrl.text = cliente.telefono;
      _pecCtrl.text = cliente.pec;
      // Reset dropdown indirizzo prelievo
      _indirizziServizio = [];
      _indirizzoPrelievoId = null;
    });
    // Carica gli indirizzi di servizio secondari dalla sotto-collezione
    _caricaIndirizziServizio(cliente.id);
  }

  /// Carica gli indirizzi di servizio del cliente dalla sotto-collezione Firestore
  Future<void> _caricaIndirizziServizio(String clienteId) async {
    try {
      final indirizzi =
          await _indirizziServizioService.getIndirizzi(clienteId).first;
      if (mounted) setState(() => _indirizziServizio = indirizzi);
    } catch (_) {
      // Se il caricamento fallisce il dropdown mostra solo l'indirizzo principale
    }
  }

  /// Gestisce la selezione di un indirizzo dal dropdown.
  /// Auto-compila il campo CAP/Città prelievo con i dati dell'indirizzo scelto.
  void _onIndirizzoPrelievoSelezionato(String? id) {
    if (id == null) return;
    setState(() => _indirizzoPrelievoId = id);

    if (id == 'principale' && _clienteSelezionato != null) {
      // Indirizzo principale dall'anagrafica cliente
      final c = _clienteSelezionato!;
      _luogoPrelievoCtrl.text = c.indirizzoServizio.isNotEmpty
          ? c.indirizzoServizio
          : c.indirizzo;
      if (c.capServizio.isNotEmpty || c.cittaServizio.isNotEmpty) {
        _capCittaPrelievoCtrl.text =
            '${c.capServizio} ${c.cittaServizio}'.trim();
      } else {
        _capCittaPrelievoCtrl.text = '${c.cap} ${c.citta}'.trim();
      }
    } else {
      // Indirizzo secondario dalla sotto-collezione
      final addr = _indirizziServizio.firstWhere(
        (a) => a.id == id,
        orElse: () => const IndirizzoServizioModel(
            id: '', indirizzo: '', cap: '', citta: '',
            provincia: '', referente: '', note: ''),
      );
      if (addr.id.isNotEmpty) {
        _luogoPrelievoCtrl.text = addr.indirizzo;
        _capCittaPrelievoCtrl.text = '${addr.cap} ${addr.citta}'.trim();
      }
    }
  }

  /// Mostra il date picker e aggiorna data e controller
  Future<void> _selezionaData({
    required DateTime? attuale,
    required void Function(DateTime) onSelezionata,
    required TextEditingController controller,
  }) async {
    final selezionata = await showDatePicker(
      context: context,
      initialDate: attuale ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2050),
      locale: const Locale('it'),
    );
    if (selezionata != null && mounted) {
      setState(() {
        onSelezionata(selezionata);
        controller.text = _formatter.format(selezionata);
      });
    }
  }

  /// Mostra il time picker e aggiorna il controller ora
  Future<void> _selezionaOra() async {
    final parti = _oraCtrl.text.split(':');
    final oraCorrente = TimeOfDay(
      hour: int.tryParse(parti.isNotEmpty ? parti[0] : '0') ?? 0,
      minute: int.tryParse(parti.length > 1 ? parti[1] : '0') ?? 0,
    );
    final selezionata = await showTimePicker(
      context: context,
      initialTime: oraCorrente,
    );
    if (selezionata != null && mounted) {
      setState(() {
        _oraCtrl.text =
            '${selezionata.hour.toString().padLeft(2, '0')}:${selezionata.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  /// Lookup automatico CAP → "CAP Città" per il campo capCittaPrelievo
  Future<void> _onCapPrelievoChanged(String valore) async {
    final soloDigiti = valore.replaceAll(RegExp(r'\D'), '');
    if (soloDigiti.length == 5) {
      final risultato = await _capService.cercaPerCap(soloDigiti);
      if (risultato != null && mounted) {
        setState(() {
          _capCittaPrelievoCtrl.text = '$soloDigiti ${risultato.citta}';
        });
      }
    }
  }

  /// Costruisce il modello dai controller correnti
  ServizioLabModel _costruisciModello({bool isDraft = false}) {
    return ServizioLabModel(
      id: _servizioIdCorrente ?? '',
      codiceCliente: _codiceClienteId,
      tipoAnalisi: _tipoAnalisi ?? '',
      certificazioneNumerica: _certificazioneCtrl.text.trim(),
      codiceA: _codiceACtrl.text.trim(),
      ora: _oraCtrl.text.trim(),
      inizioProveGenerali: _inizioProve,
      fineProveGenerali: _fineProve,
      dataEmissione: _dataEmissione,
      tipoCommittente: _tipoCommittenteCtrl.text.trim(),
      committente: _committenteCtrl.text.trim(),
      indirizzo: _indirizzoCtrl.text.trim(),
      cap: _capClienteCtrl.text.trim(),
      citta: _cittaCtrl.text.trim(),
      pivaCodiceFiscale: _pivaCtrl.text.trim(),
      codiceUnivoco: _codiceUnivocoCtrl.text.trim(),
      referente: _referenteCtrl.text.trim(),
      campioneRiferimento: _campioneRiferimento ?? '',
      prelevatoDa: _prelevatoDa ?? '',
      luogoPrelievo: _luogoPrelievoCtrl.text.trim(),
      capCittaPrelievo: _capCittaPrelievoCtrl.text.trim(),
      puntoPresa: _puntoPresaCtrl.text.trim(),
      modalitaPrelievo: _modalitaPrelievo ?? '',
      rifNormativa: _rifNormativa ?? '',
      email: _emailCtrl.text.trim(),
      telefono: _telefonoCtrl.text.trim(),
      pec: _pecCtrl.text.trim(),
      tecnico: _tecnico ?? '',
      notePrezzo: _notePrezzoCtrl.text.trim(),
      ft: _ft,
      fatturaPagata: _fatturaPagata,
      noteTecniche: _noteTecnicheCtrl.text.trim(),
      isDraft: isDraft,
      createdAt: _servizioOriginale?.createdAt ?? DateTime.now(),
    );
  }

  Map<String, Object?> _snapshotCorrente() {
    final modello = _costruisciModello(
      isDraft: _servizioOriginale?.isDraft ?? false,
    );
    return {
      'codiceCliente': modello.codiceCliente,
      'tipoAnalisi': modello.tipoAnalisi,
      'certificazioneNumerica': modello.certificazioneNumerica,
      'codiceA': modello.codiceA,
      'ora': modello.ora,
      'inizioProveGenerali': modello.inizioProveGenerali.toIso8601String(),
      'fineProveGenerali': modello.fineProveGenerali?.toIso8601String(),
      'dataEmissione': modello.dataEmissione?.toIso8601String(),
      'tipoCommittente': modello.tipoCommittente,
      'committente': modello.committente,
      'indirizzo': modello.indirizzo,
      'cap': modello.cap,
      'citta': modello.citta,
      'pivaCodiceFiscale': modello.pivaCodiceFiscale,
      'codiceUnivoco': modello.codiceUnivoco,
      'referente': modello.referente,
      'campioneRiferimento': modello.campioneRiferimento,
      'prelevatoDa': modello.prelevatoDa,
      'luogoPrelievo': modello.luogoPrelievo,
      'capCittaPrelievo': modello.capCittaPrelievo,
      'puntoPresa': modello.puntoPresa,
      'modalitaPrelievo': modello.modalitaPrelievo,
      'rifNormativa': modello.rifNormativa,
      'email': modello.email,
      'telefono': modello.telefono,
      'pec': modello.pec,
      'tecnico': modello.tecnico,
      'notePrezzo': modello.notePrezzo,
      'ft': modello.ft,
      'fatturaPagata': modello.fatturaPagata,
      'noteTecniche': modello.noteTecniche,
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
    if (validate && !(_formKey.currentState?.validate() ?? false)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compila tutti i campi obbligatori'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() => _isSaving = true);
    try {
      final modello = _costruisciModello(isDraft: isDraft);
      final servizioId =
          await _serviziLabService.salvaServizioLab(modello);
      _servizioIdCorrente = servizioId;
      _servizioOriginale = modello;
      _snapshotIniziale = _snapshotCorrente();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isDraft
                ? 'Servizio lab salvato come bozza'
                : 'Servizio lab salvato con successo'),
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
            content: Text('Errore: $e'),
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
              ? 'Vuoi salvare le modifiche prima di uscire o impostare il servizio come bozza?'
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
    final conferma = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina servizio'),
        content: Text(
            'Eliminare il servizio ${_certificazioneCtrl.text}? L\'azione è irreversibile.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annulla')),
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
      await _serviziLabService.eliminaServizioLab(_servizioIdCorrente!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Servizio eliminato')),
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

  // ─── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 600;
    final isModifica = _servizioIdCorrente != null;
    final titolo = isModifica ? 'Modifica servizio lab' : 'Nuovo servizio lab';

    // Profilo ancora in caricamento: spinner (evita flash di contenuto admin
    // durante la transizione auth → profilo Firestore)
    final userAsync = ref.watch(currentUserProvider);
    if (userAsync.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(titolo)),
        body: const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    // Defense in depth: nega l'accesso se il ruolo non è admin,
    // indipendentemente dal redirect del router
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
              style: const TextStyle(color: AppColors.error)),
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
            if (isModifica)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                tooltip: 'Elimina servizio',
                onPressed: _isSaving ? null : _elimina,
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isDesktop ? 24 : 16),
                  child: Column(
                    children: [
                      _GruppoCard(titolo: 'Identificazione e analisi', icona: Icons.science_outlined, isDesktop: isDesktop, campi: _buildGruppo1(isDesktop)),
                      const SizedBox(height: 12),
                      _GruppoCard(titolo: 'Date e tempistiche', icona: Icons.calendar_month_outlined, isDesktop: isDesktop, campi: _buildGruppo2(isDesktop)),
                      const SizedBox(height: 12),
                      _GruppoCard(titolo: 'Dati cliente', icona: Icons.business_outlined, isDesktop: isDesktop, campi: _buildGruppo3(isDesktop)),
                      const SizedBox(height: 12),
                      _GruppoCard(titolo: 'Campione e prelievo', icona: Icons.water_drop_outlined, isDesktop: isDesktop, campi: _buildGruppo4(isDesktop)),
                      const SizedBox(height: 12),
                      _GruppoCard(titolo: 'Contatti cliente', icona: Icons.contact_mail_outlined, isDesktop: isDesktop, campi: _buildGruppo5(isDesktop)),
                      const SizedBox(height: 12),
                      _GruppoCard(titolo: 'Amministrativo', icona: Icons.admin_panel_settings_outlined, isDesktop: isDesktop, campi: _buildGruppo6(isDesktop)),
                    ],
                  ),
                ),
              ),
              _buildBottoniAzione(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── GRUPPO 1 — Identificazione e analisi ─────────────────────────────────

  List<Widget> _buildGruppo1(bool isDesktop) {
    final w = isDesktop ? 300.0 : double.infinity;
    return [
      // Codice cliente — SearchableDropdown (Autocomplete)
      SizedBox(
        width: isDesktop ? w * 2 + 16 : w,
        child: _buildRicercaCliente(),
      ),
      // Tipo analisi — Dropdown da impostazioni (obbligatorio *)
      SizedBox(
        width: w,
        child: CategoriaDropdown(
          categoriaId: 'categorie_analisi',
          label: 'Tipo analisi *',
          initialValue: _tipoAnalisi,
          onChanged: (v) => setState(() => _tipoAnalisi = v),
          validator: (v) =>
              v == null || v.isEmpty ? 'Campo obbligatorio' : null,
        ),
      ),
      // Tecnico — Dropdown da impostazioni (obbligatorio *)
      SizedBox(
        width: w,
        child: CategoriaDropdown(
          categoriaId: 'lab_tecnici',
          label: 'Tecnico *',
          initialValue: _tecnico,
          onChanged: (v) => setState(() => _tecnico = v),
          validator: (v) =>
              v == null || v.isEmpty ? 'Campo obbligatorio' : null,
        ),
      ),
      // Certificazione numerica — sola lettura
      SizedBox(
        width: w,
        child: _buildCampoSolaLettura(
          label: 'Certificazione numerica',
          controller: _certificazioneCtrl,
        ),
      ),
      // Codice A — sola lettura
      SizedBox(
        width: isDesktop ? 180 : w,
        child: _buildCampoSolaLettura(
          label: 'Codice A.',
          controller: _codiceACtrl,
        ),
      ),
      // Ora — modificabile con time picker
      SizedBox(
        width: isDesktop ? 180 : w,
        child: TextFormField(
          controller: _oraCtrl,
          readOnly: true,
          onTap: _selezionaOra,
          decoration: _dec('Ora').copyWith(
            suffixIcon: const Icon(Icons.access_time,
                size: 18, color: AppColors.textDisabled),
          ),
        ),
      ),
    ];
  }

  /// Campo ricerca cliente con autocomplete
  Widget _buildRicercaCliente() {
    return Autocomplete<ClienteModel>(
      initialValue: TextEditingValue(text: _clienteDisplayCtrl.text),
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return _clienti;
        }
        final q = textEditingValue.text.toLowerCase();
        return _clienti.where((c) =>
            c.committente.toLowerCase().contains(q) ||
            c.numeroCliente.toString().contains(q));
      },
      displayStringForOption: (c) => '${c.numeroFormattato} — ${c.committente}',
      onSelected: _onClienteSelezionato,
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220, maxWidth: 400),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final cliente = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    title: Text(cliente.committente,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                        '${cliente.numeroFormattato} · ${cliente.citta}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                    onTap: () => onSelected(cliente),
                  );
                },
              ),
            ),
          ),
        );
      },
      fieldViewBuilder:
          (context, fieldController, focusNode, onFieldSubmitted) {
        // Sincronizza con il controller esterno
        if (_clienteDisplayCtrl.text.isNotEmpty &&
            fieldController.text != _clienteDisplayCtrl.text) {
          fieldController.text = _clienteDisplayCtrl.text;
        }
        return TextFormField(
          controller: fieldController,
          focusNode: focusNode,
          decoration: _dec('Codice cliente').copyWith(
            prefixIcon:
                const Icon(Icons.search, size: 18, color: AppColors.textDisabled),
            hintText: 'Cerca per nome o numero...',
          ),
          validator: (_) => _codiceClienteId.isEmpty
              ? 'Seleziona un cliente dalla lista'
              : null,
          onChanged: (v) {
            // Se l'utente cancella il testo, resetta la selezione
            if (v.isEmpty) {
              setState(() => _codiceClienteId = '');
            }
          },
        );
      },
    );
  }

  // ─── GRUPPO 2 — Date e tempistiche ────────────────────────────────────────

  List<Widget> _buildGruppo2(bool isDesktop) {
    final w = isDesktop ? 220.0 : double.infinity;
    return [
      SizedBox(
        width: w,
        child: TextFormField(
          controller: _inizioProveCtrl,
          readOnly: true,
          onTap: () => _selezionaData(
            attuale: _inizioProve,
            onSelezionata: (d) => _inizioProve = d,
            controller: _inizioProveCtrl,
          ),
          decoration: _dec('Inizio prove generali *').copyWith(
            suffixIcon: const Icon(Icons.calendar_today,
                size: 18, color: AppColors.textDisabled),
          ),
          validator: (v) => (v == null || v.isEmpty) ? 'Obbligatorio' : null,
        ),
      ),
      SizedBox(
        width: w,
        child: TextFormField(
          controller: _fineProveCtrl,
          readOnly: true,
          onTap: () => _selezionaData(
            attuale: _fineProve,
            onSelezionata: (d) => _fineProve = d,
            controller: _fineProveCtrl,
          ),
          decoration: _dec('Fine prove generali').copyWith(
            suffixIcon: const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(
                Icons.calendar_today,
                size: 18,
                color: AppColors.textDisabled,
              ),
            ),
          ),
        ),
      ),
      SizedBox(
        width: w,
        child: TextFormField(
          controller: _dataEmissioneCtrl,
          readOnly: true,
          onTap: () => _selezionaData(
            attuale: _dataEmissione,
            onSelezionata: (d) => _dataEmissione = d,
            controller: _dataEmissioneCtrl,
          ),
          decoration: _dec('Data emissione').copyWith(
            suffixIcon: const Icon(Icons.calendar_today,
                size: 18, color: AppColors.textDisabled),
          ),
        ),
      ),
    ];
  }

  // ─── GRUPPO 3 — Dati cliente ───────────────────────────────────────────────

  List<Widget> _buildGruppo3(bool isDesktop) {
    final w = isDesktop ? 280.0 : double.infinity;
    return [
      SizedBox(
          width: w,
          child: TextFormField(
              controller: _tipoCommittenteCtrl,
              decoration: _dec('Tipo committente'))),
      SizedBox(
          width: isDesktop ? w * 2 + 16 : w,
          child: TextFormField(
              controller: _committenteCtrl, decoration: _dec('Committente'))),
      SizedBox(
          width: isDesktop ? w * 2 + 16 : w,
          child: TextFormField(
              controller: _indirizzoCtrl, decoration: _dec('Indirizzo'))),
      SizedBox(
          width: isDesktop ? 120 : w,
          child: TextFormField(
              controller: _capClienteCtrl, decoration: _dec('CAP'))),
      SizedBox(
          width: w,
          child:
              TextFormField(controller: _cittaCtrl, decoration: _dec('Città'))),
      SizedBox(
          width: w,
          child: TextFormField(
              controller: _pivaCtrl,
              decoration: _dec('P.IVA / Codice Fiscale'))),
      SizedBox(
          width: w,
          child: TextFormField(
              controller: _codiceUnivocoCtrl,
              decoration: _dec('Codice Univoco'))),
      SizedBox(
          width: w,
          child: TextFormField(
              controller: _referenteCtrl, decoration: _dec('C/A Referente'))),
    ];
  }

  // ─── GRUPPO 4 — Campione e prelievo ───────────────────────────────────────

  List<Widget> _buildGruppo4(bool isDesktop) {
    final w = isDesktop ? 280.0 : double.infinity;
    return [
      // Campione di riferimento — obbligatorio (*)
      SizedBox(
        width: w,
        child: CategoriaDropdown(
          categoriaId: 'campioni_riferimento',
          label: 'Campione di riferimento *',
          initialValue: _campioneRiferimento,
          onChanged: (v) => setState(() => _campioneRiferimento = v),
          validator: (v) =>
              v == null || v.isEmpty ? 'Campo obbligatorio' : null,
        ),
      ),
      SizedBox(
        width: w,
        child: CategoriaDropdown(
          categoriaId: 'prelevato_da',
          label: 'Prelevato da',
          initialValue: _prelevatoDa,
          onChanged: (v) => setState(() => _prelevatoDa = v),
        ),
      ),
      // Dropdown indirizzo prelievo collegato all'anagrafica cliente
      SizedBox(
        width: isDesktop ? w * 2 + 16 : w,
        child: _buildDropdownIndirizzoPrelievo(isDesktop ? w * 2 + 16 : w),
      ),
      SizedBox(
        width: w,
        child: TextFormField(
          controller: _capCittaPrelievoCtrl,
          decoration: _dec('CAP/Città prelievo'),
          onChanged: _onCapPrelievoChanged,
        ),
      ),
      SizedBox(
        width: w,
        child: TextFormField(
          controller: _puntoPresaCtrl,
          decoration: _dec('Punto presa'),
        ),
      ),
      SizedBox(
        width: w,
        child: CategoriaDropdown(
          categoriaId: 'modalita_prelievo',
          label: 'Modalità prelievo',
          initialValue: _modalitaPrelievo,
          onChanged: (v) => setState(() => _modalitaPrelievo = v),
        ),
      ),
      SizedBox(
        width: w,
        child: CategoriaDropdown(
          categoriaId: 'rif_normativa',
          label: 'Rif. normativa',
          initialValue: _rifNormativa,
          onChanged: (v) => setState(() => _rifNormativa = v),
        ),
      ),
    ];
  }

  /// Dropdown indirizzo/coordinate prelievo collegato all'anagrafica del cliente.
  ///
  /// Opzioni:
  /// - "Indirizzo principale" → indirizzo principale dell'anagrafica
  /// - indirizzi secondari dalla sotto-collezione clienti/{id}/indirizzi_servizio
  ///
  /// Disabilitato se nessun cliente è selezionato.
  Widget _buildDropdownIndirizzoPrelievo(double width) {
    final clienteSelezionato = _codiceClienteId.isNotEmpty;

    // Costruisce le opzioni del dropdown
    final items = <DropdownMenuItem<String>>[];

    if (clienteSelezionato && _clienteSelezionato != null) {
      // Prima opzione: indirizzo principale dall'anagrafica
      final c = _clienteSelezionato!;
      final indirizzoP = c.indirizzoServizio.isNotEmpty
          ? c.indirizzoServizio
          : c.indirizzo;
      final cittaP = c.cittaServizio.isNotEmpty ? c.cittaServizio : c.citta;
      items.add(DropdownMenuItem(
        value: 'principale',
        child: Text(
          'Indirizzo principale — $indirizzoP${cittaP.isNotEmpty ? ", $cittaP" : ""}',
          overflow: TextOverflow.ellipsis,
        ),
      ));

      // Indirizzi secondari dalla sotto-collezione
      for (final addr in _indirizziServizio) {
        final label = [
          addr.indirizzo,
          if (addr.citta.isNotEmpty) addr.citta,
          if (addr.referente.isNotEmpty) '(${addr.referente})',
        ].join(' ');
        items.add(DropdownMenuItem(
          value: addr.id,
          child: Text(label, overflow: TextOverflow.ellipsis),
        ));
      }
    }

    return DropdownButtonFormField<String>(
      initialValue: _indirizzoPrelievoId,
      decoration: _dec('Indirizzo/Coordinate prelievo servizio').copyWith(
        hintText: clienteSelezionato
            ? 'Seleziona indirizzo...'
            : 'Seleziona prima un cliente',
        hintStyle:
            const TextStyle(color: AppColors.textDisabled, fontSize: 13),
      ),
      items: items,
      onChanged: clienteSelezionato ? _onIndirizzoPrelievoSelezionato : null,
      isExpanded: true,
    );
  }

  // ─── GRUPPO 5 — Contatti cliente ──────────────────────────────────────────

  List<Widget> _buildGruppo5(bool isDesktop) {
    final w = isDesktop ? 280.0 : double.infinity;
    return [
      SizedBox(
          width: w,
          child: TextFormField(
            controller: _emailCtrl,
            decoration: _dec('Email'),
            keyboardType: TextInputType.emailAddress,
          )),
      SizedBox(
          width: w,
          child: TextFormField(
            controller: _telefonoCtrl,
            decoration: _dec('Telefono'),
            keyboardType: TextInputType.phone,
          )),
      SizedBox(
          width: w,
          child: TextFormField(
            controller: _pecCtrl,
            decoration: _dec('PEC'),
            keyboardType: TextInputType.emailAddress,
          )),
    ];
  }

  // ─── GRUPPO 6 — Amministrativo ────────────────────────────────────────────

  List<Widget> _buildGruppo6(bool isDesktop) {
    final w = isDesktop ? 400.0 : double.infinity;
    return [
      SizedBox(
        width: w,
        child: TextFormField(
          controller: _notePrezzoCtrl,
          decoration: _dec('Note prezzo'),
          maxLines: 3,
        ),
      ),
      SizedBox(
        width: isDesktop ? 200 : w,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Switch FT
            SwitchListTile(
              title: const Text('FT',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              value: _ft,
              onChanged: (v) => setState(() => _ft = v),
              activeThumbColor: AppColors.success,
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            // Switch Fattura pagata
            SwitchListTile(
              title: const Text('Fattura pagata',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              value: _fatturaPagata,
              onChanged: (v) => setState(() => _fatturaPagata = v),
              activeThumbColor: AppColors.success,
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ],
        ),
      ),
      SizedBox(
        width: w,
        child: TextFormField(
          controller: _noteTecnicheCtrl,
          decoration: _dec('Note tecniche'),
          maxLines: 4,
        ),
      ),
    ];
  }

  // ─── WIDGET CONDIVISI ─────────────────────────────────────────────────────

  /// Campo in sola lettura con sfondo diverso (es. codici auto-generati)
  Widget _buildCampoSolaLettura({
    required String label,
    required TextEditingController controller,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      style: const TextStyle(
          fontWeight: FontWeight.w700, color: AppColors.textSecondary),
      decoration: _dec(label).copyWith(
        filled: true,
        fillColor: AppColors.inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildBottoniAzione() {
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
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
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

  /// Decorazione standard per i campi di input
  InputDecoration _dec(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}

// ─── Widget riutilizzabile per i gruppi del form ──────────────────────────────

/// Card con ExpansionTile che contiene un gruppo di campi del form.
///
/// Su desktop i campi vengono disposti in [Wrap], su mobile in [Column].
/// Inizialmente espanso su desktop, collassato su mobile.
class _GruppoCard extends StatelessWidget {
  final String titolo;
  final IconData icona;
  final bool isDesktop;
  final List<Widget> campi;

  const _GruppoCard({
    required this.titolo,
    required this.icona,
    required this.isDesktop,
    required this.campi,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.divider),
      ),
      color: AppColors.surface,
      child: ExpansionTile(
        initiallyExpanded: isDesktop,
        leading: Icon(icona, color: AppColors.primary, size: 22),
        title: Text(
          titolo,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        collapsedShape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        children: [
          const Divider(height: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.all(16),
            child: isDesktop
                ? Wrap(spacing: 16, runSpacing: 16, children: campi)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: campi
                        .expand((w) => [w, const SizedBox(height: 14)])
                        .toList()
                      ..removeLast(),
                  ),
          ),
        ],
      ),
    );
  }
}

enum _SceltaEsci { annulla, bozza, salva }
