import 'package:flutter/material.dart';

/// Paleta alineada con React web (teal interurbano).
abstract final class AppColors {
  static const primary = Color(0xFF0F766E);
  static const primaryLight = Color(0xFF14B8A6);
  static const primaryDark = Color(0xFF0C4A6E);
  static const secondary = Color(0xFF0369A1);
  static const yutong = Color(0xFF003087);
  static const background = Color(0xFFF0F4F8);
  static const surface = Color(0xFFFFFFFF);

  static const seatDisponible = Color(0xFF16A34A);
  static const seatVendido = Color(0xFFDC2626);
  static const seatCancelado = Color(0xFF94A3B8);
  static const seatReservado = Color(0xFFEA580C);

  static const gradientHero = [
    Color(0xFF0C4A6E),
    Color(0xFF0F766E),
    Color(0xFF134E4A),
  ];

  static const cardShadow = BoxShadow(
    color: Color(0x140F172A),
    blurRadius: 20,
    offset: Offset(0, 4),
  );
}
