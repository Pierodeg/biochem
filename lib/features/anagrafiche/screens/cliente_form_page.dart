import 'package:biochem/services/cap_service.dart';
import 'package:biochem/services/clienti_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/service_providers.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../models/cliente_model.dart';
import '../../../models/indirizzo_servizio_model.dart';
import '../../../services/indirizzi_servizio_service.dart';
import '../../../widgets/categoria_dropdown.dart';

/// Form per la creazione e modifica di un cliente
///
/// Parametri:
/// - [clienteId] null → modalità creazione, stringa → modalità modifica
class ClienteFormPage extends ConsumerStatefulWidget {
  final String? clienteId;
  const ClienteFormPage({super.key, this.clienteId});

  @override
  ConsumerState<ClienteFormPage> createState() => _ClienteFormPageState();
}

class _ClienteFormPageState extends ConsumerState<ClienteFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final ClientiService _clientiService;
  late final CapService _capService;
  late final IndirizziServizioService _indirizziService;

  // Stato del form
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errore;
  String? _clienteIdCorrente;
  bool _allowDirectPop = false;
  Map<String, Object?>? _snapshotIniziale;

  // Dati del cliente in modifica (null = creazione)
  ClienteModel? _clienteOriginale;
  int _numeroCliente = 0;

  // Controller per ogni campo
  final _committenteCtrl = TextEditingController();
  final _indirizzoCtrl = TextEditingController();
  final _capCtrl = TextEditingController();
  final _cittaCtrl = TextEditingController();
  final _provinciaCtrl = TextEditingController();
  final _pivaCtrl = TextEditingController();
  final _codiceUnivocoCtrl = TextEditingController();
  final _referenteCtrl = TextEditingController();
  final _numeroClienteCtrl = TextEditingController();
  final _indirizzoServizioCtrl = TextEditingController();

  // Campi CAP/Città/Provincia servizio (separati)
  final _capServizioCtrl = TextEditingController();
  final _cittaServizioCtrl = TextEditingController();
  final _provinciaServizioCtrl = TextEditingController();

  final _emailCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _cellulareCtrl = TextEditingController();
  final _pecCtrl = TextEditingController();

  // Tipo committente (aggiornato via CategoriaDropdown)
  String? _tipoCommittente;

  // Cache suggerimenti per i campi Autocomplete
  List<String> _sugCodiceUnivoco = [];
  List<String> _sugReferente = [];
  List<String> _sugEmail = [];
  List<String> _sugPec = [];

  // Lista indirizzi servizio multipli (caricati da Firestore)
  List<IndirizzoServizioModel> _indirizzi = [];

  @override
  void initState() {
    super.initState();
    _clienteIdCorrente = widget.clienteId;
    _clientiService = ref.read(clientiServiceProvider);
    _capService = ref.read(capServiceProvider);
    _indirizziService = ref.read(indirizziServizioServiceProvider);
    _inizializza();
  }

  @override
  void dispose() {
    _committenteCtrl.dispose();
    _numeroClienteCtrl.dispose();
    _indirizzoCtrl.dispose();
    _capCtrl.dispose();
    _cittaCtrl.dispose();
    _provinciaCtrl.dispose();
    _pivaCtrl.dispose();
    _codiceUnivocoCtrl.dispose();
    _referenteCtrl.dispose();
    _indirizzoServizioCtrl.dispose();
    _capServizioCtrl.dispose();
    _cittaServizioCtrl.dispose();
    _provinciaServizioCtrl.dispose();
    _emailCtrl.dispose();
    _telefonoCtrl.dispose();
    _cellulareCtrl.dispose();
    _pecCtrl.dispose();
    super.dispose();
  }

  Future<void> _inizializza() async {
    try {
      // Carica suggerimenti con una sola lettura Firestore
      final suggerimenti = await _clientiService.getAllSuggerimenti([
        'codiceUnivoco',
        'referente',
        'email',
        'pec',
      ]);
      _sugCodiceUnivoco = suggerimenti['codiceUnivoco'] ?? [];
      _sugReferente = suggerimenti['referente'] ?? [];
      _sugEmail = suggerimenti['email'] ?? [];
      _sugPec = suggerimenti['pec'] ?? [];

      if (widget.clienteId != null) {
        // Modalità modifica: carica il cliente esistente
        final cliente =
            await _clientiService.getClienteById(widget.clienteId!);
        if (cliente != null) {
          _clienteOriginale = cliente;
          _numeroCliente = cliente.numeroCliente;
          _numeroClienteCtrl.text = cliente.numeroCliente.toString();
          _tipoCommittente = cliente.tipoCommittente.isNotEmpty
              ? cliente.tipoCommittente
              : null;
          _committenteCtrl.text = cliente.committente;
          _indirizzoCtrl.text = cliente.indirizzo;
          _capCtrl.text = cliente.cap;
          _cittaCtrl.text = cliente.citta;
          _provinciaCtrl.text = cliente.provincia;
          _pivaCtrl.text = cliente.pivaCodiceFiscale;
          _codiceUnivocoCtrl.text = cliente.codiceUnivoco;
          _referenteCtrl.text = cliente.referente;
          _indirizzoServizioCtrl.text = cliente.indirizzoServizio;
          _capServizioCtrl.text = cliente.capServizio;
          _cittaServizioCtrl.text = cliente.cittaServizio;
          _provinciaServizioCtrl.text = cliente.provinciaServizio;
          _emailCtrl.text = cliente.email;
          _telefonoCtrl.text = cliente.telefono;
          _cellulareCtrl.text = cliente.cellulare;
          _pecCtrl.text = cliente.pec;
        }

        // Carica indirizzi servizio multipli
        final indirizzi = await _indirizziService
            .getIndirizzi(widget.clienteId!)
            .first;
        _indirizzi = indirizzi;
      } else {
        // Modalità creazione: il numero verrà assegnato solo al momento del salvataggio
        // per evitare di incrementare il contatore se l'utente annulla
        _numeroCliente = 0; // 0 = "Auto" (non ancora assegnato)
      }
    } catch (e) {
      _errore = e.toString();
    } finally {
      if (mounted) {
        _snapshotIniziale = _snapshotCorrente();
        setState(() => _isLoading = false);
      }
    }
  }

  /// Lookup automatico CAP indirizzo principale
  Future<void> _onCapChanged(String cap) async {
    if (cap.length == 5) {
      final risultato = await _capService.cercaPerCap(cap);
      if (risultato != null && mounted) {
        setState(() {
          _cittaCtrl.text = risultato.citta;
          _provinciaCtrl.text = risultato.provincia;
        });
      }
    }
  }

  /// Lookup automatico CAP servizio
  Future<void> _onCapServizioChanged(String cap) async {
    if (cap.length == 5) {
      final risultato = await _capService.cercaPerCap(cap);
      if (risultato != null && mounted) {
        setState(() {
          _cittaServizioCtrl.text = risultato.citta;
          _provinciaServizioCtrl.text = risultato.provincia;
        });
      }
    }
  }

  /// Costruisce il ClienteModel dai controller e salva su Firestore.
  /// Per i nuovi clienti, chiama getNextNumeroCliente() atomicamente
  /// solo in questo momento per non sprecare numeri se l'utente annulla.
  /// [isDraft] true = salva come bozza, false = salva come definitivo.
  Future<ClienteModel> _costruisciEsalva({bool isDraft = false}) async {
    if (_clienteOriginale == null) {
      // Creazione: usa il numero inserito dall'admin se valido, altrimenti auto
      final customNum = int.tryParse(_numeroClienteCtrl.text.trim());
      if (customNum != null && customNum > 0) {
        _numeroCliente = customNum;
      } else {
        _numeroCliente = await _clientiService.getNextNumeroCliente();
      }
    } else {
      // Modifica: usa il numero dal controller (admin può averlo modificato)
      _numeroCliente = int.tryParse(_numeroClienteCtrl.text.trim()) ??
          _clienteOriginale!.numeroCliente;
    }
    var cliente = ClienteModel(
      id: _clienteIdCorrente ?? _clienteOriginale?.id ?? '',
      numeroCliente: _numeroCliente,
      tipoCommittente: _tipoCommittente ?? '',
      committente: _committenteCtrl.text.trim(),
      indirizzo: _indirizzoCtrl.text.trim(),
      cap: _capCtrl.text.trim(),
      citta: _cittaCtrl.text.trim(),
      provincia: _provinciaCtrl.text.trim().toUpperCase(),
      pivaCodiceFiscale: _pivaCtrl.text.trim(),
      codiceUnivoco: _codiceUnivocoCtrl.text.trim(),
      referente: _referenteCtrl.text.trim(),
      indirizzoServizio: _indirizzoServizioCtrl.text.trim(),
      capServizio: _capServizioCtrl.text.trim(),
      cittaServizio: _cittaServizioCtrl.text.trim(),
      provinciaServizio: _provinciaServizioCtrl.text.trim().toUpperCase(),
      email: _emailCtrl.text.trim(),
      telefono: _telefonoCtrl.text.trim(),
      cellulare: _cellulareCtrl.text.trim(),
      pec: _pecCtrl.text.trim(),
      createdAt: _clienteOriginale?.createdAt ?? DateTime.now(),
      isDraft: isDraft,
    );
    final clienteId = await _clientiService.salvaCliente(cliente);
    _clienteIdCorrente = clienteId;
    cliente = ClienteModel(
      id: clienteId,
      numeroCliente: cliente.numeroCliente,
      tipoCommittente: cliente.tipoCommittente,
      committente: cliente.committente,
      indirizzo: cliente.indirizzo,
      cap: cliente.cap,
      citta: cliente.citta,
      provincia: cliente.provincia,
      pivaCodiceFiscale: cliente.pivaCodiceFiscale,
      codiceUnivoco: cliente.codiceUnivoco,
      referente: cliente.referente,
      indirizzoServizio: cliente.indirizzoServizio,
      capServizio: cliente.capServizio,
      cittaServizio: cliente.cittaServizio,
      provinciaServizio: cliente.provinciaServizio,
      email: cliente.email,
      telefono: cliente.telefono,
      cellulare: cliente.cellulare,
      pec: cliente.pec,
      createdAt: cliente.createdAt,
      isDraft: cliente.isDraft,
    );
    return cliente;
  }

  /// Salva il cliente come definitivo e rimane nella schermata corrente
  Future<void> _salva() async {
    final isAdmin =
        ref.read(currentUserProvider).valueOrNull?.isAdmin ?? false;
    if (!isAdmin) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    try {
      final salvato = await _costruisciEsalva(isDraft: false);
      if (mounted) {
        // Aggiorna il riferimento originale e il controller del numero
        _clienteOriginale = salvato;
        _numeroClienteCtrl.text = salvato.numeroCliente.toString();
        _snapshotIniziale = _snapshotCorrente();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cliente salvato con successo'),
            backgroundColor: AppColors.success,
          ),
        );
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

  /// Mostra il dialog "Esci": l'utente sceglie se salvare, salvare come bozza o annullare
  Future<void> _esci() async {
    final isAdmin =
        ref.read(currentUserProvider).valueOrNull?.isAdmin ?? false;
    if (!isAdmin) {
      await _chiudiPagina();
      return;
    }

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
              ? 'Vuoi salvare le modifiche prima di uscire o impostare il cliente come bozza?'
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
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary),
            child: const Text('Salva'),
          ),
        ],
      ),
    );

    if (scelta == null || scelta == _SceltaEsci.annulla || !mounted) return;

    final isDraft = scelta == _SceltaEsci.bozza;

    // Per salvare validiamo il form solo se non è bozza
    if (!isDraft && !(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    try {
      final salvato = await _costruisciEsalva(isDraft: isDraft);
      if (mounted) {
        _clienteOriginale = salvato;
        _numeroClienteCtrl.text = salvato.numeroCliente.toString();
        _snapshotIniziale = _snapshotCorrente();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isDraft
                ? 'Cliente salvato come bozza'
                : 'Cliente salvato con successo'),
            backgroundColor:
                isDraft ? AppColors.textSecondary : AppColors.success,
          ),
        );
        await _chiudiPagina();
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

  /// Elimina il cliente corrente dopo conferma (solo admin, solo in modifica)
  Future<void> _elimina() async {
    final nome = _committenteCtrl.text.trim().isNotEmpty
        ? _committenteCtrl.text.trim()
        : 'questo cliente';
    final conferma = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina cliente'),
        content: Text(
            'Eliminare "$nome"? L\'azione è irreversibile.'),
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
      await _clientiService.eliminaCliente(_clienteIdCorrente!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cliente eliminato')),
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

  /// Apre il dialog per aggiungere/modificare un indirizzo di servizio.
  /// Usa un StatefulWidget dedicato per evitare il dispose prematuro dei
  /// TextEditingController durante l'animazione di chiusura del dialog.
  Future<void> _apriDialogIndirizzo(
      [IndirizzoServizioModel? esistente]) async {
    if (_clienteIdCorrente == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Salva prima il cliente per aggiungere indirizzi di servizio'),
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (ctx) => _IndirizzoDialog(
        esistente: esistente,
        clienteId: _clienteIdCorrente!,
        capService: _capService,
        indirizziService: _indirizziService,
        onSalvato: (lista) {
          if (mounted) setState(() => _indirizzi = lista);
        },
      ),
    );
  }

  /// Elimina un indirizzo di servizio con conferma
  Future<void> _eliminaIndirizzo(IndirizzoServizioModel indirizzo) async {
    if (_clienteIdCorrente == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina indirizzo'),
        content: Text('Eliminare "${indirizzo.etichetta}"?'),
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
    if (ok != true || !mounted) return;
    try {
      await _indirizziService.eliminaIndirizzo(
          _clienteIdCorrente!, indirizzo.id);
      final lista =
          await _indirizziService.getIndirizzi(_clienteIdCorrente!).first;
      if (mounted) setState(() => _indirizzi = lista);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Map<String, Object?> _snapshotCorrente() {
    return {
      'numeroCliente': _numeroClienteCtrl.text.trim(),
      'tipoCommittente': _tipoCommittente ?? '',
      'committente': _committenteCtrl.text.trim(),
      'indirizzo': _indirizzoCtrl.text.trim(),
      'cap': _capCtrl.text.trim(),
      'citta': _cittaCtrl.text.trim(),
      'provincia': _provinciaCtrl.text.trim().toUpperCase(),
      'pivaCodiceFiscale': _pivaCtrl.text.trim(),
      'codiceUnivoco': _codiceUnivocoCtrl.text.trim(),
      'referente': _referenteCtrl.text.trim(),
      'indirizzoServizio': _indirizzoServizioCtrl.text.trim(),
      'capServizio': _capServizioCtrl.text.trim(),
      'cittaServizio': _cittaServizioCtrl.text.trim(),
      'provinciaServizio': _provinciaServizioCtrl.text.trim().toUpperCase(),
      'email': _emailCtrl.text.trim(),
      'telefono': _telefonoCtrl.text.trim(),
      'cellulare': _cellulareCtrl.text.trim(),
      'pec': _pecCtrl.text.trim(),
    };
  }

  bool get _hasUnsavedChanges {
    final iniziale = _snapshotIniziale;
    if (iniziale == null) return false;
    return iniziale.toString() != _snapshotCorrente().toString();
  }

  bool get _canSaveAsDraft =>
      _clienteIdCorrente == null || (_clienteOriginale?.isDraft ?? false);

  Future<void> _chiudiPagina() async {
    if (!mounted) return;
    setState(() => _allowDirectPop = true);
    context.pop();
  }

  Future<void> _gestisciBackNavigation() async {
    if (_isSaving) return;
    await _esci();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 600;
    final isAdmin =
        ref.watch(currentUserProvider).valueOrNull?.isAdmin ?? false;
    final isReadOnly = !isAdmin;
    final titolo = _clienteIdCorrente == null
        ? 'Nuovo cliente'
        : (isReadOnly ? 'Dettaglio cliente' : 'Modifica cliente');

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(titolo)),
        body: const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_errore != null) {
      return Scaffold(
        appBar: AppBar(title: Text(titolo)),
        body: Center(
          child: Text('Errore: $_errore',
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
        appBar: AppBar(
          title: Text(titolo),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _gestisciBackNavigation,
          ),
          actions: [
            if (isAdmin && _clienteIdCorrente != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                tooltip: 'Elimina cliente',
                onPressed: _isSaving ? null : _elimina,
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: isDesktop
              ? _buildLayoutDesktop(isReadOnly)
              : _buildLayoutMobile(isReadOnly),
        ),
      ),
    );
  }

  // ─── LAYOUT MOBILE ────────────────────────────────────────────────────────

  Widget _buildLayoutMobile(bool isReadOnly) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: AbsorbPointer(
              absorbing: isReadOnly,
              child: Opacity(
                opacity: isReadOnly ? 0.7 : 1.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCampoNumero(),
                    const SizedBox(height: 16),
                    _buildCampoTipoCommittente(),
                    const SizedBox(height: 16),
                    _buildCampoCommittente(),
                    const SizedBox(height: 16),
                    _buildCampoTesto(controller: _indirizzoCtrl, label: 'Indirizzo'),
                    const SizedBox(height: 16),
                    _buildCampoCapLookup(),
                    const SizedBox(height: 16),
                    _buildCampoTesto(controller: _cittaCtrl, label: 'Città'),
                    const SizedBox(height: 16),
                    _buildCampoProvincia(),
                    const SizedBox(height: 16),
                    _buildCampoTesto(controller: _pivaCtrl, label: 'P.IVA / Codice Fiscale'),
                    const SizedBox(height: 16),
                    _buildCampoAutocomplete(controller: _codiceUnivocoCtrl, label: 'Codice Univoco', suggerimenti: _sugCodiceUnivoco),
                    const SizedBox(height: 16),
                    _buildCampoAutocomplete(controller: _referenteCtrl, label: 'C/A Referente', suggerimenti: _sugReferente),
                    const SizedBox(height: 16),
                    _buildCampoTesto(controller: _indirizzoServizioCtrl, label: 'Indirizzo Servizio'),
                    const SizedBox(height: 16),
                    // CAP servizio con lookup automatico
                    _buildCampoCapServizioLookup(),
                    const SizedBox(height: 16),
                    _buildCampoTesto(controller: _cittaServizioCtrl, label: 'Città servizio'),
                    const SizedBox(height: 16),
                    _buildCampoProvinciaServizio(),
                    const SizedBox(height: 16),
                    _buildCampoAutocomplete(controller: _emailCtrl, label: 'Email', suggerimenti: _sugEmail, tastiera: TextInputType.emailAddress, validatore: _validaEmail),
                    const SizedBox(height: 16),
                    _buildCampoTesto(controller: _telefonoCtrl, label: 'Telefono', tastiera: TextInputType.phone),
                    const SizedBox(height: 16),
                    _buildCampoTesto(controller: _cellulareCtrl, label: 'Cellulare', tastiera: TextInputType.phone),
                    const SizedBox(height: 16),
                    _buildCampoAutocomplete(controller: _pecCtrl, label: 'PEC', suggerimenti: _sugPec, tastiera: TextInputType.emailAddress, validatore: _validaEmail),
                    const SizedBox(height: 24),
                    // Sezione indirizzi servizio multipli
                    _buildSezioneIndirizzi(isReadOnly),
                  ],
                ),
              ),
            ),
          ),
        ),
        _buildBottoniAzione(isReadOnly),
      ],
    );
  }

  // ─── LAYOUT DESKTOP ───────────────────────────────────────────────────────

  Widget _buildLayoutDesktop(bool isReadOnly) {
    const double w = 320;
    Widget f(Widget child) => SizedBox(width: w, child: child);
    Widget wide(Widget child) => SizedBox(width: w * 2 + 20, child: child);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: AbsorbPointer(
              absorbing: isReadOnly,
              child: Opacity(
                opacity: isReadOnly ? 0.7 : 1.0,
                child: Wrap(
                  spacing: 20,
                  runSpacing: 16,
                  children: [
                    f(_buildCampoNumero()),
                    f(_buildCampoTipoCommittente()),
                    wide(_buildCampoCommittente()),
                    f(_buildCampoTesto(controller: _indirizzoCtrl, label: 'Indirizzo')),
                    f(_buildCampoCapLookup()),
                    f(_buildCampoTesto(controller: _cittaCtrl, label: 'Città')),
                    f(_buildCampoProvincia()),
                    f(_buildCampoTesto(controller: _pivaCtrl, label: 'P.IVA / Codice Fiscale')),
                    f(_buildCampoAutocomplete(controller: _codiceUnivocoCtrl, label: 'Codice Univoco', suggerimenti: _sugCodiceUnivoco)),
                    f(_buildCampoAutocomplete(controller: _referenteCtrl, label: 'C/A Referente', suggerimenti: _sugReferente)),
                    wide(_buildCampoTesto(controller: _indirizzoServizioCtrl, label: 'Indirizzo Servizio')),
                    // Tre campi separati per CAP/Città/Provincia servizio
                    SizedBox(width: 140, child: _buildCampoCapServizioLookup()),
                    f(_buildCampoTesto(controller: _cittaServizioCtrl, label: 'Città servizio')),
                    SizedBox(width: 120, child: _buildCampoProvinciaServizio()),
                    f(_buildCampoAutocomplete(controller: _emailCtrl, label: 'Email', suggerimenti: _sugEmail, tastiera: TextInputType.emailAddress, validatore: _validaEmail)),
                    f(_buildCampoTesto(controller: _telefonoCtrl, label: 'Telefono', tastiera: TextInputType.phone)),
                    f(_buildCampoTesto(controller: _cellulareCtrl, label: 'Cellulare', tastiera: TextInputType.phone)),
                    f(_buildCampoAutocomplete(controller: _pecCtrl, label: 'PEC', suggerimenti: _sugPec, tastiera: TextInputType.emailAddress, validatore: _validaEmail)),
                    // Sezione indirizzi servizio (larghezza intera)
                    SizedBox(
                      width: w * 2 + 20,
                      child: _buildSezioneIndirizzi(isReadOnly),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        _buildBottoniAzione(isReadOnly),
      ],
    );
  }

  // ─── SEZIONE INDIRIZZI SERVIZIO MULTIPLI ──────────────────────────────────

  Widget _buildSezioneIndirizzi(bool isReadOnly) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titolo sezione
        Row(
          children: [
            const Icon(Icons.location_on_outlined,
                color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            const Text(
              'Indirizzi di servizio',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            // Bottone aggiungi solo per admin in modalità modifica
            if (!isReadOnly && _clienteIdCorrente != null)
              TextButton.icon(
                onPressed: () => _apriDialogIndirizzo(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Aggiungi indirizzo'),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Lista indirizzi
        if (_indirizzi.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 16, color: AppColors.textDisabled),
                const SizedBox(width: 8),
                Text(
                  _clienteIdCorrente == null
                      ? 'Salva il cliente per aggiungere indirizzi'
                      : 'Nessun indirizzo di servizio aggiunto',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textDisabled),
                ),
              ],
            ),
          )
        else
          ...(_indirizzi.map((ind) => _buildCardIndirizzo(ind, isReadOnly))),

        if (!isReadOnly && _clienteIdCorrente == null)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Gli indirizzi possono essere aggiunti dopo aver salvato il cliente.',
              style: TextStyle(
                  fontSize: 12, color: AppColors.textDisabled),
            ),
          ),
      ],
    );
  }

  Widget _buildCardIndirizzo(
      IndirizzoServizioModel ind, bool isReadOnly) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_pin,
              size: 16, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (ind.indirizzo.isNotEmpty)
                  Text(ind.indirizzo,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.textPrimary)),
                if (ind.cap.isNotEmpty ||
                    ind.citta.isNotEmpty ||
                    ind.provincia.isNotEmpty)
                  Text(
                    [ind.cap, ind.citta, ind.provincia.toUpperCase()]
                        .where((s) => s.isNotEmpty)
                        .join(' '),
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                if (ind.referente.isNotEmpty)
                  Text('Ref: ${ind.referente}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary)),
                if (ind.note.isNotEmpty)
                  Text(ind.note,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textDisabled,
                          fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          if (!isReadOnly) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  size: 16, color: AppColors.textSecondary),
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
              onPressed: () => _apriDialogIndirizzo(ind),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 16, color: AppColors.error),
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
              onPressed: () => _eliminaIndirizzo(ind),
            ),
          ],
        ],
      ),
    );
  }

  // ─── CAMPI CONDIVISI ─────────────────────────────────────────────────────

  Widget _buildCampoTipoCommittente() {
    return CategoriaDropdown(
      categoriaId: 'tipi_committente',
      label: 'Tipo committente',
      initialValue: _tipoCommittente,
      onChanged: (v) => setState(() => _tipoCommittente = v),
    );
  }

  Widget _buildCampoCommittente() {
    return _buildCampoTesto(
      controller: _committenteCtrl,
      label: 'Committente *',
      validatore: (v) =>
          (v == null || v.trim().isEmpty) ? 'Campo obbligatorio' : null,
    );
  }

  // ─── WIDGET DEI SINGOLI CAMPI ────────────────────────────────────────────

  Widget _buildCampoNumero() {
    final isAdmin =
        ref.read(currentUserProvider).valueOrNull?.isAdmin ?? false;

    if (isAdmin) {
      // Admin: campo editabile con hint "Auto" in creazione
      return TextFormField(
        controller: _numeroClienteCtrl,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: _inputDecoration('Numero cliente').copyWith(
          hintText: _clienteOriginale == null ? 'Auto' : null,
          prefixText: _numeroClienteCtrl.text.isNotEmpty ? '#' : null,
        ),
        onChanged: (_) => setState(() {}),
      );
    }

    // Non admin: sola lettura
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Numero cliente',
          style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _clienteOriginale == null && _numeroCliente == 0
                ? 'Auto'
                : '#${_numeroCliente.toString().padLeft(3, '0')}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: _clienteOriginale == null && _numeroCliente == 0
                  ? AppColors.textDisabled
                  : AppColors.textSecondary,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCampoTesto({
    required TextEditingController controller,
    required String label,
    TextInputType? tastiera,
    String? Function(String?)? validatore,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: tastiera,
      decoration: _inputDecoration(label),
      validator: validatore,
    );
  }

  /// Campo CAP dell'indirizzo principale con lookup automatico
  Widget _buildCampoCapLookup() {
    return TextFormField(
      controller: _capCtrl,
      decoration: _inputDecoration('CAP'),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(5),
      ],
      onChanged: _onCapChanged,
    );
  }

  /// Campo CAP servizio con lookup automatico (auto-compila Città e Provincia)
  Widget _buildCampoCapServizioLookup() {
    return TextFormField(
      controller: _capServizioCtrl,
      decoration: _inputDecoration('CAP servizio'),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(5),
      ],
      onChanged: _onCapServizioChanged,
    );
  }

  Widget _buildCampoProvincia() {
    return TextFormField(
      controller: _provinciaCtrl,
      decoration: _inputDecoration('Provincia'),
      maxLength: 2,
      textCapitalization: TextCapitalization.characters,
      buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
          null,
    );
  }

  Widget _buildCampoProvinciaServizio() {
    return TextFormField(
      controller: _provinciaServizioCtrl,
      decoration: _inputDecoration('Prov. servizio'),
      maxLength: 2,
      textCapitalization: TextCapitalization.characters,
      buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
          null,
    );
  }

  Widget _buildCampoAutocomplete({
    required TextEditingController controller,
    required String label,
    required List<String> suggerimenti,
    TextInputType? tastiera,
    String? Function(String?)? validatore,
  }) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: controller.text),
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
        final q = textEditingValue.text.toLowerCase();
        return suggerimenti.where((s) => s.toLowerCase().contains(q));
      },
      onSelected: (selection) {
        controller.text = selection;
      },
      fieldViewBuilder:
          (context, fieldController, focusNode, onFieldSubmitted) {
        // Sincronizza il controller esterno con quello interno di Autocomplete
        fieldController.text = controller.text;
        return TextFormField(
          controller: fieldController,
          focusNode: focusNode,
          keyboardType: tastiera,
          decoration: _inputDecoration(label),
          validator: validatore != null
              ? (_) => validatore(fieldController.text)
              : null,
          onChanged: (v) => controller.text = v,
        );
      },
    );
  }

  Widget _buildBottoniAzione(bool isReadOnly) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
        color: AppColors.surface,
      ),
      child: isReadOnly
          ? SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _chiudiPagina,
                child: const Text('Chiudi'),
              ),
            )
          : Row(
              children: [
                // Annulla: esce senza salvare
                OutlinedButton(
                  onPressed: _isSaving ? null : _chiudiPagina,
                  child: const Text('Annulla'),
                ),
                const SizedBox(width: 12),
                // Esci: mostra dialog salva / bozza
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : _esci,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                    child: const Text('Esci'),
                  ),
                ),
                const SizedBox(width: 12),
                // Salva: salva definitivamente e rimane nel form
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

  // ─── UTILITY ─────────────────────────────────────────────────────────────

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  /// Valida il formato email (ammette stringa vuota)
  String? _validaEmail(String? valore) {
    if (valore == null || valore.isEmpty) return null;
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!regex.hasMatch(valore)) return 'Indirizzo email non valido';
    return null;
  }
}

/// Opzioni del dialog "Esci"
enum _SceltaEsci { annulla, bozza, salva }

// ─── DIALOG INDIRIZZO DI SERVIZIO ────────────────────────────────────────────

/// Dialog per aggiungere/modificare un indirizzo di servizio.
/// È un StatefulWidget dedicato in modo che i TextEditingController siano
/// disposti dal framework (nel suo dispose()) solo DOPO che l'animazione di
/// chiusura è completata — evitando il crash "controller used after disposed".
class _IndirizzoDialog extends StatefulWidget {
  final IndirizzoServizioModel? esistente;
  final String clienteId;
  final CapService capService;
  final IndirizziServizioService indirizziService;
  final void Function(List<IndirizzoServizioModel> lista) onSalvato;

  const _IndirizzoDialog({
    required this.esistente,
    required this.clienteId,
    required this.capService,
    required this.indirizziService,
    required this.onSalvato,
  });

  @override
  State<_IndirizzoDialog> createState() => _IndirizzoDialogState();
}

class _IndirizzoDialogState extends State<_IndirizzoDialog> {
  late final TextEditingController _indirizzoCtrl;
  late final TextEditingController _capCtrl;
  late final TextEditingController _cittaCtrl;
  late final TextEditingController _provinciaCtrl;
  late final TextEditingController _referenteCtrl;
  late final TextEditingController _noteCtrl;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final e = widget.esistente;
    _indirizzoCtrl = TextEditingController(text: e?.indirizzo ?? '');
    _capCtrl = TextEditingController(text: e?.cap ?? '');
    _cittaCtrl = TextEditingController(text: e?.citta ?? '');
    _provinciaCtrl = TextEditingController(text: e?.provincia ?? '');
    _referenteCtrl = TextEditingController(text: e?.referente ?? '');
    _noteCtrl = TextEditingController(text: e?.note ?? '');
  }

  @override
  void dispose() {
    _indirizzoCtrl.dispose();
    _capCtrl.dispose();
    _cittaCtrl.dispose();
    _provinciaCtrl.dispose();
    _referenteCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _onCapChanged(String cap) async {
    if (cap.length == 5) {
      final r = await widget.capService.cercaPerCap(cap);
      if (r != null && mounted) {
        setState(() {
          _cittaCtrl.text = r.citta;
          _provinciaCtrl.text = r.provincia;
        });
      }
    }
  }

  Future<void> _salva() async {
    setState(() => _salvando = true);
    try {
      final nuovo = IndirizzoServizioModel(
        id: widget.esistente?.id ?? '',
        indirizzo: _indirizzoCtrl.text.trim(),
        cap: _capCtrl.text.trim(),
        citta: _cittaCtrl.text.trim(),
        provincia: _provinciaCtrl.text.trim().toUpperCase(),
        referente: _referenteCtrl.text.trim(),
        note: _noteCtrl.text.trim(),
      );
      await widget.indirizziService.salvaIndirizzo(widget.clienteId, nuovo);
      final lista =
          await widget.indirizziService.getIndirizzi(widget.clienteId).first;
      widget.onSalvato(lista);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _salvando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.esistente == null
            ? 'Nuovo indirizzo di servizio'
            : 'Modifica indirizzo',
        style: const TextStyle(
            fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _indirizzoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Indirizzo',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              Row(children: [
                SizedBox(
                  width: 110,
                  child: TextField(
                    controller: _capCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(5),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'CAP',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    onChanged: _onCapChanged,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _cittaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Città',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _provinciaCtrl,
                    maxLength: 2,
                    textCapitalization: TextCapitalization.characters,
                    buildCounter: (_,
                            {required currentLength,
                            required isFocused,
                            maxLength}) =>
                        null,
                    decoration: const InputDecoration(
                      labelText: 'Prov.',
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              TextField(
                controller: _referenteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Referente',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _salvando ? null : () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: _salvando ? null : _salva,
          style:
              FilledButton.styleFrom(backgroundColor: AppColors.primary),
          child: _salvando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      color: AppColors.surface, strokeWidth: 2))
              : const Text('Salva'),
        ),
      ],
    );
  }
}
