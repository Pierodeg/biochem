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
import '../../../models/registro_parametro_model.dart';
import '../../../services/indirizzi_servizio_service.dart';
import '../../../services/registro_service.dart';
import '../../../widgets/categoria_dropdown.dart';

/// Mapping campione di riferimento → nome preset nel Registro
const _mapCampionePreset = <String, String>{
  'acqua di rete': 'Registro Acque',
  'acqua rete imp. domestico': 'Registro Acque',
  'acqua di pozzo non trattata': 'Registro Acque',
  'acqua di pozzo trattata': 'Registro Acque',
  'acqua grezza': 'Registro Acque',
};

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
  late final RegistroService _registroService;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _erroreCaricamento;
  String? _servizioIdCorrente;
  bool _allowDirectPop = false;
  Map<String, Object?>? _snapshotIniziale;
  ServizioLabModel? _servizioOriginale;

  List<ClienteModel> _clienti = [];

  // Gruppo 1
  final _clienteDisplayCtrl = TextEditingController();
  String _codiceClienteId = '';
  String? _tipoAnalisi;
  final _certificazioneCtrl = TextEditingController();
  final _codiceACtrl = TextEditingController();
  final _oraCtrl = TextEditingController();

  // Gruppo 2
  DateTime _inizioProve = DateTime.now();
  DateTime? _fineProve;
  DateTime? _dataEmissione;
  final _inizioProveCtrl = TextEditingController();
  final _fineProveCtrl = TextEditingController();
  final _dataEmissioneCtrl = TextEditingController();

  // Gruppo 3
  final _tipoCommittenteCtrl = TextEditingController();
  final _committenteCtrl = TextEditingController();
  final _indirizzoCtrl = TextEditingController();
  final _capClienteCtrl = TextEditingController();
  final _cittaCtrl = TextEditingController();
  final _pivaCtrl = TextEditingController();
  final _codiceUnivocoCtrl = TextEditingController();
  final _referenteCtrl = TextEditingController();

  // Gruppo 4
  String? _campioneRiferimento;
  String? _prelevatoDa;
  final _luogoPrelievoCtrl = TextEditingController();
  final _capCittaPrelievoCtrl = TextEditingController();
  final _puntoPresaCtrl = TextEditingController();
  String? _modalitaPrelievo;
  String? _rifNormativa;

  // Gruppo Report
  List<ParametroReport> _parametriReport = [];
  bool _caricandoPreset = false;
  bool _gruppo1Aperta = true;
  bool _gruppo2Aperta = true;
  bool _gruppo3Aperta = true;
  bool _gruppo4Aperta = true;
  bool _gruppo5Aperta = true;
  bool _gruppo6Aperta = true;

  // Gruppo 5
  final _emailCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _pecCtrl = TextEditingController();

  List<IndirizzoServizioModel> _indirizziServizio = [];
  String? _indirizzoPrelievoId;
  ClienteModel? _clienteSelezionato;
  String? _tecnico;

  // Gruppo 6
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
    _registroService = ref.read(registroServiceProvider);
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
      _clienti = await _clientiService.getClienti().first;
      if (widget.servizioId != null) {
        final s =
            await _serviziLabService.getServizioLabById(widget.servizioId!);
        if (s != null) {
          _servizioOriginale = s;
          _popolaDaModello(s);
        }
      } else {
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
    _parametriReport = List.from(s.parametriReport);
    _emailCtrl.text = s.email;
    _telefonoCtrl.text = s.telefono;
    _pecCtrl.text = s.pec;
    _tecnico = s.tecnico.isNotEmpty ? s.tecnico : null;
    _notePrezzoCtrl.text = s.notePrezzo;
    _ft = s.ft;
    _fatturaPagata = s.fatturaPagata;
    _noteTecnicheCtrl.text = s.noteTecniche;
  }

  void _onClienteSelezionato(ClienteModel cliente) {
    setState(() {
      _codiceClienteId = cliente.id;
      _clienteSelezionato = cliente;
      _clienteDisplayCtrl.text =
          '${cliente.numeroFormattato} — ${cliente.committente}';
      _tipoCommittenteCtrl.text = cliente.tipoCommittente;
      _committenteCtrl.text = cliente.committente;
      _indirizzoCtrl.text = cliente.indirizzo;
      _capClienteCtrl.text = cliente.cap;
      _cittaCtrl.text = cliente.citta;
      _pivaCtrl.text = cliente.pivaCodiceFiscale;
      _codiceUnivocoCtrl.text = cliente.codiceUnivoco;
      _referenteCtrl.text = cliente.referente;
      _emailCtrl.text = cliente.email;
      _telefonoCtrl.text = cliente.telefono;
      _pecCtrl.text = cliente.pec;
      _indirizziServizio = [];
      _indirizzoPrelievoId = null;
    });
    _caricaIndirizziServizio(cliente.id);
  }

  Future<void> _caricaIndirizziServizio(String clienteId) async {
    try {
      final indirizzi =
          await _indirizziServizioService.getIndirizzi(clienteId).first;
      if (mounted) setState(() => _indirizziServizio = indirizzi);
    } catch (_) {}
  }

  void _onIndirizzoPrelievoSelezionato(String? id) {
    if (id == null) return;
    setState(() => _indirizzoPrelievoId = id);
    if (id == 'principale' && _clienteSelezionato != null) {
      final c = _clienteSelezionato!;
      _luogoPrelievoCtrl.text =
          c.indirizzoServizio.isNotEmpty ? c.indirizzoServizio : c.indirizzo;
      if (c.capServizio.isNotEmpty || c.cittaServizio.isNotEmpty) {
        _capCittaPrelievoCtrl.text =
            '${c.capServizio} ${c.cittaServizio}'.trim();
      } else {
        _capCittaPrelievoCtrl.text = '${c.cap} ${c.citta}'.trim();
      }
    } else {
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

  Future<void> _selezionaOra() async {
    final parti = _oraCtrl.text.split(':');
    final oraCorrente = TimeOfDay(
      hour: int.tryParse(parti.isNotEmpty ? parti[0] : '0') ?? 0,
      minute: int.tryParse(parti.length > 1 ? parti[1] : '0') ?? 0,
    );
    final selezionata =
        await showTimePicker(context: context, initialTime: oraCorrente);
    if (selezionata != null && mounted) {
      setState(() {
        _oraCtrl.text =
            '${selezionata.hour.toString().padLeft(2, '0')}:${selezionata.minute.toString().padLeft(2, '0')}';
      });
    }
  }

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

  // ─── Carica preset dal Registro in base al campione ──────────────────────

  Future<void> _caricaPresetDaCampione(String campione) async {
    final nomePreset =
        _mapCampionePreset[campione.toLowerCase().trim()];
    if (nomePreset == null) return;

    setState(() => _caricandoPreset = true);
    try {
      final presets = await _registroService.getPreset().first;
      final preset = presets
          .where((p) =>
              p.nome.toLowerCase() == nomePreset.toLowerCase())
          .firstOrNull;

      if (preset == null || !mounted) return;

      // Converti i parametri del Registro in ParametroReport
      final nuoviParametri = preset.categorie
          .expand((cat) => cat.parametri)
          .map((p) => ParametroReport(
                parametro: p.parametro,
                um: p.um,
                vl: p.vl,
                loq: p.loq,
                i: p.i,
                metodoRif: p.metodoRif,
                categoria: p.categoria,
                risultato: '',
              ))
          .toList();

      setState(() => _parametriReport = nuoviParametri);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _caricandoPreset = false);
    }
  }

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
      parametriReport: _parametriReport,
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
    final m = _costruisciModello(
        isDraft: _servizioOriginale?.isDraft ?? false);
    return {
      'codiceCliente': m.codiceCliente,
      'tipoAnalisi': m.tipoAnalisi,
      'certificazioneNumerica': m.certificazioneNumerica,
      'codiceA': m.codiceA,
      'ora': m.ora,
      'inizioProveGenerali': m.inizioProveGenerali.toIso8601String(),
      'fineProveGenerali': m.fineProveGenerali?.toIso8601String(),
      'dataEmissione': m.dataEmissione?.toIso8601String(),
      'tipoCommittente': m.tipoCommittente,
      'committente': m.committente,
      'indirizzo': m.indirizzo,
      'cap': m.cap,
      'citta': m.citta,
      'pivaCodiceFiscale': m.pivaCodiceFiscale,
      'codiceUnivoco': m.codiceUnivoco,
      'referente': m.referente,
      'campioneRiferimento': m.campioneRiferimento,
      'prelevatoDa': m.prelevatoDa,
      'luogoPrelievo': m.luogoPrelievo,
      'capCittaPrelievo': m.capCittaPrelievo,
      'puntoPresa': m.puntoPresa,
      'modalitaPrelievo': m.modalitaPrelievo,
      'rifNormativa': m.rifNormativa,
      'parametriReport': m.parametriReport.length,
      'email': m.email,
      'telefono': m.telefono,
      'pec': m.pec,
      'tecnico': m.tecnico,
      'notePrezzo': m.notePrezzo,
      'ft': m.ft,
      'fatturaPagata': m.fatturaPagata,
      'noteTecniche': m.noteTecniche,
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Compila tutti i campi obbligatori',
              style: TextStyle(color: Colors.white)),
          backgroundColor: AppColors.error.withValues(alpha: 0.90),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
                color: Colors.white.withValues(alpha: 0.15), width: 0.5),
          ),
        ));
      }
      return;
    }
    setState(() => _isSaving = true);
    try {
      final modello = _costruisciModello(isDraft: isDraft);
      final servizioId = await _serviziLabService.salvaServizioLab(modello);
      _servizioIdCorrente = servizioId;
      _servizioOriginale = modello;
      _snapshotIniziale = _snapshotCorrente();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              isDraft
                  ? 'Servizio lab salvato come bozza'
                  : 'Servizio lab salvato con successo',
              style: const TextStyle(color: Colors.white)),
          backgroundColor: AppColors.primary.withValues(alpha: 0.90),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
                color: Colors.white.withValues(alpha: 0.15), width: 0.5),
          ),
        ));
        if (closeAfterSave) {
          await _chiudiPagina();
        } else {
          setState(() {});
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Errore: $e',
              style: const TextStyle(color: Colors.white)),
          backgroundColor: AppColors.error.withValues(alpha: 0.90),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
                color: Colors.white.withValues(alpha: 0.15), width: 0.5),
          ),
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _salva() async =>
      _persistiServizio(isDraft: false, closeAfterSave: false);

  Future<void> _esci() async {
    if (!_hasUnsavedChanges) {
      await _chiudiPagina();
      return;
    }
    final scelta = await showDialog<_SceltaEsci>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A2A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.glassBorder, width: 0.5),
        ),
        title: const Text('Uscire dal form',
            style: TextStyle(
                color: AppColors.textOnDark, fontWeight: FontWeight.w700)),
        content: Text(
          _canSaveAsDraft
              ? 'Vuoi salvare le modifiche prima di uscire o impostare il servizio come bozza?'
              : 'Vuoi salvare le modifiche prima di uscire?',
          style: const TextStyle(color: AppColors.textOnDarkSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, _SceltaEsci.annulla),
            child: const Text('Rimani',
                style: TextStyle(color: AppColors.textOnDarkSecondary)),
          ),
          if (_canSaveAsDraft)
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, _SceltaEsci.bozza),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textOnDarkSecondary,
                side:
                    BorderSide(color: AppColors.glassBorder, width: 0.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Salva come bozza'),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, _SceltaEsci.salva),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary.withValues(alpha: 0.30),
              foregroundColor: AppColors.accentGreenDark,
              side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.50),
                  width: 0.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
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
        backgroundColor: const Color(0xFF0A2A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.glassBorder, width: 0.5),
        ),
        title: const Text('Elimina servizio',
            style: TextStyle(
                color: AppColors.textOnDark, fontWeight: FontWeight.w600)),
        content: Text(
            'Eliminare il servizio ${_certificazioneCtrl.text}? Azione irreversibile.',
            style: const TextStyle(color: AppColors.textOnDarkSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annulla',
                  style:
                      TextStyle(color: AppColors.textOnDarkSecondary))),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error.withValues(alpha: 0.25),
              foregroundColor: const Color(0xFFFF7070),
              side: BorderSide(
                  color: AppColors.error.withValues(alpha: 0.40),
                  width: 0.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (conferma != true || !mounted) return;
    try {
      await _serviziLabService.eliminaServizioLab(_servizioIdCorrente!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Servizio eliminato',
              style: TextStyle(color: Colors.white)),
          backgroundColor: AppColors.primary.withValues(alpha: 0.90),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
                color: Colors.white.withValues(alpha: 0.15), width: 0.5),
          ),
        ));
        await _chiudiPagina();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Errore eliminazione: $e',
              style: const TextStyle(color: Colors.white)),
          backgroundColor: AppColors.error.withValues(alpha: 0.90),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
                color: Colors.white.withValues(alpha: 0.15), width: 0.5),
          ),
        ));
      }
    }
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 600;
    final isModifica = _servizioIdCorrente != null;
    final titolo =
        isModifica ? 'Modifica servizio lab' : 'Nuovo servizio lab';

    final userAsync = ref.watch(currentUserProvider);
    if (userAsync.isLoading) {
      return _buildGlassScaffold(titolo: titolo, isModifica: false,
          body: const Center(
              child: CircularProgressIndicator(color: AppColors.primary)));
    }
    final user = userAsync.valueOrNull;
    if (user == null || !user.isAdmin) {
      return _buildGlassScaffold(titolo: titolo, isModifica: false,
          body: const Center(
              child: Text('Accesso non autorizzato',
                  style: TextStyle(color: AppColors.error))));
    }
    if (_isLoading) {
      return _buildGlassScaffold(titolo: titolo, isModifica: false,
          body: const Center(
              child: CircularProgressIndicator(color: AppColors.primary)));
    }
    if (_erroreCaricamento != null) {
      return _buildGlassScaffold(titolo: titolo, isModifica: false,
          body: Center(
              child: Text('Errore: $_erroreCaricamento',
                  style: const TextStyle(color: AppColors.error))));
    }

    return PopScope(
      canPop: _allowDirectPop,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _gestisciBackNavigation();
      },
      child: _buildGlassScaffold(
        titolo: titolo,
        isModifica: isModifica,
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isDesktop ? 24 : 16),
                  child: Column(
                    children: [
                      _GruppoCard(titolo: 'Identificazione e analisi', icona: Icons.science_outlined, isDesktop: isDesktop, isAperta: _gruppo1Aperta, onToggle: () => setState(() => _gruppo1Aperta = !_gruppo1Aperta), preview: _clienteDisplayCtrl.text, campi: _buildGruppo1(isDesktop)),
                      const SizedBox(height: 12),
                      _GruppoCard(titolo: 'Date e tempistiche', icona: Icons.calendar_month_outlined, isDesktop: isDesktop, isAperta: _gruppo2Aperta, onToggle: () => setState(() => _gruppo2Aperta = !_gruppo2Aperta), preview: _inizioProveCtrl.text, campi: _buildGruppo2(isDesktop)),
                      const SizedBox(height: 12),
                      _GruppoCard(titolo: 'Dati cliente', icona: Icons.business_outlined, isDesktop: isDesktop, isAperta: _gruppo3Aperta, onToggle: () => setState(() => _gruppo3Aperta = !_gruppo3Aperta), preview: _committenteCtrl.text, campi: _buildGruppo3(isDesktop)),
                      const SizedBox(height: 12),
                      _GruppoCard(titolo: 'Campione e prelievo', icona: Icons.water_drop_outlined, isDesktop: isDesktop, isAperta: _gruppo4Aperta, onToggle: () => setState(() => _gruppo4Aperta = !_gruppo4Aperta), preview: _campioneRiferimento ?? '', campi: _buildGruppo4(isDesktop)),
                      const SizedBox(height: 12),
                      // ── GRUPPO REPORT ──────────────────────────────────
                      _buildGruppoReport(isDesktop),
                      const SizedBox(height: 12),
                      _GruppoCard(titolo: 'Contatti cliente', icona: Icons.contact_mail_outlined, isDesktop: isDesktop, isAperta: _gruppo5Aperta, onToggle: () => setState(() => _gruppo5Aperta = !_gruppo5Aperta), preview: _emailCtrl.text, campi: _buildGruppo5(isDesktop)),
                      const SizedBox(height: 12),
                      _GruppoCard(titolo: 'Amministrativo', icona: Icons.admin_panel_settings_outlined, isDesktop: isDesktop, isAperta: _gruppo6Aperta, onToggle: () => setState(() => _gruppo6Aperta = !_gruppo6Aperta), preview: _tecnico ?? '', campi: _buildGruppo6(isDesktop)),
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

  // ─── GRUPPO REPORT ────────────────────────────────────────────────────────

  Widget _buildGruppoReport(bool isDesktop) {
    final hasPreset = _mapCampionePreset
        .containsKey(_campioneRiferimento?.toLowerCase().trim() ?? '');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.glassCardMedium,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorderMedium, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header gruppo
          Row(
            children: [
              const Icon(Icons.biotech_outlined,
                  color: AppColors.accentGreenDark, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Report analitico',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentGreenDark,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              // Badge contatore parametri
              if (_parametriReport.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        width: 0.5),
                  ),
                  child: Text(
                    '${_parametriReport.length} parametri',
                    style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.accentGreenDark,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              const SizedBox(width: 8),
              // Bottone apri popup
              FilledButton.icon(
                onPressed: () => _apriPopupReport(),
                icon: const Icon(Icons.open_in_full, size: 14),
                label: const Text('Gestisci'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.25),
                  foregroundColor: AppColors.accentGreenDark,
                  side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.45),
                      width: 0.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          Container(
              height: 0.5,
              color: AppColors.glassBorder,
              margin: const EdgeInsets.symmetric(vertical: 10)),

          // Stato
          if (_caricandoPreset)
            const Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      color: AppColors.accentGreenDark, strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Text('Caricamento preset...',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textOnDarkSecondary)),
              ],
            )
          else if (_parametriReport.isEmpty) ...[
            Row(
              children: [
                Icon(
                  hasPreset
                      ? Icons.info_outline
                      : Icons.block_outlined,
                  size: 14,
                  color: hasPreset
                      ? AppColors.accentGreenDark
                      : AppColors.textOnDarkMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasPreset
                        ? 'Preset disponibile per "${_campioneRiferimento}". Clicca "Gestisci" per caricarlo.'
                        : _campioneRiferimento == null
                            ? 'Seleziona prima un campione di riferimento.'
                            : 'Nessun preset disponibile per questo campione.',
                    style: TextStyle(
                        fontSize: 12,
                        color: hasPreset
                            ? AppColors.textOnDarkSecondary
                            : AppColors.textOnDarkMuted),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Anteprima prime 3 categorie
            ..._parametriReport
                .map((p) => p.categoria)
                .toSet()
                .take(3)
                .map((cat) {
              final count = _parametriReport
                  .where((p) => p.categoria == cat)
                  .length;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.accentGreenDark,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      cat.replaceAll('_', ' '),
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textOnDark,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '($count parametri)',
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textOnDarkMuted),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ─── Popup gestione report ────────────────────────────────────────────────

  void _apriPopupReport() {
    showDialog(
      context: context,
      builder: (ctx) => _ReportPopup(
        parametriIniziali: List.from(_parametriReport),
        campioneRiferimento: _campioneRiferimento,
        registroService: _registroService,
        onSalva: (nuoviParametri) {
          setState(() => _parametriReport = nuoviParametri);
        },
      ),
    );
  }

  // ─── GRUPPO 1 ─────────────────────────────────────────────────────────────

  List<Widget> _buildGruppo1(bool isDesktop) {
    final w = isDesktop ? 300.0 : double.infinity;
    return [
      SizedBox(
          width: isDesktop ? w * 2 + 16 : w,
          child: _buildRicercaCliente()),
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
      SizedBox(
          width: w,
          child: _buildCampoSolaLettura(
              label: 'Certificazione numerica',
              controller: _certificazioneCtrl)),
      SizedBox(
          width: isDesktop ? 180 : w,
          child: _buildCampoSolaLettura(
              label: 'Codice A.', controller: _codiceACtrl)),
      SizedBox(
        width: isDesktop ? 180 : w,
        child: TextFormField(
          controller: _oraCtrl,
          style: const TextStyle(color: Colors.white),
          readOnly: true,
          onTap: _selezionaOra,
          decoration: _dec('Ora').copyWith(
            suffixIcon: const Icon(Icons.access_time,
                size: 18, color: AppColors.textOnDarkMuted),
          ),
        ),
      ),
    ];
  }

  Widget _buildRicercaCliente() {
    return Autocomplete<ClienteModel>(
      initialValue: TextEditingValue(text: _clienteDisplayCtrl.text),
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) return _clienti;
        final q = textEditingValue.text.toLowerCase();
        return _clienti.where((c) =>
            c.committente.toLowerCase().contains(q) ||
            c.numeroCliente.toString().contains(q));
      },
      displayStringForOption: (c) =>
          '${c.numeroFormattato} — ${c.committente}',
      onSelected: _onClienteSelezionato,
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          color: const Color(0xFF0A2A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: AppColors.glassBorder, width: 0.5),
          ),
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxHeight: 220, maxWidth: 400),
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
                          fontSize: 12,
                          color: AppColors.textOnDarkSecondary)),
                  onTap: () => onSelected(cliente),
                );
              },
            ),
          ),
        ),
      ),
      fieldViewBuilder: (context, fieldController, focusNode, onSubmit) {
        if (_clienteDisplayCtrl.text.isNotEmpty &&
            fieldController.text != _clienteDisplayCtrl.text) {
          fieldController.text = _clienteDisplayCtrl.text;
        }
        return TextFormField(
          controller: fieldController,
          style: const TextStyle(color: Colors.white),
          focusNode: focusNode,
          decoration: _dec('Codice cliente').copyWith(
            prefixIcon: const Icon(Icons.search,
                size: 18, color: AppColors.textOnDarkMuted),
            hintText: 'Cerca per nome o numero...',
          ),
          validator: (_) => _codiceClienteId.isEmpty
              ? 'Seleziona un cliente dalla lista'
              : null,
          onChanged: (v) {
            if (v.isEmpty) setState(() => _codiceClienteId = '');
          },
        );
      },
    );
  }

  // ─── GRUPPO 2 ─────────────────────────────────────────────────────────────

  List<Widget> _buildGruppo2(bool isDesktop) {
    final w = isDesktop ? 220.0 : double.infinity;
    return [
      SizedBox(
        width: w,
        child: TextFormField(
          controller: _inizioProveCtrl,
          style: const TextStyle(color: Colors.white),
          readOnly: true,
          onTap: () => _selezionaData(
              attuale: _inizioProve,
              onSelezionata: (d) => _inizioProve = d,
              controller: _inizioProveCtrl),
          decoration: _dec('Inizio prove generali *').copyWith(
            suffixIcon: const Icon(Icons.calendar_today,
                size: 18, color: AppColors.textOnDarkMuted),
          ),
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Obbligatorio' : null,
        ),
      ),
      SizedBox(
        width: w,
        child: TextFormField(
          controller: _fineProveCtrl,
          style: const TextStyle(color: Colors.white),
          readOnly: true,
          onTap: () => _selezionaData(
              attuale: _fineProve,
              onSelezionata: (d) => _fineProve = d,
              controller: _fineProveCtrl),
          decoration: _dec('Fine prove generali').copyWith(
            suffixIcon: const Icon(Icons.calendar_today,
                size: 18, color: AppColors.textOnDarkMuted),
          ),
        ),
      ),
      SizedBox(
        width: w,
        child: TextFormField(
          controller: _dataEmissioneCtrl,
          style: const TextStyle(color: Colors.white),
          readOnly: true,
          onTap: () => _selezionaData(
              attuale: _dataEmissione,
              onSelezionata: (d) => _dataEmissione = d,
              controller: _dataEmissioneCtrl),
          decoration: _dec('Data emissione').copyWith(
            suffixIcon: const Icon(Icons.calendar_today,
                size: 18, color: AppColors.textOnDarkMuted),
          ),
        ),
      ),
    ];
  }

  // ─── GRUPPO 3 ─────────────────────────────────────────────────────────────

  List<Widget> _buildGruppo3(bool isDesktop) {
    final w = isDesktop ? 280.0 : double.infinity;
    return [
      SizedBox(width: w, child: TextFormField(controller: _tipoCommittenteCtrl, style: const TextStyle(color: Colors.white), decoration: _dec('Tipo committente'))),
      SizedBox(width: isDesktop ? w * 2 + 16 : w, child: TextFormField(controller: _committenteCtrl, style: const TextStyle(color: Colors.white), decoration: _dec('Committente'))),
      SizedBox(width: isDesktop ? w * 2 + 16 : w, child: TextFormField(controller: _indirizzoCtrl, style: const TextStyle(color: Colors.white), decoration: _dec('Indirizzo'))),
      SizedBox(width: isDesktop ? 120 : w, child: TextFormField(controller: _capClienteCtrl, style: const TextStyle(color: Colors.white), decoration: _dec('CAP'))),
      SizedBox(width: w, child: TextFormField(controller: _cittaCtrl, style: const TextStyle(color: Colors.white), decoration: _dec('Città'))),
      SizedBox(width: w, child: TextFormField(controller: _pivaCtrl, style: const TextStyle(color: Colors.white), decoration: _dec('P.IVA / Codice Fiscale'))),
      SizedBox(width: w, child: TextFormField(controller: _codiceUnivocoCtrl, style: const TextStyle(color: Colors.white), decoration: _dec('Codice Univoco'))),
      SizedBox(width: w, child: TextFormField(controller: _referenteCtrl, style: const TextStyle(color: Colors.white), decoration: _dec('C/A Referente'))),
    ];
  }

  // ─── GRUPPO 4 ─────────────────────────────────────────────────────────────

  List<Widget> _buildGruppo4(bool isDesktop) {
    final w = isDesktop ? 280.0 : double.infinity;
    return [
      SizedBox(
        width: w,
        child: CategoriaDropdown(
          categoriaId: 'campioni_riferimento',
          label: 'Campione di riferimento *',
          initialValue: _campioneRiferimento,
          onChanged: (v) {
            setState(() => _campioneRiferimento = v);
            // Carica preset automaticamente se disponibile e lista vuota
            if (v != null &&
                _parametriReport.isEmpty &&
                _mapCampionePreset
                    .containsKey(v.toLowerCase().trim())) {
              _caricaPresetDaCampione(v);
            }
          },
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
      SizedBox(
        width: isDesktop ? w * 2 + 16 : w,
        child: _buildDropdownIndirizzoPrelievo(
            isDesktop ? w * 2 + 16 : w),
      ),
      SizedBox(
        width: w,
        child: TextFormField(
          controller: _capCittaPrelievoCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: _dec('CAP/Città prelievo'),
          onChanged: _onCapPrelievoChanged,
        ),
      ),
      SizedBox(width: w, child: TextFormField(controller: _puntoPresaCtrl, style: const TextStyle(color: Colors.white), decoration: _dec('Punto presa'))),
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

  Widget _buildDropdownIndirizzoPrelievo(double width) {
    final clienteSelezionato = _codiceClienteId.isNotEmpty;
    final items = <DropdownMenuItem<String>>[];
    if (clienteSelezionato && _clienteSelezionato != null) {
      final c = _clienteSelezionato!;
      final indirizzoP =
          c.indirizzoServizio.isNotEmpty ? c.indirizzoServizio : c.indirizzo;
      final cittaP =
          c.cittaServizio.isNotEmpty ? c.cittaServizio : c.citta;
      items.add(DropdownMenuItem(
        value: 'principale',
        child: Text(
            'Indirizzo principale — $indirizzoP${cittaP.isNotEmpty ? ", $cittaP" : ""}',
            overflow: TextOverflow.ellipsis),
      ));
      for (final addr in _indirizziServizio) {
        final label = [
          addr.indirizzo,
          if (addr.citta.isNotEmpty) addr.citta,
          if (addr.referente.isNotEmpty) '(${addr.referente})',
        ].join(' ');
        items.add(DropdownMenuItem(
            value: addr.id,
            child: Text(label, overflow: TextOverflow.ellipsis)));
      }
    }
    return DropdownButtonFormField<String>(
      initialValue: _indirizzoPrelievoId,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      dropdownColor: const Color(0xFF0A2A1A),
      iconEnabledColor: AppColors.textOnDarkSecondary,
      decoration: _dec('Indirizzo/Coordinate prelievo servizio').copyWith(
        hintText: clienteSelezionato
            ? 'Seleziona indirizzo...'
            : 'Seleziona prima un cliente',
        hintStyle: const TextStyle(
            color: AppColors.textOnDarkSecondary, fontSize: 13),
      ),
      items: items,
      onChanged:
          clienteSelezionato ? _onIndirizzoPrelievoSelezionato : null,
      isExpanded: true,
    );
  }

  // ─── GRUPPO 5 ─────────────────────────────────────────────────────────────

  List<Widget> _buildGruppo5(bool isDesktop) {
    final w = isDesktop ? 280.0 : double.infinity;
    return [
      SizedBox(width: w, child: TextFormField(controller: _emailCtrl, style: const TextStyle(color: Colors.white), decoration: _dec('Email'), keyboardType: TextInputType.emailAddress)),
      SizedBox(width: w, child: TextFormField(controller: _telefonoCtrl, style: const TextStyle(color: Colors.white), decoration: _dec('Telefono'), keyboardType: TextInputType.phone)),
      SizedBox(width: w, child: TextFormField(controller: _pecCtrl, style: const TextStyle(color: Colors.white), decoration: _dec('PEC'), keyboardType: TextInputType.emailAddress)),
    ];
  }

  // ─── GRUPPO 6 ─────────────────────────────────────────────────────────────

  List<Widget> _buildGruppo6(bool isDesktop) {
    final w = isDesktop ? 400.0 : double.infinity;
    return [
      SizedBox(width: w, child: TextFormField(controller: _notePrezzoCtrl, style: const TextStyle(color: Colors.white), decoration: _dec('Note prezzo'), maxLines: 3)),
      SizedBox(
        width: isDesktop ? 200 : w,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SwitchListTile(title: const Text('FT', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textOnDark)), value: _ft, onChanged: (v) => setState(() => _ft = v), activeThumbColor: AppColors.accentGreenDark, contentPadding: EdgeInsets.zero, dense: true),
          SwitchListTile(title: const Text('Fattura pagata', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textOnDark)), value: _fatturaPagata, onChanged: (v) => setState(() => _fatturaPagata = v), activeThumbColor: AppColors.accentGreenDark, contentPadding: EdgeInsets.zero, dense: true),
        ]),
      ),
      SizedBox(width: w, child: TextFormField(controller: _noteTecnicheCtrl, style: const TextStyle(color: Colors.white), decoration: _dec('Note tecniche'), maxLines: 4)),
    ];
  }

  // ─── WIDGET CONDIVISI ─────────────────────────────────────────────────────

  Widget _buildCampoSolaLettura({required String label, required TextEditingController controller}) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.accentGreenDark),
      decoration: _dec(label).copyWith(filled: true, fillColor: const Color(0x0DFFFFFF)),
    );
  }

  Widget _buildBottoniAzione() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.glassDarkest,
        border: Border(top: BorderSide(color: AppColors.glassBorder, width: 0.5)),
      ),
      child: Row(children: [
        OutlinedButton(
          onPressed: _isSaving ? null : _chiudiPagina,
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.textOnDarkSecondary, side: BorderSide(color: AppColors.glassBorder, width: 0.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: const Text('Annulla'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: _isSaving ? null : _esci,
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.textOnDarkSecondary, side: BorderSide(color: AppColors.glassBorder, width: 0.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: _isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: AppColors.accentGreenDark, strokeWidth: 2)) : const Text('Esci'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: _isSaving ? null : _salva,
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary.withValues(alpha: 0.30), foregroundColor: AppColors.accentGreenDark, side: BorderSide(color: AppColors.primary.withValues(alpha: 0.50), width: 0.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: _isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: AppColors.accentGreenDark, strokeWidth: 2)) : const Text('Salva'),
          ),
        ),
      ]),
    );
  }

  Widget _buildGlassScaffold({required String titolo, required bool isModifica, required Widget body}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.gradientStart, AppColors.gradientMid1, AppColors.gradientMid2, AppColors.gradientEnd],
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: AppColors.glassDarkest,
          title: Text(titolo, style: const TextStyle(color: AppColors.textOnDark, fontWeight: FontWeight.w600)),
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textOnDark), onPressed: _gestisciBackNavigation),
          actions: [
            if (isModifica)
              IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.error), tooltip: 'Elimina servizio', onPressed: _isSaving ? null : _elimina),
          ],
        ),
        body: body,
      ),
    );
  }

  InputDecoration _dec(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.glassFieldLabelDim, fontSize: 13),
      filled: true,
      fillColor: const Color(0x0DFFFFFF),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.glassBorder, width: 0.5)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.glassBorder, width: 0.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.error, width: 0.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}

// ─── Popup gestione parametri report (quasi fullscreen) ───────────────────────

class _ReportPopup extends StatefulWidget {
  final List<ParametroReport> parametriIniziali;
  final String? campioneRiferimento;
  final RegistroService registroService;
  final void Function(List<ParametroReport>) onSalva;

  const _ReportPopup({
    required this.parametriIniziali,
    required this.campioneRiferimento,
    required this.registroService,
    required this.onSalva,
  });

  @override
  State<_ReportPopup> createState() => _ReportPopupState();
}

class _ReportPopupState extends State<_ReportPopup> {
  late List<ParametroReport> _parametri;
  String? _categoriaSelezionata;
  bool _caricando = false;

  @override
  void initState() {
    super.initState();
    _parametri = List.from(widget.parametriIniziali);
    final categorie = _parametri.map((p) => p.categoria).toSet().toList();
    if (categorie.isNotEmpty) _categoriaSelezionata = categorie.first;
  }

  List<String> get _categorie =>
      _parametri.map((p) => p.categoria).toSet().toList();

  List<ParametroReport> get _parametriCategoria => _categoriaSelezionata == null
      ? _parametri
      : _parametri
          .where((p) => p.categoria == _categoriaSelezionata)
          .toList();

  Future<void> _caricaPreset() async {
    final campione = widget.campioneRiferimento;
    if (campione == null) return;
    final nomePreset =
        _mapCampionePreset[campione.toLowerCase().trim()];
    if (nomePreset == null) return;

    setState(() => _caricando = true);
    try {
      final presets =
          await widget.registroService.getPreset().first;
      final preset = presets
          .where((p) =>
              p.nome.toLowerCase() == nomePreset.toLowerCase())
          .firstOrNull;
      if (preset == null || !mounted) return;

      final nuovi = preset.categorie
          .expand((cat) => cat.parametri)
          .map((p) => ParametroReport(
                parametro: p.parametro,
                um: p.um,
                vl: p.vl,
                loq: p.loq,
                i: p.i,
                metodoRif: p.metodoRif,
                categoria: p.categoria,
                risultato: '',
              ))
          .toList();

      setState(() {
        _parametri = nuovi;
        final categorie = _parametri.map((p) => p.categoria).toSet().toList();
        _categoriaSelezionata =
            categorie.isNotEmpty ? categorie.first : null;
      });
    } finally {
      if (mounted) setState(() => _caricando = false);
    }
  }

  // Apre dialog modifica/aggiunta parametro con tutti i campi editabili
  void _modificaParametro(ParametroReport? esistente) async {
    final parametroCtrl =
        TextEditingController(text: esistente?.parametro ?? '');
    final umCtrl = TextEditingController(text: esistente?.um ?? '');
    final vlCtrl = TextEditingController(text: esistente?.vl ?? '');
    final loqCtrl = TextEditingController(text: esistente?.loq ?? '');
    final iCtrl = TextEditingController(text: esistente?.i ?? '');
    final metodoCtrl =
        TextEditingController(text: esistente?.metodoRif ?? '');
    final risultatoCtrl =
        TextEditingController(text: esistente?.risultato ?? '');

    InputDecoration dec(String label, {String? hint}) => InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(
              color: AppColors.textOnDarkSecondary, fontSize: 12),
          hintStyle: const TextStyle(
              color: AppColors.textOnDarkMuted, fontSize: 12),
          filled: true,
          fillColor: const Color(0x0DFFFFFF),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: AppColors.glassBorder, width: 0.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: AppColors.glassBorder, width: 0.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          isDense: true,
        );

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A2A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.glassBorder, width: 0.5),
        ),
        title: Text(
          esistente == null ? 'Nuovo parametro' : 'Modifica parametro',
          style: const TextStyle(
              color: AppColors.textOnDark,
              fontWeight: FontWeight.w600,
              fontSize: 14),
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Parametro
                TextField(
                  controller: parametroCtrl,
                  style: const TextStyle(
                      color: AppColors.textOnDark, fontSize: 13),
                  decoration: dec('Parametro *'),
                  autofocus: esistente == null,
                ),
                const SizedBox(height: 10),
                // U.M. + LoQ
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: umCtrl,
                      style: const TextStyle(
                          color: AppColors.textOnDark, fontSize: 13),
                      decoration: dec('U.M.'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: loqCtrl,
                      style: const TextStyle(
                          color: AppColors.textOnDark, fontSize: 13),
                      decoration: dec('LoQ'),
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                // V.L.
                TextField(
                  controller: vlCtrl,
                  style: const TextStyle(
                      color: AppColors.textOnDark, fontSize: 13),
                  decoration: dec('V.L. (Valore limite)'),
                ),
                const SizedBox(height: 10),
                // I — Incertezza
                TextField(
                  controller: iCtrl,
                  style: const TextStyle(
                      color: AppColors.textOnDark, fontSize: 13),
                  decoration: dec('I (Incertezza estesa)'),
                ),
                const SizedBox(height: 10),
                // Metodo
                TextField(
                  controller: metodoCtrl,
                  style: const TextStyle(
                      color: AppColors.textOnDark, fontSize: 13),
                  decoration: dec('Metodo di riferimento'),
                ),
                const SizedBox(height: 14),
                // Divisore
                Container(
                    height: 0.5, color: AppColors.glassBorderSubtle),
                const SizedBox(height: 14),
                // Risultato
                TextField(
                  controller: risultatoCtrl,
                  style: const TextStyle(
                      color: AppColors.textOnDark, fontSize: 13),
                  decoration: dec('Risultato',
                      hint: 'Es. <LOQ, 0,12, non det...'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla',
                style:
                    TextStyle(color: AppColors.textOnDarkSecondary)),
          ),
          FilledButton(
            onPressed: () {
              if (parametroCtrl.text.trim().isEmpty) return;
              setState(() {
                if (esistente == null) {
                  // Aggiungi nuovo
                  _parametri.add(ParametroReport(
                    parametro: parametroCtrl.text.trim(),
                    um: umCtrl.text.trim(),
                    vl: vlCtrl.text.trim(),
                    loq: loqCtrl.text.trim(),
                    i: iCtrl.text.trim(),
                    metodoRif: metodoCtrl.text.trim(),
                    categoria: _categoriaSelezionata ?? 'altro',
                    risultato: risultatoCtrl.text.trim(),
                  ));
                } else {
                  // Modifica esistente
                  final idx = _parametri.indexOf(esistente);
                  if (idx != -1) {
                    _parametri[idx] = esistente.copyWith(
                      parametro: parametroCtrl.text.trim(),
                      um: umCtrl.text.trim(),
                      vl: vlCtrl.text.trim(),
                      loq: loqCtrl.text.trim(),
                      i: iCtrl.text.trim(),
                      metodoRif: metodoCtrl.text.trim(),
                      risultato: risultatoCtrl.text.trim(),
                    );
                  }
                }
              });
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary.withValues(alpha: 0.30),
              foregroundColor: AppColors.accentGreenDark,
              side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.50),
                  width: 0.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }

  Widget _infoRiga(String label, String valore) {
    if (valore.isEmpty || valore == '-') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textOnDarkMuted)),
          ),
          Expanded(
            child: Text(valore,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textOnDark)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final hasPreset = _mapCampionePreset.containsKey(
        widget.campioneRiferimento?.toLowerCase().trim() ?? '');

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: size.width,
        height: size.height * 0.92,
        decoration: BoxDecoration(
          color: const Color(0xFF0A2A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassBorder, width: 0.5),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              decoration: BoxDecoration(
                color: AppColors.glassDarkest,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16)),
                border: Border(
                    bottom: BorderSide(
                        color: AppColors.glassBorder, width: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.biotech_outlined,
                      color: AppColors.accentGreenDark, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Report analitico',
                            style: TextStyle(
                                color: AppColors.textOnDark,
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                        if (widget.campioneRiferimento != null)
                          Text(widget.campioneRiferimento!,
                              style: const TextStyle(
                                  color: AppColors.textOnDarkSecondary,
                                  fontSize: 12)),
                      ],
                    ),
                  ),
                  // Bottone carica preset
                  if (hasPreset)
                    OutlinedButton.icon(
                      onPressed: _caricando ? null : _caricaPreset,
                      icon: _caricando
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                  color: AppColors.accentGreenDark,
                                  strokeWidth: 2))
                          : const Icon(Icons.download_outlined, size: 14),
                      label: Text(_parametri.isEmpty
                          ? 'Carica preset'
                          : 'Ricarica preset'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accentGreenDark,
                        side: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.50),
                            width: 0.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: AppColors.textOnDarkMuted, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Tab categorie
            if (_categorie.isNotEmpty)
              Container(
                color: AppColors.glassDark,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  child: Row(
                    children: _categorie.map((cat) {
                      final isSelected = cat == _categoriaSelezionata;
                      final count = _parametri
                          .where((p) => p.categoria == cat)
                          .length;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _categoriaSelezionata = cat),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.30)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.60)
                                  : AppColors.glassBorder,
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            '${cat.replaceAll('_', ' ')} ($count)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? AppColors.accentGreenDark
                                  : AppColors.textOnDarkSecondary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

            // Lista parametri
            Expanded(
              child: _parametri.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.science_outlined,
                              size: 48, color: AppColors.textOnDarkMuted),
                          const SizedBox(height: 12),
                          Text(
                            hasPreset
                                ? 'Clicca "Carica preset" per importare i parametri\ndal Registro Acque.'
                                : 'Nessun parametro caricato.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textOnDarkSecondary),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          // Intestazione tabella
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.glassDarkest,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: AppColors.glassBorder,
                                  width: 0.5),
                            ),
                            child: const Row(
                              children: [
                                Expanded(flex: 3, child: Text('PARAMETRO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textOnDarkMuted, letterSpacing: 0.5))),
                                Expanded(flex: 1, child: Text('U.M.', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textOnDarkMuted, letterSpacing: 0.5))),
                                Expanded(flex: 2, child: Text('V.L.', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textOnDarkMuted, letterSpacing: 0.5))),
                                Expanded(flex: 1, child: Text('LoQ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textOnDarkMuted, letterSpacing: 0.5))),
                                Expanded(flex: 1, child: Text('I', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textOnDarkMuted, letterSpacing: 0.5))),
                                Expanded(flex: 2, child: Text('METODO RIF.', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textOnDarkMuted, letterSpacing: 0.5))),
                                SizedBox(width: 40),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          ..._parametriCategoria.map((p) => Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.glassCard,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: AppColors.glassBorderSubtle,
                                      width: 0.5),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(flex: 3, child: Text(p.parametro, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textOnDark))),
                                    Expanded(flex: 1, child: Text(p.um, style: const TextStyle(fontSize: 11, color: AppColors.textOnDarkSecondary))),
                                    Expanded(flex: 2, child: Text(p.vl, style: const TextStyle(fontSize: 11, color: AppColors.textOnDarkSecondary))),
                                    Expanded(flex: 1, child: Text(p.loq, style: const TextStyle(fontSize: 11, color: AppColors.textOnDarkSecondary))),
                                    Expanded(flex: 1, child: Text(p.i, style: const TextStyle(fontSize: 11, color: AppColors.textOnDarkSecondary))),
                                    Expanded(flex: 2, child: Text(p.metodoRif, style: const TextStyle(fontSize: 10, color: AppColors.textOnDarkMuted), maxLines: 2, overflow: TextOverflow.ellipsis)),
                                    SizedBox(
                                      width: 56,
                                      child: Row(
                                        children: [
                                          GestureDetector(
                                            onTap: () => _modificaParametro(p),
                                            child: const Icon(Icons.edit_outlined, size: 16, color: AppColors.textOnDarkSecondary),
                                          ),
                                          const SizedBox(width: 8),
                                          GestureDetector(
                                            onTap: () async {
                                              final ok = await showDialog<bool>(
                                                context: context,
                                                builder: (ctx) => AlertDialog(
                                                  backgroundColor: const Color(0xFF0A2A1A),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppColors.glassBorder, width: 0.5)),
                                                  title: const Text('Elimina parametro', style: TextStyle(color: AppColors.textOnDark, fontWeight: FontWeight.w600)),
                                                  content: Text('Eliminare "${p.parametro}"?', style: const TextStyle(color: AppColors.textOnDarkSecondary)),
                                                  actions: [
                                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla', style: TextStyle(color: AppColors.textOnDarkSecondary))),
                                                    FilledButton(
                                                      onPressed: () => Navigator.pop(ctx, true),
                                                      style: FilledButton.styleFrom(backgroundColor: AppColors.error.withValues(alpha: 0.25), foregroundColor: const Color(0xFFFF7070), side: BorderSide(color: AppColors.error.withValues(alpha: 0.40), width: 0.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                                      child: const Text('Elimina'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              if (ok == true) {
                                                setState(() => _parametri.remove(p));
                                              }
                                            },
                                            child: Icon(Icons.delete_outline, size: 16, color: AppColors.error.withValues(alpha: 0.7)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              decoration: BoxDecoration(
                color: AppColors.glassDarkest,
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16)),
                border: Border(
                    top: BorderSide(
                        color: AppColors.glassBorder, width: 0.5)),
              ),
              child: Row(
                children: [
                  Text(
                    '${_parametri.length} parametri totali',
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textOnDarkSecondary),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => _modificaParametro(null),
                    icon: const Icon(Icons.add, size: 14),
                    label: const Text('Aggiungi'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accentGreenDark,
                      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.50), width: 0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textOnDarkSecondary,
                      side: BorderSide(
                          color: AppColors.glassBorder, width: 0.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Annulla'),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: () {
                      widget.onSalva(_parametri);
                      Navigator.pop(context);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.30),
                      foregroundColor: AppColors.accentGreenDark,
                      side: BorderSide(
                          color:
                              AppColors.primary.withValues(alpha: 0.50),
                          width: 0.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Conferma'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Widget riutilizzabile per i gruppi del form ──────────────────────────────

class _GruppoCard extends StatelessWidget {
  final String titolo;
  final IconData icona;
  final bool isDesktop;
  final List<Widget> campi;
  final bool isAperta;
  final VoidCallback? onToggle;
  final String preview;

  const _GruppoCard({
    required this.titolo,
    required this.icona,
    required this.isDesktop,
    required this.campi,
    this.isAperta = true,
    this.onToggle,
    this.preview = '',
  });

  @override
  Widget build(BuildContext context) {
    if (isDesktop) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.glassCardMedium,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.glassBorderMedium, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
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
                child: Icon(icona, color: AppColors.accentGreenDark, size: 14),
              ),
              const SizedBox(width: 8),
              Text(titolo,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentGreenDark,
                      letterSpacing: 0.3)),
            ]),
            Container(
                height: 0.5,
                color: const Color(0x26FFFFFF),
                margin: const EdgeInsets.symmetric(vertical: 10)),
            Wrap(spacing: 16, runSpacing: 16, children: campi),
          ],
        ),
      );
    }

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
                    child:
                        Icon(icona, color: AppColors.accentGreenDark, size: 14),
                  ),
                  const SizedBox(width: 8),
                  Text(titolo,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentGreenDark,
                          letterSpacing: 0.3)),
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: campi
                          .expand((w) => [w, const SizedBox(height: 14)])
                          .toList()
                        ..removeLast(),
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
}

enum _SceltaEsci { annulla, bozza, salva }
