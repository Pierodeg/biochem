import 'dart:typed_data';
import 'dart:html' as html;

Future<void> downloadBytes({
  required Uint8List bytes,
  required String mimeType,
  required String fileName,
}) async {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = fileName
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}