import 'package:flutter/material.dart';

enum AdminSectionId {
  plataforma,
  perfil,
  buses,
  viajes,
  operadores,
  pasajeros,
  ocupacion,
  ingresos,
  paradas,
}

class AdminNavItem {
  const AdminNavItem({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    this.globalOnly = false,
    this.empresaOnly = false,
  });

  final AdminSectionId id;
  final String label;
  final String description;
  final IconData icon;
  final bool globalOnly;
  final bool empresaOnly;
}

class AdminNavGroup {
  const AdminNavGroup({required this.title, required this.items});

  final String title;
  final List<AdminNavItem> items;
}

List<AdminNavGroup> buildAdminNav(bool esGlobal) {
  final groups = <AdminNavGroup>[];

  if (esGlobal) {
    groups.add(
      const AdminNavGroup(
        title: 'Plataforma',
        items: [
          AdminNavItem(
            id: AdminSectionId.plataforma,
            label: 'Cooperativas',
            description: 'Alta, métricas globales y accesos por tenant.',
            icon: Icons.dashboard,
            globalOnly: true,
          ),
        ],
      ),
    );
  }

  groups.add(
    AdminNavGroup(
      title: esGlobal ? 'Cooperativa seleccionada' : 'Mi cooperativa',
      items: [
        AdminNavItem(
          id: AdminSectionId.perfil,
          label: esGlobal ? 'Perfil y datos' : 'Datos de empresa',
          description: 'Nombre, contacto, tarifas de equipaje y logo.',
          icon: Icons.storefront,
        ),
      ],
    ),
  );

  groups.add(
    const AdminNavGroup(
      title: 'Operación diaria',
      items: [
        AdminNavItem(
          id: AdminSectionId.buses,
          label: 'Flota de buses',
          description: 'Registro de unidades, sede terminal y asientos.',
          icon: Icons.directions_bus,
        ),
        AdminNavItem(
          id: AdminSectionId.viajes,
          label: 'Viajes programados',
          description: 'Salidas Bluefields ↔ Managua por fecha y terminal.',
          icon: Icons.event_note,
        ),
      ],
    ),
  );

  if (!esGlobal) {
    groups.add(
      const AdminNavGroup(
        title: 'Personal',
        items: [
          AdminNavItem(
            id: AdminSectionId.operadores,
            label: 'Operadores',
            description: 'Cajeros y administradores con terminal asignada.',
            icon: Icons.groups,
            empresaOnly: true,
          ),
          AdminNavItem(
            id: AdminSectionId.pasajeros,
            label: 'Pasajeros',
            description: 'Manifiesto y consulta de boletos vendidos.',
            icon: Icons.people,
            empresaOnly: true,
          ),
        ],
      ),
    );
  }

  groups.add(
    const AdminNavGroup(
      title: 'Reportes',
      items: [
        AdminNavItem(
          id: AdminSectionId.ocupacion,
          label: 'Ocupación',
          description: 'Cupos vendidos, reservados y libres por viaje.',
          icon: Icons.pie_chart,
        ),
        AdminNavItem(
          id: AdminSectionId.ingresos,
          label: 'Ingresos',
          description: 'Ventas completadas, desglose por cajero y terminal.',
          icon: Icons.monetization_on,
        ),
      ],
    ),
  );

  groups.add(
    const AdminNavGroup(
      title: 'Configuración',
      items: [
        AdminNavItem(
          id: AdminSectionId.paradas,
          label: 'Ruta y paradas',
          description: 'Paradas del corredor interurbano en el mapa.',
          icon: Icons.map,
        ),
      ],
    ),
  );

  return groups;
}

AdminNavItem? findNavItem(List<AdminNavGroup> groups, AdminSectionId sectionId) {
  for (final g in groups) {
    for (final item in g.items) {
      if (item.id == sectionId) return item;
    }
  }
  return null;
}
