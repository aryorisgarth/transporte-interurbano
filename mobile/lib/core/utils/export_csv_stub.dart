void exportarCsv(String filename, List<List<String>> rows) {}

String csvEscape(String value) {
  if (value.contains(',') || value.contains('"') || value.contains('\n')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

String rowsToCsv(List<List<String>> rows) {
  return rows.map((r) => r.map(csvEscape).join(',')).join('\n');
}
