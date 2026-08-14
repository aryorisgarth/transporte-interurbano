import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../models/viaje.dart';
import '../services/transporte_api.dart';
import '../theme/app_colors.dart';
import '../utils/formato.dart';
import '../widgets/app_widgets.dart';
import '../widgets/seat_grid.dart';

class DetalleViajeScreen extends StatefulWidget {
  const DetalleViajeScreen({
    super.key,
    required this.viajeId,
    this.apiBaseUrl,
  });

  final int viajeId;
  final String? apiBaseUrl;

  @override
  State<DetalleViajeScreen> createState() => _DetalleViajeScreenState();
}

class _DetalleViajeScreenState extends State<DetalleViajeScreen> {
  late final TransporteApi _api;
  bool _loading = true;
  String? _error;
  DetalleViaje? _detalle;

  @override
  void initState() {
    super.initState();
    _api = TransporteApi(baseUrl: widget.apiBaseUrl ?? ApiConfig.baseUrl);
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _api.detalleViaje(widget.viajeId);
      if (!mounted) return;
      setState(() => _detalle = data);
    } on TransporteApiException catch (e) {
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _cargar)
              : _buildContent(_detalle!),
    );
  }

  Widget _buildContent(DetalleViaje d) {
    final total = d.asientos.length;
    final libres = d.asientosDisponibles;
    final pctLibre = total > 0 ? (libres / total * 100).round() : 0;

    return Column(
      children: [
        GradientHeader(
          title: '${d.origen} → ${d.destino}',
          subtitle: d.empresaNombre,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          bottom: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatChip(icon: Icons.schedule, label: formatearHora(d.horaSalida)),
              StatChip(icon: Icons.calendar_today, label: formatearFechaCorta(d.fecha)),
              StatChip(icon: Icons.event_seat, label: '$libres libres ($pctLibre%)'),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _cargar,
            color: AppColors.primary,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: [
                AppCard(
                  child: Row(
                    children: [
                      EmpresaAvatar(nombre: d.empresaNombre, logoUrl: d.empresaLogoUrl, size: 52),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d.empresaNombre, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                            if (d.busNumeroInterno != null)
                              Text(
                                'Bus ${d.busNumeroInterno}',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              ),
                            const SizedBox(height: 6),
                            Text(
                              formatearCordobas(d.tarifa),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 24,
                              ),
                            ),
                            Text(
                              'Equipaje extra: ${formatearCordobas(d.tarifaEquipajeExtra)}',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.12),
                        AppColors.secondary.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.storefront, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text('Compra en terminal', style: TextStyle(fontWeight: FontWeight.w800)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Este mapa es solo informativo. Para comprar, acérquese a la ventanilla de ${d.empresaNombre} con su cédula.',
                        style: TextStyle(color: Colors.blueGrey.shade800, height: 1.45, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Mapa de asientos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                _SeatLegend(),
                const SizedBox(height: 12),
                SeatGrid(asientos: d.asientos, busNumeroInterno: d.busNumeroInterno),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SeatLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget item(Color c, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 14, height: 14, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(4))),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          ],
        );

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        item(AppColors.seatDisponible, 'Disponible'),
        item(AppColors.seatVendido, 'Vendido'),
        item(AppColors.seatReservado, 'Reservado'),
        item(AppColors.seatCancelado, 'Cancelado'),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 56, color: AppColors.seatVendido),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
