import 'dart:typed_data';
import 'package:biochem/utils/web_pdf_preview_stub.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/service_providers.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../models/preventivo_model.dart';
import '../../../widgets/filtri/filtro_preventivi.dart';

// ─── Provider ─────────────────────────────────────────────────────────────────

final _preventiviStreamProvider = StreamProvider<List<PreventivoModel>>((ref) {
  // Dipende dall'auth: si ricrea con token fresco dopo ogni sign-in
  final authUser = ref.watch(authStateProvider).valueOrNull;
  if (authUser == null) return Stream.value([]);
  return ref.watch(preventiviServiceProvider).getPreventivi();
});

// ─── Pagina lista preventivi ──────────────────────────────────────────────────

/// Pagina Preventivi — lista con ricerca, filtri e form (solo admin).
///
/// Incorporata nell'IndexedStack di [MainScreen] (tab 1), NON ha un proprio Scaffold.
class PreventiviPage extends ConsumerStatefulWidget {
  const PreventiviPage({super.key});

  @override
  ConsumerState<PreventiviPage> createState() => _PreventiviPageState();
}

class _PreventiviPageState extends ConsumerState<PreventiviPage> {
  final _cercaController = TextEditingController();
  String _queryRicerca = '';
  bool _filtroAperto = false;
  FiltroPreventiviStato _filtro = const FiltroPreventiviStato();
  // Traccia quale preventivo sta generando il PDF (per mostrare il loader)
  String? _pdfInGenerazione;

  final _moneyFmt =
      NumberFormat.currency(locale: 'it_IT', symbol: '€', decimalDigits: 2);
  final _dateFmt = DateFormat('dd/MM/yyyy');

  @override
  void dispose() {
    _cercaController.dispose();
    super.dispose();
  }

  Future<void> _eliminaPreventivo(PreventivoModel p) async {
    final conferma = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina preventivo'),
        content: Text('Eliminare il preventivo di ${p.committente}? Azione irreversibile.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
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
      await ref.read(preventiviServiceProvider).eliminaPreventivo(p.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preventivo eliminato')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  /// Mostra un'anteprima del PDF prima di scaricare/condividere
  Future<void> _mostraAnteprima(PreventivoModel p) async {
    setState(() => _pdfInGenerazione = p.id);
    try {
      final service = ref.read(preventivoPdfServiceProvider);
      final bytes = await service.buildPdfBytes(p);
      if (!mounted) return;
      setState(() => _pdfInGenerazione = null);
      await showDialog<void>(
        context: context,
        builder: (_) => _PdfPreviewDialog(
          titolo: p.numeroFormattato,
          nomeFile: '${p.numeroFormattato}.pdf',
          bytes: bytes,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _pdfInGenerazione = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore generazione PDF: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Applica ricerca testuale + filtri avanzati
  List<PreventivoModel> _filtra(List<PreventivoModel> lista) {
    List<PreventivoModel> risultato = lista;
    if (_queryRicerca.isNotEmpty) {
      final q = _queryRicerca.toLowerCase();
      risultato = lista
          .where((p) =>
              p.committente.toLowerCase().contains(q) ||
              p.numeroFormattato.toLowerCase().contains(q))
          .toList();
    }
    return applicaFiltroPreventivi(risultato, _filtro);
  }

  @override
  Widget build(BuildContext context) {
    final preventiviAsync = ref.watch(_preventiviStreamProvider);
    final isAdmin =
        ref.watch(currentUserProvider).valueOrNull?.isAdmin ?? false;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 600;

        return preventiviAsync.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary)),
          error: (err, _) => Center(
            child: Text('Errore: $err',
                style: const TextStyle(color: AppColors.error)),
          ),
          data: (preventivi) {
            final filtrati = _filtra(preventivi);
            return isDesktop
                ? _buildDesktopLayout(preventivi, filtrati, isAdmin)
                : _buildMobileLayout(preventivi, filtrati, isAdmin);
          },
        );
      },
    );
  }

  // ─── LAYOUT MOBILE ────────────────────────────────────────────────────────

  Widget _buildMobileLayout(
    List<PreventivoModel> tutti,
    List<PreventivoModel> filtrati,
    bool isAdmin,
  ) {
    return Stack(
      children: [
        Column(
          children: [
            // Barra ricerca + bottone filtri
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: _buildBarraRicercaConFiltro(),
            ),
            // Pannello filtri animato
            FiltroPreventivi(
              aperto: _filtroAperto,
              statoFiltro: _filtro,
              onFiltroApplicato: (f) =>
                  setState(() { _filtro = f; _filtroAperto = false; }),
            ),
            // Riga chip filtri attivi
            FiltriAttiviRowPreventivi(
              stato: _filtro,
              onRimosso: (f) => setState(() => _filtro = f),
            ),
            // Lista preventivi
            Expanded(
              child: filtrati.isEmpty
                  ? _buildStatoVuoto()
                  : ListView.builder(
                      padding: EdgeInsets.fromLTRB(
                          12, 12, 12, isAdmin ? 80 : 16),
                      itemCount: filtrati.length,
                      itemBuilder: (_, i) =>
                          _buildCard(filtrati[i], isAdmin),
                    ),
            ),
          ],
        ),
        // FAB visibile solo agli admin
        if (isAdmin)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              heroTag: 'fab_preventivi',
              onPressed: () => context.push('/preventivo/nuovo'),
              backgroundColor: AppColors.fabBackground,
              child: const Icon(Icons.add, color: AppColors.fabIcon),
            ),
          ),
      ],
    );
  }

  Widget _buildCard(PreventivoModel p, bool isAdmin) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isAdmin ? () => context.push('/preventivo/${p.id}') : null,
        onLongPress: () => _mostraAnteprima(p),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Prima riga: numero + data + freccia
              Row(
                children: [
                  if (p.isDraft) ...[
                    _buildBadgeBozza(),
                    const SizedBox(width: 8),
                  ],
                  _buildBadgeNumero(p),
                  const Spacer(),
                  Text(
                    _dateFmt.format(p.data),
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 4),
                  // Icona PDF (o spinner se in generazione)
                  _pdfInGenerazione == p.id
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: AppColors.primary, strokeWidth: 2))
                      : GestureDetector(
                          onTap: () => _mostraAnteprima(p),
                          child: const Icon(Icons.picture_as_pdf_outlined,
                              color: AppColors.primary, size: 18),
                        ),
                  if (isAdmin) ...[
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => _eliminaPreventivo(p),
                      child: const Icon(Icons.delete_outline,
                          color: AppColors.error, size: 18),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right,
                        color: AppColors.textDisabled, size: 18),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              // Committente
              Text(
                p.committente,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              // Totale + righe
              Row(
                children: [
                  if (p.totale > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _moneyFmt.format(p.totale),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  if (p.righe.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      '${p.righe.length} ${p.righe.length == 1 ? 'servizio' : 'servizi'}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── LAYOUT DESKTOP ───────────────────────────────────────────────────────

  Widget _buildDesktopLayout(
    List<PreventivoModel> tutti,
    List<PreventivoModel> filtrati,
    bool isAdmin,
  ) {
    return Column(
      children: [
        // Barra azioni
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
          child: Row(
            children: [
              SizedBox(
                  width: 340,
                  child: _buildBarraRicercaConFiltro()),
              const Spacer(),
              if (isAdmin)
                FilledButton.icon(
                  onPressed: () => context.push('/preventivo/nuovo'),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nuovo'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.buttonPrimary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                ),
            ],
          ),
        ),
        // Pannello filtri
        FiltroPreventivi(
          aperto: _filtroAperto,
          statoFiltro: _filtro,
          onFiltroApplicato: (f) =>
              setState(() { _filtro = f; _filtroAperto = false; }),
        ),
        // Chip filtri attivi
        FiltriAttiviRowPreventivi(
          stato: _filtro,
          onRimosso: (f) => setState(() => _filtro = f),
        ),
        const Divider(height: 1, color: AppColors.divider),
        // Tabella
        Expanded(
          child: filtrati.isEmpty
              ? _buildStatoVuoto()
              : _buildTabella(filtrati, isAdmin),
        ),
      ],
    );
  }

  Widget _buildTabella(List<PreventivoModel> lista, bool isAdmin) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.tableHeader),
          headingTextStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
          dataRowMinHeight: 52,
          dataRowMaxHeight: 52,
          columnSpacing: 20,
          columns: [
            const DataColumn(label: Text('N° preventivo')),
            const DataColumn(label: Text('Data')),
            const DataColumn(label: Text('Committente')),
            const DataColumn(label: Text('Servizi')),
            const DataColumn(label: Text('Totale')),
            if (isAdmin) const DataColumn(label: Text('')),
          ],
          rows: lista
              .map((p) => _buildRigaTabella(p, isAdmin))
              .toList(),
        ),
      ),
    );
  }

  DataRow _buildRigaTabella(PreventivoModel p, bool isAdmin) {
    void apri() => context.push('/preventivo/${p.id}');
    return DataRow(cells: [
      DataCell(
        Row(children: [
          if (p.isDraft) ...[
            _buildBadgeBozza(),
            const SizedBox(width: 6),
          ],
          _buildBadgeNumero(p),
        ]),
        onTap: isAdmin ? apri : null,
      ),
      DataCell(
        Text(_dateFmt.format(p.data),
            style: const TextStyle(color: AppColors.textSecondary)),
        onTap: isAdmin ? apri : null,
      ),
      DataCell(
        Text(p.committente,
            style: const TextStyle(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis),
        onTap: isAdmin ? apri : null,
      ),
      DataCell(
        Text('${p.righe.length}',
            style: const TextStyle(color: AppColors.textSecondary)),
        onTap: isAdmin ? apri : null,
      ),
      DataCell(
        Text(
          p.totale > 0 ? _moneyFmt.format(p.totale) : '—',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        onTap: isAdmin ? apri : null,
      ),
      if (isAdmin)
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: apri,
              child: const Text('Apri'),
            ),
            const SizedBox(width: 4),
            _pdfInGenerazione == p.id
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        color: AppColors.primary, strokeWidth: 2))
                : IconButton(
                    icon: const Icon(Icons.picture_as_pdf_outlined,
                        color: AppColors.primary, size: 18),
                    tooltip: 'Anteprima PDF',
                    onPressed: () => _mostraAnteprima(p),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.error, size: 18),
              tooltip: 'Elimina',
              onPressed: () => _eliminaPreventivo(p),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        )),
    ]);
  }

  // ─── Widget condivisi ─────────────────────────────────────────────────────

  Widget _buildBarraRicercaConFiltro() {
    final filtriAttivi = _filtro.filtriAttivi;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _cercaController,
            onChanged: (v) =>
                setState(() => _queryRicerca = v.trim()),
            decoration: InputDecoration(
              hintText: 'Cerca per committente o numero...',
              prefixIcon: const Icon(Icons.search,
                  size: 20, color: AppColors.textDisabled),
              suffixIcon: _queryRicerca.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _cercaController.clear();
                        setState(() => _queryRicerca = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.inputBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: () =>
                  setState(() => _filtroAperto = !_filtroAperto),
              icon: Icon(
                _filtroAperto
                    ? Icons.filter_list_off
                    : Icons.filter_list,
                color: _filtroAperto || filtriAttivi > 0
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
              tooltip: 'Filtri',
            ),
            if (filtriAttivi > 0)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$filtriAttivi',
                      style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildBadgeNumero(PreventivoModel p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        p.numeroFormattato,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.info,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBadgeBozza() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.textSecondary.withValues(alpha: 0.35)),
      ),
      child: const Text(
        'Bozza',
        style: TextStyle(
          fontSize: 11,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildStatoVuoto() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.description_outlined,
              size: 64,
              color: AppColors.textDisabled.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            _queryRicerca.isEmpty && !_filtro.hasFiltri
                ? 'Nessun preventivo ancora'
                : 'Nessun risultato trovato',
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textDisabled,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Dialog anteprima PDF ─────────────────────────────────────────────────────

class _PdfPreviewDialog extends StatefulWidget {
  const _PdfPreviewDialog({
    required this.titolo,
    required this.nomeFile,
    required this.bytes,
  });

  final String titolo;
  final String nomeFile;
  final Uint8List bytes;

  @override
  State<_PdfPreviewDialog> createState() => _PdfPreviewDialogState();
}

class _PdfPreviewDialogState extends State<_PdfPreviewDialog> {
  @override
  void dispose() {
    if (kIsWeb) disposeWebPdfIframePreview();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            // Barra titolo
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
              decoration: const BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf_outlined,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.titolo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Chiudi',
                  ),
                ],
              ),
            ),
            // Anteprima
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(16)),
                child: kIsWeb
                    ? _buildWebPreview()
                    : PdfPreview(
                        build: (_) async => widget.bytes,
                        pdfFileName: widget.nomeFile,
                        allowPrinting: true,
                        allowSharing: true,
                        canChangeOrientation: false,
                        canChangePageFormat: false,
                        canDebug: false,
                        initialPageFormat: PdfPageFormat.a4,
                        maxPageWidth: 800,
                        actions: const [],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebPreview() {
    final webWidget = buildWebPdfIframePreview(widget.bytes);
    if (webWidget != null) return webWidget;
    return const Center(
      child: Text('Anteprima non disponibile su questo browser'),
    );
  }
}