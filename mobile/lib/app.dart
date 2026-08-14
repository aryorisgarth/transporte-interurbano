import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/auth/auth_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class TransporteApp extends StatelessWidget {
  const TransporteApp({super.key, required this.auth});

  final AuthProvider auth;

  @override
  Widget build(BuildContext context) {
    final router = AppRouter.create(auth);
    return MaterialApp.router(
      title: 'Transporte B–M',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
