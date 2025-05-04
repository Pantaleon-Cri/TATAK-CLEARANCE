import 'dart:html' as html;
import 'dart:typed_data';

Future<void> saveFile(Uint8List fileBytes, String fileName) async {
  final blob = html.Blob([fileBytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}
