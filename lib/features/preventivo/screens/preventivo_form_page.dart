import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/service_providers.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/preventivo/preventivo_preview_page.dart';
import '../../../models/cliente_model.dart';
import '../../../models/listino_model.dart';
import '../../../models/preventivo_model.dart';
import '../../../services/cap_service.dart';
import '../../../services/clienti_service.dart';
import '../../../services/listino_service.dart';
import '../../../services/preventivi_service.dart';
import '../../../services/preventivo_pdf_service.dart';
import '../../../widgets/categoria_dropdown.dart';

/// Form per la creazione e modifica di un preventivo.
/// Replica fedelmente il layout del documento cartaceo BioChem.
class PreventivoFormPage extends ConsumerStatefulWidget {
  final String? preventivoId;
  const PreventivoFormPage({super.key, this.preventivoId});

  @override
  ConsumerState<PreventivoFormPage> createState() => _PreventivoFormPageState();
}

class _PreventivoFormPageState extends ConsumerState<PreventivoFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final PreventiviService _preventiviService;
  late final ClientiService _clientiService;
  late final CapService _capService;
  late final ListinoService _listinoService;
  late final PreventivoPdfService _pdfService;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _erroreCaricamento;
  String? _preventivoIdCorrente;
  bool _allowDirectPop = false;
  bool _gruppo1Aperta = true;
  bool _gruppo2Aperta = true;
  bool _gruppo3Aperta = true;
  bool _gruppo4Aperta = true;
  bool _gruppo5Aperta = true;
  bool _gruppo6Aperta = true;
  Map<String, Object?>? _snapshotIniziale;
  PreventivoModel? _preventivoOriginale;

  List<ClienteModel> _clienti = [];
  List<TipologiaListino> _tipologie = [];

  // ─── Gruppo 1 — Intestazione documento ───────────────────────────────────
  int? _numeroPrev;
  DateTime _dataPrev = DateTime.now();
  final _dataCtrl = TextEditingController();
  final _oraCtrl = TextEditingController();

  // ─── Gruppo 2 — Dati cliente ──────────────────────────────────────────────
  final _clienteDisplayCtrl = TextEditingController();
  String _codiceClienteId = '';

  // Sinistra (dati azienda)
  final _committenteCtrl = TextEditingController();
  final _indirizzoCommCtrl = TextEditingController();
  final _capCommCtrl = TextEditingController();
  final _cittaCommCtrl = TextEditingController();
  final _provCommCtrl = TextEditingController();
  final _codiceFiscaleCtrl = TextEditingController();
  final _codiceUnivocoCtrl = TextEditingController();

  // Destra (spett. / alla cortese att.)
  final _spettCtrl = TextEditingController();
  final _allaCorteseDiCtrl = TextEditingController();
  final _indirizzoSpettCtrl = TextEditingController();
  final _cittaSpettCtrl = TextEditingController();
  final _piSpettCtrl = TextEditingController();
  final _cuSpettCtrl = TextEditingController();

  // Indirizzo servizio e oggetto
  final _indirizzoServizioCtrl = TextEditingController();
  final _oggettoCtrl = TextEditingController();

  // ─── Gruppo 3 — Dettaglio servizi ─────────────────────────────────────────
  String? _giornataEsecuzione;
  String? _tipologiaServizi;
  final List<_RigaController> _righeCtrl = [];

  // ─── Gruppo 4 — Condizioni ────────────────────────────────────────────────
  final _pagamentoCtrl = TextEditingController();
  final _durataContrattoCtrl = TextEditingController();
  String? _rinnovoScadenza;
  final _periodoInterventoCtrl = TextEditingController();
  final _validitaCtrl = TextEditingController(text: '30 giorni');

  // ─── Gruppo 5 — Note ─────────────────────────────────────────────────────
  final _noteCtrl = TextEditingController();

  // ─── Gruppo 6 — IBAN e causale ────────────────────────────────────────────
  final _ibanCtrl = TextEditingController();
  final _intestatoACtrl = TextEditingController();
  final _causaleCtrl = TextEditingController();

  // ─── Totali ───────────────────────────────────────────────────────────────
  double _imponibile = 0;
  double _totale = 0;

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
    _listinoService = ref.read(listinoServiceProvider);
    _pdfService = ref.read(preventivoPdfServiceProvider);
    _dataCtrl.text = _dateFmt.format(_dataPrev);
    _oraCtrl.text = DateFormat('HH:mm').format(DateTime.now());
    _inizializza();
  }

  @override
  void dispose() {
    _dataCtrl.dispose();
    _oraCtrl.dispose();
    _clienteDisplayCtrl.dispose();
    _committenteCtrl.dispose();
    _indirizzoCommCtrl.dispose();
    _capCommCtrl.dispose();
    _cittaCommCtrl.dispose();
    _provCommCtrl.dispose();
    _codiceFiscaleCtrl.dispose();
    _codiceUnivocoCtrl.dispose();
    _spettCtrl.dispose();
    _allaCorteseDiCtrl.dispose();
    _indirizzoSpettCtrl.dispose();
    _cittaSpettCtrl.dispose();
    _piSpettCtrl.dispose();
    _cuSpettCtrl.dispose();
    _indirizzoServizioCtrl.dispose();
    _oggettoCtrl.dispose();
    _pagamentoCtrl.dispose();
    _durataContrattoCtrl.dispose();
    _periodoInterventoCtrl.dispose();
    _validitaCtrl.dispose();
    _noteCtrl.dispose();
    _ibanCtrl.dispose();
    _intestatoACtrl.dispose();
    _causaleCtrl.dispose();
    for (final r in _righeCtrl) {
      r.dispose();
    }
    super.dispose();
  }

  // ─── Inizializzazione ─────────────────────────────────────────────────────

  Future<void> _inizializza() async {
    try {
      final risultati = await Future.wait([
        _clientiService.getClienti().first,
      ]);
      _clienti = risultati[0];
      _tipologie = await _listinoService.getTipologie();

      if (widget.preventivoId != null) {
        final p =
            await _preventiviService.getPreventivoById(widget.preventivoId!);
        if (p != null) {
          _preventivoOriginale = p;
          _popolaDaModello(p);
        }
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

  void _popolaDaModello(PreventivoModel p) {
    _numeroPrev = p.numeroPrev;
    _dataPrev = p.data;
    _dataCtrl.text = _dateFmt.format(p.data);
    _oraCtrl.text =
        p.ora.isNotEmpty ? p.ora : DateFormat('HH:mm').format(DateTime.now());
    _codiceClienteId = p.codiceCliente;
    _clienteDisplayCtrl.text = p.committente;

    _committenteCtrl.text = p.committente;
    _indirizzoCommCtrl.text = p.indirizzoCommittente;
    _capCommCtrl.text = p.cap;
    _cittaCommCtrl.text = p.citta;
    _provCommCtrl.text = p.provincia;
    _codiceFiscaleCtrl.text = p.codiceFiscale;
    _codiceUnivocoCtrl.text = p.codiceUnivoco;

    _spettCtrl.text = p.spett;
    _allaCorteseDiCtrl.text = p.allaCorteseDi;
    _indirizzoSpettCtrl.text = p.indirizzoSpett;
    _cittaSpettCtrl.text = p.cittaSpett;
    _piSpettCtrl.text = p.piSpett;
    _cuSpettCtrl.text = p.cuSpett;

    _indirizzoServizioCtrl.text = p.indirizzoServizio;
    _oggettoCtrl.text = p.oggetto;

    _giornataEsecuzione =
        p.giornataEsecuzione.isNotEmpty ? p.giornataEsecuzione : null;
    _tipologiaServizi =
        p.tipologiaServizi.isNotEmpty ? p.tipologiaServizi : null;

    for (final riga in p.righe) {
      _righeCtrl.add(_RigaController.fromRiga(riga));
    }

    _pagamentoCtrl.text = p.pagamento;
    _durataContrattoCtrl.text = p.durataContratto;
    _rinnovoScadenza = p.rinnovoScadenza.isNotEmpty ? p.rinnovoScadenza : null;
    _periodoInterventoCtrl.text = p.periodoIntervento;
    _validitaCtrl.text = p.validita;

    _noteCtrl.text = p.note;
    _ibanCtrl.text = p.iban;
    _intestatoACtrl.text = p.intestatoA;
    _causaleCtrl.text = p.causale;

    _ricalcola();
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

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

  Future<void> _selezionaOra() async {
    final parts = _oraCtrl.text.split(':');
    final init = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? TimeOfDay.now().hour,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
    final sel = await showTimePicker(context: context, initialTime: init);
    if (sel != null && mounted) {
      setState(() {
        _oraCtrl.text =
            '${sel.hour.toString().padLeft(2, '0')}:${sel.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  void _onClienteSelezionato(ClienteModel c) {
    setState(() {
      _codiceClienteId = c.id;
      _clienteDisplayCtrl.text = '${c.numeroFormattato} — ${c.committente}';
      _committenteCtrl.text = c.committente;
      _indirizzoCommCtrl.text = c.indirizzo;
      _capCommCtrl.text = c.cap;
      _cittaCommCtrl.text = c.citta;
      _provCommCtrl.text = c.provincia;
      _codiceFiscaleCtrl.text = c.pivaCodiceFiscale;
      _codiceUnivocoCtrl.text = c.codiceUnivoco;
      // Destra: pre-compila con stessi dati, modificabili
      _spettCtrl.text = c.committente;
      _allaCorteseDiCtrl.text = c.referente;
      _indirizzoSpettCtrl.text = c.indirizzo;
      _cittaSpettCtrl.text = '${c.cap} ${c.citta}';
      _piSpettCtrl.text = c.pivaCodiceFiscale;
      _cuSpettCtrl.text = c.codiceUnivoco;
      _indirizzoServizioCtrl.text = c.indirizzoServizio;
      _intestatoACtrl.text = c.committente;
    });
  }

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

  void _aggiungiRiga() => setState(() => _righeCtrl.add(_RigaController()));

  void _rimuoviRiga(int i) {
    _righeCtrl[i].dispose();
    setState(() {
      _righeCtrl.removeAt(i);
      _ricalcola();
    });
  }

  void _ricalcola() {
    double arrotonda(double v) => double.parse(v.toStringAsFixed(2));
    double parseDbl(String t) => double.tryParse(t.replaceAll(',', '.')) ?? 0.0;

    double imponibile = 0;
    for (final r in _righeCtrl) {
      final prezzo = parseDbl(r.prezzoCtrl.text);
      final qta = int.tryParse(r.qtaCtrl.text) ?? 0;
      final sconto = parseDbl(r.scontoCtrl.text);
      r.costoCaduno = arrotonda(prezzo - prezzo * sconto / 100);
      r.importo = arrotonda(r.costoCaduno * qta);
      imponibile += r.importo;
    }
    _imponibile = arrotonda(imponibile);
    _totale = _imponibile;
    setState(() {});
  }

  // ─── Modello ──────────────────────────────────────────────────────────────

  PreventivoModel _costruisciModello({bool isDraft = false}) {
    double parseDbl(String t) => double.tryParse(t.replaceAll(',', '.')) ?? 0.0;
    final righe = _righeCtrl
        .map((r) => PreventivoRiga(
              codice: r.codice,
              descrizione: r.descrizioneCtrl.text.trim(),
              giornata: '',
              prezzoUnitario: parseDbl(r.prezzoCtrl.text),
              quantita: int.tryParse(r.qtaCtrl.text) ?? 0,
              scontoPerc: parseDbl(r.scontoCtrl.text),
              importo: r.importo,
            ))
        .toList();

    // Genera causale automatica se vuota
    final causale = _causaleCtrl.text.trim().isNotEmpty
        ? _causaleCtrl.text.trim()
        : '${_numeroPrev ?? ''} ${_oraCtrl.text}';

    return PreventivoModel(
      id: _preventivoIdCorrente ?? '',
      numeroPrev: _numeroPrev ?? 0,
      data: _dataPrev,
      ora: _oraCtrl.text.trim(),
      codiceCliente: _codiceClienteId,
      committente: _committenteCtrl.text.trim(),
      indirizzoCommittente: _indirizzoCommCtrl.text.trim(),
      cap: _capCommCtrl.text.trim(),
      citta: _cittaCommCtrl.text.trim(),
      provincia: _provCommCtrl.text.trim(),
      codiceFiscale: _codiceFiscaleCtrl.text.trim(),
      codiceUnivoco: _codiceUnivocoCtrl.text.trim(),
      spett: _spettCtrl.text.trim(),
      allaCorteseDi: _allaCorteseDiCtrl.text.trim(),
      indirizzoSpett: _indirizzoSpettCtrl.text.trim(),
      cittaSpett: _cittaSpettCtrl.text.trim(),
      piSpett: _piSpettCtrl.text.trim(),
      cuSpett: _cuSpettCtrl.text.trim(),
      indirizzoServizio: _indirizzoServizioCtrl.text.trim(),
      oggetto: _oggettoCtrl.text.trim(),
      giornataEsecuzione: _giornataEsecuzione ?? '',
      tipologiaServizi: _tipologiaServizi ?? '',
      righe: righe,
      pagamento: _pagamentoCtrl.text.trim(),
      durataContratto: _durataContrattoCtrl.text.trim(),
      rinnovoScadenza: _rinnovoScadenza ?? '',
      periodoIntervento: _periodoInterventoCtrl.text.trim(),
      validita: _validitaCtrl.text.trim(),
      note: _noteCtrl.text.trim(),
      iban: _ibanCtrl.text.trim(),
      intestatoA: _intestatoACtrl.text.trim(),
      causale: causale,
      imponibile: _imponibile,
      totale: _totale,
      isDraft: isDraft,
      createdAt: _preventivoOriginale?.createdAt ?? DateTime.now(),
    );
  }

  Map<String, Object?> _snapshotCorrente() {
    final m =
        _costruisciModello(isDraft: _preventivoOriginale?.isDraft ?? false);
    return {
      'committente': m.committente,
      'data': m.data.toIso8601String(),
      'righe': m.righe.map((r) => r.toMap().toString()).join('|'),
      'giornata': m.giornataEsecuzione,
      'tipologia': m.tipologiaServizi,
      'pagamento': m.pagamento,
      'note': m.note,
      'iban': m.iban,
    };
  }

  bool get _hasUnsavedChanges {
    final iniziale = _snapshotIniziale;
    if (iniziale == null) return false;
    return iniziale.toString() != _snapshotCorrente().toString();
  }

  bool get _canSaveAsDraft =>
      _preventivoIdCorrente == null || (_preventivoOriginale?.isDraft ?? false);

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
      if (_numeroPrev == null && !isDraft) {
        _numeroPrev = await _preventiviService.generaNumeroPrev(_dataPrev);
      }
      final modello = _costruisciModello(isDraft: isDraft);
      final id = await _preventiviService.salvaPreventivo(modello);
      _preventivoIdCorrente = id;
      _preventivoOriginale = modello;
      _snapshotIniziale = _snapshotCorrente();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isDraft ? 'Salvato come bozza' : 'Preventivo salvato', style: const TextStyle(color: Colors.white)),
          backgroundColor: (isDraft ? AppColors.textOnDarkSecondary : AppColors.success).withValues(alpha: 0.90),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 0.5),
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
          content: Text('Errore: $e', style: const TextStyle(color: Colors.white)),
          backgroundColor: AppColors.error.withValues(alpha: 0.90),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 0.5),
          ),
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _salvaEResta() async =>
      _persistiPreventivo(isDraft: false, closeAfterSave: false);

  Future<void> _salvaEsci() async =>
      _persistiPreventivo(isDraft: false, closeAfterSave: true);

  Future<bool> _confermaAzione({
    required String titolo,
    required String contenuto,
    required String confermaLabel,
    bool pericolo = false,
  }) async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A2A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.glassBorder, width: 0.5),
        ),
        title: Text(titolo, style: const TextStyle(color: AppColors.textOnDark, fontWeight: FontWeight.w600, fontSize: 16)),
        content: Text(contenuto, style: const TextStyle(color: AppColors.textOnDarkSecondary, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla', style: TextStyle(color: AppColors.textOnDarkSecondary)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: (pericolo ? AppColors.error : AppColors.primary).withValues(alpha: pericolo ? 0.25 : 0.30),
              foregroundColor: pericolo ? const Color(0xFFFF7070) : AppColors.accentGreenDark,
              side: BorderSide(
                color: (pericolo ? AppColors.error : AppColors.primary).withValues(alpha: pericolo ? 0.40 : 0.50),
                width: 0.5,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(confermaLabel),
          ),
        ],
      ),
    );
    return conferma == true;
  }

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
        title: const Text('Uscire dal form', style: TextStyle(color: AppColors.textOnDark, fontWeight: FontWeight.w600, fontSize: 16)),
        content: Text(
          _canSaveAsDraft
              ? 'Ci sono modifiche non salvate. Cosa vuoi fare?'
              : 'Ci sono modifiche non salvate. Salvarle prima di uscire?',
          style: const TextStyle(color: AppColors.textOnDarkSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, _SceltaEsci.annulla),
              child: const Text('Rimani', style: TextStyle(color: AppColors.textOnDarkSecondary))),
          if (_canSaveAsDraft)
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, _SceltaEsci.bozza),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textOnDarkSecondary,
                side: BorderSide(color: AppColors.glassBorder, width: 0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Salva come bozza'),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, _SceltaEsci.salva),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary.withValues(alpha: 0.30),
              foregroundColor: AppColors.accentGreenDark,
              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.50), width: 0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Salva ed esci'),
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

  Future<void> _mostraAnteprima() async {
    if (_preventivoIdCorrente == null) return;
    final modello = _preventivoOriginale;
    if (modello == null) return;

    final conferma = await _confermaAzione(
      titolo: 'Anteprima e download PDF',
      contenuto: _hasUnsavedChanges
          ? 'Aprire il PDF con i dati salvati in precedenza? Dalla schermata successiva potrai visualizzarlo o scaricarlo.'
          : 'Aprire il PDF di questo preventivo? Dalla schermata successiva potrai visualizzarlo o scaricarlo.',
      confermaLabel: 'Apri PDF',
    );
    if (!conferma || !mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PreventivoPreviewPage(
          buildPdf: () => _pdfService.buildPdfBytes(modello),
          nomeFile: 'preventivo_${modello.numeroFormattato}.pdf',
        ),
      ),
    );
  }

  Future<void> _elimina() async {
    if (_preventivoIdCorrente == null) return;
    final conferma = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A2A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.glassBorder, width: 0.5),
        ),
        title: const Text('Elimina preventivo', style: TextStyle(color: AppColors.textOnDark, fontWeight: FontWeight.w600, fontSize: 16)),
        content: Text('Eliminare il preventivo di ${_committenteCtrl.text.trim()}? Azione irreversibile.', style: const TextStyle(color: AppColors.textOnDarkSecondary, fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annulla', style: TextStyle(color: AppColors.textOnDarkSecondary))),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error.withValues(alpha: 0.25),
              foregroundColor: const Color(0xFFFF7070),
              side: BorderSide(color: AppColors.error.withValues(alpha: 0.40), width: 0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    if (conferma != true || !mounted) return;
    try {
      await _preventiviService.eliminaPreventivo(_preventivoIdCorrente!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Preventivo eliminato', style: TextStyle(color: Colors.white)),
          backgroundColor: AppColors.primary.withValues(alpha: 0.90),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 0.5),
          ),
        ));
        await _chiudiPagina();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Errore: $e', style: const TextStyle(color: Colors.white)),
          backgroundColor: AppColors.error.withValues(alpha: 0.90),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 0.5),
          ),
        ));
      }
    }
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final titolo = _preventivoIdCorrente == null
        ? 'Nuovo preventivo'
        : 'Modifica preventivo';
    final userAsync = ref.watch(currentUserProvider);
    if (userAsync.isLoading) {
      return _buildGlassScaffold(
        titolo: titolo,
        body: const Center(child: CircularProgressIndicator(color: AppColors.accentGreenDark)),
      );
    }
    final user = userAsync.valueOrNull;
    if (user == null || !user.isAdmin) {
      return _buildGlassScaffold(
        titolo: titolo,
        body: const Center(child: Text('Accesso non autorizzato', style: TextStyle(color: AppColors.error))),
      );
    }

    return PopScope(
      canPop: _allowDirectPop,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _esci();
      },
      child: _buildGlassScaffold(
        titolo: titolo,
        actions: [
          if (!_isLoading && _preventivoIdCorrente != null) ...[
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.accentGreenDark),
              tooltip: 'Anteprima e download PDF',
              onPressed: _isSaving ? null : _mostraAnteprima,
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: AppColors.error.withValues(alpha: 0.8)),
              tooltip: 'Elimina',
              onPressed: _isSaving ? null : _elimina,
            ),
          ],
        ],
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.accentGreenDark))
            : _erroreCaricamento != null
                ? Center(child: Text('Errore: $_erroreCaricamento', style: const TextStyle(color: AppColors.error)))
                : Column(children: [
                    Expanded(
                      child: LayoutBuilder(builder: (ctx, constraints) {
                        final isDesktop = constraints.maxWidth >= 600;
                        return Form(
                          key: _formKey,
                          child: SingleChildScrollView(
                            padding: EdgeInsets.all(isDesktop ? 24 : 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildGruppo1(isDesktop),
                                const SizedBox(height: 12),
                                _buildGruppo2(isDesktop),
                                const SizedBox(height: 12),
                                _buildGruppo3(isDesktop),
                                const SizedBox(height: 12),
                                _buildGruppo4(isDesktop),
                                const SizedBox(height: 12),
                                _buildGruppo5(isDesktop),
                                const SizedBox(height: 12),
                                _buildGruppo6(isDesktop),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                    _buildBottoni(),
                  ]),
      ),
    );
  }

  Widget _buildGlassScaffold({
    required String titolo,
    required Widget body,
    List<Widget> actions = const [],
  }) {
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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textOnDark),
            onPressed: _esci,
          ),
          actions: actions,
        ),
        body: body,
      ),
    );
  }

  // ─── Gruppo 1 — Intestazione documento ───────────────────────────────────
  Widget _buildGruppo1(bool isDesktop) {
    final numeroTesto = _numeroPrev == null
        ? 'Auto'
        : '${_dataPrev.year % 100}${(_dataPrev.month).toString().padLeft(2, '0')}${_dataPrev.day.toString().padLeft(2, '0')}${_numeroPrev.toString().padLeft(3, '0')}';

    return _buildGruppoCard(
      titolo: 'Intestazione documento',
      isDesktop: isDesktop,
      icona: Icons.info_outline,
      isAperta: _gruppo1Aperta,
      onToggle: () => setState(() => _gruppo1Aperta = !_gruppo1Aperta),
      preview: _dataCtrl.text,
      children: [
        // Riga: pvr off n°, ora, data
        _buildRiga(isDesktop, [
          TextFormField(
            initialValue: numeroTesto,
            readOnly: true,
            style: const TextStyle(color: Colors.white),
            decoration: _dec('pvr off n°').copyWith(
              filled: true,
              fillColor: const Color(0x0DFFFFFF),
              suffixIcon: const Icon(Icons.lock_outline,
                  size: 16, color: AppColors.textOnDarkMuted),
            ),
          ),
          GestureDetector(
            onTap: _selezionaOra,
            child: AbsorbPointer(
              child: TextFormField(
                controller: _oraCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _dec('Ora').copyWith(
                    suffixIcon:
                        const Icon(Icons.access_time_outlined, size: 18,color: AppColors.textOnDarkMuted)),
              ),
            ),
          ),
          GestureDetector(
            onTap: _selezionaData,
            child: AbsorbPointer(
              child: TextFormField(
                controller: _dataCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _dec('Data').copyWith(
                    suffixIcon:
                        const Icon(Icons.calendar_today_outlined, size: 18,color: AppColors.textOnDarkMuted)),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Obbligatorio' : null,
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
      icona: Icons.person_outline,
      isAperta: _gruppo2Aperta,
      onToggle: () => setState(() => _gruppo2Aperta = !_gruppo2Aperta),
      preview: _committenteCtrl.text,
      children: [
        // Su desktop: 2 colonne (sinistra azienda, destra spett.)
        // Su mobile: colonna singola
        isDesktop
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildDatiSinistra()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDatiDestra()),
                ],
              )
            : Column(children: [
                _buildDatiSinistra(),
                const SizedBox(height: 12),
                _buildDatiDestra(),
              ]),
        const SizedBox(height: 12),
        Container(height: 0.5, color: AppColors.glassBorder, margin: const EdgeInsets.symmetric(vertical: 8)),
        // Indirizzo servizio
        Row(children: [
          const Text('indirizzo servizio:',
              style: TextStyle(fontSize: 12, color: AppColors.textOnDarkSecondary)),
          const SizedBox(width: 8),
          Expanded(
              child: TextFormField(
                  controller: _indirizzoServizioCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _dec('').copyWith(isDense: true))),
        ]),
        const SizedBox(height: 12),
        // Oggetto
        const Text('Oggetto:',
            style: TextStyle(fontSize: 12, color: AppColors.textOnDarkSecondary)),
        const SizedBox(height: 4),
        TextFormField(
            controller: _oggettoCtrl,
            style: const TextStyle(color: Colors.white),
            maxLines: 2,
            decoration: _dec('Oggetto del preventivo')),
      ],
    );
  }

  Widget _buildDatiSinistra() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Dati azienda',
            style: TextStyle(
                fontSize: 11,
                color: AppColors.textOnDarkSecondary,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _committenteCtrl,
          decoration: _dec('Committente'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Obbligatorio' : null,
        ),
        const SizedBox(height: 8),
        TextFormField(
            controller: _indirizzoCommCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: _dec('Indirizzo')),
        const SizedBox(height: 8),
        Row(children: [
          SizedBox(
            width: 80,
            child: TextFormField(
              controller: _capCommCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _dec('CAP'),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(5)
              ],
              onChanged: _onCapChanged,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
              child: TextFormField(
                  controller: _cittaCommCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _dec('Città'))),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: TextFormField(
                controller: _codiceFiscaleCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _dec('P.I.')),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: TextFormField(
                controller: _codiceUnivocoCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _dec('CU')),
          ),
        ]),
      ],
    );
  }

  // ─── FIX 3: _buildDatiDestra usa _dec() invece di _buildLabelField ────────
  Widget _buildDatiDestra() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Spett. / destinatario',
            style: TextStyle(
                fontSize: 11,
                color: AppColors.textOnDarkSecondary,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextFormField(
            controller: _spettCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: _dec('Spett.')),
        const SizedBox(height: 8),
        TextFormField(
            controller: _allaCorteseDiCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: _dec('Alla cortese att. di')),
        const SizedBox(height: 8),
        TextFormField(
            controller: _indirizzoSpettCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: _dec('Indirizzo')),
        const SizedBox(height: 8),
        TextFormField(
            controller: _cittaSpettCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: _dec('Città')),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: TextFormField(
                controller: _piSpettCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _dec('P.I.')),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
                controller: _cuSpettCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _dec('CU')),
          ),
        ]),
      ],
    );
  }

  // ─── Gruppo 3 — Dettaglio servizi ─────────────────────────────────────────
  Widget _buildGruppo3(bool isDesktop) {
    return _buildGruppoCard(
      titolo: 'Dettaglio servizi',
      isDesktop: isDesktop,
      icona: Icons.receipt_outlined,
      isAperta: _gruppo3Aperta,
      onToggle: () => setState(() => _gruppo3Aperta = !_gruppo3Aperta),
      children: [
        // Giornata/esecuzione e Tipologia — sopra la tabella
        _buildRiga(isDesktop, [
          CategoriaDropdown(
            categoriaId: 'preventivo_giornata',
            label: 'Giornata/esecuzione',
            initialValue: _giornataEsecuzione,
            onChanged: (v) => setState(() => _giornataEsecuzione = v),
          ),
          DropdownButtonFormField<String>(
            key: ValueKey('tipServ_$_tipologiaServizi'),
            value: _tipologie.any((t) => t.nome == _tipologiaServizi)
                ? _tipologiaServizi
                : null,
            decoration: _dec('Tipologia servizi'),
            hint: const Text('Seleziona...'),
            isExpanded: true,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            dropdownColor: const Color(0xFF0A2A1A),
            iconEnabledColor: AppColors.textOnDarkSecondary,
            items: _tipologie
                .map((t) => DropdownMenuItem(
                    value: t.nome, child: Text('${t.id} — ${t.nome}')))
                .toList(),
            onChanged: (v) => setState(() => _tipologiaServizi = v),
          ),
        ]),
        const SizedBox(height: 16),
        // Avviso listino non configurato
        if (_tipologie.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.60)),
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xFFD97706).withValues(alpha: 0.12),
            ),
            child: const Row(children: [
              Icon(Icons.warning_amber_outlined,
                  color: Color(0xFFD97706), size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Listino non configurato — vai in Impostazioni → Preventivo',
                  style: TextStyle(fontSize: 12, color: Color(0xFFD97706)),
                ),
              ),
            ]),
          ),
        // Intestazione tabella
        _buildIntestazioneTabella(isDesktop),
        Container(height: 0.5, color: AppColors.accentGreenDark.withValues(alpha: 0.40)),
        // Righe
        if (_righeCtrl.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'Nessun servizio — premi "+ Aggiungi"',
                style: TextStyle(color: AppColors.textOnDarkMuted),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _righeCtrl.length,
            separatorBuilder: (_, __) =>
                Container(height: 0.5, color: AppColors.glassBorder),
            itemBuilder: (_, i) => _buildRigaServizio(i, isDesktop),
          ),
        Container(height: 0.5, color: AppColors.accentGreenDark.withValues(alpha: 0.40)),
        // Totale
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text('Totale',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13,color: Colors.white)),
              const SizedBox(width: 24),
              Text(_moneyFmt.format(_totale),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.accentGreenDark)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _aggiungiRiga,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Aggiungi servizio'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.accentGreenDark,
            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.50), width: 0.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildIntestazioneTabella(bool isDesktop) {
    if (!isDesktop) return const SizedBox.shrink();
    return Container(
      color: AppColors.glassDarkest,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: const Row(children: [
        SizedBox(width: 32),
        SizedBox(width: 6),
        SizedBox(
            width: 100,
            child: Text('Tipologia',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600))),
        SizedBox(width: 6),
        SizedBox(
            width: 130,
            child: Text('Sotto-tipo',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600))),
        SizedBox(width: 6),
        Expanded(
            child: Text('Servizio',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600))),
        SizedBox(width: 6),
        SizedBox(
            width: 90,
            child: Text('cad',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center)),
        SizedBox(width: 6),
        SizedBox(
            width: 60,
            child: Text('num',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center)),
        SizedBox(width: 6),
        SizedBox(
            width: 65,
            child: Text('sct %',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center)),
        SizedBox(width: 6),
        SizedBox(
            width: 90,
            child: Text('cst an/ser',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center)),
        SizedBox(width: 6),
        SizedBox(
            width: 90,
            child: Text('tot',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center)),
      ]),
    );
  }

  Widget _buildRigaServizio(int i, bool isDesktop) {
    final r = _righeCtrl[i];

    // Sotto-tipi e servizi filtrati in base alla selezione corrente
    final sottotipiRiga = _tipologie
        .where((t) => t.id == r.tipologiaId)
        .expand((t) => t.sottotipi)
        .toList();
    final serviziRiga = sottotipiRiga
        .where((st) => st.id == r.sottotipoId)
        .expand((st) => st.servizi)
        .toList();

    const decCascade = InputDecoration(
      isDense: true,
      border: UnderlineInputBorder(),
      contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    );

    DropdownMenuItem<String> ddItem(String value, String label) =>
        DropdownMenuItem<String>(
          value: value,
          child: Text(label,
              style: const TextStyle(fontSize: 11),
              overflow: TextOverflow.ellipsis),
        );

    if (isDesktop) {
      return Container(
        color:
            i.isOdd ? AppColors.glassCard.withValues(alpha: 0.5) : null,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // rimuovi
            SizedBox(
              width: 32,
              child: IconButton(
                icon: const Icon(Icons.close, size: 16, color: AppColors.error),
                onPressed: () => _rimuoviRiga(i),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
            const SizedBox(width: 6),
            // ─── FIX 1 desktop: larghezze ridotte + isExpanded: true ────────
            // Tipologia
            SizedBox(
              width: 100,
              child: DropdownButtonFormField<String>(
                key: ValueKey('tip_${i}_${r.tipologiaId}'),
                isDense: true,
                isExpanded: true,
                decoration: decCascade,
                value: r.tipologiaId,
                hint: const Text('Tip.', style: TextStyle(fontSize: 11)),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                dropdownColor: const Color(0xFF0A2A1A),
                iconEnabledColor: AppColors.textOnDarkSecondary,
                items: _tipologie
                    .map((t) => ddItem(t.id, '${t.id} — ${t.nome}'))
                    .toList(),
                onChanged: (v) => setState(() {
                  r.tipologiaId = v;
                  r.sottotipoId = null;
                  r.codice = '';
                  r.descrizioneCtrl.text = '';
                  r.prezzoCtrl.text = '0';
                  _ricalcola();
                }),
              ),
            ),
            const SizedBox(width: 6),
            // Sotto-tipo
            SizedBox(
              width: 130,
              child: DropdownButtonFormField<String>(
                key: ValueKey('sub_${i}_${r.tipologiaId}_${r.sottotipoId}'),
                isDense: true,
                isExpanded: true,
                decoration: decCascade,
                value: r.sottotipoId,
                hint: const Text('Sotto-tipo', style: TextStyle(fontSize: 11)),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                dropdownColor: const Color(0xFF0A2A1A),
                iconEnabledColor: AppColors.textOnDarkSecondary,
                items: sottotipiRiga
                    .map((st) => ddItem(st.id, '${st.id} — ${st.nome}'))
                    .toList(),
                onChanged: r.tipologiaId == null
                    ? null
                    : (v) => setState(() {
                          r.sottotipoId = v;
                          r.codice = '';
                          r.descrizioneCtrl.text = '';
                          r.prezzoCtrl.text = '0';
                          _ricalcola();
                        }),
              ),
            ),
            const SizedBox(width: 6),
            // Servizio
            Expanded(
              child: DropdownButtonFormField<String>(
                key: ValueKey('srv_${i}_${r.sottotipoId}_${r.codice}'),
                isDense: true,
                isExpanded: true,
                decoration: decCascade,
                value: r.codice.isNotEmpty ? r.codice : null,
                hint: const Text('Servizio', style: TextStyle(fontSize: 11)),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                dropdownColor: const Color(0xFF0A2A1A),
                iconEnabledColor: AppColors.textOnDarkSecondary,
                items: serviziRiga
                    .map((s) => ddItem(s.codiceUnivoco,
                        '[${s.codiceUnivoco}] ${s.descrizione} — €${s.prezzoUnitario.toStringAsFixed(2)}'))
                    .toList(),
                onChanged: (r.tipologiaId == null || r.sottotipoId == null)
                    ? null
                    : (v) {
                        if (v == null) return;
                        final servizio = serviziRiga.firstWhere(
                            (s) => s.codiceUnivoco == v,
                            orElse: () => const ServizioListino(
                                codiceUnivoco: '',
                                descrizione: '',
                                prezzoUnitario: 0));
                        setState(() {
                          r.codice = servizio.codiceUnivoco;
                          r.descrizioneCtrl.text = servizio.descrizione;
                          r.prezzoCtrl.text =
                              servizio.prezzoUnitario.toStringAsFixed(2);
                          _ricalcola();
                        });
                      },
              ),
            ),
            const SizedBox(width: 6),
            // cad
            SizedBox(width: 90, child: _buildCampoNumDesktop(r.prezzoCtrl)),
            const SizedBox(width: 6),
            // num
            SizedBox(
                width: 60,
                child: _buildCampoNumDesktop(r.qtaCtrl, intero: true)),
            const SizedBox(width: 6),
            // sct %
            SizedBox(width: 65, child: _buildCampoNumDesktop(r.scontoCtrl)),
            const SizedBox(width: 6),
            // cst an/ser
            SizedBox(
              width: 90,
              child: Text(
                  _moneyFmt.format(
                      r.costoCaduno * (int.tryParse(r.qtaCtrl.text) ?? 0)),
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500,color: Colors.white),
                  textAlign: TextAlign.center),
            ),
            const SizedBox(width: 6),
            // tot
            SizedBox(
              width: 90,
              child: Text(_moneyFmt.format(r.importo),
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentGreenDark),
                  textAlign: TextAlign.center),
            ),
          ],
        ),
      );
    }

    // ─── FIX 2 mobile: isExpanded: true su tutti i dropdown ─────────────────
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('Servizio ${i + 1}',
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: AppColors.primary)),
            const Spacer(),
            IconButton(
                icon: const Icon(Icons.close, size: 18, color: AppColors.error),
                onPressed: () => _rimuoviRiga(i),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints()),
          ]),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            key: ValueKey('m_tip_${i}_${r.tipologiaId}'),
            isExpanded: true,
            decoration: _dec('Tipologia'),
            value: r.tipologiaId,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            dropdownColor: const Color(0xFF0A2A1A),
            iconEnabledColor: AppColors.textOnDarkSecondary,
            items: _tipologie
                .map((t) => DropdownMenuItem(
                    value: t.id,
                    child: Text('${t.id} — ${t.nome}',
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (v) => setState(() {
              r.tipologiaId = v;
              r.sottotipoId = null;
              r.codice = '';
              r.descrizioneCtrl.text = '';
              r.prezzoCtrl.text = '0';
              _ricalcola();
            }),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            key: ValueKey('m_sub_${i}_${r.tipologiaId}_${r.sottotipoId}'),
            isExpanded: true,
            decoration: _dec('Sotto-tipo'),
            value: r.sottotipoId,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            dropdownColor: const Color(0xFF0A2A1A),
            iconEnabledColor: AppColors.textOnDarkSecondary,
            items: sottotipiRiga
                .map((st) => DropdownMenuItem(
                    value: st.id,
                    child: Text('${st.id} — ${st.nome}',
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: r.tipologiaId == null
                ? null
                : (v) => setState(() {
                      r.sottotipoId = v;
                      r.codice = '';
                      r.descrizioneCtrl.text = '';
                      r.prezzoCtrl.text = '0';
                      _ricalcola();
                    }),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            key: ValueKey('m_srv_${i}_${r.sottotipoId}_${r.codice}'),
            isExpanded: true,
            decoration: _dec('Servizio'),
            value: r.codice.isNotEmpty ? r.codice : null,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            dropdownColor: const Color(0xFF0A2A1A),
            iconEnabledColor: AppColors.textOnDarkSecondary,
            items: serviziRiga
                .map((s) => DropdownMenuItem(
                    value: s.codiceUnivoco,
                    child: Text(
                        '[${s.codiceUnivoco}] ${s.descrizione} — €${s.prezzoUnitario.toStringAsFixed(2)}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12))))
                .toList(),
            onChanged: (r.tipologiaId == null || r.sottotipoId == null)
                ? null
                : (v) {
                    if (v == null) return;
                    final servizio = serviziRiga.firstWhere(
                        (s) => s.codiceUnivoco == v,
                        orElse: () => const ServizioListino(
                            codiceUnivoco: '',
                            descrizione: '',
                            prezzoUnitario: 0));
                    setState(() {
                      r.codice = servizio.codiceUnivoco;
                      r.descrizioneCtrl.text = servizio.descrizione;
                      r.prezzoCtrl.text =
                          servizio.prezzoUnitario.toStringAsFixed(2);
                      _ricalcola();
                    });
                  },
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _buildCampoNumerico('€ cad', r.prezzoCtrl)),
            const SizedBox(width: 6),
            Expanded(
                child: _buildCampoNumerico('num', r.qtaCtrl, intero: true)),
            const SizedBox(width: 6),
            Expanded(child: _buildCampoNumerico('sct %', r.scontoCtrl)),
          ]),
          const SizedBox(height: 6),
          Text('tot: ${_moneyFmt.format(r.importo)}',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.accentGreenDark)),
        ],
      ),
    );
  }

  Widget _buildCampoNumDesktop(TextEditingController ctrl,
      {bool intero = false}) {
    return TextFormField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white, fontSize: 12),
      textAlign: TextAlign.center,
      decoration: const InputDecoration(
          border: UnderlineInputBorder(),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4)),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: intero
          ? [FilteringTextInputFormatter.digitsOnly]
          : [FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))],
      onChanged: (_) => _ricalcola(),
    );
  }

  // ─── Gruppo 4 — Condizioni ────────────────────────────────────────────────
  Widget _buildGruppo4(bool isDesktop) {
    return _buildGruppoCard(
      titolo: 'Condizioni',
      isDesktop: isDesktop,
      icona: Icons.tune_outlined,
      isAperta: _gruppo4Aperta,
      onToggle: () => setState(() => _gruppo4Aperta = !_gruppo4Aperta),
      children: [
        // PAGAMENTO
        TextFormField(
            controller: _pagamentoCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: _dec('PAGAMENTO')),
        const SizedBox(height: 12),
        _buildRiga(isDesktop, [
          TextFormField(
              controller: _durataContrattoCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _dec('Durata contratto')),
          CategoriaDropdown(
            categoriaId: 'preventivo_rinnovo',
            label: 'Rinnovo a scadenza',
            initialValue: _rinnovoScadenza,
            onChanged: (v) => setState(() => _rinnovoScadenza = v),
          ),
        ]),
        const SizedBox(height: 12),
        _buildRiga(isDesktop, [
          TextFormField(
              controller: _periodoInterventoCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _dec('Periodo intervento')),
          TextFormField(
              controller: _validitaCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _dec('Validità offerta')),
        ]),
      ],
    );
  }

  // ─── Gruppo 5 — Note ─────────────────────────────────────────────────────
  Widget _buildGruppo5(bool isDesktop) {
    return _buildGruppoCard(
      titolo: 'NOTE VARIE SERVIZI CONDIZIONI OFFERTA',
      isDesktop: isDesktop,
      icona: Icons.edit_note_outlined,
      isAperta: _gruppo5Aperta,
      onToggle: () => setState(() => _gruppo5Aperta = !_gruppo5Aperta),
      children: [
        TextFormField(
            controller: _noteCtrl,
            style: const TextStyle(color: Colors.white),
            maxLines: 6,
            decoration: _dec('Note')),
      ],
    );
  }

  // ─── Gruppo 6 — IBAN e causale ────────────────────────────────────────────
  Widget _buildGruppo6(bool isDesktop) {
    return _buildGruppoCard(
      titolo: 'Coordinate bancarie',
      isDesktop: isDesktop,
      icona: Icons.link_outlined,
      isAperta: _gruppo6Aperta,
      onToggle: () => setState(() => _gruppo6Aperta = !_gruppo6Aperta),
      children: [
        _buildRiga(isDesktop, [
          TextFormField(
              controller: _ibanCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _dec('Coordinate IBAN')),
          TextFormField(
              controller: _intestatoACtrl,
              style: const TextStyle(color: Colors.white),
              decoration: _dec('Intestato a')),
        ]),
        const SizedBox(height: 12),
        TextFormField(
            controller: _causaleCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: _dec('Causale (auto-generata se vuota)')),
        const SizedBox(height: 16),
        // Sezione firme (solo visuale)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              border: Border.all(color: AppColors.glassBorder, width: 0.5),
              borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('DATA, LUOGO',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textOnDarkSecondary)),
                      const SizedBox(height: 20),
                      Container(height: 0.5, color: AppColors.glassBorder),
                      const Text('FIRMA CLIENTE',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textOnDarkSecondary)),
                    ]),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Biochemlabs',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.accentGreenDark)),
                      const Text('il chimico',
                          style: TextStyle(
                              fontStyle: FontStyle.italic, fontSize: 12, color: AppColors.textOnDarkSecondary)),
                      const Text('Dr. Leonardo Daga',
                          style: TextStyle(fontSize: 12, color: AppColors.textOnDark)),
                      const Text('iscr. Ord. Pur Chimici n° 219A',
                          style: TextStyle(
                              fontSize: 10, color: AppColors.textOnDarkSecondary)),
                      const SizedBox(height: 20),
                      Container(height: 0.5, color: AppColors.glassBorder),
                    ]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Bottoni ─────────────────────────────────────────────────────────────
  Widget _buildBottoni() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.glassDarkest,
        border: Border(top: BorderSide(color: AppColors.glassBorder, width: 0.5)),
      ),
      child: Row(children: [
        OutlinedButton(
          onPressed: _isSaving ? null : _esci,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textOnDarkSecondary,
            side: BorderSide(color: AppColors.glassBorder, width: 0.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: const Text('Annulla'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: _isSaving ? null : _salvaEResta,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textOnDarkSecondary,
              side: BorderSide(color: AppColors.glassBorder, width: 0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _isSaving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentGreenDark))
                : const Text('Salva e resta'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FilledButton(
            onPressed: _isSaving ? null : _salvaEsci,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary.withValues(alpha: 0.30),
              foregroundColor: AppColors.accentGreenDark,
              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.50), width: 0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _isSaving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: AppColors.accentGreenDark, strokeWidth: 2))
                : const Text('Salva ed esci'),
          ),
        ),
      ]),
    );
  }

  // ─── Helpers UI ──────────────────────────────────────────────────────────

  Widget _buildGruppoCard({
    required String titolo,
    required bool isDesktop,
    required List<Widget> children,
    required IconData icona,
    required bool isAperta,
    required VoidCallback onToggle,
    String preview = '',
  }) {
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
            ...children,
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: fields
          .asMap()
          .entries
          .expand((e) => [
                if (e.key > 0) const SizedBox(width: 12),
                Expanded(child: e.value)
              ])
          .toList(),
    );
  }

  Widget _buildCampoNumerico(String label, TextEditingController ctrl,
      {bool intero = false}) {
    return TextFormField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      decoration: _dec(label),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: intero
          ? [FilteringTextInputFormatter.digitsOnly]
          : [FilteringTextInputFormatter.allow(RegExp(r'[\d,.]'))],
      onChanged: (_) => _ricalcola(),
    );
  }

  Widget _buildAutocompleteCliente() {
    return Autocomplete<ClienteModel>(
      optionsBuilder: (TextEditingValue valore) {
        if (valore.text.isEmpty) return const Iterable<ClienteModel>.empty();
        final q = valore.text.toLowerCase();
        return _clienti.where((c) =>
            c.committente.toLowerCase().contains(q) ||
            c.numeroFormattato.toLowerCase().contains(q));
      },
      displayStringForOption: (c) => '${c.numeroFormattato} — ${c.committente}',
      fieldViewBuilder: (ctx, ctrl, focusNode, onSubmit) {
        if (_clienteDisplayCtrl.text.isNotEmpty &&
            ctrl.text != _clienteDisplayCtrl.text) {
          ctrl.text = _clienteDisplayCtrl.text;
        }
        return TextFormField(
          controller: ctrl,
          focusNode: focusNode,
          style: const TextStyle(color: Colors.white),
          decoration: _dec('Cliente — cerca per nome o numero'),
          onFieldSubmitted: (_) => onSubmit(),
        );
      },
      onSelected: _onClienteSelezionato,
      optionsViewBuilder: (ctx, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            color: const Color(0xFF0A2A1A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: AppColors.glassBorder, width: 0.5),
            ),
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
                            AppColors.primary.withValues(alpha: 0.20),
                        child: Text(c.initials,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.accentGreenDark,
                                fontWeight: FontWeight.w700))),
                    title: Text(c.committente,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textOnDark)),
                    subtitle: Text(c.numeroFormattato,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textOnDarkSecondary)),
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
        labelStyle: const TextStyle(color: AppColors.glassFieldLabelDim, fontSize: 13),
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

// ─── Controller riga ─────────────────────────────────────────────────────────

class _RigaController {
  String codice;
  String? tipologiaId;
  String? sottotipoId;
  double importo;
  double costoCaduno;

  final TextEditingController descrizioneCtrl;
  final TextEditingController prezzoCtrl;
  final TextEditingController qtaCtrl;
  final TextEditingController scontoCtrl;

  _RigaController({
    this.codice = '',
    this.tipologiaId,
    this.sottotipoId,
    this.importo = 0.0,
    this.costoCaduno = 0.0,
    String descrizione = '',
    String prezzo = '0',
    String qta = '1',
    String sconto = '0',
  })  : descrizioneCtrl = TextEditingController(text: descrizione),
        prezzoCtrl = TextEditingController(text: prezzo),
        qtaCtrl = TextEditingController(text: qta),
        scontoCtrl = TextEditingController(text: sconto);

  factory _RigaController.fromRiga(PreventivoRiga r) {
    String? tipologiaId;
    String? sottotipoId;
    if (r.codice.isNotEmpty) {
      final parts = r.codice.split('_');
      if (parts.length >= 2) {
        tipologiaId = parts[0];
        // Rimuove le cifre finali per ottenere l'ID del sotto-tipo
        // es. "A_DSF6" → "A_DSF", "ND_ND23" → "ND_ND"
        sottotipoId = r.codice.replaceAll(RegExp(r'\d+$'), '');
      }
    }
    return _RigaController(
      codice: r.codice,
      tipologiaId: tipologiaId,
      sottotipoId: sottotipoId,
      importo: r.importo,
      costoCaduno: r.quantita > 0 ? r.importo / r.quantita : 0,
      descrizione: r.descrizione,
      prezzo: r.prezzoUnitario.toStringAsFixed(2),
      qta: r.quantita.toString(),
      sconto: r.scontoPerc.toStringAsFixed(2),
    );
  }

  void dispose() {
    descrizioneCtrl.dispose();
    prezzoCtrl.dispose();
    qtaCtrl.dispose();
    scontoCtrl.dispose();
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

enum _SceltaEsci { annulla, bozza, salva }
