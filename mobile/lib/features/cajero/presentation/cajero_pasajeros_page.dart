import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/transporte_api.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/models/venta.dart';
import '../../../core/utils/export_csv.dart';
import '../../../core/utils/formato.dart';
import '../../../shared/widgets/section_card.dart';
import 'cajero_shell.dart';

class CajeroPasajerosPage extends StatefulWidget {
  const CajeroPasajerosPage({super.key});

  @override
  State<CajeroPasajerosPage> createState() => _CajeroPasajerosPageState();
}

class _CajeroPasajerosPageState extends State<CajeroPasajerosPage> {
  final _api = TransporteApi();
  String _fecha = fechaHoyIso();
  List<ManifiestoPasajero> _filas = [];
  bool _loading = false;
  String? _error;

  Future<void> _cargar() async {
    final token = context.read<AuthProvider>().token;
    final perfil = CajeroScope.perfilOf(context);
    if (token == null || perfil?.empresaId == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _api.manifiestoPasajeros(token, fecha: _fecha, empresaId: perfil!.empresaId);
      if (!mounted) return;
      setState(() => _filas = data);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _filas = [];
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _exportarCsv() {
    exportarCsv('manifiesto-$_fecha.csv', [
      const [
        'Fecha',
        'Hora',
        'Ruta',
        'Bus',
        'Placa',
        'Asiento',
        'Pasajero',
        'Cédula',
        'Teléfono',
        'Código venta',
        'Operador',
      ],
      ..._filas.map(
        (p) => [
          p.fechaViaje,
          formatearHora(p.horaSalida),
          '${p.origen} → ${p.destino}',
          p.busNumeroInterno,
          p.busPlaca,
          '${p.numeroAsiento}',
          p.pasajeroNombre,
          p.pasajeroCedula,
          p.pasajeroTelefono ?? '',
          p.codigoVenta,
          p.operadorNombre,
        ],
      ),
    ]);
  }

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Manifiesto de pasajeros',
      subtitle: 'Boletos vendidos para la fecha seleccionada',
      actions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 140,
            child: TextFormField(
              decoration: const InputDecoration(labelText: 'Fecha', isDense: true),
              initialValue: _fecha,
              readOnly: true,
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.tryParse(_fecha) ?? DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 90)),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (picked != null) {
                  setState(() {
                    _fecha =
                        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                  });
                  _cargar();
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: _filas.isEmpty ? null : _exportarCsv,
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Excel (CSV)'),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_error!, style: TextStyle(color: Colors.red.shade800)),
            ),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (_filas.isEmpty)
            Text('No hay pasajeros registrados para esta fecha.', style: TextStyle(color: Colors.grey.shade600))
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Asiento')),
                  DataColumn(label: Text('Pasajero')),
                  DataColumn(label: Text('Cédula')),
                  DataColumn(label: Text('Viaje')),
                  DataColumn(label: Text('Bus')),
                  DataColumn(label: Text('Venta')),
                  DataColumn(label: Text('Estado')),
                ],
                rows: _filas
                    .map(
                      (p) => DataRow(
                        cells: [
                          DataCell(Text('${p.numeroAsiento}')),
                          DataCell(Text('${p.pasajeroNombre}${p.esMenor ? ' (menor)' : ''}')),
                          DataCell(Text(p.pasajeroCedula)),
                          DataCell(Text('${p.origen}→${p.destino} ${formatearHora(p.horaSalida)}')),
                          DataCell(Text('${p.busNumeroInterno} (${p.busPlaca})')),
                          DataCell(Text(p.codigoVenta)),
                          DataCell(Text(p.estadoBoleto)),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}
