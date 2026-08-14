import 'package:flutter/material.dart';

import '../models/viaje.dart';
import '../theme/app_colors.dart';
import '../utils/formato.dart';
import 'app_widgets.dart';

class ViajeCard extends StatelessWidget {
  const ViajeCard({super.key, required this.viaje, this.onTap});

  final ViajeDisponible viaje;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final agotado = viaje.asientosDisponibles == 0;
    final pct = viaje.capacidadTotal > 0 ? viaje.asientosDisponibles / viaje.capacidadTotal : 0.0;
    final ocupacion = ((1 - pct) * 100).round();
    final cuposColor = agotado
        ? AppColors.seatVendido
        : pct < 0.15
            ? AppColors.seatReservado
            : AppColors.seatDisponible;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      color: agotado ? Colors.grey.shade50 : AppColors.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Opacity(
          opacity: agotado ? 0.72 : 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EmpresaAvatar(nombre: viaje.empresaNombre, logoUrl: viaje.empresaLogoUrl),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          viaje.empresaNombre,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatearCordobas(viaje.tarifa),
                          style: const TextStyle(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.schedule, color: AppColors.primary, size: 20),
                        const SizedBox(height: 2),
                        Text(
                          formatearHora(viaje.horaSalida),
                          style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: agotado ? 1 : pct,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade200,
                  color: cuposColor,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      agotado
                          ? 'Sin cupos disponibles'
                          : '${viaje.asientosDisponibles} de ${viaje.capacidadTotal} asientos libres · $ocupacion% ocupado',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ),
                  if (agotado)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.seatVendido.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'AGOTADO',
                        style: TextStyle(
                          color: AppColors.seatVendido,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
              if (!agotado) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.tonalIcon(
                    onPressed: onTap,
                    icon: const Icon(Icons.event_seat_outlined, size: 20),
                    label: const Text('Ver mapa de asientos'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.message, this.icon = Icons.directions_bus_outlined});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      child: Column(
        children: [
          Icon(icon, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 15, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.seatVendido.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.seatVendido),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red.shade900, height: 1.45, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
