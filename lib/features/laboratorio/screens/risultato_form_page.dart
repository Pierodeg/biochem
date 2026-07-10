import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/service_providers.dart';
import '../../../models/risultato_analisi_model.dart';
import '../../../models/servizio_lab_model.dart';
import '../famiglie_analisi.dart';

/// Form di inserimento/modifica di una riga di risultati.
///
/// Un solo campione (scelto da Reg Lab) + un campo per ogni colonna della
/// famiglia. Le prime colonne (cert numb / cod A / committente) si
/// auto-compilano dal campione selezionato.
class RisultatoFormPage extends ConsumerStatefulWidget {
  final FamigliaAnalisi famiglia;
  final RisultatoAnalisi? risultato;

  const RisultatoFormPage({
    super.key,
    required this.famiglia,
    this.risultato,
  });

  @override
  ConsumerState<RisultatoFormPage> createState() => _RisultatoFormPageState();
}

class _RisultatoFormPageState extends ConsumerState<RisultatoFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _certCtrl;
  late final TextEditingController _codACtrl;
  late final TextEditingController _committenteCtrl;
  late final Map<String, TextEditingController> _valori;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final r = widget.risultato;
    _certCtrl = TextEditingController(text: r?.certNumb ?? '');
    _codACtrl = TextEditingController(text: r?.codA ?? '');
    _committenteCtrl = TextEditingController(text: r?.committente ?? '');
    _valori = {
      for (final c in widget.famiglia.colonne)
        c.key: TextEditingController(text: r?.valori[c.key] ?? ''),
    };
  }

  @override
  void dispose() {
    _certCtrl.dispose();
    _codACtrl.dispose();
    _committenteCtrl.dispose();
    for (final c in _valori.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _scegliCampione() async {
    final scelto = await showModalBottomSheet<ServizioLabModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A2A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => const _SelettoreCampione(),
    );
    if (scelto == null) return;
    setState(() {
      _certCtrl.text = scelto.certificazioneNumerica;
      _codACtrl.text = scelto.codiceA;
      _committenteCtrl.text = scelto.committente;
    });
  }

  Future<void> _salva() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      final valori = <String, String>{};
      _valori.forEach((k, c) {
        if (c.text.trim().isNotEmpty) valori[k] = c.text.trim();
      });
      final r = RisultatoAnalisi(
        id: widget.risultato?.id ?? '',
        certNumb: _certCtrl.text.trim(),
        codA: _codACtrl.text.trim(),
        committente: _committenteCtrl.text.trim(),
        valori: valori,
        createdAt: widget.risultato?.createdAt ?? DateTime.now(),
      );
      await ref
          .read(risultatiAnalisiServiceProvider)
          .salva(widget.famiglia.collection, r);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore nel salvataggio: $e')),
      );
    }
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.glassFieldLabel),
        filled: true,
        fillColor: AppColors.glassDark,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.glassBorder, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              const BorderSide(color: AppColors.accentGreenDark, width: 1),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final isModifica = widget.risultato != null;
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
          foregroundColor: AppColors.textOnDark,
          title: Text(
              '${isModifica ? 'Modifica' : 'Nuovo'} — ${widget.famiglia.titolo}'),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Campione ────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.glassCard,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.glassBorder, width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Campione (da Reg Lab)',
                            style: TextStyle(
                              color: AppColors.textOnDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _scegliCampione,
                          icon: const Icon(Icons.search, size: 16),
                          label: const Text('Scegli'),
                          style: TextButton.styleFrom(
                              foregroundColor: AppColors.accentGreenDark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _certCtrl,
                      style: const TextStyle(color: AppColors.textOnDark),
                      decoration: _dec('N° certificato'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Seleziona un campione'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _codACtrl,
                            style:
                                const TextStyle(color: AppColors.textOnDark),
                            decoration: _dec('Cod A'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _committenteCtrl,
                            style:
                                const TextStyle(color: AppColors.textOnDark),
                            decoration: _dec('Committente'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'RISULTATI',
                style: TextStyle(
                  color: AppColors.textOnDarkMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),
              // ── Valori misurati ─────────────────────────────────────────
              ...widget.famiglia.colonne.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TextFormField(
                      controller: _valori[c.key],
                      style: const TextStyle(color: AppColors.textOnDark),
                      decoration: _dec(c.label),
                    ),
                  )),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _salvando ? null : _salva,
                icon: _salvando
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_salvando ? 'Salvataggio…' : 'Salva'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom-sheet per scegliere un campione da Reg Lab (`servizi_lab`).
class _SelettoreCampione extends ConsumerStatefulWidget {
  const _SelettoreCampione();

  @override
  ConsumerState<_SelettoreCampione> createState() => _SelettoreCampioneState();
}

class _SelettoreCampioneState extends ConsumerState<_SelettoreCampione> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final service = ref.read(serviziLabServiceProvider);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.glassBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                autofocus: true,
                style: const TextStyle(color: AppColors.textOnDark),
                onChanged: (v) => setState(() => _query = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Cerca committente o n° certificato…',
                  hintStyle:
                      const TextStyle(color: AppColors.textOnDarkMuted),
                  prefixIcon: const Icon(Icons.search,
                      color: AppColors.textOnDarkSecondary),
                  filled: true,
                  fillColor: AppColors.glassDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<ServizioLabModel>>(
                stream: service.getServiziLab(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.accentGreenDark));
                  }
                  final servizi = snap.data!.where((s) {
                    if (_query.isEmpty) return true;
                    return s.committente.toLowerCase().contains(_query) ||
                        s.certificazioneNumerica
                            .toLowerCase()
                            .contains(_query);
                  }).toList();
                  if (servizi.isEmpty) {
                    return const Center(
                      child: Text('Nessun campione trovato',
                          style:
                              TextStyle(color: AppColors.textOnDarkMuted)),
                    );
                  }
                  return ListView.builder(
                    itemCount: servizi.length,
                    itemBuilder: (context, i) {
                      final s = servizi[i];
                      return ListTile(
                        title: Text(
                          s.committente.isNotEmpty
                              ? s.committente
                              : '(senza committente)',
                          style: const TextStyle(color: AppColors.textOnDark),
                        ),
                        subtitle: Text(
                          'Cert. ${s.certificazioneNumerica} · Cod A ${s.codiceA}',
                          style: const TextStyle(
                              color: AppColors.textOnDarkSecondary,
                              fontSize: 12),
                        ),
                        onTap: () => Navigator.of(context).pop(s),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
