import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class EmpresaAvatar extends StatelessWidget {
  const EmpresaAvatar({
    super.key,
    required this.nombre,
    this.logoUrl,
    this.size = 40,
  });

  final String nombre;
  final String? logoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = nombre.isNotEmpty ? nombre[0].toUpperCase() : '?';

    if (logoUrl != null && logoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: AppColors.primary.withValues(alpha: 0.12),
        backgroundImage: NetworkImage(logoUrl!),
        onBackgroundImageError: (_, __) {},
        child: Text(
          initial,
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
            fontSize: size * 0.4,
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
      child: Text(
        initial,
        style: TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.4,
        ),
      ),
    );
  }
}
