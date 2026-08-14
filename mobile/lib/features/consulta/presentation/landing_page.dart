import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  static const _roles = [
    _RoleCard(
      icon: Icons.search,
      color: Color(0xFF0369A1),
      title: 'Pasajero',
      desc: 'Consulta horarios y cupos sin cuenta. La compra es presencial en terminal.',
      route: '/consulta',
      label: 'Consultar viajes',
    ),
    _RoleCard(
      icon: Icons.storefront,
      color: AppColors.primary,
      title: 'Cajero',
      desc: 'Venta en mostrador, terminal fija, manifiesto de su sede.',
      route: '/acceso/login?from=/cajero',
      label: 'Entrar como cajero',
    ),
    _RoleCard(
      icon: Icons.business,
      color: Color(0xFF7C3AED),
      title: 'Admin empresa',
      desc: 'Flota, viajes, operadores y reportes de su cooperativa.',
      route: '/acceso/login?from=/admin',
      label: 'Entrar como admin',
    ),
    _RoleCard(
      icon: Icons.hub,
      color: AppColors.primaryDark,
      title: 'Plataforma',
      desc: 'Multi-tenant: cooperativas, admins de empresa y métricas globales.',
      route: '/acceso/login?from=/admin',
      label: 'Admin global',
    ),
  ];

  static const _empresas = [
    ('Wendelyn Transporte', 'WT'),
    ('Martínez Líneas', 'ML'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 640;
            final heroContent = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bluefields ↔ Managua',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 28),
                ),
                const SizedBox(height: 8),
                Text(
                  'Plataforma multi-cooperativa: consulta pública, venta en terminal y administración por roles.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 15),
                ),
              ],
            );
            final heroButton = FilledButton.icon(
              onPressed: () => context.go('/consulta'),
              icon: const Icon(Icons.search),
              label: const Text('Consultar ahora'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryDark,
              ),
            );

            return Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: AppColors.gradientHero),
                borderRadius: BorderRadius.circular(20),
              ),
              child: stacked
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        heroContent,
                        const SizedBox(height: 16),
                        heroButton,
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: heroContent),
                        const SizedBox(width: 16),
                        heroButton,
                      ],
                    ),
            );
          },
        ),
        const SizedBox(height: 28),
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth > 900 ? 4 : constraints.maxWidth > 600 ? 2 : 1;
            return GridView.count(
              crossAxisCount: cols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: cols == 1 ? 2.2 : 0.85,
              children: _roles.map((r) => _RoleCardWidget(card: r)).toList(),
            );
          },
        ),
        const SizedBox(height: 32),
        const Text('Cooperativas en la ruta', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
        const SizedBox(height: 12),
        ..._empresas.map(
          (e) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Text(e.$2, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
              title: Text(e.$1, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Corredor interurbano · datos aislados por tenant'),
            ),
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 560;
            final copy = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¿Personal de terminal o administración?',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 17),
                ),
                Text(
                  'Inicie sesión con su usuario asignado.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                ),
              ],
            );
            final loginBtn = OutlinedButton.icon(
              onPressed: () => context.go('/acceso/login'),
              icon: const Icon(Icons.login, color: Colors.white),
              label: const Text('Iniciar sesión', style: TextStyle(color: Colors.white)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
              ),
            );

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: AppColors.gradientHero),
                borderRadius: BorderRadius.circular(16),
              ),
              child: stacked
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [copy, const SizedBox(height: 12), loginBtn],
                    )
                  : Row(
                      children: [
                        Expanded(child: copy),
                        loginBtn,
                      ],
                    ),
            );
          },
        ),
      ],
      ),
    );
  }
}

class _RoleCard {
  const _RoleCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.desc,
    required this.route,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String desc;
  final String route;
  final String label;
}

class _RoleCardWidget extends StatelessWidget {
  const _RoleCardWidget({required this.card});

  final _RoleCard card;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(card.icon, size: 36, color: card.color),
            const SizedBox(height: 12),
            Text(card.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
            const SizedBox(height: 8),
            Expanded(
              child: Text(card.desc, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            ),
            TextButton.icon(
              onPressed: () => context.go(card.route),
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: Text(card.label, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}
