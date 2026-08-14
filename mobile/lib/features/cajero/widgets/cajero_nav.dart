import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum CajeroSectionId { viajes, pasajeros, venta }

class CajeroNav extends StatelessWidget {
  const CajeroNav({super.key});

  static CajeroSectionId resolveSection(String path) {
    if (path.startsWith('/cajero/venta')) return CajeroSectionId.venta;
    if (path.startsWith('/cajero/pasajeros')) return CajeroSectionId.pasajeros;
    return CajeroSectionId.viajes;
  }

  static ({String title, String description}) sectionMeta(CajeroSectionId section) {
    switch (section) {
      case CajeroSectionId.venta:
        return (
          title: 'Registrar venta',
          description: 'Seleccione asientos, datos del comprador y confirme.',
        );
      case CajeroSectionId.pasajeros:
        return (
          title: 'Lista de pasajeros',
          description: 'Manifiesto y boletos vendidos del día.',
        );
      case CajeroSectionId.viajes:
        return (
          title: 'Viajes del día',
          description: 'Salidas programadas y venta en mostrador.',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final section = resolveSection(path);

    const items = [
      (id: CajeroSectionId.viajes, label: 'Viajes del día', route: '/cajero', icon: Icons.event_note),
      (id: CajeroSectionId.pasajeros, label: 'Lista de pasajeros', route: '/cajero/pasajeros', icon: Icons.people),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            'TERMINAL',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ),
        ...items.map((item) {
          final active = section == item.id || (item.id == CajeroSectionId.viajes && section == CajeroSectionId.venta);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Material(
              color: active ? Colors.white.withValues(alpha: 0.14) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => context.go(item.route),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: active
                      ? BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border(left: BorderSide(color: const Color(0xFF5EEAD4), width: 3)),
                        )
                      : null,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Icon(
                        item.icon,
                        size: 20,
                        color: active ? const Color(0xFF99F6E4) : Colors.white.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
