import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/service_providers.dart';
import '../../../models/risultato_analisi_model.dart';
import '../../../services/import_risultati_service.dart';
import '../famiglie_analisi.dart';
import 'risultato_form_page.dart';

/// Pagina generica dei risultati di una famiglia di analisi.
///
/// Stesso codice per Cationi/Primarie/Anioni/Microbio: cambia solo la
/// `famiglia` passata. Un solo widget per desktop e mobile (LayoutBuilder).
class RisultatiPage extends ConsumerStatefulWidget {
  final FamigliaAnalisi famiglia;
  const RisultatiPage({super.key, required this.famiglia});

  @override
  ConsumerState<RisultatiPage> createState() => _RisultatiPageState();
}

class _RisultatiPageState extends ConsumerState<RisultatiPage> {
  final _cercaCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _cercaCtrl.dispose();
    super.dispose();
  }

  Stream<List<RisultatoAnalisi>> get _stream => ref
      .read(risultatiAnalisiServiceProvider)
      .getRisultati(widget.famiglia.collection);

  List<RisultatoAnalisi> _filtra(List<RisultatoAnalisi> lista) {
    if (_query.isEmpty) return lista;
    final q = _query.toLowerCase();
    return lista
        .where((r) =>
            r.committente.toLowerCase().contains(q) ||
            r.certNumb.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _nuovo({RisultatoAnalisi? esistente}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RisultatoFormPage(
          famiglia: widget.famiglia,
          risultato: esistente,
        ),
      ),
    );
  }

  Future<void> _elimina(RisultatoAnalisi r) async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminare la riga?'),
        content: Text(
            'Certificato ${r.certNumb} — ${r.committente}. Operazione non annullabile.'),
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
    if (conferma != true) return;
    await ref
        .read(risultatiAnalisiServiceProvider)
        .elimina(widget.famiglia.collection, r.id);
  }

  Future<void> _importaCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true, // bytes: funziona anche su web
    );
    if (result == null || result.files.single.bytes == null) return;

    final parsed = ImportRisultatiService()
        .parsaCSV(result.files.single.bytes!, widget.famiglia);

    if (!mounted) return;
    if (parsed.righe.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(parsed.errori.isNotEmpty
                ? parsed.errori.first
                : 'Nessuna riga importabile')),
      );
      return;
    }

    final conferma = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Conferma import'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Righe da importare: ${parsed.righe.length}'),
            if (parsed.colonneNonTrovate.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Colonne non trovate nel CSV: ${parsed.colonneNonTrovate.join(", ")}',
                style: const TextStyle(fontSize: 12, color: AppColors.warning),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Importa'),
          ),
        ],
      ),
    );
    if (conferma != true) return;

    await ref
        .read(risultatiAnalisiServiceProvider)
        .salvaBatch(widget.famiglia.collection, parsed.righe);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${parsed.righe.length} righe importate')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            _buildToolbar(),
            Expanded(
              child: StreamBuilder<List<RisultatoAnalisi>>(
                stream: _stream,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Center(
                      child: Text('Errore: ${snap.error}',
                          style: const TextStyle(color: AppColors.error)),
                    );
                  }
                  if (!snap.hasData) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.accentGreenDark));
                  }
                  final righe = _filtra(snap.data!);
                  if (righe.isEmpty) {
                    return Center(
                      child: Text(
                        _query.isEmpty
                            ? 'Nessun risultato. Aggiungi una riga o importa un CSV.'
                            : 'Nessun risultato per «$_query».',
                        style:
                            const TextStyle(color: AppColors.textOnDarkMuted),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 88),
                    itemCount: righe.length,
                    itemBuilder: (context, i) => _RigaRisultato(
                      famiglia: widget.famiglia,
                      risultato: righe[i],
                      onTap: () => _nuovo(esistente: righe[i]),
                      onElimina: () => _elimina(righe[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: () => _nuovo(),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Aggiungi'),
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _cercaCtrl,
              style: const TextStyle(color: AppColors.textOnDark),
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Cerca committente o n° certificato…',
                hintStyle: const TextStyle(color: AppColors.textOnDarkMuted),
                prefixIcon: const Icon(Icons.search,
                    color: AppColors.textOnDarkSecondary, size: 20),
                isDense: true,
                filled: true,
                fillColor: AppColors.glassDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _importaCsv,
            tooltip: 'Importa CSV',
            icon: const Icon(Icons.upload_file_outlined,
                color: AppColors.accentGreenDark),
          ),
        ],
      ),
    );
  }
}

class _RigaRisultato extends StatelessWidget {
  final FamigliaAnalisi famiglia;
  final RisultatoAnalisi risultato;
  final VoidCallback onTap;
  final VoidCallback onElimina;

  const _RigaRisultato({
    required this.famiglia,
    required this.risultato,
    required this.onTap,
    required this.onElimina,
  });

  @override
  Widget build(BuildContext context) {
    final compilati = risultato.valori.length;
    final totale = famiglia.colonne.length;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppColors.glassCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.glassBorder, width: 0.5),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            risultato.certNumb.isNotEmpty ? risultato.certNumb : '—',
            style: const TextStyle(
              color: AppColors.accentGreenDark,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(
          risultato.committente.isNotEmpty
              ? risultato.committente
              : '(senza committente)',
          style: const TextStyle(
              color: AppColors.textOnDark, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Cod A ${risultato.codA.isNotEmpty ? risultato.codA : "—"} · $compilati/$totale valori',
          style: const TextStyle(
              color: AppColors.textOnDarkSecondary, fontSize: 12),
        ),
        trailing: IconButton(
          onPressed: onElimina,
          icon: const Icon(Icons.delete_outline,
              color: AppColors.textOnDarkMuted, size: 20),
          tooltip: 'Elimina',
        ),
      ),
    );
  }
}
