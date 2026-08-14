import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/transporte_api.dart';
import '../../../../core/models/reporte.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/export_csv.dart';
import '../../../../core/utils/formato.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../../../shared/widgets/stat_card.dart';

String _formatearFechaHora(String iso) {
  if (iso.isEmpty) return '—';
  final d = DateTime.tryParse(iso);
  if (d == null) return iso;
  final hora = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  return '${DateFormat('dd/MM/yyyy').format(d)} ${formatearHora(hora)}';
}

class AdminIngresosSection extends StatefulWidget {
  const AdminIngresosSection({
    super.key,
    required this.token,
    required this.empresaId,
    required this.esGlobal,
  });

  final String token;
  final int empresaId;
  final bool esGlobal;

  @override
  State<AdminIngresosSection> createState() => _AdminIngresosSectionState();
}

class _AdminIngresosSectionState extends State<AdminIngresosSection> with SingleTickerProviderStateMixin {
  final _api = TransporteApi();
  late TabController _tabCtrl;
  String _desde = fechaHoyIso();
  String _hasta = fechaHoyIso();
  String _preset = 'hoy';
  IngresosReporte? _reporte;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 5, vsync: this);
    _cargar();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.reporteIngresos(
        widget.token,
        _desde,
        _hasta,
        empresaId: widget.esGlobal ? widget.empresaId : null,
      );
      if (!mounted) return;
      setState(() => _reporte = data);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _reporte = null;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _aplicarPreset(String preset) {
    final hoy = DateTime.now();
    final hasta = fechaHoyIso();
    final d = switch (preset) {
      '7d' => hoy.subtract(const Duration(days: 6)),
      '30d' => hoy.subtract(const Duration(days: 29)),
      _ => hoy,
    };
    final desde = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    setState(() {
      _preset = preset;
      _desde = desde;
      _hasta = hasta;
    });
    _cargar();
  }

  Future<void> _pickDate(bool desde) async {
    final current = DateTime.tryParse(desde ? _desde : _hasta) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    final iso = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    setState(() {
      _preset = 'custom';
      if (desde) {
        _desde = iso;
      } else {
        _hasta = iso;
      }
    });
    _cargar();
  }

  void _exportarVentas() {
    if (_reporte == null) return;
    exportarCsv('ingresos-${_reporte!.desde}-${_reporte!.hasta}.csv', [
      [
        'Código',
        'Fecha venta',
        'Viaje',
        'Fecha viaje',
        'Hora',
        'Cajero',
        'Terminal cajero',
        'Boletos',
        'Subtotal boletos',
        'Equipaje',
        'Total',
      ],
      ..._reporte!.ventas.map((v) => [
            '${v['codigo'] ?? ''}',
            _formatearFechaHora('${v['fechaVenta'] ?? ''}'),
            '${v['origen'] ?? ''} → ${v['destino'] ?? ''}',
            '${v['fechaViaje'] ?? ''}',
            formatearHora('${v['horaSalida'] ?? ''}'),
            '${v['operadorNombre'] ?? ''}',
            '${v['operadorSede'] ?? ''}',
            '${v['cantidadBoletos'] ?? ''}',
            '${v['subtotalBoletos'] ?? ''}',
            '${v['subtotalEquipaje'] ?? ''}',
            '${v['total'] ?? ''}',
          ]),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final resumen = _reporte?.resumen ?? {};
    final totalIngresos = (resumen['totalIngresos'] as num?)?.toDouble() ?? 0;
    final subtotalBoletos = (resumen['subtotalBoletos'] as num?)?.toDouble() ?? 0;
    final subtotalEquipaje = (resumen['subtotalEquipaje'] as num?)?.toDouble() ?? 0;
    final cantidadVentas = (resumen['cantidadVentas'] as num?)?.toInt() ?? 0;
    final cantidadBoletos = (resumen['cantidadBoletos'] as num?)?.toInt() ?? 0;
    final ticketPromedio = (resumen['ticketPromedio'] as num?)?.toDouble() ?? 0;
    final pctBoletos = totalIngresos > 0 ? ((subtotalBoletos / totalIngresos) * 100).round() : 0;
    final sinDatos = !_loading && _reporte != null && cantidadVentas == 0;

    return SectionCard(
      title: 'Ingresos por ventas',
      subtitle: 'Ventas completadas agrupadas por fecha del viaje',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'hoy', label: Text('Hoy')),
                  ButtonSegment(value: '7d', label: Text('7 días')),
                  ButtonSegment(value: '30d', label: Text('30 días')),
                ],
                selected: {_preset == 'custom' ? 'hoy' : _preset},
                onSelectionChanged: (s) => _aplicarPreset(s.first),
              ),
              OutlinedButton(onPressed: () => _pickDate(true), child: Text('Desde ${formatearFechaCorta(_desde)}')),
              OutlinedButton(onPressed: () => _pickDate(false), child: Text('Hasta ${formatearFechaCorta(_hasta)}')),
              if (_reporte != null && _reporte!.ventas.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: _exportarVentas,
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Exportar CSV'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
              child: Text(_error!, style: TextStyle(color: Colors.red.shade800)),
            ),
          if (_loading)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
          else if (_reporte != null) ...[
            LayoutBuilder(
              builder: (context, c) {
                final cols = c.maxWidth > 900 ? 4 : (c.maxWidth > 500 ? 2 : 1);
                return GridView.count(
                  crossAxisCount: cols,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: cols == 1 ? 3.2 : 2.4,
                  children: [
                    StatCard(
                      compact: true,
                      label: 'Ingresos totales',
                      value: formatearCordobas(totalIngresos),
                      icon: Icons.account_balance_wallet,
                      accent: AppColors.primary,
                    ),
                    StatCard(
                      compact: true,
                      label: 'Boletos',
                      value: formatearCordobas(subtotalBoletos),
                      icon: Icons.confirmation_number,
                      accent: AppColors.secondary,
                    ),
                    StatCard(
                      compact: true,
                      label: 'Equipaje extra',
                      value: formatearCordobas(subtotalEquipaje),
                      icon: Icons.luggage,
                      accent: const Color(0xFF7C3AED),
                    ),
                    StatCard(
                      compact: true,
                      label: 'Ventas / ticket prom.',
                      value: '$cantidadVentas · ${formatearCordobas(ticketPromedio)}',
                      icon: Icons.point_of_sale,
                      accent: AppColors.seatDisponible,
                      hint: '$cantidadBoletos boletos',
                    ),
                  ],
                );
              },
            ),
            if (totalIngresos > 0) ...[
              const SizedBox(height: 16),
              Text('Composición del ingreso', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pctBoletos / 100,
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade200,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('$pctBoletos% boletos', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                ],
              ),
              Text('$cantidadBoletos boletos vendidos en el período', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
            const SizedBox(height: 20),
            if (sinDatos)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                child: const Text('No hay ventas completadas en el período seleccionado.'),
              )
            else ...[
              TabBar(
                controller: _tabCtrl,
                isScrollable: true,
                labelColor: AppColors.primary,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(text: 'Por día'),
                  Tab(text: 'Por viaje'),
                  Tab(text: 'Por cajero'),
                  Tab(text: 'Por terminal'),
                  Tab(text: 'Detalle ventas'),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 360,
                child: TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _tablaPorDia(_reporte!.porDia),
                    _tablaPorViaje(_reporte!.porViaje),
                    _tablaPorCajero(_reporte!.porCajero),
                    _tablaPorTerminal(_reporte!.porTerminal),
                    _tablaVentas(_reporte!.ventas),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _tablaPorDia(List<Map<String, dynamic>> filas) {
    return _scrollTable(
      columns: const ['Fecha', 'Ventas', 'Boletos', 'Boletos C\$', 'Equipaje C\$', 'Total C\$'],
      rows: filas.map((f) => [
            formatearFechaCorta('${f['fecha']}'),
            '${f['cantidadVentas'] ?? 0}',
            '${f['cantidadBoletos'] ?? 0}',
            formatearCordobas((f['subtotalBoletos'] as num?)?.toDouble() ?? 0),
            formatearCordobas((f['subtotalEquipaje'] as num?)?.toDouble() ?? 0),
            formatearCordobas((f['totalIngresos'] as num?)?.toDouble() ?? 0),
          ]),
    );
  }

  Widget _tablaPorViaje(List<Map<String, dynamic>> filas) {
    return _scrollTable(
      columns: const ['Fecha', 'Hora', 'Ruta', 'Bus', 'Ventas', 'Total C\$'],
      rows: filas.map((f) => [
            formatearFechaCorta('${f['fecha']}'),
            formatearHora('${f['horaSalida']}'),
            '${f['origen']} → ${f['destino']}',
            '${f['busNumeroInterno']}',
            '${f['cantidadVentas'] ?? 0}',
            formatearCordobas((f['totalIngresos'] as num?)?.toDouble() ?? 0),
          ]),
    );
  }

  Widget _tablaPorCajero(List<Map<String, dynamic>> filas) {
    return _scrollTable(
      columns: const ['Cajero', 'Terminal', 'Ventas', 'Boletos', 'Total C\$'],
      rows: filas.map((f) => [
            '${f['operadorNombre'] ?? f['cajeroNombre'] ?? '—'}',
            '${f['sede'] ?? ''}',
            '${f['cantidadVentas'] ?? 0}',
            '${f['cantidadBoletos'] ?? 0}',
            formatearCordobas((f['totalIngresos'] as num?)?.toDouble() ?? 0),
          ]),
    );
  }

  Widget _tablaPorTerminal(List<Map<String, dynamic>> filas) {
    return _scrollTable(
      columns: const ['Terminal de salida', 'Ventas', 'Boletos', 'Total C\$'],
      rows: filas.map((f) => [
            '${f['terminal']}',
            '${f['cantidadVentas'] ?? 0}',
            '${f['cantidadBoletos'] ?? 0}',
            formatearCordobas((f['totalIngresos'] as num?)?.toDouble() ?? 0),
          ]),
    );
  }

  Widget _tablaVentas(List<Map<String, dynamic>> ventas) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: ventas.isEmpty ? null : _exportarVentas,
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Exportar CSV'),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _scrollTable(
            columns: const ['Código', 'Fecha venta', 'Viaje', 'Cajero', 'Boletos', 'Total C\$'],
            rows: ventas.map((v) => [
                  '${v['codigo']}',
                  _formatearFechaHora('${v['fechaVenta']}'),
                  '${formatearFechaCorta('${v['fechaViaje']}')} ${formatearHora('${v['horaSalida']}')} · ${v['origen']}→${v['destino']}',
                  '${v['operadorNombre']}',
                  '${v['cantidadBoletos']}',
                  formatearCordobas((v['total'] as num?)?.toDouble() ?? 0),
                ]),
          ),
        ),
      ],
    );
  }

  Widget _scrollTable({required List<String> columns, required Iterable<List<String>> rows}) {
    final rowList = rows.toList();
    if (rowList.isEmpty) {
      return Center(child: Text('Sin datos.', style: TextStyle(color: Colors.grey.shade600)));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: columns.map((c) => DataColumn(label: Text(c))).toList(),
        rows: rowList.map((cells) => DataRow(cells: cells.map((c) => DataCell(Text(c))).toList())).toList(),
      ),
    );
  }
}
