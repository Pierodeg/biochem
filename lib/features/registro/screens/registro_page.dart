import 'package:biochem/core/providers/service_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/registro_parametro_model.dart';
import '../../../services/registro_service.dart';

// ─── Provider ─────────────────────────────────────────────────────────────────

final _registroServiceProvider = Provider<RegistroService>((ref) {
  return ref.watch(registroServiceProvider);
});

final _presetStreamProvider = StreamProvider<List<RegistroPresetModel>>((ref) {
  return ref.watch(_registroServiceProvider).getPreset();
});

// ─── Pagina Registro ──────────────────────────────────────────────────────────

class RegistroPage extends ConsumerStatefulWidget {
  const RegistroPage({super.key});

  @override
  ConsumerState<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends ConsumerState<RegistroPage> {
  final _cercaCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _cercaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final presetAsync = ref.watch(_presetStreamProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 600;

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
          title: const Text('Registro',
              style: TextStyle(
                  color: AppColors.textOnDark, fontWeight: FontWeight.w600)),
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: AppColors.accentGreenDark),
              tooltip: 'Nuovo preset',
              onPressed: () => _apriDialogPreset(null),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                  isDesktop ? 40 : 16, 14, isDesktop ? 40 : 16, 14),
              child: TextField(
                controller: _cercaCtrl,
                style: const TextStyle(color: AppColors.textOnDark),
                onChanged: (v) => setState(() => _query = v.trim()),
                decoration: InputDecoration(
                  hintText: 'Cerca preset...',
                  hintStyle: const TextStyle(color: AppColors.textOnDarkMuted),
                  prefixIcon: const Icon(Icons.search,
                      size: 20, color: AppColors.textOnDarkSecondary),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear,
                              size: 18, color: AppColors.textOnDarkSecondary),
                          onPressed: () {
                            _cercaCtrl.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0x1A000000),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: AppColors.glassBorder, width: 0.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: AppColors.glassBorder, width: 0.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ),
            Container(
              height: 0.5,
              color: AppColors.glassBorder,
              margin: EdgeInsets.symmetric(horizontal: isDesktop ? 40 : 16),
            ),
            Expanded(
              child: presetAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.accentGreenDark)),
                error: (e, _) => Center(
                    child: Text('Errore: $e',
                        style: const TextStyle(color: AppColors.error))),
                data: (preset) {
                  final filtrati = _query.isEmpty
                      ? preset
                      : preset
                          .where((p) => p.nome
                              .toLowerCase()
                              .contains(_query.toLowerCase()))
                          .toList();

                  if (filtrati.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.folder_outlined,
                              size: 64, color: AppColors.textOnDarkMuted),
                          SizedBox(height: 16),
                          Text('Nessun preset nel registro',
                              style: TextStyle(
                                  fontSize: 15,
                                  color: AppColors.textOnDarkSecondary,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 40 : 16, vertical: 16),
                    itemCount: filtrati.length,
                    itemBuilder: (_, i) =>
                        _buildCardPreset(filtrati[i], isDesktop),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Card preset ──────────────────────────────────────────────────────────

  Widget _buildCardPreset(RegistroPresetModel preset, bool isDesktop) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.glassCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder, width: 0.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          hoverColor: AppColors.glassCardHover,
          onTap: () => _apriDettaglioPreset(preset),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        width: 0.5),
                  ),
                  child: const Icon(Icons.science_outlined,
                      color: AppColors.accentGreenDark, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(preset.nome,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textOnDark)),
                      if (preset.descrizione.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(preset.descrizione,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textOnDarkSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: preset.categorie
                            .map((c) => Container(
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.20),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.35),
                                        width: 0.5),
                                  ),
                                  child: Text(
                                    '${c.nome} (${c.parametri.length})',
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.accentGreenDark,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          color: AppColors.textOnDarkSecondary, size: 18),
                      onPressed: () => _apriDialogPreset(preset),
                      tooltip: 'Modifica preset',
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          color: AppColors.error.withValues(alpha: 0.8),
                          size: 18),
                      onPressed: () => _eliminaPreset(preset),
                      tooltip: 'Elimina preset',
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right,
                    color: AppColors.textOnDarkMuted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Dialog nuovo/modifica preset ─────────────────────────────────────────

  Future<void> _apriDialogPreset(RegistroPresetModel? esistente) async {
    final nomeCtrl = TextEditingController(text: esistente?.nome ?? '');
    final descCtrl = TextEditingController(text: esistente?.descrizione ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A2A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.glassBorder, width: 0.5),
        ),
        title: Text(
          esistente == null ? 'Nuovo preset' : 'Modifica preset',
          style: const TextStyle(
              color: AppColors.textOnDark, fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeCtrl,
              style: const TextStyle(color: AppColors.textOnDark),
              decoration: _inputDec('Nome preset'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              style: const TextStyle(color: AppColors.textOnDark),
              decoration: _inputDec('Descrizione'),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla',
                style: TextStyle(color: AppColors.textOnDarkSecondary)),
          ),
          FilledButton(
            onPressed: () async {
              if (nomeCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              final service = ref.read(_registroServiceProvider);
              await service.salvaPreset(RegistroPresetModel(
                id: esistente?.id ?? '',
                nome: nomeCtrl.text.trim(),
                descrizione: descCtrl.text.trim(),
                categorie: esistente?.categorie ?? [],
                createdAt: esistente?.createdAt ?? DateTime.now(),
              ));
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary.withValues(alpha: 0.30),
              foregroundColor: AppColors.accentGreenDark,
              side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.50), width: 0.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }

  // ─── Dettaglio preset ─────────────────────────────────────────────────────

  void _apriDettaglioPreset(RegistroPresetModel preset) {
    showDialog(
      context: context,
      builder: (ctx) => _DettaglioPresetDialog(
        preset: preset,
        onSalva: (aggiornato) async {
          await ref.read(_registroServiceProvider).salvaPreset(aggiornato);
        },
      ),
    );
  }

  // ─── Elimina preset ───────────────────────────────────────────────────────

  Future<void> _eliminaPreset(RegistroPresetModel preset) async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A2A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.glassBorder, width: 0.5),
        ),
        title: const Text('Elimina preset',
            style: TextStyle(
                color: AppColors.textOnDark, fontWeight: FontWeight.w600)),
        content: Text('Eliminare "${preset.nome}"? Azione irreversibile.',
            style: const TextStyle(color: AppColors.textOnDarkSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla',
                style: TextStyle(color: AppColors.textOnDarkSecondary)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
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
    if (conferma != true) return;
    await ref.read(_registroServiceProvider).eliminaPreset(preset.id);
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
}

// ─── Dialog dettaglio preset (quasi fullscreen) ───────────────────────────────

class _DettaglioPresetDialog extends StatefulWidget {
  final RegistroPresetModel preset;
  final Future<void> Function(RegistroPresetModel) onSalva;

  const _DettaglioPresetDialog({
    required this.preset,
    required this.onSalva,
  });

  @override
  State<_DettaglioPresetDialog> createState() => _DettaglioPresetDialogState();
}

class _DettaglioPresetDialogState extends State<_DettaglioPresetDialog> {
  late List<RegistroCategoriaModel> _categorie;
  String? _categoriaSelezionata;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _categorie = List.from(widget.preset.categorie);
    if (_categorie.isNotEmpty) {
      _categoriaSelezionata = _categorie.first.id;
    }
  }

  RegistroCategoriaModel? get _catCorrente =>
      _categorie.where((c) => c.id == _categoriaSelezionata).firstOrNull;

  Future<void> _salva() async {
    setState(() => _salvando = true);
    try {
      final aggiornato = RegistroPresetModel(
        id: widget.preset.id,
        nome: widget.preset.nome,
        descrizione: widget.preset.descrizione,
        categorie: _categorie,
        createdAt: widget.preset.createdAt,
      );
      await widget.onSalva(aggiornato);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: size.width,
        height: size.height * 0.90,
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
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(
                    bottom:
                        BorderSide(color: AppColors.glassBorder, width: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.science_outlined,
                      color: AppColors.accentGreenDark, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(widget.preset.nome,
                        style: const TextStyle(
                            color: AppColors.textOnDark,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline,
                        color: AppColors.accentGreenDark, size: 20),
                    tooltip: 'Aggiungi categoria',
                    onPressed: _aggiungiCategoria,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: _categorie.map((cat) {
                      final isSelected = cat.id == _categoriaSelezionata;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _categoriaSelezionata = cat.id),
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
                          child: Row(
                            children: [
                              Text(cat.nome,
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected
                                          ? AppColors.accentGreenDark
                                          : AppColors.textOnDarkSecondary)),
                              const SizedBox(width: 6),
                              Text('(${cat.parametri.length})',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: isSelected
                                          ? AppColors.accentGreenDark
                                          : AppColors.textOnDarkMuted)),
                              if (isSelected) ...[
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => _eliminaCategoria(cat),
                                  child: Icon(Icons.close,
                                      size: 14,
                                      color: AppColors.error
                                          .withValues(alpha: 0.7)),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

            // Lista parametri
            Expanded(
              child: _catCorrente == null
                  ? const Center(
                      child: Text('Nessuna categoria',
                          style: TextStyle(color: AppColors.textOnDarkMuted)))
                  : _buildListaParametri(_catCorrente!),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              decoration: BoxDecoration(
                color: AppColors.glassDarkest,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border(
                    top: BorderSide(color: AppColors.glassBorder, width: 0.5)),
              ),
              child: Row(
                children: [
                  if (_catCorrente != null)
                    OutlinedButton.icon(
                      onPressed: () => _aggiungiParametro(_catCorrente!),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Aggiungi parametro'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accentGreenDark,
                        side: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.50),
                            width: 0.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _salvando ? null : _salva,
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.30),
                      foregroundColor: AppColors.accentGreenDark,
                      side: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.50),
                          width: 0.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _salvando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                color: AppColors.accentGreenDark,
                                strokeWidth: 2))
                        : const Text('Salva tutto'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Lista parametri ──────────────────────────────────────────────────────

  Widget _buildListaParametri(RegistroCategoriaModel cat) {
    if (cat.parametri.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.list_outlined,
                size: 48, color: AppColors.textOnDarkMuted),
            const SizedBox(height: 12),
            const Text('Nessun parametro in questa categoria',
                style: TextStyle(
                    color: AppColors.textOnDarkSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _aggiungiParametro(cat),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Aggiungi parametro'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accentGreenDark,
                side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.50),
                    width: 0.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Intestazione tabella — con campo I
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.glassDarkest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.glassBorder, width: 0.5),
            ),
            child: const Row(
              children: [
                Expanded(
                    flex: 3,
                    child: Text('PARAMETRO',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textOnDarkMuted,
                            letterSpacing: 0.5))),
                Expanded(
                    flex: 1,
                    child: Text('U.M.',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textOnDarkMuted,
                            letterSpacing: 0.5))),
                Expanded(
                    flex: 2,
                    child: Text('V.L.',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textOnDarkMuted,
                            letterSpacing: 0.5))),
                Expanded(
                    flex: 1,
                    child: Text('LoQ',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textOnDarkMuted,
                            letterSpacing: 0.5))),
                Expanded(
                    flex: 1,
                    child: Text('I',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textOnDarkMuted,
                            letterSpacing: 0.5))),
                Expanded(
                    flex: 3,
                    child: Text('METODO RIF.',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textOnDarkMuted,
                            letterSpacing: 0.5))),
                SizedBox(width: 60),
              ],
            ),
          ),
          const SizedBox(height: 6),
          ...cat.parametri.map((p) => _buildRigaParametro(p, cat)),
        ],
      ),
    );
  }

  Widget _buildRigaParametro(
      RegistroParametroModel p, RegistroCategoriaModel cat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.glassCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.glassBorderSubtle, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
              flex: 3,
              child: Text(p.parametro,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textOnDark))),
          Expanded(
              flex: 1,
              child: Text(p.um,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textOnDarkSecondary))),
          Expanded(
              flex: 2,
              child: Text(p.vl,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textOnDarkSecondary))),
          Expanded(
              flex: 1,
              child: Text(p.loq,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textOnDarkSecondary))),
          // Campo I — incertezza
          Expanded(
              flex: 1,
              child: Text(p.i,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textOnDarkSecondary))),
          Expanded(
              flex: 3,
              child: Text(p.metodoRif,
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textOnDarkMuted),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis)),
          SizedBox(
            width: 60,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _modificaParametro(p, cat),
                  child: const Icon(Icons.edit_outlined,
                      size: 16, color: AppColors.textOnDarkSecondary),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _eliminaParametro(p, cat),
                  child: Icon(Icons.delete_outline,
                      size: 16, color: AppColors.error.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Azioni ───────────────────────────────────────────────────────────────

  Future<void> _aggiungiCategoria() async {
    final nomeCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A2A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.glassBorder, width: 0.5),
        ),
        title: const Text('Nuova categoria',
            style: TextStyle(
                color: AppColors.textOnDark, fontWeight: FontWeight.w600)),
        content: TextField(
          controller: nomeCtrl,
          style: const TextStyle(color: AppColors.textOnDark),
          decoration: InputDecoration(
            labelText: 'Nome categoria',
            labelStyle: const TextStyle(color: AppColors.textOnDarkSecondary),
            filled: true,
            fillColor: const Color(0x0DFFFFFF),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: AppColors.glassBorder, width: 0.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla',
                style: TextStyle(color: AppColors.textOnDarkSecondary)),
          ),
          FilledButton(
            onPressed: () {
              if (nomeCtrl.text.trim().isEmpty) return;
              setState(() {
                final newId = DateTime.now().millisecondsSinceEpoch.toString();
                _categorie.add(RegistroCategoriaModel(
                  id: newId,
                  nome: nomeCtrl.text.trim(),
                  parametri: [],
                ));
                _categoriaSelezionata = newId;
              });
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary.withValues(alpha: 0.30),
              foregroundColor: AppColors.accentGreenDark,
              side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.50), width: 0.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Aggiungi'),
          ),
        ],
      ),
    );
  }

  void _eliminaCategoria(RegistroCategoriaModel cat) async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A2A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.glassBorder, width: 0.5),
        ),
        title: const Text('Elimina categoria',
            style: TextStyle(
                color: AppColors.textOnDark, fontWeight: FontWeight.w600)),
        content: Text(
            'Eliminare "${cat.nome}" e tutti i suoi parametri? Azione irreversibile.',
            style: const TextStyle(color: AppColors.textOnDarkSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla',
                style: TextStyle(color: AppColors.textOnDarkSecondary)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
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
    if (conferma != true) return;
    setState(() {
      _categorie.removeWhere((c) => c.id == cat.id);
      _categoriaSelezionata =
          _categorie.isNotEmpty ? _categorie.first.id : null;
    });
  }

  Future<void> _aggiungiParametro(RegistroCategoriaModel cat) async {
    await _apriDialogParametro(null, cat);
  }

  Future<void> _modificaParametro(
      RegistroParametroModel p, RegistroCategoriaModel cat) async {
    await _apriDialogParametro(p, cat);
  }

  void _eliminaParametro(
      RegistroParametroModel p, RegistroCategoriaModel cat) async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A2A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.glassBorder, width: 0.5),
        ),
        title: const Text('Elimina parametro',
            style: TextStyle(
                color: AppColors.textOnDark, fontWeight: FontWeight.w600)),
        content: Text('Eliminare "${p.parametro}"? Azione irreversibile.',
            style: const TextStyle(color: AppColors.textOnDarkSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla',
                style: TextStyle(color: AppColors.textOnDarkSecondary)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
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
    if (conferma != true) return;
    setState(() {
      final catIndex = _categorie.indexWhere((c) => c.id == cat.id);
      if (catIndex == -1) return;
      final nuoviParametri = List<RegistroParametroModel>.from(cat.parametri)
        ..removeWhere((x) => x.id == p.id);
      _categorie[catIndex] = RegistroCategoriaModel(
        id: cat.id,
        nome: cat.nome,
        parametri: nuoviParametri,
      );
    });
  }

  Future<void> _apriDialogParametro(
      RegistroParametroModel? esistente, RegistroCategoriaModel cat) async {
    final parametroCtrl =
        TextEditingController(text: esistente?.parametro ?? '');
    final umCtrl = TextEditingController(text: esistente?.um ?? '');
    final vlCtrl = TextEditingController(text: esistente?.vl ?? '');
    final loqCtrl = TextEditingController(text: esistente?.loq ?? '');
    final iCtrl = TextEditingController(text: esistente?.i ?? '');
    final metodoCtrl = TextEditingController(text: esistente?.metodoRif ?? '');

    InputDecoration dec(String label) => InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
              color: AppColors.textOnDarkSecondary, fontSize: 12),
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
              color: AppColors.textOnDark, fontWeight: FontWeight.w600),
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
                    decoration: dec('Parametro *')),
                const SizedBox(height: 10),
                // U.M. + LoQ
                Row(children: [
                  Expanded(
                      child: TextField(
                          controller: umCtrl,
                          style: const TextStyle(
                              color: AppColors.textOnDark, fontSize: 13),
                          decoration: dec('U.M.'))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: TextField(
                          controller: loqCtrl,
                          style: const TextStyle(
                              color: AppColors.textOnDark, fontSize: 13),
                          decoration: dec('LoQ'))),
                ]),
                const SizedBox(height: 10),
                // V.L.
                TextField(
                    controller: vlCtrl,
                    style: const TextStyle(
                        color: AppColors.textOnDark, fontSize: 13),
                    decoration: dec('V.L. (Valore limite)')),
                const SizedBox(height: 10),
                // I — Incertezza
                TextField(
                    controller: iCtrl,
                    style: const TextStyle(
                        color: AppColors.textOnDark, fontSize: 13),
                    decoration: dec('I (Incertezza estesa)')),
                const SizedBox(height: 10),
                // Metodo di riferimento
                TextField(
                    controller: metodoCtrl,
                    style: const TextStyle(
                        color: AppColors.textOnDark, fontSize: 13),
                    decoration: dec('Metodo di riferimento')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla',
                style: TextStyle(color: AppColors.textOnDarkSecondary)),
          ),
          FilledButton(
            onPressed: () {
              if (parametroCtrl.text.trim().isEmpty) return;
              setState(() {
                final catIndex = _categorie.indexWhere((c) => c.id == cat.id);
                if (catIndex == -1) return;
                final nuoviParametri =
                    List<RegistroParametroModel>.from(cat.parametri);
                if (esistente == null) {
                  nuoviParametri.add(RegistroParametroModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    parametro: parametroCtrl.text.trim(),
                    um: umCtrl.text.trim(),
                    vl: vlCtrl.text.trim(),
                    loq: loqCtrl.text.trim(),
                    i: iCtrl.text.trim(),
                    metodoRif: metodoCtrl.text.trim(),
                    categoria: cat.id,
                    ordine: nuoviParametri.length,
                  ));
                } else {
                  final idx =
                      nuoviParametri.indexWhere((x) => x.id == esistente.id);
                  if (idx != -1) {
                    nuoviParametri[idx] = esistente.copyWith(
                      parametro: parametroCtrl.text.trim(),
                      um: umCtrl.text.trim(),
                      vl: vlCtrl.text.trim(),
                      loq: loqCtrl.text.trim(),
                      i: iCtrl.text.trim(),
                      metodoRif: metodoCtrl.text.trim(),
                    );
                  }
                }
                _categorie[catIndex] = RegistroCategoriaModel(
                  id: cat.id,
                  nome: cat.nome,
                  parametri: nuoviParametri,
                );
              });
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary.withValues(alpha: 0.30),
              foregroundColor: AppColors.accentGreenDark,
              side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.50), width: 0.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }
}
