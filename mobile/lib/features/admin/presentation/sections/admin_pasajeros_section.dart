import 'package:flutter/material.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/transporte_api.dart';
import '../../../../core/models/bus.dart';
import '../../../../core/models/venta.dart';
import '../../../../core/models/viaje.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/export_csv.dart';
import '../../../../core/utils/formato.dart';
import '../../../../shared/widgets/section_card.dart';

class AdminPasajerosSection extends StatefulWidget {
  const AdminPasajerosSection({
    super.key,
    required this.token,
    required this.empresaId,
    this.esGlobal = false,
  });

  final String token;
  final int empresaId;
  final bool esGlobal;

  @override
  State<AdminPasajerosSection> createState() => _AdminPasajerosSectionState();
}

class _AdminPasajerosSectionState extends State<AdminPasajerosSection> {
  final _api = TransporteApi();
  String _fecha = fechaHoyIso();
  int? _viajeId;
  int? _busId;
  List<ViajeOperador> _viajes = [];
  List<Bus> _buses = [];
  List<ManifiestoPasajero> _filas = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarFiltros();
    _cargar();
  }

  Future<void> _cargarFiltros() async {
    try {
      final viajes = widget.esGlobal
          ? await _api.viajesPorEmpresa(widget.token, widget.empresaId, _fecha)
          : await _api.viajesMiEmpresa(widget.token, _fecha);
      final buses = widget.esGlobal
          ? await _api.busesPorEmpresa(widget.token, widget.empresaId)
          : await _api.busesMiEmpresa(widget.token);
      if (!mounted) return;
      setState(() {
        _viajes = viajes;
        _buses = buses;
      });
    } on ApiException {
      if (!mounted) return;
      setState(() {
        _viajes = [];
        _buses = [];
      });
    }
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.manifiestoPasajeros(
        widget.token,
        fecha: _fecha,
        empresaId: widget.esGlobal ? widget.empresaId : null,
        viajeId: _viajeId,
        busId: _busId,
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

  Future<void> _onFechaChange(String fecha) async {
    setState(() {
      _fecha = fecha;
      _viajeId = null;
    });
    await _cargarFiltros();
    await _cargar();
  }

  void _exportCsv() {
    exportarCsv('manifiesto-$_fecha.csv', [
      ['Fecha', 'Hora', 'Ruta', 'Bus', 'Placa', 'Asiento', 'Pasajero', 'Cédula', 'Teléfono', 'Código venta', 'Operador'],
      ..._filas.map((p) => [
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
          ]),
    ]);
  }

  void _mostrarHintImpresion() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.print_outlined, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Imprimir manifiesto'),
          ],
        ),
        content: const Text(
          'En la versión web use Ctrl+P (o Cmd+P en Mac) para imprimir o guardar como PDF.\n\n'
          'También puede exportar a CSV y abrirlo en Excel para imprimir desde allí.',
        ),
        actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Entendido'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Manifiesto de pasajeros',
      subtitle: 'Una fila por boleto/asiento',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              Widget fechaField() => InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.tryParse(_fecha) ?? DateTime.now(),
                        firstDate: DateTime.now().subtract(const Duration(days: 90)),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) {
                        await _onFechaChange(
                          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}',
                        );
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        hintText: 'Fecha',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        formatearFechaCorta(_fecha),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );

              Widget viajeField() {
                final labels = [
                  'Todos',
                  ..._viajes.map((v) => '${formatearHora(v.horaSalida)} · Bus ${v.busNumeroInterno}'),
                ];
                return ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 180),
                  child: DropdownButtonFormField<int?>(
                    value: _viajeId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      hintText: 'Viaje',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    selectedItemBuilder: (context) => labels
                        .map(
                          (label) => Text(
                            label,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            softWrap: false,
                          ),
                        )
                        .toList(),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todos')),
                      ..._viajes.map(
                        (v) => DropdownMenuItem(
                          value: v.id,
                          child: Text(
                            '${formatearHora(v.horaSalida)} · Bus ${v.busNumeroInterno}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() => _viajeId = v);
                      _cargar();
                    },
                  ),
                );
              }

              Widget busField() {
                final labels = [
                  'Todos',
                  ..._buses.map((b) => '${b.numeroInterno} (${b.placa})'),
                ];
                return ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 160),
                  child: DropdownButtonFormField<int?>(
                    value: _busId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      hintText: 'Bus',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    selectedItemBuilder: (context) => labels
                        .map(
                          (label) => Text(
                            label,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            softWrap: false,
                          ),
                        )
                        .toList(),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todos')),
                      ..._buses.map(
                        (b) => DropdownMenuItem(
                          value: b.id,
                          child: Text(
                            '${b.numeroInterno} (${b.placa})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() => _busId = v);
                      _cargar();
                    },
                  ),
                );
              }

              final actions = Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _filas.isEmpty ? null : _exportCsv,
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Excel (CSV)'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _filas.isEmpty ? null : _mostrarHintImpresion,
                    icon: const Icon(Icons.print, size: 18),
                    label: const Text('PDF / Imprimir'),
                  ),
                ],
              );

              final filters = constraints.maxWidth >= 768
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: fechaField()),
                        const SizedBox(width: 12),
                        Expanded(flex: 2, child: viajeField()),
                        const SizedBox(width: 12),
                        Expanded(child: busField()),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        fechaField(),
                        const SizedBox(height: 12),
                        viajeField(),
                        const SizedBox(height: 12),
                        busField(),
                      ],
                    );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  filters,
                  const SizedBox(height: 12),
                  actions,
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Text('Pasajeros (${_filas.length})', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          if (_loading)
            const Center(child: CircularProgressIndicator(color: AppColors.primary))
          else if (_error != null)
            Text(_error!, style: TextStyle(color: Colors.red.shade800))
          else if (_filas.isEmpty)
            Text('No hay pasajeros para los filtros seleccionados.', style: TextStyle(color: Colors.grey.shade600))
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Hora')),
                  DataColumn(label: Text('Ruta')),
                  DataColumn(label: Text('Bus')),
                  DataColumn(label: Text('Asiento')),
                  DataColumn(label: Text('Pasajero')),
                  DataColumn(label: Text('Cédula')),
                  DataColumn(label: Text('Menor')),
                  DataColumn(label: Text('Teléfono')),
                  DataColumn(label: Text('Estado')),
                  DataColumn(label: Text('Venta')),
                ],
                rows: _filas
                    .map(
                      (p) => DataRow(
                        cells: [
                          DataCell(Text(formatearHora(p.horaSalida))),
                          DataCell(Text('${p.origen} → ${p.destino}')),
                          DataCell(Text('${p.busNumeroInterno} (${p.busPlaca})')),
                          DataCell(Text('${p.numeroAsiento}')),
                          DataCell(Text(p.pasajeroNombre)),
                          DataCell(Text(p.pasajeroCedula)),
                          DataCell(Text(p.esMenor ? 'Sí' : '—')),
                          DataCell(Text(p.pasajeroTelefono ?? '—')),
                          DataCell(Text(p.estadoBoleto == 'RESERVA_EXCEPCIONAL' ? 'Reserva' : 'Vendido')),
                          DataCell(Text(p.codigoVenta)),
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
