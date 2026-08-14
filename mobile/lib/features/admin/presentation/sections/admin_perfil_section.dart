import 'package:flutter/material.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/transporte_api.dart';
import '../../../../core/models/empresa.dart';

class AdminPerfilSection extends StatefulWidget {
  const AdminPerfilSection({
    super.key,
    required this.token,
    required this.empresaId,
    required this.esGlobal,
    this.onActualizado,
  });

  final String token;
  final int empresaId;
  final bool esGlobal;
  final ValueChanged<Empresa>? onActualizado;

  @override
  State<AdminPerfilSection> createState() => _AdminPerfilSectionState();
}

class _AdminPerfilSectionState extends State<AdminPerfilSection> {
  final _api = TransporteApi();
  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _logoCtrl = TextEditingController();
  double _tarifaEquipaje = 100;
  bool _loading = true;
  bool _saving = false;
  String? _msg;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _correoCtrl.dispose();
    _logoCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final e = widget.esGlobal
          ? await _api.obtenerEmpresa(widget.token, widget.empresaId)
          : await _api.miEmpresa(widget.token);
      if (!mounted) return;
      _nombreCtrl.text = e.nombre;
      _telefonoCtrl.text = e.telefono ?? '';
      _correoCtrl.text = e.correo ?? '';
      _logoCtrl.text = e.logoUrl ?? '';
      _tarifaEquipaje = e.tarifaEquipajeExtra;
    } catch (_) {
      _msg = 'No se pudo cargar el perfil';
      _error = true;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _guardar() async {
    setState(() {
      _saving = true;
      _msg = null;
    });
    try {
      final actualizada = await _api.actualizarEmpresa(widget.token, widget.empresaId, {
        'nombre': _nombreCtrl.text.trim(),
        if (_telefonoCtrl.text.trim().isNotEmpty) 'telefono': _telefonoCtrl.text.trim(),
        if (_correoCtrl.text.trim().isNotEmpty) 'correo': _correoCtrl.text.trim(),
        'tarifaEquipajeExtra': _tarifaEquipaje,
        if (_logoCtrl.text.trim().isNotEmpty) 'logoUrl': _logoCtrl.text.trim(),
      });
      if (!mounted) return;
      setState(() {
        _msg = 'Perfil actualizado';
        _error = false;
      });
      widget.onActualizado?.call(actualizada);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _msg = e.message;
        _error = true;
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Perfil de la cooperativa', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
              Text('Datos comerciales y logo público', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              const SizedBox(height: 16),
              if (_msg != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _error ? Colors.red.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_msg!, style: TextStyle(color: _error ? Colors.red.shade800 : Colors.green.shade800)),
                ),
              TextField(controller: _nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre *')),
              const SizedBox(height: 12),
              TextField(controller: _telefonoCtrl, decoration: const InputDecoration(labelText: 'Teléfono')),
              const SizedBox(height: 12),
              TextField(controller: _correoCtrl, decoration: const InputDecoration(labelText: 'Correo comercial')),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Tarifa equipaje extra (C\$)'),
                keyboardType: TextInputType.number,
                initialValue: '$_tarifaEquipaje',
                onChanged: (v) => _tarifaEquipaje = double.tryParse(v) ?? _tarifaEquipaje,
              ),
              const SizedBox(height: 12),
              TextField(controller: _logoCtrl, decoration: const InputDecoration(labelText: 'URL logo (opcional)')),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _saving ? null : _guardar,
                icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
                label: Text(_saving ? 'Guardando…' : 'Guardar cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
