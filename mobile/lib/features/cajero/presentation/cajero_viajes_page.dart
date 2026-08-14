import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/transporte_api.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/auth/jwt_utils.dart';
import '../../../core/models/viaje.dart';
import '../../../core/utils/corredor.dart';
import '../../../core/utils/formato.dart';
import '../../../shared/widgets/section_card.dart';
import 'cajero_shell.dart';

class CajeroViajesPage extends StatefulWidget {
  const CajeroViajesPage({super.key});

  @override
  State<CajeroViajesPage> createState() => _CajeroViajesPageState();
}

class _CajeroViajesPageState extends State<CajeroViajesPage> {
  final _api = TransporteApi();
  List<ViajeOperador> _viajes = [];
  String _fecha = fechaHoyIso();
  String _filtroOrigen = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final auth = context.read<AuthProvider>();
    final terminal = CajeroScope.terminalOf(context);
    final token = auth.token;
    if (token == null) return;

    final esSoloCajero = auth.hasRole(AppRoles.cajero) && !auth.hasRole(AppRoles.adminEmpresa);
    final terminalFija = esSoloCajero ? terminal : null;
    final origenConsulta = terminalFija ?? (_filtroOrigen.isEmpty ? null : _filtroOrigen);

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final v = await _api.viajesMiEmpresa(token, _fecha, origen: origenConsulta);
      if (!mounted) return;
      setState(() => _viajes = v);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _viajes = [];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error al cargar viajes';
        _viajes = [];
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final terminal = CajeroScope.terminalOf(context);
    final esSoloCajero = auth.hasRole(AppRoles.cajero) && !auth.hasRole(AppRoles.adminEmpresa);
    final terminalFija = esSoloCajero ? terminal : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (esSoloCajero && terminal != null)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('Terminal asignada: $terminal. Solo verá salidas desde esa ciudad.'),
          ),
        if (esSoloCajero && terminal == null)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'No tiene terminal asignada. Contacte al administrador para configurar su sede de venta.',
            ),
          ),
        LayoutBuilder(
          builder: (context, c) {
            if (c.maxWidth > 700) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(child: _FlujoVentaCard()),
                  const SizedBox(width: 16),
                  const Expanded(child: _AyudaCard()),
                ],
              );
            }
            return const Column(
              children: [
                _FlujoVentaCard(),
                SizedBox(height: 16),
                _AyudaCard(),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 160,
              child: InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.tryParse(_fecha) ?? DateTime.now(),
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
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
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Salidas desde',
                  isDense: true,
                  helperText: terminalFija != null ? 'Fijado por su terminal' : null,
                ),
                value: terminalFija ?? (_filtroOrigen.isEmpty ? '' : _filtroOrigen),
                items: [
                  if (terminalFija == null) const DropdownMenuItem(value: '', child: Text('Todas las terminales')),
                  ...ciudadesCorredor.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                ],
                onChanged: terminalFija != null
                    ? null
                    : (v) {
                        setState(() => _filtroOrigen = v ?? '');
                        _cargar();
                      },
              ),
            ),
            Text('Venta permitida día anterior o mismo día del viaje', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 20),
        if (_error != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
            child: Text(_error!, style: TextStyle(color: Colors.red.shade800)),
          ),
        if (_loading)
          const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
        else if (_viajes.isEmpty && _error == null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
            child: Text(
              terminalFija != null
                  ? 'No hay salidas programadas desde $terminalFija para esta fecha.'
                  : 'No hay viajes programados para la fecha seleccionada.',
            ),
          )
        else
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth > 900 ? 3 : c.maxWidth > 600 ? 2 : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.4,
                ),
                itemCount: _viajes.length,
                itemBuilder: (context, i) {
                  final v = _viajes[i];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Bus ${v.busNumeroInterno}', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                          Text('${v.origen} → ${v.destino}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          Text('${formatearHora(v.horaSalida)} · ${formatearCordobas(v.tarifa)}'),
                          const Spacer(),
                          Text('Disponibles: ${v.asientosDisponibles}', style: const TextStyle(fontSize: 13)),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: v.asientosDisponibles == 0 ? null : () => context.go('/cajero/venta/${v.id}'),
                              icon: const Icon(Icons.point_of_sale, size: 18),
                              label: const Text('Vender boletos'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
      ],
    );
  }
}

class _FlujoVentaCard extends StatelessWidget {
  const _FlujoVentaCard();

  @override
  Widget build(BuildContext context) {
    return const SectionCard(
      title: 'Flujo de venta',
      subtitle: '3 pasos en mostrador',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('1. Elija fecha y viaje'),
          SizedBox(height: 6),
          Text('2. Seleccione asientos en el mapa'),
          SizedBox(height: 6),
          Text('3. Confirme y entregue comprobante'),
        ],
      ),
    );
  }
}

class _AyudaCard extends StatelessWidget {
  const _AyudaCard();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Ayuda rápida',
      child: Text(
        'Venta permitida el día anterior o el mismo día del viaje. Use Lista de pasajeros para imprimir manifiesto del día.',
        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
      ),
    );
  }
}
