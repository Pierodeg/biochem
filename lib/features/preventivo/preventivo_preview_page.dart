import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../../core/constants/app_colors.dart';
import '../../../utils/web_pdf_preview.dart';
import '../../../utils/web_download.dart';

class PreventivoPreviewPage extends StatefulWidget {
  final Future<Uint8List> Function() buildPdf;
  final String nomeFile;

  const PreventivoPreviewPage({
    super.key,
    required this.buildPdf,
    required this.nomeFile,
  });

  @override
  State<PreventivoPreviewPage> createState() => _PreventivoPreviewPageState();
}

class _PreventivoPreviewPageState extends State<PreventivoPreviewPage> {
  Uint8List? _bytes;
  bool _loading = true;
  String? _errore;

  @override
  void initState() {
    super.initState();
    _caricaPdf();
  }

  @override
  void dispose() {
    if (kIsWeb) disposeWebPdfIframePreview();
    super.dispose();
  }

  Future<void> _caricaPdf() async {
    try {
      final bytes = await widget.buildPdf();
      if (mounted) setState(() { _bytes = bytes; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _errore = e.toString(); _loading = false; });
    }
  }

  Future<void> _scarica() async {
    if (_bytes == null) return;
    if (kIsWeb) {
      await downloadBytes(
        bytes: _bytes!,
        mimeType: 'application/pdf',
        fileName: widget.nomeFile,
      );
    } else {
      await Printing.sharePdf(
        bytes: _bytes!,
        filename: widget.nomeFile,
      );
    }
  }

  Future<void> _stampa() async {
    if (_bytes == null) return;
    await Printing.layoutPdf(
      onLayout: (_) async => _bytes!,
      name: widget.nomeFile,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.nomeFile),
        actions: [
          if (!_loading && _errore == null) ...[
            IconButton(
              icon: const Icon(Icons.print_outlined),
              tooltip: 'Stampa',
              onPressed: _stampa,
            ),
            IconButton(
              icon: const Icon(Icons.download_outlined),
              tooltip: 'Scarica PDF',
              onPressed: _scarica,
            ),
          ],
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _errore != null
              ? Center(child: Text('Errore: $_errore', style: const TextStyle(color: AppColors.error)))
              : _buildPreview(),
    );
  }

  Widget _buildPreview() {
    if (kIsWeb) {
      final webWidget = buildWebPdfIframePreview(_bytes);
      if (webWidget != null) return webWidget;
      return const Center(child: Text('Anteprima non disponibile su questo browser'));
    }

    final preview = PdfPreview(
      build: (_) async => _bytes!,
      canChangePageFormat: false,
      canChangeOrientation: false,
      canDebug: false,
      pdfFileName: widget.nomeFile,
    );

    final isMobile = defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    if (!isMobile) return preview;

    return InteractiveViewer(
      minScale: 1,
      maxScale: 4,
      child: preview,
    );
  }
}
