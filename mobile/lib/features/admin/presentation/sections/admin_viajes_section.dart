import 'package:flutter/material.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/transporte_api.dart';
import '../../../../core/models/bus.dart';
import '../../../../core/models/viaje.dart';
import '../../../../core/utils/corredor.dart';
import '../../../../core/utils/formato.dart';
import '../../../../shared/widgets/hora_salida_field.dart';
import '../../../../shared/widgets/section_card.dart';

class AdminViajesSection extends StatefulWidget {
  const AdminViajesSection({
    super.key,
    required this.token,
    required this.empresaId,
    required this.buses,
    required this.viajes,
    required this.fechaViajes,
    required this.filtroOrigen,
    required this.onFechaChange,
    required this.onFiltroOrigenChange,
    required this.onActualizado,
    required this.onMsg,
  });

  final String token;
  final int empresaId;
  final List<Bus> buses;
  final List<ViajeOperador> viajes;
  final String fechaViajes;
  final String filtroOrigen;
  final ValueChanged<String> onFechaChange;
  final ValueChanged<String> onFiltroOrigenChange;
  final VoidCallback onActualizado;
  final void Function(String text, {bool error}) onMsg;

  @override
  State<AdminViajesSection> createState() => _AdminViajesSectionState();
}

class _AdminViajesSectionState extends State<AdminViajesSection> {
  final _api = TransporteApi();
  String _origen = ciudadesCorredor.first;
  String _destino = ciudadesCorredor.last;
  int? _busId;
  HoraSalidaNicaragua _hora = HoraSalidaNicaragua.inicial;
  String _fecha = fechaHoyIso();
  double _tarifa = 350;

  @override
  void initState() {
    super.initState();
    _fecha = widget.fechaViajes;
    _syncBus();
  }

  @override
  void didUpdateWidget(covariant AdminViajesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.buses != widget.buses) _syncBus();
  }

  void _syncBus() {
    final enOrigen = widget.buses.where((b) => b.sede == _origen).toList();
    if (enOrigen.isEmpty) {
      _busId = null;
    } else if (_busId == null || !enOrigen.any((b) => b.id == _busId)) {
      _busId = enOrigen.first.id;
    }
  }

  Future<void> _programar() async {
    if (_origen == _destino) {
      widget.onMsg('Origen y destino deben ser distintos.', error: true);
      return;
    }
    if (_busId == null) {
      widget.onMsg('Seleccione un bus con sede en $_origen.', error: true);
      return;
    }
    try {
      await _api.programarViaje(widget.token, {
        'empresaId': widget.empresaId,
        'busId': _busId,
        'origen': _origen,
        'destino': _destino,
        'fecha': _fecha,
        'horaSalida': _hora.toBackend(),
        'tarifa': _tarifa,
      });
      widget.onMsg('Viaje programado');
      widget.onActualizado();
    } on ApiException catch (e) {
      widget.onMsg(e.message, error: true);
    }
  }

  Future<void> _abrirEditar(ViajeOperador v) async {
    final tarifaCtrl = TextEditingController(text: '${v.tarifa.toInt()}');
    final obsCtrl = TextEditingController();
    var horaEdit = HoraSalidaNicaragua.desdeBackend(v.horaSalida);
    var guardando = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Text('Editar viaje ${v.origen} → ${v.destino}'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Origen, destino, fecha y bus no se cambian. Si hay ventas, la hora tampoco.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),
                HoraSalidaField(
                  value: horaEdit,
                  onChanged: (h) => setDlg(() => horaEdit = h),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: tarifaCtrl,
                  decoration: const InputDecoration(labelText: 'Tarifa C\$'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: obsCtrl,
                  decoration: const InputDecoration(labelText: 'Observaciones'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: guardando ? null : () => Navigator.pop(ctx), child: const Text('Cerrar')),
            FilledButton(
              onPressed: guardando
                  ? null
                  : () async {
                      final tarifa = double.tryParse(tarifaCtrl.text) ?? -1;
                      if (tarifa < 0) {
                        widget.onMsg('La tarifa no puede ser negativa (RN V2).', error: true);
                        return;
                      }
                      setDlg(() => guardando = true);
                      try {
                        await _api.actualizarViaje(widget.token, v.id, {
                          'horaSalida': horaEdit.toBackend(),
                          'tarifa': tarifa,
                          if (obsCtrl.text.trim().isNotEmpty) 'observaciones': obsCtrl.text.trim(),
                        });
                        widget.onMsg('Viaje actualizado');
                        widget.onActualizado();
                        if (ctx.mounted) Navigator.pop(ctx);
                      } on ApiException catch (e) {
                        widget.onMsg(e.message, error: true);
                        setDlg(() => guardando = false);
                      }
                    },
              child: Text(guardando ? 'Guardando…' : 'Guardar'),
            ),
          ],
        ),
      ),
    );
    tarifaCtrl.dispose();
    obsCtrl.dispose();
  }

  Future<void> _confirmarCancelar(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar viaje'),
        content: const Text(
          'Cancela el viaje (baja lógica). No se borra el registro. Solo si no hay boletos vendidos o reservas activas.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar viaje'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _api.cancelarViaje(widget.token, id);
      widget.onMsg('Viaje cancelado (RN V5 — no permite nuevas ventas)');
      widget.onActualizado();
    } on ApiException catch (e) {
      widget.onMsg(e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busesEnOrigen = widget.buses.where((b) => b.sede == _origen).toList();

    return LayoutBuilder(
      builder: (context, c) {
        final row = c.maxWidth > 800;
        return row
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _form(busesEnOrigen)),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: _lista()),
                ],
              )
            : Column(children: [_form(busesEnOrigen), const SizedBox(height: 16), _lista()]);
      },
    );
  }

  Widget _form(List<Bus> busesEnOrigen) {
    return SectionCard(
      title: 'Programar viaje',
      subtitle: 'Salidas Bluefields ↔ Managua',
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: _origen,
            decoration: const InputDecoration(labelText: 'Origen'),
            items: ciudadesCorredor.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() {
              _origen = v ?? _origen;
              _destino = destinoOpuesto(_origen);
              _syncBus();
            }),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _destino,
            decoration: const InputDecoration(labelText: 'Destino'),
            items: ciudadesCorredor.where((c) => c != _origen).map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _destino = v ?? _destino),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: _busId,
            decoration: InputDecoration(
              labelText: 'Bus (sede origen)',
              helperText: busesEnOrigen.isEmpty ? 'No hay buses en $_origen' : null,
            ),
            items: busesEnOrigen.map((b) => DropdownMenuItem(value: b.id, child: Text('${b.numeroInterno} (${b.placa})'))).toList(),
            onChanged: busesEnOrigen.isEmpty ? null : (v) => setState(() => _busId = v),
          ),
          const SizedBox(height: 12),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Fecha'),
            initialValue: _fecha,
            readOnly: true,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.tryParse(_fecha) ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) setState(() => _fecha = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
            },
          ),
          const SizedBox(height: 12),
          HoraSalidaField(
            value: _hora,
            onChanged: (h) => setState(() => _hora = h),
          ),
          const SizedBox(height: 12),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Tarifa C\$'),
            keyboardType: TextInputType.number,
            initialValue: '$_tarifa',
            onChanged: (v) => _tarifa = double.tryParse(v) ?? _tarifa,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busId == null ? null : _programar,
            icon: const Icon(Icons.add),
            label: const Text('Programar'),
          ),
        ],
      ),
    );
  }

  Widget _lista() {
    return SectionCard(
      title: 'Viajes programados',
      subtitle: 'Filtre por fecha y terminal de salida',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            children: [
              SizedBox(
                width: 160,
                child: DropdownButtonFormField<String>(
                  value: widget.filtroOrigen.isEmpty ? '' : widget.filtroOrigen,
                  decoration: const InputDecoration(labelText: 'Salidas desde', isDense: true),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('Todas')),
                    ...ciudadesCorredor.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                  ],
                  onChanged: (v) => widget.onFiltroOrigenChange(v ?? ''),
                ),
              ),
              SizedBox(
                width: 140,
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.tryParse(widget.fechaViajes) ?? DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      widget.onFechaChange('${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Fecha', isDense: true),
                    child: Text(formatearFechaCorta(widget.fechaViajes)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.viajes.isEmpty)
            Text('No hay viajes para los filtros seleccionados.', style: TextStyle(color: Colors.grey.shade600))
          else
            ...widget.viajes.map((v) {
              final programado = v.estado == 'PROGRAMADO';
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Opacity(
                        opacity: v.estado == 'CANCELADO' ? 0.6 : 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${v.origen} → ${v.destino} · ${formatearHora(v.horaSalida)} · ${formatearCordobas(v.tarifa)}',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                            Text(
                              'Bus ${v.busNumeroInterno} · ${v.asientosDisponibles} cupos · ${v.estado}',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                            ),
                            if (v.estado == 'CANCELADO')
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Chip(label: const Text('Cancelado', style: TextStyle(fontSize: 11)), backgroundColor: Colors.orange.shade50, visualDensity: VisualDensity.compact),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (programado) ...[
                      IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _abrirEditar(v)),
                      IconButton(icon: Icon(Icons.delete_outline, color: Colors.red.shade700), onPressed: () => _confirmarCancelar(v.id)),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
