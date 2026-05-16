import 'package:biochem/core/providers/service_providers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/registro_parametro_model.dart';
import '../../../services/import_registro_service.dart';
import '../../../services/registro_service.dart';
import 'dart:io';
import 'dart:typed_data';

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
              icon: const Icon(Icons.upload_file_outlined,
                  color: AppColors.accentGreenDark),
              tooltip: 'Importa da Excel',
              onPressed: _importaExcel,
            ),
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
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          ...preset.categorie.map((c) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.primary.withValues(alpha: 0.20),
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
                              )),
                          GestureDetector(
                            onTap: () => _gestisciCampioni(preset),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: preset.campioni.isEmpty
                                    ? AppColors.glassDark
                                    : AppColors.accentBlueDark
                                        .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: preset.campioni.isEmpty
                                      ? AppColors.glassBorder
                                      : AppColors.accentBlueDark
                                          .withValues(alpha: 0.40),
                                  width: 0.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    preset.campioni.isEmpty
                                        ? Icons.water_drop_outlined
                                        : Icons.water_drop,
                                    size: 12,
                                    color: preset.campioni.isEmpty
                                        ? AppColors.textOnDarkMuted
                                        : AppColors.accentBlueDark,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    preset.campioni.isEmpty
                                        ? 'Nessun campione'
                                        : preset.campioni.length == 1
                                            ? preset.campioni.first
                                            : '${preset.campioni.length} campioni',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: preset.campioni.isEmpty
                                          ? AppColors.textOnDarkMuted
                                          : AppColors.accentBlueDark,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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
                campioni: esistente?.campioni ?? [],
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

  Future<void> _importaExcel() async {
    // Mostra dialog informativo prima di aprire il file picker
    final conferma = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A2A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.glassBorder, width: 0.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.info_outline,
                color: AppColors.accentGreenDark, size: 20),
            SizedBox(width: 8),
            Text('Struttura file CSV',
                style: TextStyle(
                    color: AppColors.textOnDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 15)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Il file CSV deve seguire questa struttura:',
                style: TextStyle(
                    color: AppColors.textOnDarkSecondary, fontSize: 13),
              ),
              const SizedBox(height: 14),
              _rigaLeggenda('Riga 1', 'Nome del registro',
                  AppColors.accentGreenDark, 'Es: Registro Acque Potabili'),
              const SizedBox(height: 8),
              _rigaLeggenda('## Categoria', 'Inizio nuova categoria',
                  AppColors.accentBlueDark, 'Es: ## Chimico-fisici'),
              const SizedBox(height: 8),
              _rigaLeggenda(
                  'Intestazioni',
                  'Riga obbligatoria dopo ##',
                  AppColors.accentAmberDark,
                  'Parametro,U.M.,V.L.,LoQ,I,Metodo Rif.'),
              const SizedBox(height: 8),
              _rigaLeggenda('Parametri', 'Una riga per parametro',
                  AppColors.textOnDarkSecondary, 'pH,-,6.5-9.5,-,-,ISO 10523'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.glassDark,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.glassBorderSubtle, width: 0.5),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Esempio completo:',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textOnDarkSecondary)),
                    SizedBox(height: 6),
                    Text(
                      'Registro Acque Potabili\n'
                      '\n'
                      '## Chimico-fisici\n'
                      'Parametro,U.M.,V.L.,LoQ,I,Metodo Rif.\n'
                      'pH,-,6.5 - 9.5,-,-,ISO 10523\n'
                      'Conducibilità,µS/cm,2500,5,-,ISO 7888\n'
                      '\n'
                      '## Microbiologici\n'
                      'Parametro,U.M.,V.L.,LoQ,I,Metodo Rif.\n'
                      'E. Coli,UFC/100mL,0,-,-,ISO 9308-1',
                      style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textOnDarkMuted,
                          fontFamily: 'monospace',
                          height: 1.6),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '⚠️ Le celle vuote vanno lasciate vuote — non scrivere - o N/A',
                style:
                    TextStyle(fontSize: 11, color: AppColors.accentAmberDark),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla',
                style: TextStyle(color: AppColors.textOnDarkSecondary)),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.upload_file_outlined, size: 16),
            label: const Text('Scegli file CSV'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary.withValues(alpha: 0.30),
              foregroundColor: AppColors.accentGreenDark,
              side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.50), width: 0.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );

    if (conferma != true || !mounted) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: false,
    );

    if (result == null || result.files.single.path == null) return;

    final bytes = await File(result.files.single.path!).readAsBytes();
    final service = ImportRegistroService();
    final importResult = service.parsaCSV(bytes);

    if (importResult.nomePreset.isEmpty && importResult.categorie.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('File CSV non valido o vuoto'),
          backgroundColor: Colors.red,
        ));
      }
      return;
    }

    if (!mounted) return;
    await _apriPreviewImport(importResult);
  }

  Widget _rigaLeggenda(
      String tag, String descrizione, Color colore, String esempio) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: colore.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border:
                Border.all(color: colore.withValues(alpha: 0.40), width: 0.5),
          ),
          child: Text(tag,
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600, color: colore)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(descrizione,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textOnDark,
                      fontWeight: FontWeight.w500)),
              Text(esempio,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textOnDarkMuted,
                      fontFamily: 'monospace')),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _apriPreviewImport(ImportRegistroResult importResult) async {
    final registroService = ref.read(_registroServiceProvider);

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => _PreviewImportPage(
          importResult: importResult,
          registroService: registroService,
        ),
      ),
    );
  }

  Future<void> _gestisciCampioni(RegistroPresetModel preset) async {
    final registroService = ref.read(_registroServiceProvider);
    final campioni = await registroService.getCampioni();

    if (!mounted) return;

    final selezionati = List<String>.from(preset.campioni);

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          backgroundColor: const Color(0xFF0A2A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.glassBorder, width: 0.5),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Campioni di riferimento',
                  style: TextStyle(
                      color: AppColors.textOnDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
              const SizedBox(height: 2),
              Text(preset.nome,
                  style: const TextStyle(
                      color: AppColors.textOnDarkSecondary, fontSize: 12)),
            ],
          ),
          content: SizedBox(
            width: 400,
            height: 300,
            child: campioni.isEmpty
                ? const Center(
                    child: Text('Nessun campione disponibile',
                        style: TextStyle(color: AppColors.textOnDarkMuted)))
                : ListView.builder(
                    itemCount: campioni.length,
                    itemBuilder: (_, i) {
                      final campione = campioni[i];
                      final isSelected = selezionati.contains(campione);
                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (v) {
                          setStateDialog(() {
                            if (v == true) {
                              selezionati.add(campione);
                            } else {
                              selezionati.remove(campione);
                            }
                          });
                        },
                        title: Text(campione,
                            style: const TextStyle(
                                color: AppColors.textOnDark, fontSize: 13)),
                        activeColor: AppColors.accentGreenDark,
                        checkColor: const Color(0xFF003D1E),
                        side: BorderSide(
                            color: AppColors.glassBorder, width: 0.5),
                        dense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 4),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annulla',
                  style: TextStyle(color: AppColors.textOnDarkSecondary)),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final aggiornato = RegistroPresetModel(
                  id: preset.id,
                  nome: preset.nome,
                  descrizione: preset.descrizione,
                  categorie: preset.categorie,
                  campioni: selezionati,
                  createdAt: preset.createdAt,
                );
                await registroService.salvaPreset(aggiornato);
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
      ),
    );
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
        campioni: widget.preset.campioni,
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

// ─── Preview import da Excel ──────────────────────────────────────────────────

class _PreviewImportPage extends ConsumerStatefulWidget {
  final ImportRegistroResult importResult;
  final RegistroService registroService;

  const _PreviewImportPage({
    required this.importResult,
    required this.registroService,
  });

  @override
  ConsumerState<_PreviewImportPage> createState() => _PreviewImportPageState();
}

class _PreviewImportPageState extends ConsumerState<_PreviewImportPage> {
  late String _nomePreset;
  late List<RegistroCategoriaModel> _categorie;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _nomePreset = widget.importResult.nomePreset;
    _categorie = widget.importResult.categorie
        .map((c) => RegistroCategoriaModel(
              id: c.id,
              nome: c.nome,
              parametri: List.from(c.parametri),
            ))
        .toList();
  }

  Future<void> _modificaNomePreset() async {
    final ctrl = TextEditingController(text: _nomePreset);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A2A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.glassBorder, width: 0.5),
        ),
        title: const Text('Nome registro',
            style: TextStyle(
                color: AppColors.textOnDark, fontWeight: FontWeight.w600)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDec('Nome registro'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla',
                style: TextStyle(color: AppColors.textOnDarkSecondary)),
          ),
          FilledButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                setState(() => _nomePreset = ctrl.text.trim());
              }
              Navigator.pop(ctx);
            },
            style: _primaryButtonStyle(),
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }

  Future<void> _modificaNomeCategoria(int catIndex) async {
    final ctrl = TextEditingController(text: _categorie[catIndex].nome);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A2A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.glassBorder, width: 0.5),
        ),
        title: const Text('Nome categoria',
            style: TextStyle(
                color: AppColors.textOnDark, fontWeight: FontWeight.w600)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDec('Nome categoria'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla',
                style: TextStyle(color: AppColors.textOnDarkSecondary)),
          ),
          FilledButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                setState(() {
                  _categorie[catIndex] = RegistroCategoriaModel(
                    id: _categorie[catIndex].id,
                    nome: ctrl.text.trim(),
                    parametri: _categorie[catIndex].parametri,
                  );
                });
              }
              Navigator.pop(ctx);
            },
            style: _primaryButtonStyle(),
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminaCategoria(int catIndex) async {
    final ok = await showDialog<bool>(
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
            'Eliminare "${_categorie[catIndex].nome}" e tutti i suoi parametri?',
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
    if (ok == true) {
      setState(() => _categorie.removeAt(catIndex));
    }
  }

  Future<void> _modificaParametro(
      int catIndex, int paramIndex, RegistroParametroModel p) async {
    final ctrlParametro = TextEditingController(text: p.parametro);
    final ctrlUm = TextEditingController(text: p.um);
    final ctrlVl = TextEditingController(text: p.vl);
    final ctrlLoq = TextEditingController(text: p.loq);
    final ctrlI = TextEditingController(text: p.i);
    final ctrlMetodo = TextEditingController(text: p.metodoRif);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A2A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.glassBorder, width: 0.5),
        ),
        title: const Text('Modifica parametro',
            style: TextStyle(
                color: AppColors.textOnDark,
                fontWeight: FontWeight.w600,
                fontSize: 14)),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: ctrlParametro,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDec('Parametro *'),
                    autofocus: true),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                      child: TextField(
                          controller: ctrlUm,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDec('U.M.'))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: TextField(
                          controller: ctrlLoq,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDec('LoQ'))),
                ]),
                const SizedBox(height: 10),
                TextField(
                    controller: ctrlVl,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDec('V.L.')),
                const SizedBox(height: 10),
                TextField(
                    controller: ctrlI,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDec('I (Incertezza)')),
                const SizedBox(height: 10),
                TextField(
                    controller: ctrlMetodo,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDec('Metodo di riferimento')),
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
              if (ctrlParametro.text.trim().isEmpty) return;
              setState(() {
                final nuovi = List<RegistroParametroModel>.from(
                    _categorie[catIndex].parametri);
                nuovi[paramIndex] = p.copyWith(
                  parametro: ctrlParametro.text.trim(),
                  um: ctrlUm.text.trim(),
                  vl: ctrlVl.text.trim(),
                  loq: ctrlLoq.text.trim(),
                  i: ctrlI.text.trim(),
                  metodoRif: ctrlMetodo.text.trim(),
                );
                _categorie[catIndex] = RegistroCategoriaModel(
                  id: _categorie[catIndex].id,
                  nome: _categorie[catIndex].nome,
                  parametri: nuovi,
                );
              });
              Navigator.pop(ctx);
            },
            style: _primaryButtonStyle(),
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }

  Future<void> _spostaParametro(int catIndex, int paramIndex) async {
    if (_categorie.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Crea prima un\'altra categoria per spostare')),
      );
      return;
    }

    final altreCategorie =
        _categorie.asMap().entries.where((e) => e.key != catIndex).toList();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A2A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.glassBorder, width: 0.5),
        ),
        title: const Text('Sposta in categoria',
            style: TextStyle(
                color: AppColors.textOnDark, fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: altreCategorie
              .map((e) => ListTile(
                    title: Text(e.value.nome,
                        style: const TextStyle(color: AppColors.textOnDark)),
                    onTap: () {
                      setState(() {
                        final param =
                            _categorie[catIndex].parametri[paramIndex];
                        final nuoviSrc = List<RegistroParametroModel>.from(
                            _categorie[catIndex].parametri)
                          ..removeAt(paramIndex);
                        _categorie[catIndex] = RegistroCategoriaModel(
                          id: _categorie[catIndex].id,
                          nome: _categorie[catIndex].nome,
                          parametri: nuoviSrc,
                        );
                        final nuoviDst = List<RegistroParametroModel>.from(
                            _categorie[e.key].parametri)
                          ..add(param.copyWith(
                              categoria: _categorie[e.key].nome,
                              ordine: _categorie[e.key].parametri.length));
                        _categorie[e.key] = RegistroCategoriaModel(
                          id: _categorie[e.key].id,
                          nome: _categorie[e.key].nome,
                          parametri: nuoviDst,
                        );
                      });
                      Navigator.pop(ctx);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _eliminaParametro(int catIndex, int paramIndex) {
    setState(() {
      final nuovi =
          List<RegistroParametroModel>.from(_categorie[catIndex].parametri)
            ..removeAt(paramIndex);
      _categorie[catIndex] = RegistroCategoriaModel(
        id: _categorie[catIndex].id,
        nome: _categorie[catIndex].nome,
        parametri: nuovi,
      );
    });
  }

  Future<void> _aggiungiCategoria() async {
    final ctrl = TextEditingController();
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
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDec('Nome categoria'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla',
                style: TextStyle(color: AppColors.textOnDarkSecondary)),
          ),
          FilledButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                setState(() {
                  _categorie.add(RegistroCategoriaModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    nome: ctrl.text.trim(),
                    parametri: [],
                  ));
                });
              }
              Navigator.pop(ctx);
            },
            style: _primaryButtonStyle(),
            child: const Text('Aggiungi'),
          ),
        ],
      ),
    );
  }

  Future<void> _salva() async {
    if (_nomePreset.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci il nome del registro')),
      );
      return;
    }

    setState(() => _salvando = true);

    try {
      final presetEsistenti = await widget.registroService.getPreset().first;
      final duplicato = presetEsistenti
          .where((p) => p.nome.toLowerCase() == _nomePreset.toLowerCase())
          .toList();

      if (duplicato.isNotEmpty && mounted) {
        setState(() => _salvando = false);
        await _gestisciDuplicato(duplicato.first);
        return;
      }

      await _salvaNuovoPreset();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _gestisciDuplicato(RegistroPresetModel esistente) async {
    final scelta = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A2A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.glassBorder, width: 0.5),
        ),
        title: const Text('Registro già esistente',
            style: TextStyle(
                color: AppColors.textOnDark, fontWeight: FontWeight.w600)),
        content: Text('"$_nomePreset" esiste già. Cosa vuoi fare?',
            style: const TextStyle(color: AppColors.textOnDarkSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'annulla'),
            child: const Text('Annulla',
                style: TextStyle(color: AppColors.textOnDarkSecondary)),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, 'nuovo'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accentBlueDark,
              side: BorderSide(
                  color: AppColors.accentBlueDark.withValues(alpha: 0.50),
                  width: 0.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Crea nuovo'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'sovrascrivi'),
            style: _primaryButtonStyle(),
            child: const Text('Sovrascrivi'),
          ),
        ],
      ),
    );

    if (scelta == 'annulla' || scelta == null) return;

    if (scelta == 'sovrascrivi') {
      await _salvaSovrascrivendo(esistente.id);
    } else if (scelta == 'nuovo') {
      await _chiediNuovoNomeESalva();
    }
  }

  Future<void> _chiediNuovoNomeESalva() async {
    final ctrl = TextEditingController(text: '$_nomePreset (2)');
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A2A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.glassBorder, width: 0.5),
        ),
        title: const Text('Nuovo nome registro',
            style: TextStyle(
                color: AppColors.textOnDark, fontWeight: FontWeight.w600)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDec('Nome registro'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla',
                style: TextStyle(color: AppColors.textOnDarkSecondary)),
          ),
          FilledButton(
            onPressed: () async {
              if (ctrl.text.trim().isNotEmpty) {
                setState(() => _nomePreset = ctrl.text.trim());
                Navigator.pop(ctx);
                await _salvaNuovoPreset();
              }
            },
            style: _primaryButtonStyle(),
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }

  Future<void> _salvaNuovoPreset() async {
    final preset = RegistroPresetModel(
      id: '',
      nome: _nomePreset,
      descrizione: '',
      categorie: _categorie,
      campioni: const [],
      createdAt: DateTime.now(),
    );
    await widget.registroService.salvaPreset(preset);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registro "$_nomePreset" salvato'),
          backgroundColor: AppColors.primary.withValues(alpha: 0.90),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _salvaSovrascrivendo(String id) async {
    final preset = RegistroPresetModel(
      id: id,
      nome: _nomePreset,
      descrizione: '',
      categorie: _categorie,
      campioni: const [],
      createdAt: DateTime.now(),
    );
    await widget.registroService.salvaPreset(preset);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registro "$_nomePreset" sovrascritto'),
          backgroundColor: AppColors.primary.withValues(alpha: 0.90),
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
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
          title: const Text('Preview import',
              style: TextStyle(
                  color: AppColors.textOnDark, fontWeight: FontWeight.w600)),
          actions: [
            IconButton(
              icon: const Icon(Icons.create_new_folder_outlined,
                  color: AppColors.accentGreenDark),
              tooltip: 'Aggiungi categoria',
              onPressed: _aggiungiCategoria,
            ),
            FilledButton(
              onPressed: _salvando ? null : _salva,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary.withValues(alpha: 0.30),
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
                          color: AppColors.accentGreenDark, strokeWidth: 2))
                  : const Text('Salva registro'),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GestureDetector(
              onTap: _modificaNomePreset,
              child: Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.glassCardMedium,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.glassBorderMedium, width: 0.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.science_outlined,
                        color: AppColors.accentGreenDark, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _nomePreset.isEmpty
                            ? 'Tocca per inserire il nome'
                            : _nomePreset,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _nomePreset.isEmpty
                              ? AppColors.textOnDarkMuted
                              : AppColors.textOnDark,
                        ),
                      ),
                    ),
                    const Icon(Icons.edit_outlined,
                        color: AppColors.textOnDarkMuted, size: 16),
                  ],
                ),
              ),
            ),
            if (widget.importResult.errori.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.30),
                      width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.warning_amber_outlined,
                          size: 14,
                          color: AppColors.error.withValues(alpha: 0.80)),
                      const SizedBox(width: 6),
                      Text(
                          '${widget.importResult.errori.length} righe ignorate',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.error.withValues(alpha: 0.80),
                              fontWeight: FontWeight.w600)),
                    ]),
                    ...widget.importResult.errori.map((e) => Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(e,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textOnDarkSecondary)),
                        )),
                  ],
                ),
              ),
            ..._categorie.asMap().entries.map((catEntry) {
              final catIndex = catEntry.key;
              final cat = catEntry.value;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.glassCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.glassBorder, width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.20),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Icon(Icons.folder_outlined,
                                color: AppColors.accentGreenDark, size: 12),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(cat.nome,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.accentGreenDark)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.glassDark,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('${cat.parametri.length} param.',
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textOnDarkSecondary)),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => _modificaNomeCategoria(catIndex),
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(Icons.edit_outlined,
                                  size: 15,
                                  color: AppColors.textOnDarkSecondary),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _eliminaCategoria(catIndex),
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Icon(Icons.delete_outline,
                                  size: 15,
                                  color:
                                      AppColors.error.withValues(alpha: 0.70)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 0.5,
                      color: AppColors.glassBorderSubtle,
                      margin: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    ...cat.parametri.asMap().entries.map((paramEntry) {
                      final paramIndex = paramEntry.key;
                      final p = paramEntry.value;
                      return Container(
                        margin: const EdgeInsets.fromLTRB(10, 6, 10, 0),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.glassDark,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.glassBorderSubtle, width: 0.5),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(p.parametro,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textOnDark)),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(p.um,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textOnDarkSecondary)),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(p.vl,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textOnDarkSecondary)),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  _modificaParametro(catIndex, paramIndex, p),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(Icons.edit_outlined,
                                    size: 14,
                                    color: AppColors.textOnDarkSecondary),
                              ),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  _spostaParametro(catIndex, paramIndex),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(Icons.swap_horiz,
                                    size: 14,
                                    color: AppColors.textOnDarkSecondary),
                              ),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  _eliminaParametro(catIndex, paramIndex),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(Icons.delete_outline,
                                    size: 14,
                                    color: AppColors.error
                                        .withValues(alpha: 0.70)),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: GestureDetector(
                        onTap: () => _apriDialogNuovoParametro(catIndex),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.30),
                              width: 0.5,
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add,
                                  size: 14, color: AppColors.accentGreenDark),
                              SizedBox(width: 4),
                              Text('Aggiungi parametro',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.accentGreenDark,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _apriDialogNuovoParametro(int catIndex) async {
    final ctrlParametro = TextEditingController();
    final ctrlUm = TextEditingController();
    final ctrlVl = TextEditingController();
    final ctrlLoq = TextEditingController();
    final ctrlI = TextEditingController();
    final ctrlMetodo = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A2A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.glassBorder, width: 0.5),
        ),
        title: const Text('Nuovo parametro',
            style: TextStyle(
                color: AppColors.textOnDark,
                fontWeight: FontWeight.w600,
                fontSize: 14)),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: ctrlParametro,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDec('Parametro *'),
                    autofocus: true),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                      child: TextField(
                          controller: ctrlUm,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDec('U.M.'))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: TextField(
                          controller: ctrlLoq,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDec('LoQ'))),
                ]),
                const SizedBox(height: 10),
                TextField(
                    controller: ctrlVl,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDec('V.L.')),
                const SizedBox(height: 10),
                TextField(
                    controller: ctrlI,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDec('I (Incertezza)')),
                const SizedBox(height: 10),
                TextField(
                    controller: ctrlMetodo,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDec('Metodo di riferimento')),
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
              if (ctrlParametro.text.trim().isEmpty) return;
              setState(() {
                final nuovi = List<RegistroParametroModel>.from(
                    _categorie[catIndex].parametri)
                  ..add(RegistroParametroModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    parametro: ctrlParametro.text.trim(),
                    um: ctrlUm.text.trim(),
                    vl: ctrlVl.text.trim(),
                    loq: ctrlLoq.text.trim(),
                    i: ctrlI.text.trim(),
                    metodoRif: ctrlMetodo.text.trim(),
                    categoria: _categorie[catIndex].nome,
                    ordine: _categorie[catIndex].parametri.length,
                  ));
                _categorie[catIndex] = RegistroCategoriaModel(
                  id: _categorie[catIndex].id,
                  nome: _categorie[catIndex].nome,
                  parametri: nuovi,
                );
              });
              Navigator.pop(ctx);
            },
            style: _primaryButtonStyle(),
            child: const Text('Aggiungi'),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDec(String label) => InputDecoration(
        labelText: label,
        labelStyle:
            const TextStyle(color: AppColors.glassFieldLabelDim, fontSize: 13),
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

  ButtonStyle _primaryButtonStyle() => FilledButton.styleFrom(
        backgroundColor: AppColors.primary.withValues(alpha: 0.30),
        foregroundColor: AppColors.accentGreenDark,
        side: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.50), width: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      );
}
