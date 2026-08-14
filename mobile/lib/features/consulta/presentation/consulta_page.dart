import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/transporte_api.dart';
import '../../../core/models/viaje.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/corredor.dart';
import '../../../core/utils/formato.dart';

class ConsultaPage extends StatefulWidget {
  const ConsultaPage({super.key});

  @override
  State<ConsultaPage> createState() => _ConsultaPageState();
}

class _ConsultaPageState extends State<ConsultaPage> {
  final _api = TransporteApi();
  String _origen = ciudadesCorredor.first;
  String _destino = ciudadesCorredor.last;
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
      final data = await _api.buscarViajes(origen: _origen, destino: _destino, fecha: _fecha);
      if (!mounted) return;
      setState(() => _viajes = data);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _viajes = [];
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Sin conexión al servidor. Verifique que el backend esté activo.';
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
    setState(() => _fecha = '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}');
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
      setState(() => _fecha = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
      _buscar();
    }
  }

  bool get _esHoy => _fecha == fechaHoyIso();

  bool get _esManana {
    final m = DateTime.now().add(const Duration(days: 1));
    final iso = '${m.year.toString().padLeft(4, '0')}-${m.month.toString().padLeft(2, '0')}-${m.day.toString().padLeft(2, '0')}';
    return _fecha == iso;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeroHeader(
          origen: _origen,
          destino: _destino,
          fecha: _fecha,
          loading: _loading,
          esHoy: _esHoy,
          esManana: _esManana,
          onSwap: _intercambiarRuta,
          onOrigen: (v) => setState(() => _origen = v),
          onDestino: (v) => setState(() => _destino = v),
          onHoy: () => _fechaRelativa(0),
          onManana: () => _fechaRelativa(1),
          onFecha: _elegirFecha,
          onBuscar: _buscar,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: const Row(
            children: [
              Icon(Icons.storefront_outlined, color: AppColors.primary, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'La compra es presencial en terminal. Presente su cédula el día anterior o el mismo día del viaje.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (_error != null)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
            child: Text(_error!, style: TextStyle(color: Colors.red.shade800)),
          ),
        if (_buscado && !_loading && _viajes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '${_viajes.length} salida(s) · $_origen → $_destino',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
        if (_loading && _viajes.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
        if (!_loading && _buscado && _viajes.isEmpty && _error == null)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'No hay viajes programados para esta ruta y fecha.\nPruebe otra fecha o sentido.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ),
        ..._viajes.map(
          (v) => _ViajeTile(
            viaje: v,
            onTap: v.asientosDisponibles == 0 ? null : () => context.go('/consulta/viaje/${v.viajeId}'),
          ),
        ),
      ],
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.origen,
    required this.destino,
    required this.fecha,
    required this.loading,
    required this.esHoy,
    required this.esManana,
    required this.onSwap,
    required this.onOrigen,
    required this.onDestino,
    required this.onHoy,
    required this.onManana,
    required this.onFecha,
    required this.onBuscar,
  });

  final String origen;
  final String destino;
  final String fecha;
  final bool loading;
  final bool esHoy;
  final bool esManana;
  final VoidCallback onSwap;
  final ValueChanged<String> onOrigen;
  final ValueChanged<String> onDestino;
  final VoidCallback onHoy;
  final VoidCallback onManana;
  final VoidCallback onFecha;
  final VoidCallback onBuscar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppColors.gradientHero),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Viajes interurbanos',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 24),
          ),
          Text(
            'Consulte horarios y cupos · sin cuenta ni login',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.85)),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 480;
              final routeSelector = stacked
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _CityPicker(value: origen, label: 'Desde', onChanged: onOrigen),
                        Align(
                          alignment: Alignment.center,
                          child: IconButton(
                            onPressed: onSwap,
                            icon: const Icon(Icons.swap_vert, color: Colors.white),
                          ),
                        ),
                        _CityPicker(value: destino, label: 'Hacia', onChanged: onDestino),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: _CityPicker(value: origen, label: 'Desde', onChanged: onOrigen)),
                        IconButton(onPressed: onSwap, icon: const Icon(Icons.swap_horiz, color: Colors.white)),
                        Expanded(child: _CityPicker(value: destino, label: 'Hacia', onChanged: onDestino)),
                      ],
                    );

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: routeSelector,
              );
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DateChip(label: 'Hoy', selected: esHoy, onTap: onHoy),
              _DateChip(label: 'Mañana', selected: esManana, onTap: onManana),
              _DateChip(
                label: formatearFechaCorta(fecha),
                selected: !esHoy && !esManana,
                onTap: onFecha,
                icon: Icons.calendar_month,
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: loading ? null : onBuscar,
            icon: loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.search),
            label: Text(loading ? 'Buscando…' : 'Buscar salidas'),
            style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primaryDark),
          ),
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
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            dropdownColor: AppColors.primaryDark,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
            icon: const Icon(Icons.expand_more, color: Colors.white70),
            items: ciudadesCorredor.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
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
  const _DateChip({required this.label, required this.selected, required this.onTap, this.icon});

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

class _ViajeTile extends StatelessWidget {
  const _ViajeTile({required this.viaje, this.onTap});

  final ViajeDisponible viaje;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pct = viaje.capacidadTotal > 0 ? (viaje.asientosDisponibles / viaje.capacidadTotal * 100).round() : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  viaje.empresaNombre.isNotEmpty ? viaje.empresaNombre[0] : '?',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(viaje.empresaNombre, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16), overflow: TextOverflow.ellipsis),
                    Text(
                      '${formatearHora(viaje.horaSalida)} · ${formatearCordobas(viaje.tarifa)}',
                      style: TextStyle(color: Colors.grey.shade600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      viaje.asientosDisponibles == 0
                          ? 'Sin cupos'
                          : '$pct% libre · ${viaje.asientosDisponibles} asientos',
                      style: TextStyle(
                        color: viaje.asientosDisponibles == 0 ? Colors.red : AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null) const Icon(Icons.chevron_right, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
