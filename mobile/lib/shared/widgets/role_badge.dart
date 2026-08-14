import 'package:flutter/material.dart';

import '../../core/auth/jwt_utils.dart';

const _roleColors = {
  AppRoles.cajero: Color(0xFF0F766E),
  AppRoles.adminEmpresa: Color(0xFF7C3AED),
  AppRoles.adminGeneral: Color(0xFF0C4A6E),
  AppRoles.reservaExcepcional: Color(0xFFEA580C),
};

class RoleBadge extends StatelessWidget {
  const RoleBadge({
    super.key,
    required this.role,
    this.inverted = false,
  });

  final String role;
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final color = _roleColors[role] ?? Colors.grey;
    final label = roleLabel(role);

    if (inverted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Chip(
      label: Text(label),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      backgroundColor: color.withValues(alpha: 0.12),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }
}
