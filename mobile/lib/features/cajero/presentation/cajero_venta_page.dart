import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/transporte_api.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/auth/jwt_utils.dart';
import '../../../core/models/viaje.dart';
import '../../../core/models/venta.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formato.dart';
import '../../../shared/widgets/seat_grid.dart';
import '../../../shared/widgets/section_card.dart';
import '../widgets/comprobante_venta_dialog.dart';
import '../widgets/reserva_excepcional_dialog.dart';

class _DatosPasajero {
  String nombre = '';
  String cedula = '';
  bool esMenor = false;
  String edad = '';
}

class CajeroVentaPage extends StatefulWidget {
  const CajeroVentaPage({super.key, required this.viajeId});

  final int viajeId;

  @override
  State<CajeroVentaPage> createState() => _CajeroVentaPageState();
}

class _CajeroVentaPageState extends State<CajeroVentaPage> {
  final _api = TransporteApi();
  final _nombreCtrl = TextEditingController();
  final _cedulaCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _equipajeCtrl = TextEditingController(text: '0');

  DetalleViaje? _detalle;
  List<int> _seleccionados = [];
  final Map<int, _DatosPasajero> _pasajeros = {};
  bool _modoDetallado = false;
  int _equipajeExtra = 0;
  bool _loading = true;
  bool _ventaLoading = false;
  String? _error;
  VentaResponse? _ventaOk;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _cedulaCtrl.dispose();
    _telefonoCtrl.dispose();
    _equipajeCtrl.dispose();
    for (final c in _pasajeroNombreCtrls.values) {
      c.dispose();
    }
    for (final c in _pasajeroCedulaCtrls.values) {
      c.dispose();
    }
    for (final c in _pasajeroEdadCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _puedeReservar {
    final auth = context.read<AuthProvider>();
    return auth.hasAnyRole([
      AppRoles.reservaExcepcional,
      AppRoles.adminEmpresa,
      AppRoles.adminGeneral,
    ]);
  }

  Future<void> _cargar() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final d = await _api.detalleViajeOperador(widget.viajeId, token);
      if (!mounted) return;
      setState(() => _detalle = d);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  final Map<int, TextEditingController> _pasajeroNombreCtrls = {};
  final Map<int, TextEditingController> _pasajeroCedulaCtrls = {};
  final Map<int, TextEditingController> _pasajeroEdadCtrls = {};

  void _toggleAsiento(int id) {
    setState(() {
      if (_seleccionados.contains(id)) {
        _seleccionados = _seleccionados.where((x) => x != id).toList();
        _pasajeros.remove(id);
        _pasajeroNombreCtrls.remove(id)?.dispose();
        _pasajeroCedulaCtrls.remove(id)?.dispose();
        _pasajeroEdadCtrls.remove(id)?.dispose();
      } else {
        _seleccionados = [..._seleccionados, id];
        _pasajeros.putIfAbsent(id, () => _DatosPasajero());
        _pasajeroNombreCtrls.putIfAbsent(id, () => TextEditingController());
        _pasajeroCedulaCtrls.putIfAbsent(id, () => TextEditingController());
        _pasajeroEdadCtrls.putIfAbsent(id, () => TextEditingController());
      }
    });
  }

  int _numeroAsiento(int viajeAsientoId) {
    final match = _detalle?.asientos.where((a) => a.viajeAsientoId == viajeAsientoId);
    if (match != null && match.isNotEmpty) return match.first.numero;
    return viajeAsientoId;
  }

  bool _cedulaValida(String cedula) => cedula.trim().length >= 5;

  /// Resuelve datos por asiento: el adulto responsable puede viajar sin duplicar
  /// el formulario; los menores pueden usar la cédula del pagador.
  ({String nombre, String cedula, bool esMenor, int? edad}) _datosPasajero(int asientoId) {
    final p = _pasajeros[asientoId] ?? _DatosPasajero();
    var nombre = _pasajeroNombreCtrls[asientoId]?.text.trim() ?? p.nombre.trim();
    var cedula = _pasajeroCedulaCtrls[asientoId]?.text.trim() ?? p.cedula.trim();
    final responsableNombre = _nombreCtrl.text.trim();
    final responsableCedula = _cedulaCtrl.text.trim();
    final edadTxt = _pasajeroEdadCtrls[asientoId]?.text.trim() ?? p.edad.trim();

    if (!p.esMenor) {
      if (nombre.isEmpty) nombre = responsableNombre;
      if (cedula.isEmpty) cedula = responsableCedula;
    } else if (cedula.isEmpty) {
      cedula = responsableCedula;
    }

    return (
      nombre: nombre,
      cedula: cedula,
      esMenor: p.esMenor,
      edad: p.esMenor ? int.tryParse(edadTxt) : null,
    );
  }

  bool get _pasajerosValidos {
    if (!_modoDetallado) {
      return _nombreCtrl.text.trim().isNotEmpty && _cedulaValida(_cedulaCtrl.text);
    }
    if (_nombreCtrl.text.trim().isEmpty || !_cedulaValida(_cedulaCtrl.text)) return false;
    for (final id in _seleccionados) {
      final d = _datosPasajero(id);
      if (d.nombre.isEmpty || !_cedulaValida(d.cedula)) return false;
      if (d.esMenor && d.edad == null) return false;
    }
    return true;
  }

  String? get _motivoFormularioInvalido {
    if (_seleccionados.isEmpty) return 'Seleccione al menos un asiento.';
    if (!_modoDetallado) {
      if (_nombreCtrl.text.trim().isEmpty) return 'Indique el nombre del comprador.';
      if (!_cedulaValida(_cedulaCtrl.text)) return 'La cédula del comprador debe tener al menos 5 caracteres.';
      return null;
    }
    if (_nombreCtrl.text.trim().isEmpty) return 'Indique el nombre del adulto responsable.';
    if (!_cedulaValida(_cedulaCtrl.text)) {
      return 'La cédula del responsable debe tener al menos 5 caracteres.';
    }
    for (final id in _seleccionados) {
      final d = _datosPasajero(id);
      final num = _numeroAsiento(id);
      if (d.nombre.isEmpty) return 'Falta el nombre del pasajero en asiento #$num.';
      if (!_cedulaValida(d.cedula)) {
        return d.esMenor
            ? 'Indique cédula del menor o del responsable en asiento #$num.'
            : 'Indique cédula del pasajero o del responsable en asiento #$num.';
      }
      if (d.esMenor && d.edad == null) return 'Indique la edad del menor en asiento #$num.';
    }
    return null;
  }

  Future<void> _confirmarVenta() async {
    final detalle = _detalle;
    final token = context.read<AuthProvider>().token;
    if (detalle == null || token == null || _seleccionados.isEmpty || !_pasajerosValidos) return;

    setState(() {
      _ventaLoading = true;
      _error = null;
      _ventaOk = null;
    });

    try {
      final body = <String, dynamic>{
        'viajeId': detalle.viajeId,
        'compradorNombre': _nombreCtrl.text.trim(),
        'compradorCedula': _cedulaCtrl.text.trim(),
        if (_telefonoCtrl.text.trim().isNotEmpty) 'compradorTelefono': _telefonoCtrl.text.trim(),
        'viajeAsientoIds': _seleccionados,
        if (_modoDetallado)
          'pasajeros': _seleccionados.map((asientoId) {
            final d = _datosPasajero(asientoId);
            return {
              'viajeAsientoId': asientoId,
              'pasajeroNombre': d.nombre,
              'pasajeroCedula': d.cedula,
              'esMenor': d.esMenor,
              if (d.esMenor) 'edad': d.edad,
            };
          }).toList(),
        if (_equipajeExtra > 0)
          'equipajeExtra': {
            'cantidad': _equipajeExtra,
            'montoUnitario': detalle.tarifaEquipajeExtra,
          },
      };

      final res = await _api.crearVenta(token, body);
      if (!mounted) return;

      final viajeInfo = ViajeComprobanteInfo(
        origen: detalle.origen,
        destino: detalle.destino,
        fecha: detalle.fecha,
        hora: formatearHora(detalle.horaSalida),
        empresa: detalle.empresaNombre,
      );

      setState(() {
        _ventaOk = res;
        _seleccionados = [];
        _pasajeros.clear();
        for (final c in _pasajeroNombreCtrls.values) {
          c.dispose();
        }
        for (final c in _pasajeroCedulaCtrls.values) {
          c.dispose();
        }
        for (final c in _pasajeroEdadCtrls.values) {
          c.dispose();
        }
        _pasajeroNombreCtrls.clear();
        _pasajeroCedulaCtrls.clear();
        _pasajeroEdadCtrls.clear();
        _equipajeExtra = 0;
        _equipajeCtrl.text = '0';
        _nombreCtrl.clear();
        _cedulaCtrl.clear();
        _telefonoCtrl.clear();
      });

      await _cargar();
      if (!mounted) return;
      await ComprobanteVentaDialog.show(context, venta: res, viajeInfo: viajeInfo);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _ventaLoading = false);
    }
  }

  void _abrirReservaExcepcional() {
    final detalle = _detalle;
    final token = context.read<AuthProvider>().token;
    if (detalle == null || token == null) return;

    ReservaExcepcionalDialog.show(
      context,
      token: token,
      detalle: detalle,
      onSuccess: _cargar,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    final detalle = _detalle;
    if (detalle == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_error ?? 'Viaje no encontrado', style: TextStyle(color: Colors.red.shade800)),
          if (_error?.contains('Acceso denegado') == true)
            Text(
              ' — Solo puede vender viajes de su cooperativa.',
              style: TextStyle(color: Colors.red.shade800),
            ),
        ],
      );
    }

    final tarifa = detalle.tarifa;
    final tarifaEquipaje = detalle.tarifaEquipajeExtra;
    final subtotalBoletos = _seleccionados.length * tarifa;
    final subtotalEquipaje = _equipajeExtra > 0 ? _equipajeExtra * tarifaEquipaje : 0.0;
    final total = subtotalBoletos + subtotalEquipaje;
    final esMobile = MediaQuery.sizeOf(context).width < 800;

    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 720;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            stacked
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${detalle.origen} → ${detalle.destino}',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                          ),
                          Text(
                            '${detalle.empresaNombre} · ${detalle.fecha} · ${formatearHora(detalle.horaSalida)} · Bus ${detalle.busNumeroInterno}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton(onPressed: () => context.go('/cajero'), child: const Text('Volver a viajes')),
                          if (_puedeReservar)
                            OutlinedButton(onPressed: _abrirReservaExcepcional, child: const Text('Reserva excepcional')),
                        ],
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${detalle.origen} → ${detalle.destino}',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                            ),
                            Text(
                              '${detalle.empresaNombre} · ${detalle.fecha} · ${formatearHora(detalle.horaSalida)} · Bus ${detalle.busNumeroInterno}',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton(onPressed: () => context.go('/cajero'), child: const Text('Volver a viajes')),
                          if (_puedeReservar)
                            OutlinedButton(onPressed: _abrirReservaExcepcional, child: const Text('Reserva excepcional')),
                        ],
                      ),
                    ],
                  ),
            const SizedBox(height: 16),
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  final desktop = c.maxWidth > 900;
                  if (desktop) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                    Expanded(
                      flex: 3,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                              child: Text(
                                'Seleccionar asientos',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Scrollbar(
                                thumbVisibility: true,
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(16),
                                  child: Center(
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 400),
                                      child: _buildMapa(detalle, embedded: true),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                              child: Text(
                                'Datos del comprador',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Scrollbar(
                                thumbVisibility: true,
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(16),
                                  child: _buildForm(
                                    detalle,
                                    subtotalBoletos,
                                    subtotalEquipaje,
                                    total,
                                    esMobile,
                                    embedded: true,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }
              return SingleChildScrollView(
                child: Column(
                  children: [
                    _buildMapa(detalle),
                    const SizedBox(height: 16),
                    _buildForm(detalle, subtotalBoletos, subtotalEquipaje, total, esMobile),
                  ],
                ),
              );
            },
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(_error!, style: TextStyle(color: Colors.red.shade800)),
          ),
        if (_ventaOk != null)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Expanded(child: Text('Venta ${_ventaOk!.codigo} registrada.')),
                TextButton(
                  onPressed: () => ComprobanteVentaDialog.show(
                    context,
                    venta: _ventaOk!,
                    viajeInfo: ViajeComprobanteInfo(
                      origen: detalle.origen,
                      destino: detalle.destino,
                      fecha: detalle.fecha,
                      hora: formatearHora(detalle.horaSalida),
                      empresa: detalle.empresaNombre,
                    ),
                  ),
                  child: const Text('Ver comprobante'),
                ),
              ],
            ),
          ),
      ],
    );
      },
    );
  }

  Widget _buildMapa(DetalleViaje detalle, {bool embedded = false}) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!embedded)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text('Seleccionar asientos', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ),
        Padding(
          padding: EdgeInsets.all(embedded ? 0 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SeatGrid(
                asientos: detalle.asientos,
                busNumeroInterno: detalle.busNumeroInterno,
                busFotoUrl: detalle.busFotoUrl,
                seleccionados: _seleccionados,
                modoSeleccion: true,
                onToggle: _toggleAsiento,
                compact: true,
              ),
            ],
          ),
        ),
      ],
    );

    if (embedded) return content;

    return SectionCard(title: 'Seleccionar asientos', noPadding: true, child: content);
  }

  Widget _buildForm(
    DetalleViaje detalle,
    double subtotalBoletos,
    double subtotalEquipaje,
    double total,
    bool esMobile, {
    bool embedded = false,
  }) {
    final fields = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_seleccionados.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${_seleccionados.map((id) => '#${_numeroAsiento(id)}').join(' · ')} · ${formatearCordobas(total)}',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
        if (_seleccionados.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
              child: Text(
                'Elija asientos en el mapa ${esMobile ? 'arriba' : 'a la izquierda'}. '
                'El resumen y el botón de confirmar aparecen en este panel.',
              ),
            ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('Registrar cada pasajero por separado'),
            value: _modoDetallado,
            onChanged: (v) => setState(() => _modoDetallado = v ?? false),
          ),
          if (!_modoDetallado) ...[
            TextField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(labelText: 'Nombre completo *'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cedulaCtrl,
              decoration: const InputDecoration(labelText: 'Cédula *'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(controller: _telefonoCtrl, decoration: const InputDecoration(labelText: 'Teléfono')),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
              child: const Text(
                'Un registro por asiento. Si el adulto responsable viaja en uno de los asientos, '
                'puede dejar ese asiento en blanco: se usarán los datos del pagador. '
                'Para menores, la cédula puede ser la del responsable.',
              ),
            ),
            if (_seleccionados.isEmpty)
              Text('Seleccione asientos en el mapa.', style: TextStyle(color: Colors.grey.shade600)),
            for (final asientoId in _seleccionados) _buildPasajeroCard(asientoId),
            const Divider(height: 24),
            const Text('Adulto responsable / pagador', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _nombreCtrl,
              decoration: const InputDecoration(labelText: 'Nombre responsable *', isDense: true),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _cedulaCtrl,
              decoration: const InputDecoration(labelText: 'Cédula responsable *', isDense: true),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _telefonoCtrl,
              decoration: const InputDecoration(labelText: 'Teléfono contacto', isDense: true),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _equipajeCtrl,
            decoration: InputDecoration(
              labelText: 'Equipaje extra (${formatearCordobas(detalle.tarifaEquipajeExtra)}/u.)',
            ),
            keyboardType: TextInputType.number,
            onChanged: (v) => setState(() => _equipajeExtra = int.tryParse(v)?.clamp(0, 99) ?? 0),
          ),
          const Divider(height: 24),
          Text('Boletos (${_seleccionados.length}): ${formatearCordobas(subtotalBoletos)}'),
          if (subtotalEquipaje > 0) Text('Equipaje: ${formatearCordobas(subtotalEquipaje)}'),
          Text('Total: ${formatearCordobas(total)}', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (_seleccionados.isEmpty)
            FilledButton(onPressed: null, child: const Text('Seleccione asientos primero'))
          else ...[
            if (!_pasajerosValidos && _motivoFormularioInvalido != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _motivoFormularioInvalido!,
                  style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
                ),
              ),
            FilledButton(
              onPressed: _ventaLoading || !_pasajerosValidos ? null : _confirmarVenta,
              child: _ventaLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text('Confirmar venta · ${formatearCordobas(total)}'),
            ),
          ],
        ],
    );

    if (embedded) return fields;

    return SectionCard(title: 'Datos del comprador', child: fields);
  }

  Widget _buildPasajeroCard(int asientoId) {
    final p = _pasajeros.putIfAbsent(asientoId, () => _DatosPasajero());
    final nombreCtrl = _pasajeroNombreCtrls.putIfAbsent(asientoId, () => TextEditingController());
    final cedulaCtrl = _pasajeroCedulaCtrls.putIfAbsent(asientoId, () => TextEditingController());
    final edadCtrl = _pasajeroEdadCtrls.putIfAbsent(asientoId, () => TextEditingController());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.event_seat, size: 18),
              const SizedBox(width: 6),
              Text('Asiento ${_numeroAsiento(asientoId)}', style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(labelText: 'Nombre pasajero *', isDense: true),
            controller: nombreCtrl,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              labelText: 'Cédula',
              isDense: true,
              helperText: !p.esMenor ? 'Opcional si es el mismo adulto responsable de abajo.' : null,
              helperMaxLines: 2,
            ),
            controller: cedulaCtrl,
            onChanged: (_) => setState(() {}),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text('Menor de 18 años'),
            value: p.esMenor,
            onChanged: (v) => setState(() => p.esMenor = v ?? false),
          ),
          if (p.esMenor)
            TextField(
              decoration: const InputDecoration(labelText: 'Edad *', isDense: true),
              keyboardType: TextInputType.number,
              controller: edadCtrl,
              onChanged: (_) => setState(() {}),
            ),
        ],
      ),
    );
  }
}
