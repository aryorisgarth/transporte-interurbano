import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/auth/jwt_utils.dart';
import '../../core/config/app_config.dart';
import '../../mocks/mock_demo_profile.dart';

class MockModeBanner extends StatelessWidget {
  const MockModeBanner({super.key});

  Future<void> _selectProfile(BuildContext context, MockDemoProfile profile) async {
    final auth = context.read<AuthProvider>();
    if (auth.mockProfile == profile) return;

    await auth.switchMockProfile(profile);
    if (!context.mounted) return;
    context.go(rutaInicio(auth.roles));
  }

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.useMock) return const SizedBox.shrink();

    final auth = context.watch<AuthProvider>();
    final current = auth.mockProfile ?? MockDemoProfile.globalAdmin;
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 720;

    return Material(
      color: Colors.amber.shade200,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Modo demo — datos estáticos (USE_MOCK=true). Perfil: ${current.displayName}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.amber.shade900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (compact)
                DropdownButtonFormField<MockDemoProfile>(
                  value: current,
                  isExpanded: true,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: Colors.amber.shade50,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: MockDemoProfile.values
                      .map(
                        (p) => DropdownMenuItem(
                          value: p,
                          child: Text('${p.label} (${p.code})'),
                        ),
                      )
                      .toList(),
                  onChanged: (p) {
                    if (p != null) _selectProfile(context, p);
                  },
                )
              else
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: MockDemoProfile.values.map((profile) {
                    final selected = profile == current;
                    return FilterChip(
                      label: Text('${profile.label} · ${profile.code}'),
                      selected: selected,
                      onSelected: (_) => _selectProfile(context, profile),
                      selectedColor: Colors.amber.shade400,
                      checkmarkColor: Colors.amber.shade900,
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: Colors.amber.shade900,
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
