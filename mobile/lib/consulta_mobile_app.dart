import 'package:flutter/material.dart';

import 'screens/consulta_screen.dart';
import 'theme/app_theme.dart';

/// App móvil (Android/iOS): solo consulta pública para pasajeros.
/// Admin, cajero y login están en Flutter Web o React.
class ConsultaMobileApp extends StatelessWidget {
  const ConsultaMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Transporte B–M',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const ConsultaScreen(),
    );
  }
}
