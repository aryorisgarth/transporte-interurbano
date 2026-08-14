import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';

class MockModeBanner extends StatelessWidget {
  const MockModeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.useMock) return const SizedBox.shrink();

    return Material(
      color: Colors.amber.shade200,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            'Modo demo — datos estáticos (USE_MOCK=true). Sin backend ni Keycloak.',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.amber.shade900,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
