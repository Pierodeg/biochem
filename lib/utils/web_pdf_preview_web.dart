import 'dart:typed_data';
import 'dart:ui_web' as ui_web;
import 'package:flutter/widgets.dart';
import 'package:universal_html/html.dart' as html;

const String _kDesktopLabelPdfViewType = 'biochem-pdf-iframe-view';

final html.IFrameElement _iframeElement = html.IFrameElement()
  ..style.border = '0'
  ..style.width = '100%'
  ..style.height = '100%';

bool _viewRegistered = false;
String? _currentObjectUrl;

Widget? buildWebPdfIframePreview(Uint8List? bytes) {
  if (bytes == null) return const SizedBox.shrink();

  if (!_viewRegistered) {
    ui_web.platformViewRegistry.registerViewFactory(
      _kDesktopLabelPdfViewType,
      (int _) => _iframeElement,
    );
    _viewRegistered = true;
  }

  final blob = html.Blob([bytes], 'application/pdf');
  final nextUrl = html.Url.createObjectUrlFromBlob(blob);
  _iframeElement.src = '$nextUrl#toolbar=0&navpanes=0&scrollbar=0';

  final previousUrl = _currentObjectUrl;
  _currentObjectUrl = nextUrl;
  if (previousUrl != null) html.Url.revokeObjectUrl(previousUrl);

  return const HtmlElementView(viewType: _kDesktopLabelPdfViewType);
}

void disposeWebPdfIframePreview() {
  final currentUrl = _currentObjectUrl;
  _currentObjectUrl = null;
  if (currentUrl != null) html.Url.revokeObjectUrl(currentUrl);
}