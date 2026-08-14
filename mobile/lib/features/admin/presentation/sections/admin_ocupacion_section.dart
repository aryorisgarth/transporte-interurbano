import 'package:flutter/material.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/transporte_api.dart';
import '../../../../core/models/reporte.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formato.dart';
import '../../../../shared/widgets/section_card.dart';

Color _colorOcupacion(double pct) {
  if (pct >= 80) return AppColors.seatDisponible;
  if (pct >= 50) return AppColors.primary;
  return Colors.grey.shade400;
}

class AdminOcupacionSection extends StatefulWidget {
  const AdminOcupacionSection({
    super.key,
    required this.token,
    required this.empresaId,
    required this.esGlobal,
  });

  final String token;
  final int empresaId;
  final bool esGlobal;

  @override
  State<AdminOcupacionSection> createState() => _AdminOcupacionSectionState();
}

class _AdminOcupacionSectionState extends State<AdminOcupacionSection> {
  final _api = TransporteApi();
  String _fecha = fechaHoyIso();
  List<OcupacionViaje> _filas = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.reporteOcupacion(
        widget.token,
        _fecha,
        empresaId: widget.esGlobal ? widget.empresaId : null,
      );
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

  @override
  Widget build(BuildContext context) {
    final totalVendidos = _filas.fold<int>(0, (s, f) => s + f.asientosVendidos);
    final totalCap = _filas.fold<int>(0, (s, f) => s + f.capacidadTotal);
    final ocupacionGlobal = totalCap > 0
        ? ((_filas.fold<int>(0, (s, f) => s + f.asientosVendidos + f.asientosReservados) / totalCap) * 100).round()
        : 0;

    return SectionCard(
      title: 'Ocupación por viaje',
      subtitle: 'Asientos vendidos y reservados según la fecha del viaje',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(
                width: 160,
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.tryParse(_fecha) ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (picked != null) {
                      setState(() => _fecha = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
                      _cargar();
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Fecha', isDense: true),
                    child: Text(formatearFechaCorta(_fecha)),
                  ),
                ),
              ),
              if (_filas.isNotEmpty) ...[
                const Spacer(),
                Text(
                  '${_filas.length} viaje(s) · $totalVendidos vendidos · ocupación media $ocupacionGlobal%',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator(color: AppColors.primary))
          else if (_error != null)
            Text(_error!, style: TextStyle(color: Colors.red.shade800))
          else if (_filas.isEmpty)
            Text('No hay viajes para la fecha seleccionada.', style: TextStyle(color: Colors.grey.shade600))
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Hora')),
                  DataColumn(label: Text('Ruta')),
                  DataColumn(label: Text('Bus')),
                  DataColumn(label: Text('Vendidos')),
                  DataColumn(label: Text('Reservados')),
                  DataColumn(label: Text('Libres')),
                  DataColumn(label: Text('Ocupación')),
                ],
                rows: _filas.map((f) {
                  final pct = f.porcentajeOcupacion.clamp(0.0, 100.0);
                  final color = _colorOcupacion(pct);
                  return DataRow(
                    cells: [
                      DataCell(Text(formatearHora(f.horaSalida))),
                      DataCell(Text('${f.origen} → ${f.destino}')),
                      DataCell(Text('${f.busNumeroInterno} (${f.busPlaca})')),
                      DataCell(Text('${f.asientosVendidos}')),
                      DataCell(Text('${f.asientosReservados}')),
                      DataCell(Text('${f.asientosDisponibles}')),
                      DataCell(
                        SizedBox(
                          width: 180,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: pct / 100,
                                        minHeight: 8,
                                        backgroundColor: Colors.grey.shade200,
                                        color: color,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text('${pct.round()}%', style: const TextStyle(fontWeight: FontWeight.w600)),
                                ],
                              ),
                              Text(
                                '${f.asientosVendidos + f.asientosReservados}/${f.capacidadTotal}',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
