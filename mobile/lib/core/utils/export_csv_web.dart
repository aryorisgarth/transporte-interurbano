import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'export_csv_stub.dart' show rowsToCsv;

void exportarCsv(String filename, List<List<String>> rows) {
  final content = rowsToCsv(rows);
  final bytes = utf8.encode(content);
  final blob = html.Blob([bytes], 'text/csv', 'native');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename.endsWith('.csv') ? filename : '$filename.csv')
    ..style.display = 'none';
  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(url);
}
