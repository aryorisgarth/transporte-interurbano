import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/models/venta.dart';
import '../../../core/utils/formato.dart';

class ViajeComprobanteInfo {
  const ViajeComprobanteInfo({
    required this.origen,
    required this.destino,
    required this.fecha,
    required this.hora,
    required this.empresa,
  });

  final String origen;
  final String destino;
  final String fecha;
  final String hora;
  final String empresa;
}

class ComprobanteVentaDialog extends StatelessWidget {
  const ComprobanteVentaDialog({
    super.key,
    required this.venta,
    this.viajeInfo,
  });

  final VentaResponse venta;
  final ViajeComprobanteInfo? viajeInfo;

  static Future<void> show(
    BuildContext context, {
    required VentaResponse venta,
    ViajeComprobanteInfo? viajeInfo,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => ComprobanteVentaDialog(venta: venta, viajeInfo: viajeInfo),
    );
  }

  Future<void> _descargarPdf() async {
    final doc = pw.Document();
    final empresa = viajeInfo?.empresa ?? 'Transporte Interurbano';

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (context) {
          final lineas = <String>[
            'Código: ${venta.codigo}',
            if (viajeInfo != null) ...[
              'Viaje: ${viajeInfo!.origen} → ${viajeInfo!.destino}',
              'Fecha: ${viajeInfo!.fecha} ${viajeInfo!.hora}',
            ],
            'Comprador: ${venta.compradorNombre}',
            'Cédula: ${venta.compradorCedula}',
            'Asientos: ${venta.numerosAsiento.join(', ')}',
            '',
            'Boletos: ${formatearCordobas(venta.subtotalBoletos)}',
            if (venta.subtotalEquipaje > 0)
              'Equipaje extra: ${formatearCordobas(venta.subtotalEquipaje)}',
            'Total: ${formatearCordobas(venta.total)}',
          ];

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(empresa, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 6),
              pw.Center(child: pw.Text('Bluefields – Managua', style: const pw.TextStyle(fontSize: 10))),
              pw.SizedBox(height: 8),
              pw.Divider(),
              pw.SizedBox(height: 8),
              for (final linea in lineas)
                if (linea.isEmpty)
                  pw.SizedBox(height: 4)
                else
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Text(linea, style: const pw.TextStyle(fontSize: 10)),
                  ),
              pw.SizedBox(height: 8),
              pw.Text(
                '1 equipaje incluido por boleto. Presente este comprobante en terminal.',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
              ),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'comprobante-${venta.codigo}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Comprobante de venta'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              viajeInfo?.empresa ?? 'Transporte Interurbano',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            Text(
              'Bluefields – Managua',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const Divider(height: 24),
            _Linea(label: 'Código', value: venta.codigo),
            if (viajeInfo != null)
              _Linea(
                label: 'Viaje',
                value: '${viajeInfo!.origen} → ${viajeInfo!.destino} · ${viajeInfo!.fecha} ${viajeInfo!.hora}',
              ),
            _Linea(label: 'Comprador', value: venta.compradorNombre),
            _Linea(label: 'Cédula', value: venta.compradorCedula),
            _Linea(label: 'Asientos', value: venta.numerosAsiento.join(', ')),
            const Divider(height: 24),
            Text('Boletos: ${formatearCordobas(venta.subtotalBoletos)}'),
            if (venta.subtotalEquipaje > 0)
              Text('Equipaje extra: ${formatearCordobas(venta.subtotalEquipaje)}'),
            Text(
              'Total: ${formatearCordobas(venta.total)}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            const SizedBox(height: 12),
            Text(
              '1 equipaje incluido por boleto. Presente este comprobante en terminal.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
        OutlinedButton.icon(
          onPressed: _descargarPdf,
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('Descargar PDF'),
        ),
      ],
    );
  }
}

class _Linea extends StatelessWidget {
  const _Linea({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
