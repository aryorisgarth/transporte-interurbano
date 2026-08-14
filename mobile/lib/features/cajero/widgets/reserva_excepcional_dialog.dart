import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/transporte_api.dart';
import '../../../core/models/viaje.dart';

class ReservaExcepcionalDialog extends StatefulWidget {
  const ReservaExcepcionalDialog({
    super.key,
    required this.token,
    required this.detalle,
    required this.onSuccess,
  });

  final String token;
  final DetalleViaje detalle;
  final VoidCallback onSuccess;

  static Future<void> show(
    BuildContext context, {
    required String token,
    required DetalleViaje detalle,
    required VoidCallback onSuccess,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => ReservaExcepcionalDialog(
        token: token,
        detalle: detalle,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  State<ReservaExcepcionalDialog> createState() => _ReservaExcepcionalDialogState();
}

class _ReservaExcepcionalDialogState extends State<ReservaExcepcionalDialog> {
  final _api = TransporteApi();
  final _nombreCtrl = TextEditingController();
  final _cedulaCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _motivoCtrl = TextEditingController();
  final _horasCtrl = TextEditingController(text: '24');

  int? _asientoId;
  bool _loading = false;
  String? _error;

  List<AsientoViaje> get _disponibles =>
      widget.detalle.asientos.where((a) => a.estado == 'DISPONIBLE').toList();

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _cedulaCtrl.dispose();
    _telefonoCtrl.dispose();
    _motivoCtrl.dispose();
    _horasCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_asientoId == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _api.crearReservaExcepcional(widget.token, {
        'viajeAsientoId': _asientoId,
        'compradorNombre': _nombreCtrl.text.trim(),
        'compradorCedula': _cedulaCtrl.text.trim(),
        if (_telefonoCtrl.text.trim().isNotEmpty) 'compradorTelefono': _telefonoCtrl.text.trim(),
        'motivo': _motivoCtrl.text.trim(),
        'horasExpiracion': int.tryParse(_horasCtrl.text) ?? 24,
      });
      if (!mounted) return;
      widget.onSuccess();
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reserva excepcional'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Casos autorizados (gobierno, empleados). No genera venta; el asiento queda apartado sin pago.',
                  style: TextStyle(color: Colors.orange.shade900, fontSize: 13),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: Colors.red.shade800)),
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _asientoId,
                decoration: const InputDecoration(labelText: 'Asiento disponible *'),
                items: _disponibles
                    .map(
                      (a) => DropdownMenuItem(
                        value: a.viajeAsientoId,
                        child: Text('Asiento ${a.numero} (${a.posicion})'),
                      ),
                    )
                    .toList(),
                onChanged: _disponibles.isEmpty ? null : (v) => setState(() => _asientoId = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _cedulaCtrl,
                decoration: const InputDecoration(labelText: 'Cédula *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _telefonoCtrl,
                decoration: const InputDecoration(labelText: 'Teléfono'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _motivoCtrl,
                decoration: const InputDecoration(labelText: 'Motivo (obligatorio) *'),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _horasCtrl,
                decoration: const InputDecoration(labelText: 'Expira en (horas)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _loading ? null : () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(
          onPressed: _loading || _disponibles.isEmpty || _asientoId == null ? null : _submit,
          child: _loading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Apartar asiento'),
        ),
      ],
    );
  }
}
