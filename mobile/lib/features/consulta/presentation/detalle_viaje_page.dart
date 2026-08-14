import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/transporte_api.dart';
import '../../../core/models/viaje.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formato.dart';
import '../../../shared/layout/responsive.dart';
import '../../../shared/widgets/empresa_avatar.dart';
import '../../../shared/widgets/mapa_ruta.dart';
import '../../../shared/widgets/seat_grid.dart';
import '../../../shared/widgets/section_card.dart';

class DetalleViajePage extends StatefulWidget {
  const DetalleViajePage({super.key, required this.viajeId});

  final int viajeId;

  @override
  State<DetalleViajePage> createState() => _DetalleViajePageState();
}

class _DetalleViajePageState extends State<DetalleViajePage> {
  final _api = TransporteApi();
  bool _loading = true;
  String? _error;
  DetalleViaje? _detalle;
  String? _usd;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
      _usd = null;
    });

    try {
      final data = await _api.detalleViaje(widget.viajeId);
      String? usd;
      try {
        final ref = await _api.tarifaReferenciaUsd(data.tarifa);
        usd = '~ USD ${ref.toStringAsFixed(2)} (referencia)';
      } catch (_) {
        usd = null;
      }
      if (!mounted) return;
      setState(() {
        _detalle = data;
        _usd = usd;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Error de conexión con el servidor');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_error != null || _detalle == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: () => context.go('/consulta'),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Volver a consulta'),
          ),
          const SizedBox(height: 12),
          Text(_error ?? 'Viaje no encontrado', style: TextStyle(color: Colors.red.shade800)),
        ],
      );
    }

    final d = _detalle!;
    final subtitle = [
      d.empresaNombre,
      if (d.busNumeroInterno != null) 'Bus ${d.busNumeroInterno}',
      '${d.fecha} · ${formatearHora(d.horaSalida)}',
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextButton.icon(
          onPressed: () => context.go('/consulta'),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Volver a consulta'),
          style: TextButton.styleFrom(alignment: Alignment.centerLeft),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 520;
            final info = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${d.origen} → ${d.destino}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22),
                ),
                const SizedBox(height: 6),
                Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.85))),
              ],
            );
            final price = Column(
              crossAxisAlignment: stacked ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                Text(
                  formatearCordobas(d.tarifa),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20),
                ),
                if (_usd != null)
                  Text(
                    _usd!,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12),
                  ),
              ],
            );

            return Container(
              padding: EdgeInsets.all(AppBreakpoints.isMobile(context) ? 16 : 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: AppColors.gradientHero),
                borderRadius: BorderRadius.circular(20),
              ),
              child: stacked
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [info, const SizedBox(height: 12), price],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: info),
                        price,
                      ],
                    ),
            );
          },
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EmpresaAvatar(nombre: d.empresaNombre, logoUrl: d.empresaLogoUrl, size: 48),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Equipaje extra: ${formatearCordobas(d.tarifaEquipajeExtra)} por unidad',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  Text(
                    '${d.asientosDisponibles} asiento(s) disponible(s)',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Esta consulta es solo informativa. Para comprar, presente su cédula en la terminal de la '
                  'empresa el día anterior o el mismo día del viaje. No se requiere cuenta de usuario.',
                  style: TextStyle(color: Colors.blueGrey.shade800, height: 1.45, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        if (d.paradas.isNotEmpty) ...[
          const SizedBox(height: 20),
          ResponsiveTwoColumn(
            primary: MapaRuta(paradas: d.paradas, origen: d.origen, destino: d.destino),
            secondary: SectionCard(
              title: 'Mapa de asientos',
              noPadding: true,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final height = AppBreakpoints.isMobile(context) ? 420.0 : 520.0;
                    return SizedBox(
                      height: height,
                      child: SeatGrid(
                        asientos: d.asientos,
                        busNumeroInterno: d.busNumeroInterno,
                        busFotoUrl: d.busFotoUrl,
                      ),
                    );
                  },
                ),
              ),
            ),
            primaryFlex: 5,
            secondaryFlex: 6,
          ),
        ] else ...[
          const SizedBox(height: 20),
          SectionCard(
            title: 'Mapa de asientos',
            noPadding: true,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: AppBreakpoints.isMobile(context) ? 420 : 520,
                child: SeatGrid(
                  asientos: d.asientos,
                  busNumeroInterno: d.busNumeroInterno,
                  busFotoUrl: d.busFotoUrl,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
