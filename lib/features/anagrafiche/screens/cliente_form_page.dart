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

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errore;
  String? _clienteIdCorrente;
  bool _allowDirectPop = false;
  Map<String, Object?>? _snapshotIniziale;
  ClienteModel? _clienteOriginale;
  int _numeroCliente = 0;

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
  final _capServizioCtrl = TextEditingController();
  final _cittaServizioCtrl = TextEditingController();
  final _provinciaServizioCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _cellulareCtrl = TextEditingController();
  final _pecCtrl = TextEditingController();
  bool _identificazioneAperta = true;
  bool _indirizzoAperta = true;
  bool _datiFiscaliAperta = true;
  bool _indirizzoServizioAperta = true;
  bool _contattiAperta = true;

  String? _tipoCommittente;
  List<String> _sugCodiceUnivoco = [];
  List<String> _sugReferente = [];
  List<String> _sugEmail = [];
  List<String> _sugPec = [];
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

  Widget _buildCardIdentificazione() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0x21FFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x38FFFFFF), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(
                () => _identificazioneAperta = !_identificazioneAperta),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              child: Row(
                children: [
                  // Icona
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        width: 0.5,
                      ),
                    ),
                    child: const Icon(Icons.person_outline,
                        color: AppColors.accentGreenDark, size: 14),
                  ),
                  const SizedBox(width: 8),
                  // Titolo — larghezza fissa così non sposta la freccia
                  const Text(
                    'Identificazione',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentGreenDark,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Anteprima — Expanded così occupa lo spazio centrale
                  // senza spostare la freccia
                  Expanded(
                    child: AnimatedOpacity(
                      opacity: _identificazioneAperta ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _committenteCtrl.text,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0x80FFFFFF)),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Freccia — sempre in posizione fissa a destra
                  AnimatedRotation(
                    turns: _identificazioneAperta ? 0 : 0.5,
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

          // ── Contenuto animato ────────────────────────────────────────
          ClipRect(
            child: AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              sizeCurve: Curves.easeInOut,
              firstCurve: Curves.easeInOut,
              secondCurve: Curves.easeInOut,
              crossFadeState: _identificazioneAperta
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
                      children: [
                        _buildCampoNumero(),
                        const SizedBox(height: 12),
                        _buildCampoTipoCommittente(),
                        const SizedBox(height: 12),
                        _buildCampoCommittente(),
                      ],
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

  Widget _buildCardIndirizzoForm() {
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
            onTap: () => setState(() => _indirizzoAperta = !_indirizzoAperta),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              child: Row(
                children: [
                  Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.35), width: 0.5),
                    ),
                    child: const Icon(Icons.home_outlined, color: AppColors.accentGreenDark, size: 14),
                  ),
                  const SizedBox(width: 8),
                  const Text('Indirizzo principale', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accentGreenDark, letterSpacing: 0.3)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AnimatedOpacity(
                      opacity: _indirizzoAperta ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Text(_cittaCtrl.text, style: const TextStyle(fontSize: 11, color: Color(0x80FFFFFF)), overflow: TextOverflow.ellipsis, maxLines: 1, textAlign: TextAlign.end),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _indirizzoAperta ? 0 : 0.5,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0x14FFFFFF), border: Border.all(color: const Color(0x26FFFFFF), width: 0.5)),
                      child: const Icon(Icons.keyboard_arrow_up, color: Color(0x80FFFFFF), size: 14),
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
              crossFadeState: _indirizzoAperta ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              firstChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 0.5, color: const Color(0x26FFFFFF), margin: const EdgeInsets.symmetric(horizontal: 14)),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCampoTesto(controller: _indirizzoCtrl, label: 'Indirizzo'),
                        const SizedBox(height: 12),
                        Row(children: [
                          SizedBox(width: 90, child: _buildCampoCapLookup()),
                          const SizedBox(width: 8),
                          Expanded(child: _buildCampoTesto(controller: _cittaCtrl, label: 'Città')),
                          const SizedBox(width: 8),
                          SizedBox(width: 70, child: _buildCampoProvincia()),
                        ]),
                      ],
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

  Widget _buildCardDatiFiscali() {
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
            onTap: () => setState(() => _datiFiscaliAperta = !_datiFiscaliAperta),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              child: Row(
                children: [
                  Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.35), width: 0.5),
                    ),
                    child: const Icon(Icons.receipt_outlined, color: AppColors.accentGreenDark, size: 14),
                  ),
                  const SizedBox(width: 8),
                  const Text('Dati fiscali', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accentGreenDark, letterSpacing: 0.3)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AnimatedOpacity(
                      opacity: _datiFiscaliAperta ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Text(_pivaCtrl.text, style: const TextStyle(fontSize: 11, color: Color(0x80FFFFFF)), overflow: TextOverflow.ellipsis, maxLines: 1, textAlign: TextAlign.end),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _datiFiscaliAperta ? 0 : 0.5,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0x14FFFFFF), border: Border.all(color: const Color(0x26FFFFFF), width: 0.5)),
                      child: const Icon(Icons.keyboard_arrow_up, color: Color(0x80FFFFFF), size: 14),
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
              crossFadeState: _datiFiscaliAperta ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              firstChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 0.5, color: const Color(0x26FFFFFF), margin: const EdgeInsets.symmetric(horizontal: 14)),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCampoTesto(controller: _pivaCtrl, label: 'P.IVA / Codice Fiscale'),
                        const SizedBox(height: 12),
                        _buildCampoAutocomplete(controller: _codiceUnivocoCtrl, label: 'Codice Univoco', suggerimenti: _sugCodiceUnivoco),
                        const SizedBox(height: 12),
                        _buildCampoAutocomplete(controller: _referenteCtrl, label: 'C/A Referente', suggerimenti: _sugReferente),
                      ],
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

  Widget _buildCardIndirizzoServizio() {
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
            onTap: () => setState(() => _indirizzoServizioAperta = !_indirizzoServizioAperta),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              child: Row(
                children: [
                  Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.35), width: 0.5),
                    ),
                    child: const Icon(Icons.location_on_outlined, color: AppColors.accentGreenDark, size: 14),
                  ),
                  const SizedBox(width: 8),
                  const Text('Indirizzo servizio', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accentGreenDark, letterSpacing: 0.3)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AnimatedOpacity(
                      opacity: _indirizzoServizioAperta ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Text(_cittaServizioCtrl.text, style: const TextStyle(fontSize: 11, color: Color(0x80FFFFFF)), overflow: TextOverflow.ellipsis, maxLines: 1, textAlign: TextAlign.end),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _indirizzoServizioAperta ? 0 : 0.5,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0x14FFFFFF), border: Border.all(color: const Color(0x26FFFFFF), width: 0.5)),
                      child: const Icon(Icons.keyboard_arrow_up, color: Color(0x80FFFFFF), size: 14),
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
              crossFadeState: _indirizzoServizioAperta ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              firstChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 0.5, color: const Color(0x26FFFFFF), margin: const EdgeInsets.symmetric(horizontal: 14)),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCampoTesto(controller: _indirizzoServizioCtrl, label: 'Indirizzo servizio'),
                        const SizedBox(height: 12),
                        Row(children: [
                          SizedBox(width: 90, child: _buildCampoCapServizioLookup()),
                          const SizedBox(width: 8),
                          Expanded(child: _buildCampoTesto(controller: _cittaServizioCtrl, label: 'Città')),
                          const SizedBox(width: 8),
                          SizedBox(width: 70, child: _buildCampoProvinciaServizio()),
                        ]),
                      ],
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

  Widget _buildCardContatti() {
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
            onTap: () => setState(() => _contattiAperta = !_contattiAperta),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              child: Row(
                children: [
                  Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.35), width: 0.5),
                    ),
                    child: const Icon(Icons.contact_phone_outlined, color: AppColors.accentGreenDark, size: 14),
                  ),
                  const SizedBox(width: 8),
                  const Text('Contatti', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accentGreenDark, letterSpacing: 0.3)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AnimatedOpacity(
                      opacity: _contattiAperta ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Text(_emailCtrl.text, style: const TextStyle(fontSize: 11, color: Color(0x80FFFFFF)), overflow: TextOverflow.ellipsis, maxLines: 1, textAlign: TextAlign.end),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _contattiAperta ? 0 : 0.5,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0x14FFFFFF), border: Border.all(color: const Color(0x26FFFFFF), width: 0.5)),
                      child: const Icon(Icons.keyboard_arrow_up, color: Color(0x80FFFFFF), size: 14),
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
              crossFadeState: _contattiAperta ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              firstChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 0.5, color: const Color(0x26FFFFFF), margin: const EdgeInsets.symmetric(horizontal: 14)),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCampoAutocomplete(controller: _emailCtrl, label: 'Email', suggerimenti: _sugEmail, tastiera: TextInputType.emailAddress, validatore: _validaEmail),
                        const SizedBox(height: 12),
                        _buildCampoTesto(controller: _telefonoCtrl, label: 'Telefono', tastiera: TextInputType.phone),
                        const SizedBox(height: 12),
                        _buildCampoTesto(controller: _cellulareCtrl, label: 'Cellulare', tastiera: TextInputType.phone),
                        const SizedBox(height: 12),
                        _buildCampoAutocomplete(controller: _pecCtrl, label: 'PEC', suggerimenti: _sugPec, tastiera: TextInputType.emailAddress, validatore: _validaEmail),
                      ],
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

  Future<void> _inizializza() async {
    try {
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
        final cliente = await _clientiService.getClienteById(widget.clienteId!);
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
        final indirizzi =
            await _indirizziService.getIndirizzi(widget.clienteId!).first;
        _indirizzi = indirizzi;
      } else {
        _numeroCliente = 0;
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

  Future<void> _onCapChanged(String cap) async {
    if (cap.length == 5) {
      final r = await _capService.cercaPerCap(cap);
      if (r != null && mounted)
        setState(() {
          _cittaCtrl.text = r.citta;
          _provinciaCtrl.text = r.provincia;
        });
    }
  }

  Future<void> _onCapServizioChanged(String cap) async {
    if (cap.length == 5) {
      final r = await _capService.cercaPerCap(cap);
      if (r != null && mounted)
        setState(() {
          _cittaServizioCtrl.text = r.citta;
          _provinciaServizioCtrl.text = r.provincia;
        });
    }
  }

  Future<ClienteModel> _costruisciEsalva({bool isDraft = false}) async {
    if (_clienteOriginale == null) {
      final customNum = int.tryParse(_numeroClienteCtrl.text.trim());
      if (customNum != null && customNum > 0) {
        _numeroCliente = customNum;
      } else {
        _numeroCliente = await _clientiService.getNextNumeroCliente();
      }
    } else {
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

  Future<void> _salva() async {
    final isAdmin = ref.read(currentUserProvider).valueOrNull?.isAdmin ?? false;
    if (!isAdmin) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    try {
      final salvato = await _costruisciEsalva(isDraft: false);
      if (mounted) {
        _clienteOriginale = salvato;
        _numeroClienteCtrl.text = salvato.numeroCliente.toString();
        _snapshotIniziale = _snapshotCorrente();
        _showSnackBar('Cliente salvato con successo', AppColors.primary);
      }
    } catch (e) {
      if (mounted) _showSnackBar('Errore: $e', AppColors.error);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _esci() async {
    final isAdmin = ref.read(currentUserProvider).valueOrNull?.isAdmin ?? false;
    if (!isAdmin || !_hasUnsavedChanges) {
      await _chiudiPagina();
      return;
    }

    final scelta = await showDialog<_SceltaEsci>(
      context: context,
      builder: (ctx) => _buildDialog(
        titolo: 'Uscire dal form',
        contenuto: _canSaveAsDraft
            ? 'Ci sono modifiche non salvate. Cosa vuoi fare?'
            : 'Ci sono modifiche non salvate. Salvarle prima di uscire?',
        azioni: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, _SceltaEsci.annulla),
              child: const Text('Rimani')),
          if (_canSaveAsDraft)
            _glassOutlinedButton('Salva come bozza',
                () => Navigator.pop(ctx, _SceltaEsci.bozza)),
          _glassPrimaryButton(
              'Salva ed esci', () => Navigator.pop(ctx, _SceltaEsci.salva)),
        ],
      ),
    );

    if (scelta == null || scelta == _SceltaEsci.annulla || !mounted) return;
    final isDraft = scelta == _SceltaEsci.bozza;
    if (!isDraft && !(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);
    try {
      final salvato = await _costruisciEsalva(isDraft: isDraft);
      if (mounted) {
        _clienteOriginale = salvato;
        _snapshotIniziale = _snapshotCorrente();
        _showSnackBar(isDraft ? 'Salvato come bozza' : 'Cliente salvato',
            isDraft ? AppColors.textOnDarkSecondary : AppColors.primary);
        await _chiudiPagina();
      }
    } catch (e) {
      if (mounted) _showSnackBar('Errore: $e', AppColors.error);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _elimina() async {
    final nome = _committenteCtrl.text.trim().isNotEmpty
        ? _committenteCtrl.text.trim()
        : 'questo cliente';
    final conferma = await showDialog<bool>(
      context: context,
      builder: (ctx) => _buildDialog(
        titolo: 'Elimina cliente',
        contenuto: 'Eliminare "$nome"? L\'azione è irreversibile.',
        azioni: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annulla',
                  style: TextStyle(color: AppColors.textOnDarkSecondary))),
          _glassDangerButton('Elimina', () => Navigator.pop(ctx, true)),
        ],
      ),
    );
    if (conferma != true || !mounted) return;
    try {
      await _clientiService.eliminaCliente(_clienteIdCorrente!);
      if (mounted) {
        _showSnackBar('Cliente eliminato', AppColors.error);
        await _chiudiPagina();
      }
    } catch (e) {
      if (mounted) _showSnackBar('Errore: $e', AppColors.error);
    }
  }

  Future<void> _apriDialogIndirizzo([IndirizzoServizioModel? esistente]) async {
    if (_clienteIdCorrente == null) {
      _showSnackBar(
          'Salva prima il cliente per aggiungere indirizzi', AppColors.warning);
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

  Future<void> _eliminaIndirizzo(IndirizzoServizioModel indirizzo) async {
    if (_clienteIdCorrente == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => _buildDialog(
        titolo: 'Elimina indirizzo',
        contenuto: 'Eliminare "${indirizzo.etichetta}"?',
        azioni: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annulla',
                  style: TextStyle(color: AppColors.textOnDarkSecondary))),
          _glassDangerButton('Elimina', () => Navigator.pop(ctx, true)),
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
      if (mounted) _showSnackBar('Errore: $e', AppColors.error);
    }
  }

  Map<String, Object?> _snapshotCorrente() => {
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

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: color.withValues(alpha: 0.90),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side:
            BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 0.5),
      ),
    ));
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────

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
      return _buildScaffold(titolo, isAdmin,
          body: const Center(
              child:
                  CircularProgressIndicator(color: AppColors.accentGreenDark)));
    }

    if (_errore != null) {
      return _buildScaffold(titolo, isAdmin,
          body: Center(
              child: Text('Errore: $_errore',
                  style: const TextStyle(color: AppColors.error))));
    }

    return PopScope(
      canPop: _allowDirectPop,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (!_isSaving) await _esci();
      },
      child: _buildScaffold(
        titolo,
        isAdmin,
        body: Form(
          key: _formKey,
          child: isDesktop
              ? _buildLayoutDesktop(isReadOnly)
              : _buildLayoutMobile(isReadOnly),
        ),
      ),
    );
  }

  Widget _buildScaffold(String titolo, bool isAdmin, {required Widget body}) {
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
        appBar: _buildAppBar(titolo, isAdmin),
        body: body,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(String titolo, bool isAdmin) {
    return AppBar(
      backgroundColor: AppColors.glassDarkest,
      title: Text(titolo,
          style: const TextStyle(
              color: AppColors.textOnDark, fontWeight: FontWeight.w600)),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textOnDark),
        onPressed: () {
          if (!_isSaving) _esci();
        },
      ),
      actions: [
        if (isAdmin && _clienteIdCorrente != null)
          IconButton(
            icon: Icon(Icons.delete_outline,
                color: AppColors.error.withValues(alpha: 0.8)),
            tooltip: 'Elimina cliente',
            onPressed: _isSaving ? null : _elimina,
          ),
      ],
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
                    _buildCardIdentificazione(),
                    const SizedBox(height: 12),
                    _buildCardIndirizzoForm(),
                    const SizedBox(height: 12),
                    _buildCardDatiFiscali(),
                    const SizedBox(height: 12),
                    _buildCardIndirizzoServizio(),
                    const SizedBox(height: 12),
                    _buildCardContatti(),
                    const SizedBox(height: 12),
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
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 24),
            child: AbsorbPointer(
              absorbing: isReadOnly,
              child: Opacity(
                opacity: isReadOnly ? 0.7 : 1.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGruppoCard('Identificazione', [
                      Row(children: [
                        SizedBox(width: 150, child: _buildCampoNumero()),
                        const SizedBox(width: 16),
                        SizedBox(
                            width: 200, child: _buildCampoTipoCommittente()),
                        const SizedBox(width: 16),
                        Expanded(child: _buildCampoCommittente()),
                      ]),
                    ]),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildGruppoCard('Indirizzo principale', [
                            _buildCampoTesto(
                                controller: _indirizzoCtrl, label: 'Indirizzo'),
                            const SizedBox(height: 12),
                            Row(children: [
                              SizedBox(
                                  width: 90, child: _buildCampoCapLookup()),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: _buildCampoTesto(
                                      controller: _cittaCtrl, label: 'Città')),
                              const SizedBox(width: 8),
                              SizedBox(
                                  width: 70, child: _buildCampoProvincia()),
                            ]),
                          ]),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildGruppoCard('Indirizzo servizio', [
                            _buildCampoTesto(
                                controller: _indirizzoServizioCtrl,
                                label: 'Indirizzo servizio'),
                            const SizedBox(height: 12),
                            Row(children: [
                              SizedBox(
                                  width: 90,
                                  child: _buildCampoCapServizioLookup()),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: _buildCampoTesto(
                                      controller: _cittaServizioCtrl,
                                      label: 'Città')),
                              const SizedBox(width: 8),
                              SizedBox(
                                  width: 70,
                                  child: _buildCampoProvinciaServizio()),
                            ]),
                          ]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildGruppoCard('Dati fiscali', [
                            _buildCampoTesto(
                                controller: _pivaCtrl,
                                label: 'P.IVA / Codice Fiscale'),
                            const SizedBox(height: 12),
                            _buildCampoAutocomplete(
                                controller: _codiceUnivocoCtrl,
                                label: 'Codice Univoco',
                                suggerimenti: _sugCodiceUnivoco),
                            const SizedBox(height: 12),
                            _buildCampoAutocomplete(
                                controller: _referenteCtrl,
                                label: 'C/A Referente',
                                suggerimenti: _sugReferente),
                          ]),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildGruppoCard('Contatti', [
                            _buildCampoAutocomplete(
                                controller: _emailCtrl,
                                label: 'Email',
                                suggerimenti: _sugEmail,
                                tastiera: TextInputType.emailAddress,
                                validatore: _validaEmail),
                            const SizedBox(height: 12),
                            Row(children: [
                              Expanded(
                                  child: _buildCampoTesto(
                                      controller: _telefonoCtrl,
                                      label: 'Telefono',
                                      tastiera: TextInputType.phone)),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: _buildCampoTesto(
                                      controller: _cellulareCtrl,
                                      label: 'Cellulare',
                                      tastiera: TextInputType.phone)),
                            ]),
                            const SizedBox(height: 12),
                            _buildCampoAutocomplete(
                                controller: _pecCtrl,
                                label: 'PEC',
                                suggerimenti: _sugPec,
                                tastiera: TextInputType.emailAddress,
                                validatore: _validaEmail),
                          ]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
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

  // ─── GRUPPO CARD GLASS ────────────────────────────────────────────────────

  Widget _buildGruppoCard(String titolo, List<Widget> children) {
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
          Text(
            titolo,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.accentGreenDark,
              letterSpacing: 0.3,
            ),
          ),
          Container(
            height: 0.5,
            color: AppColors.glassBorder,
            margin: const EdgeInsets.symmetric(vertical: 10),
          ),
          ...children,
        ],
      ),
    );
  }

  // ─── SEZIONE INDIRIZZI ────────────────────────────────────────────────────

  Widget _buildSezioneIndirizzi(bool isReadOnly) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.glassCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  color: AppColors.accentGreenDark, size: 16),
              const SizedBox(width: 6),
              const Text(
                'Indirizzi di servizio',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentGreenDark,
                    letterSpacing: 0.3),
              ),
              const Spacer(),
              if (!isReadOnly && _clienteIdCorrente != null)
                GestureDetector(
                  onTap: () => _apriDialogIndirizzo(),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.40),
                          width: 0.5),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add,
                            size: 14, color: AppColors.accentGreenDark),
                        SizedBox(width: 4),
                        Text('Aggiungi',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.accentGreenDark)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          Container(
              height: 0.5,
              color: AppColors.glassBorder,
              margin: const EdgeInsets.symmetric(vertical: 10)),
          if (_indirizzi.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.glassDark,
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: AppColors.glassBorderSubtle, width: 0.5),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 14, color: AppColors.textOnDarkMuted),
                  const SizedBox(width: 8),
                  Text(
                    _clienteIdCorrente == null
                        ? 'Salva il cliente per aggiungere indirizzi'
                        : 'Nessun indirizzo di servizio',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textOnDarkMuted),
                  ),
                ],
              ),
            )
          else
            ...(_indirizzi.map((ind) => _buildCardIndirizzo(ind, isReadOnly))),
        ],
      ),
    );
  }

  Widget _buildCardIndirizzo(IndirizzoServizioModel ind, bool isReadOnly) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.glassDark,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.glassBorderSubtle, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.location_pin,
              size: 14, color: AppColors.accentGreenDark),
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
                          color: AppColors.textOnDark)),
                if (ind.cap.isNotEmpty ||
                    ind.citta.isNotEmpty ||
                    ind.provincia.isNotEmpty)
                  Text(
                    [ind.cap, ind.citta, ind.provincia.toUpperCase()]
                        .where((s) => s.isNotEmpty)
                        .join(' '),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textOnDarkSecondary),
                  ),
                if (ind.referente.isNotEmpty)
                  Text('Ref: ${ind.referente}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textOnDarkSecondary)),
              ],
            ),
          ),
          if (!isReadOnly) ...[
            IconButton(
              icon: Icon(Icons.edit_outlined,
                  size: 15, color: AppColors.textOnDarkSecondary),
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
              onPressed: () => _apriDialogIndirizzo(ind),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(Icons.delete_outline,
                  size: 15, color: AppColors.error.withValues(alpha: 0.8)),
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
              onPressed: () => _eliminaIndirizzo(ind),
            ),
          ],
        ],
      ),
    );
  }

  // ─── BOTTONI AZIONE ───────────────────────────────────────────────────────

  Widget _buildBottoniAzione(bool isReadOnly) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.glassDarkest,
        border:
            Border(top: BorderSide(color: AppColors.glassBorder, width: 0.5)),
      ),
      child: isReadOnly
          ? SizedBox(
              width: double.infinity,
              child: _glassOutlinedButton('Chiudi', _chiudiPagina),
            )
          : Row(
              children: [
                _glassOutlinedButton(
                    'Annulla', _isSaving ? null : _chiudiPagina),
                const SizedBox(width: 10),
                Expanded(
                    child:
                        _glassOutlinedButton('Esci', _isSaving ? null : _esci)),
                const SizedBox(width: 10),
                Expanded(
                  child: _glassPrimaryButton(
                    _isSaving ? '' : 'Salva e resta',
                    _isSaving ? null : _salva,
                    isLoading: _isSaving,
                  ),
                ),
              ],
            ),
    );
  }

  // ─── CAMPI ────────────────────────────────────────────────────────────────

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

  Widget _buildCampoNumero() {
    final isAdmin = ref.read(currentUserProvider).valueOrNull?.isAdmin ?? false;
    if (isAdmin) {
      return TextFormField(
        controller: _numeroClienteCtrl,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(color: AppColors.textOnDark),
        decoration: _inputDec('Numero cliente').copyWith(
          hintText: _clienteOriginale == null ? 'Auto' : null,
          prefixText: _numeroClienteCtrl.text.isNotEmpty ? '#' : null,
        ),
        onChanged: (_) => setState(() {}),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Numero cliente',
            style:
                TextStyle(fontSize: 11, color: AppColors.textOnDarkSecondary)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.glassDark,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.glassBorderSubtle, width: 0.5),
          ),
          child: Text(
            _clienteOriginale == null && _numeroCliente == 0
                ? 'Auto'
                : '#${_numeroCliente.toString().padLeft(3, '0')}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: _clienteOriginale == null && _numeroCliente == 0
                  ? AppColors.textOnDarkMuted
                  : AppColors.textOnDark,
              fontSize: 14,
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
      style: const TextStyle(color: AppColors.textOnDark),
      decoration: _inputDec(label),
      validator: validatore,
    );
  }

  Widget _buildCampoCapLookup() {
    return TextFormField(
      controller: _capCtrl,
      style: const TextStyle(color: AppColors.textOnDark),
      decoration: _inputDec('CAP'),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(5)
      ],
      onChanged: _onCapChanged,
    );
  }

  Widget _buildCampoCapServizioLookup() {
    return TextFormField(
      controller: _capServizioCtrl,
      style: const TextStyle(color: AppColors.textOnDark),
      decoration: _inputDec('CAP'),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(5)
      ],
      onChanged: _onCapServizioChanged,
    );
  }

  Widget _buildCampoProvincia() {
    return TextFormField(
      controller: _provinciaCtrl,
      style: const TextStyle(color: AppColors.textOnDark),
      decoration: _inputDec('Prov.'),
      maxLength: 2,
      textCapitalization: TextCapitalization.characters,
      buildCounter:
          (_, {required currentLength, required isFocused, maxLength}) => null,
    );
  }

  Widget _buildCampoProvinciaServizio() {
    return TextFormField(
      controller: _provinciaServizioCtrl,
      style: const TextStyle(color: AppColors.textOnDark),
      decoration: _inputDec('Prov.'),
      maxLength: 2,
      textCapitalization: TextCapitalization.characters,
      buildCounter:
          (_, {required currentLength, required isFocused, maxLength}) => null,
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
      optionsBuilder: (v) {
        if (v.text.isEmpty) return const Iterable<String>.empty();
        final q = v.text.toLowerCase();
        return suggerimenti.where((s) => s.toLowerCase().contains(q));
      },
      onSelected: (s) => controller.text = s,
      fieldViewBuilder:
          (context, fieldController, focusNode, onFieldSubmitted) {
        fieldController.text = controller.text;
        return TextFormField(
          controller: fieldController,
          focusNode: focusNode,
          keyboardType: tastiera,
          style: const TextStyle(color: AppColors.textOnDark),
          decoration: _inputDec(label),
          validator: validatore != null
              ? (_) => validatore(fieldController.text)
              : null,
          onChanged: (v) => controller.text = v,
        );
      },
    );
  }

  // ─── HELPER UI ────────────────────────────────────────────────────────────

  InputDecoration _inputDec(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: AppColors.glassFieldLabelDim,
          fontSize: 13,
        ),
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
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error, width: 0.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );

  Widget _buildDialog({
    required String titolo,
    required String contenuto,
    required List<Widget> azioni,
  }) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0A2A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.glassBorder, width: 0.5),
      ),
      title: Text(titolo,
          style: const TextStyle(
              color: AppColors.textOnDark,
              fontWeight: FontWeight.w600,
              fontSize: 16)),
      content: Text(contenuto,
          style: const TextStyle(
              color: AppColors.textOnDarkSecondary, fontSize: 14)),
      actions: azioni,
    );
  }

  Widget _glassPrimaryButton(String label, VoidCallback? onTap,
      {bool isLoading = false}) {
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary.withValues(alpha: 0.30),
        foregroundColor: AppColors.accentGreenDark,
        side: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.50), width: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  color: AppColors.accentGreenDark, strokeWidth: 2))
          : Text(label),
    );
  }

  Widget _glassOutlinedButton(String label, VoidCallback? onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textOnDarkSecondary,
        side: BorderSide(color: AppColors.glassBorder, width: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Text(label),
    );
  }

  Widget _glassDangerButton(String label, VoidCallback? onTap) {
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.error.withValues(alpha: 0.25),
        foregroundColor: const Color(0xFFFF7070),
        side: BorderSide(
            color: AppColors.error.withValues(alpha: 0.40), width: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label),
    );
  }

  String? _validaEmail(String? valore) {
    if (valore == null || valore.isEmpty) return null;
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!regex.hasMatch(valore)) return 'Email non valida';
    return null;
  }
}

enum _SceltaEsci { annulla, bozza, salva }

// ─── DIALOG INDIRIZZO ─────────────────────────────────────────────────────────

class _IndirizzoDialog extends StatefulWidget {
  final IndirizzoServizioModel? esistente;
  final String clienteId;
  final CapService capService;
  final IndirizziServizioService indirizziService;
  final void Function(List<IndirizzoServizioModel>) onSalvato;

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
      if (r != null && mounted)
        setState(() {
          _cittaCtrl.text = r.citta;
          _provinciaCtrl.text = r.provincia;
        });
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
              content: Text('Errore: $e'), backgroundColor: AppColors.error),
        );
        setState(() => _salvando = false);
      }
    }
  }

  InputDecoration _inputDec(String label) => InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(color: AppColors.textOnDarkSecondary, fontSize: 13),
        filled: true,
        fillColor: const Color(0x0DFFFFFF),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: AppColors.glassBorder, width: 0.5)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: AppColors.glassBorder, width: 0.5)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0A2A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.glassBorder, width: 0.5),
      ),
      title: Text(
        widget.esistente == null
            ? 'Nuovo indirizzo di servizio'
            : 'Modifica indirizzo',
        style: const TextStyle(
            color: AppColors.textOnDark, fontWeight: FontWeight.w600),
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: _indirizzoCtrl,
                  style: const TextStyle(color: AppColors.textOnDark),
                  decoration: _inputDec('Indirizzo')),
              const SizedBox(height: 12),
              Row(children: [
                SizedBox(
                    width: 110,
                    child: TextField(
                        controller: _capCtrl,
                        style: const TextStyle(color: AppColors.textOnDark),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(5)
                        ],
                        decoration: _inputDec('CAP'),
                        onChanged: _onCapChanged)),
                const SizedBox(width: 10),
                Expanded(
                    child: TextField(
                        controller: _cittaCtrl,
                        style: const TextStyle(color: AppColors.textOnDark),
                        decoration: _inputDec('Città'))),
                const SizedBox(width: 10),
                SizedBox(
                    width: 80,
                    child: TextField(
                        controller: _provinciaCtrl,
                        style: const TextStyle(color: AppColors.textOnDark),
                        maxLength: 2,
                        textCapitalization: TextCapitalization.characters,
                        buildCounter: (_,
                                {required currentLength,
                                required isFocused,
                                maxLength}) =>
                            null,
                        decoration: _inputDec('Prov.'))),
              ]),
              const SizedBox(height: 12),
              TextField(
                  controller: _referenteCtrl,
                  style: const TextStyle(color: AppColors.textOnDark),
                  decoration: _inputDec('Referente')),
              const SizedBox(height: 12),
              TextField(
                  controller: _noteCtrl,
                  style: const TextStyle(color: AppColors.textOnDark),
                  maxLines: 2,
                  decoration: _inputDec('Note')),
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: _salvando ? null : () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textOnDarkSecondary,
            side: BorderSide(color: AppColors.glassBorder, width: 0.5),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Annulla'),
        ),
        FilledButton(
          onPressed: _salvando ? null : _salva,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary.withValues(alpha: 0.30),
            foregroundColor: AppColors.accentGreenDark,
            side: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.50), width: 0.5),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: _salvando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      color: AppColors.accentGreenDark, strokeWidth: 2))
              : const Text('Salva'),
        ),
      ],
    );
  }
}
