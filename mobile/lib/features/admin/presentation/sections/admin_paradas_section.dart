import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/transporte_api.dart';
import '../../../../core/models/viaje.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/corredor.dart';
import '../../../../core/utils/formato.dart';
import '../../../../shared/widgets/hora_salida_field.dart';
import '../../../../shared/widgets/mapa_paradas_editor.dart';
import '../../../../shared/widgets/section_card.dart';

enum _ModoMapa { mover, agregar }

class _ParadaEditable {
  _ParadaEditable({
    required this.id,
    required this.nombre,
    required this.orden,
    this.minutosDesdeSalida,
    this.horaEstimada,
    this.latitud,
    this.longitud,
    this.dirty = false,
  });

  final int id;
  String nombre;
  final int orden;
  int? minutosDesdeSalida;
  String? horaEstimada;
  double? latitud;
  double? longitud;
  bool dirty;

  ParadaRuta toParada() => ParadaRuta(
        id: id,
        nombre: nombre,
        orden: orden,
        minutosDesdeSalida: minutosDesdeSalida,
        horaEstimada: horaEstimada,
        latitud: latitud,
        longitud: longitud,
      );

  factory _ParadaEditable.from(ParadaRuta p) => _ParadaEditable(
        id: p.id,
        nombre: p.nombre,
        orden: p.orden,
        minutosDesdeSalida: p.minutosDesdeSalida,
        horaEstimada: p.horaEstimada,
        latitud: p.latitud,
        longitud: p.longitud,
      );
}

class AdminParadasSection extends StatefulWidget {
  const AdminParadasSection({super.key, required this.token});

  final String token;

  @override
  State<AdminParadasSection> createState() => _AdminParadasSectionState();
}

class _AdminParadasSectionState extends State<AdminParadasSection> {
  final _api = TransporteApi();
  String _origen = ciudadesCorredor.first;
  String _destino = ciudadesCorredor.last;
  HoraSalidaNicaragua _hora = HoraSalidaNicaragua.inicial;
  List<_ParadaEditable> _paradas = [];
  int? _selectedId;
  _ModoMapa _modo = _ModoMapa.mover;
  bool _loading = true;
  bool _saving = false;
  String? _msg;
  bool _msgError = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final hora24 = _hora.toBackend();
      final hora = hora24.length == 5 ? '$hora24:00' : hora24;
      final data = await _api.listarParadas(widget.token, _origen, _destino, horaSalida: hora);
      if (!mounted) return;
      setState(() {
        _paradas = data.map(_ParadaEditable.from).toList();
        if (_paradas.isNotEmpty && (_selectedId == null || !_paradas.any((p) => p.id == _selectedId))) {
          _selectedId = _paradas.first.id;
        }
        if (_paradas.isEmpty) _selectedId = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _paradas = [];
        _selectedId = null;
        _setMsg(e.message, error: true);
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _setMsg(String text, {bool error = false, bool info = false}) {
    setState(() {
      _msg = text;
      _msgError = error;
      if (info) _msgError = false;
    });
  }

  void _moverParada(int id, double lat, double lng) {
    setState(() {
      _paradas = _paradas.map((p) {
        if (p.id == id) {
          p.latitud = lat;
          p.longitud = lng;
          p.dirty = true;
        }
        return p;
      }).toList();
      _selectedId = id;
      _setMsg('Posición actualizada. Pulse "Guardar" para confirmar.', info: true);
    });
  }

  Future<void> _onMapTap(double lat, double lng) async {
    if (_modo == _ModoMapa.agregar) {
      setState(() => _saving = true);
      try {
        final nombre = 'Parada ${_paradas.length + 1}';
        final minutos = _paradas.isEmpty
            ? 0
            : _paradas.map((p) => p.minutosDesdeSalida ?? 0).reduce((a, b) => a > b ? a : b) + 30;
        await _api.crearParada(widget.token, {
          'origen': _origen,
          'destino': _destino,
          'nombre': nombre,
          'minutosDesdeSalida': minutos,
          'latitud': lat,
          'longitud': lng,
        });
        _setMsg('Parada "$nombre" agregada. Edite el nombre y guarde si desea.');
        await _cargar();
      } on ApiException catch (e) {
        _setMsg(e.message, error: true);
      } finally {
        if (mounted) setState(() => _saving = false);
      }
      return;
    }

    if (_selectedId == null) {
      _setMsg('Seleccione una parada de la lista, o use modo "Agregar parada".', error: true);
      return;
    }
    _moverParada(_selectedId!, lat, lng);
  }

  Future<void> _guardarParada(_ParadaEditable p) async {
    if (p.latitud == null || p.longitud == null) {
      _setMsg('Coloque la parada en el mapa (clic o arrastre del marcador)', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await _api.actualizarParada(widget.token, p.id, {
        'nombre': p.nombre,
        'minutosDesdeSalida': p.minutosDesdeSalida ?? 0,
        'latitud': p.latitud,
        'longitud': p.longitud,
      });
      _setMsg('Parada "${p.nombre}" guardada');
      await _cargar();
    } on ApiException catch (e) {
      _setMsg(e.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _borrarParada(_ParadaEditable p) async {
    if (_paradas.length <= 2) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar parada'),
        content: Text('¿Eliminar "${p.nombre}" de la ruta?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _saving = true);
    try {
      await _api.eliminarParada(widget.token, p.id);
      _setMsg('Parada eliminada');
      await _cargar();
    } on ApiException catch (e) {
      _setMsg(e.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _abrirDialogAgregar(double lat, double lng) async {
    final nombreCtrl = TextEditingController(text: 'Parada ${_paradas.length + 1}');
    final minutos = _paradas.isEmpty
        ? 0
        : _paradas.map((p) => p.minutosDesdeSalida ?? 0).reduce((a, b) => a > b ? a : b) + 30;
    final minutosCtrl = TextEditingController(text: '$minutos');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva parada'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ubicación: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre')),
            const SizedBox(height: 12),
            TextField(
              controller: minutosCtrl,
              decoration: const InputDecoration(labelText: 'Minutos desde salida'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Crear')),
        ],
      ),
    );
    if (ok != true) {
      nombreCtrl.dispose();
      minutosCtrl.dispose();
      return;
    }
    try {
      await _api.crearParada(widget.token, {
        'origen': _origen,
        'destino': _destino,
        'nombre': nombreCtrl.text.trim(),
        'minutosDesdeSalida': int.tryParse(minutosCtrl.text) ?? minutos,
        'latitud': lat,
        'longitud': lng,
      });
      _setMsg('Parada creada');
      await _cargar();
    } on ApiException catch (e) {
      _setMsg(e.message, error: true);
    }
    nombreCtrl.dispose();
    minutosCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Ruta y paradas',
      subtitle: 'Arme su ruta real en el mapa interurbano',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
            child: const Text(
              'Arme su ruta real: elimine paradas que no usan y agregue solo las suyas. '
              'Seleccione una parada y haga clic en el mapa para reposicionarla.',
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(
                width: 160,
                child: DropdownButtonFormField<String>(
                  value: _origen,
                  decoration: const InputDecoration(labelText: 'Origen', isDense: true),
                  items: ciudadesCorredor.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _origen = v;
                      _destino = destinoOpuesto(v);
                    });
                    _cargar();
                  },
                ),
              ),
              SizedBox(
                width: 160,
                child: DropdownButtonFormField<String>(
                  value: _destino,
                  decoration: const InputDecoration(labelText: 'Destino', isDense: true),
                  items: ciudadesCorredor.where((c) => c != _origen).map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _destino = v);
                    _cargar();
                  },
                ),
              ),
              SizedBox(
                width: 320,
                child: HoraSalidaField(
                  value: _hora,
                  dense: true,
                  label: 'Hora salida referencia',
                  onChanged: (h) {
                    setState(() => _hora = h);
                    _cargar();
                  },
                ),
              ),
            ],
          ),
          if (_msg != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _msgError ? Colors.red.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_msg!, style: TextStyle(color: _msgError ? Colors.red.shade800 : Colors.green.shade800)),
            ),
          ],
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator(color: AppColors.primary))
          else
            LayoutBuilder(
              builder: (context, c) {
                final row = c.maxWidth > 900;
                return row
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: _mapaPanel()),
                          const SizedBox(width: 16),
                          Expanded(flex: 2, child: _listaParadas()),
                        ],
                      )
                    : Column(
                        children: [
                          _mapaPanel(),
                          const SizedBox(height: 16),
                          _listaParadas(),
                        ],
                      );
              },
            ),
        ],
      ),
    );
  }

  Widget _mapaPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Text('Mapa — edite la ruta aquí', style: TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            SegmentedButton<_ModoMapa>(
              segments: const [
                ButtonSegment(value: _ModoMapa.mover, label: Text('Mover'), icon: Icon(Icons.edit_location_alt, size: 16)),
                ButtonSegment(value: _ModoMapa.agregar, label: Text('Agregar'), icon: Icon(Icons.add_location_alt, size: 16)),
              ],
              selected: {_modo},
              onSelectionChanged: (s) => setState(() => _modo = s.first),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          _modo == _ModoMapa.agregar
              ? 'Clic en el mapa = nueva parada en esa ubicación'
              : 'Seleccione parada → clic en el mapa para reposicionar',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 8),
        MapaParadasEditor(
          paradas: _paradas.map((p) => p.toParada()).toList(),
          selectedId: _selectedId,
          onMapTap: _modo == _ModoMapa.agregar ? _abrirDialogAgregar : _onMapTap,
          onMarkerTap: (id) => setState(() {
            _selectedId = id;
            _modo = _ModoMapa.mover;
          }),
        ),
      ],
    );
  }

  Widget _listaParadas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Paradas (${_paradas.length}) — mínimo 2', style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (_paradas.isEmpty)
          Text('Sin paradas. Use Agregar y haga clic en el mapa.', style: TextStyle(color: Colors.grey.shade600))
        else
          ..._paradas.map((p) {
            final selected = p.id == _selectedId;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: selected ? AppColors.primary : Colors.grey.shade300, width: selected ? 2 : 1),
              ),
              color: p.dirty ? Colors.grey.shade50 : null,
              child: InkWell(
                onTap: () => setState(() {
                  _selectedId = p.id;
                  _modo = _ModoMapa.mover;
                }),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('${p.orden}. ${p.nombre}${p.dirty ? ' *' : ''}${p.horaEstimada != null ? ' · ${formatearHora(p.horaEstimada!)}' : ''}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: ValueKey('nom-${p.id}-${p.nombre}'),
                        decoration: const InputDecoration(labelText: 'Nombre', isDense: true),
                        initialValue: p.nombre,
                        onChanged: (v) => setState(() {
                          p.nombre = v;
                          p.dirty = true;
                        }),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: ValueKey('min-${p.id}-${p.minutosDesdeSalida}'),
                        decoration: const InputDecoration(labelText: 'Minutos desde salida', isDense: true),
                        keyboardType: TextInputType.number,
                        initialValue: '${p.minutosDesdeSalida ?? 0}',
                        onChanged: (v) => setState(() {
                          p.minutosDesdeSalida = int.tryParse(v) ?? 0;
                          p.dirty = true;
                        }),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              key: ValueKey('lat-${p.id}-${p.latitud}'),
                              decoration: const InputDecoration(labelText: 'Latitud', isDense: true),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              initialValue: p.latitud?.toStringAsFixed(4) ?? '',
                              onChanged: (v) => setState(() {
                                p.latitud = double.tryParse(v);
                                p.dirty = true;
                              }),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              key: ValueKey('lng-${p.id}-${p.longitud}'),
                              decoration: const InputDecoration(labelText: 'Longitud', isDense: true),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              initialValue: p.longitud?.toStringAsFixed(4) ?? '',
                              onChanged: (v) => setState(() {
                                p.longitud = double.tryParse(v);
                                p.dirty = true;
                              }),
                            ),
                          ),
                        ],
                      ),
                      if (p.latitud != null && p.longitud != null)
                        TextButton(
                          onPressed: () => launchUrl(Uri.parse('https://www.google.com/maps?q=${p.latitud},${p.longitud}')),
                          child: const Text('Ver en Google Maps', style: TextStyle(fontSize: 12)),
                        ),
                      Row(
                        children: [
                          FilledButton.icon(
                            onPressed: _saving ? null : () => _guardarParada(p),
                            icon: _saving
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.save, size: 18),
                            label: const Text('Guardar'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: _saving || _paradas.length <= 2 ? null : () => _borrarParada(p),
                            icon: const Icon(Icons.delete_outline, size: 18),
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                            label: const Text('Eliminar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}
