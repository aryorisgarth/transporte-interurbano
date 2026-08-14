import 'package:flutter/material.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/transporte_api.dart';
import '../../../../core/models/bus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/corredor.dart';
import '../../../../shared/widgets/section_card.dart';

class AdminBusesSection extends StatefulWidget {
  const AdminBusesSection({
    super.key,
    required this.token,
    required this.empresaId,
    required this.esGlobal,
    required this.buses,
    required this.onActualizado,
    required this.onMsg,
  });

  final String token;
  final int empresaId;
  final bool esGlobal;
  final List<Bus> buses;
  final VoidCallback onActualizado;
  final void Function(String text, {bool error}) onMsg;

  @override
  State<AdminBusesSection> createState() => _AdminBusesSectionState();
}

class _AdminBusesSectionState extends State<AdminBusesSection> {
  final _api = TransporteApi();
  final _numeroCtrl = TextEditingController();
  final _placaCtrl = TextEditingController();
  final _fotoCtrl = TextEditingController();
  int _capacidad = 50;
  String _sede = ciudadesCorredor.first;

  @override
  void dispose() {
    _numeroCtrl.dispose();
    _placaCtrl.dispose();
    _fotoCtrl.dispose();
    super.dispose();
  }

  Future<void> _crearBus() async {
    if (_capacidad <= 0 || _capacidad % 2 != 0) {
      widget.onMsg('La capacidad debe ser un número par mayor a 0.', error: true);
      return;
    }
    try {
      await _api.crearBus(widget.token, {
        'empresaId': widget.empresaId,
        'numeroInterno': _numeroCtrl.text.trim(),
        'placa': _placaCtrl.text.trim(),
        'capacidad': _capacidad,
        'sede': _sede,
        if (_fotoCtrl.text.trim().isNotEmpty) 'fotoUrl': _fotoCtrl.text.trim(),
      });
      widget.onMsg('Bus registrado con asientos generados');
      _numeroCtrl.clear();
      _placaCtrl.clear();
      _fotoCtrl.clear();
      widget.onActualizado();
    } on ApiException catch (e) {
      widget.onMsg(e.message, error: true);
    }
  }

  Future<void> _abrirEditar(Bus bus) async {
    final numeroCtrl = TextEditingController(text: bus.numeroInterno);
    final placaCtrl = TextEditingController(text: bus.placa);
    final fotoCtrl = TextEditingController(text: bus.fotoUrl ?? '');
    var sede = bus.sede;
    var activo = bus.activo;
    var guardando = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Text('Editar bus ${bus.numeroInterno}'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'La capacidad no se modifica (layout de asientos ya generado). Desactive el bus si sale de servicio.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: numeroCtrl, decoration: const InputDecoration(labelText: 'Número interno *')),
                  const SizedBox(height: 12),
                  TextField(
                    controller: placaCtrl,
                    decoration: const InputDecoration(labelText: 'Placa *', helperText: 'Placa única en el sistema (RN BU3)'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: ciudadesCorredor.contains(sede) ? sede : ciudadesCorredor.first,
                    decoration: const InputDecoration(labelText: 'Terminal base (sede) *'),
                    items: ciudadesCorredor.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setDlg(() => sede = v ?? sede),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: fotoCtrl, decoration: const InputDecoration(labelText: 'URL foto')),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(activo ? 'Bus activo en flota' : 'Bus inactivo'),
                    value: activo,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setDlg(() => activo = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: guardando ? null : () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              onPressed: guardando
                  ? null
                  : () async {
                      setDlg(() => guardando = true);
                      try {
                        await _api.actualizarBus(widget.token, bus.id, {
                          'numeroInterno': numeroCtrl.text.trim(),
                          'placa': placaCtrl.text.trim(),
                          'sede': sede,
                          if (fotoCtrl.text.trim().isNotEmpty) 'fotoUrl': fotoCtrl.text.trim(),
                          'activo': activo,
                        });
                        widget.onMsg(activo ? 'Bus actualizado' : 'Bus desactivado (no aparece en nuevos viajes)');
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
    numeroCtrl.dispose();
    placaCtrl.dispose();
    fotoCtrl.dispose();
  }

  Future<void> _confirmarDesactivar(Bus bus) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar bus'),
        content: const Text(
          'Baja lógica: el bus queda inactivo (no se borra de la base de datos por historial de viajes). '
          'Puede reactivarlo desde editar.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _api.actualizarBus(widget.token, bus.id, {
        'numeroInterno': bus.numeroInterno,
        'placa': bus.placa,
        'sede': bus.sede,
        if (bus.fotoUrl != null) 'fotoUrl': bus.fotoUrl,
        'activo': false,
      });
      widget.onMsg('Bus eliminado (desactivado) — no se usa en nuevos viajes');
      widget.onActualizado();
    } on ApiException catch (e) {
      widget.onMsg(e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final row = c.maxWidth > 800;
        return row
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _form()),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: _lista()),
                ],
              )
            : Column(children: [_form(), const SizedBox(height: 16), _lista()]);
      },
    );
  }

  Widget _form() {
    return SectionCard(
      title: 'Nuevo bus',
      subtitle: 'Registro con asientos zigzag automáticos',
      child: Column(
        children: [
          TextField(controller: _numeroCtrl, decoration: const InputDecoration(labelText: 'Número interno *')),
          const SizedBox(height: 12),
          TextField(controller: _placaCtrl, decoration: const InputDecoration(labelText: 'Placa *')),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: _capacidad,
            decoration: const InputDecoration(labelText: 'Capacidad'),
            items: const [DropdownMenuItem(value: 50, child: Text('50 asientos'))],
            onChanged: (v) => setState(() => _capacidad = v ?? 50),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _sede,
            decoration: const InputDecoration(labelText: 'Terminal base (sede)'),
            items: ciudadesCorredor.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _sede = v ?? _sede),
          ),
          const SizedBox(height: 12),
          TextField(controller: _fotoCtrl, decoration: const InputDecoration(labelText: 'URL foto (opcional)')),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: _crearBus, icon: const Icon(Icons.add), label: const Text('Registrar bus')),
        ],
      ),
    );
  }

  Widget _lista() {
    return SectionCard(
      title: 'Flota (${widget.buses.length})',
      child: widget.buses.isEmpty
          ? Text('Sin buses registrados.', style: TextStyle(color: Colors.grey.shade600))
          : Column(
              children: widget.buses.map((b) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (b.fotoUrl != null && b.fotoUrl!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(b.fotoUrl!, width: 56, height: 40, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox(width: 56, height: 40)),
                        ),
                      if (b.fotoUrl != null && b.fotoUrl!.isNotEmpty) const SizedBox(width: 12),
                      Expanded(
                        child: Opacity(
                          opacity: b.activo ? 1 : 0.65,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${b.numeroInterno} · ${b.placa} · ${b.capacidad} asientos · Sede ${b.sede}'),
                              if (!b.activo)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Chip(
                                    label: const Text('Inactivo', style: TextStyle(fontSize: 11)),
                                    backgroundColor: Colors.orange.shade50,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _abrirEditar(b)),
                      if (b.activo)
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.red.shade700),
                          onPressed: () => _confirmarDesactivar(b),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}
