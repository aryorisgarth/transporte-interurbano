import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../models/viaje.dart';
import '../services/transporte_api.dart';
import '../theme/app_colors.dart';
import '../utils/formato.dart';
import '../widgets/app_widgets.dart';
import '../widgets/viaje_card.dart';
import 'detalle_viaje_screen.dart';

const ciudades = ['Bluefields', 'Managua'];

class ConsultaScreen extends StatefulWidget {
  const ConsultaScreen({super.key});

  @override
  State<ConsultaScreen> createState() => _ConsultaScreenState();
}

class _ConsultaScreenState extends State<ConsultaScreen> {
  String _origen = 'Bluefields';
  String _destino = 'Managua';
  late String _fecha;
  List<ViajeDisponible> _viajes = [];
  bool _loading = false;
  bool _buscado = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fecha = fechaHoyIso();
    _buscar();
  }

  Future<void> _buscar() async {
    if (_origen == _destino) {
      setState(() {
        _error = 'El origen y el destino deben ser diferentes';
        _viajes = [];
        _buscado = true;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _buscado = true;
    });

    try {
      final data = await TransporteApi().buscarViajes(
        origen: _origen,
        destino: _destino,
        fecha: _fecha,
      );
      if (!mounted) return;
      setState(() => _viajes = data);
    } on TransporteApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _viajes = [];
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Sin conexión al servidor. Verifique que el backend esté activo en su PC.';
        _viajes = [];
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _intercambiarRuta() {
    setState(() {
      final tmp = _origen;
      _origen = _destino;
      _destino = tmp;
    });
  }

  void _fechaRelativa(int dias) {
    final d = DateTime.now().add(Duration(days: dias));
    setState(() {
      _fecha = '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';
    });
    _buscar();
  }

  Future<void> _elegirFecha() async {
    final parsed = DateTime.tryParse(_fecha) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: parsed,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Fecha del viaje',
    );
    if (picked != null) {
      setState(() {
        _fecha = '${picked.year.toString().padLeft(4, '0')}-'
            '${picked.month.toString().padLeft(2, '0')}-'
            '${picked.day.toString().padLeft(2, '0')}';
      });
      _buscar();
    }
  }

  bool get _esHoy => _fecha == fechaHoyIso();

  bool get _esManana {
    final m = DateTime.now().add(const Duration(days: 1));
    final iso = '${m.year.toString().padLeft(4, '0')}-'
        '${m.month.toString().padLeft(2, '0')}-'
        '${m.day.toString().padLeft(2, '0')}';
    return _fecha == iso;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          GradientHeader(
            title: 'Viajes interurbanos',
            subtitle: 'Consulte horarios y cupos · sin cuenta ni login',
            bottom: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _RouteSelector(
                  origen: _origen,
                  destino: _destino,
                  onSwap: _intercambiarRuta,
                  onOrigen: (v) => setState(() => _origen = v),
                  onDestino: (v) => setState(() => _destino = v),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _DateChip(label: 'Hoy', selected: _esHoy, onTap: () => _fechaRelativa(0)),
                    const SizedBox(width: 8),
                    _DateChip(label: 'Mañana', selected: _esManana, onTap: () => _fechaRelativa(1)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _DateChip(
                        label: formatearFechaCorta(_fecha),
                        selected: !_esHoy && !_esManana,
                        onTap: _elegirFecha,
                        icon: Icons.calendar_month,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _loading ? null : _buscar,
                  icon: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.search),
                  label: Text(_loading ? 'Buscando…' : 'Buscar salidas'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _buscar,
              color: AppColors.primary,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                children: [
                  const InfoBanner(
                    message:
                        'La compra es presencial en terminal. Presente su cédula el día anterior o el mismo día del viaje.',
                    icon: Icons.storefront_outlined,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '¿Es cajero o administrador?',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  Text(
                    'Use la versión web en PC — esta app es solo para pasajeros.',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  if (_error != null) ErrorBanner(message: _error!),
                  if (_buscado && !_loading && _viajes.isNotEmpty) ...[
                    Text(
                      '${_viajes.length} salida(s) · $_origen → $_destino',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_loading && _viajes.isEmpty)
                    ...List.generate(3, (_) => const _SkeletonCard()),
                  if (!_loading && _buscado && _viajes.isEmpty && _error == null)
                    const EmptyState(
                      message: 'No hay viajes programados para esta ruta y fecha.\nPruebe otra fecha o sentido.',
                    ),
                  ..._viajes.map(
                    (v) => ViajeCard(
                      viaje: v,
                      onTap: v.asientosDisponibles == 0
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => DetalleViajeScreen(
                                    viajeId: v.viajeId,
                                    apiBaseUrl: ApiConfig.baseUrl,
                                  ),
                                ),
                              );
                            },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteSelector extends StatelessWidget {
  const _RouteSelector({
    required this.origen,
    required this.destino,
    required this.onSwap,
    required this.onOrigen,
    required this.onDestino,
  });

  final String origen;
  final String destino;
  final VoidCallback onSwap;
  final ValueChanged<String> onOrigen;
  final ValueChanged<String> onDestino;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(child: _CityPicker(value: origen, label: 'Desde', onChanged: onOrigen)),
          IconButton(
            onPressed: onSwap,
            icon: const Icon(Icons.swap_horiz, color: Colors.white),
            tooltip: 'Intercambiar',
          ),
          Expanded(child: _CityPicker(value: destino, label: 'Hacia', onChanged: onDestino)),
        ],
      ),
    );
  }
}

class _CityPicker extends StatelessWidget {
  const _CityPicker({required this.value, required this.label, required this.onChanged});

  final String value;
  final String label;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11)),
        const SizedBox(height: 4),
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            dropdownColor: AppColors.primaryDark,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
            icon: const Icon(Icons.expand_more, color: Colors.white70),
            items: ciudades.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      ],
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: selected ? AppColors.primary : Colors.white),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: selected ? AppColors.primaryDark : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 18, width: 180, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6))),
          const SizedBox(height: 12),
          Container(height: 12, width: double.infinity, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6))),
          const SizedBox(height: 8),
          Container(height: 12, width: 120, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6))),
        ],
      ),
    );
  }
}
