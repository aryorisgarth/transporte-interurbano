import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/auth/jwt_utils.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/role_badge.dart';

class PublicScaffold extends StatelessWidget {
  const PublicScaffold({super.key, required this.child});

  final Widget child;

  String _homeRoute(AuthProvider auth) {
    if (!auth.isAuthenticated) return '/';
    if (isAdmin(auth.roles)) return '/admin';
    if (puedeUsarPanelCajero(auth.roles)) return '/cajero';
    return '/';
  }

  String _roleBadgeKey(List<String> roles) {
    if (roles.contains(AppRoles.adminGeneral)) return AppRoles.adminGeneral;
    if (roles.contains(AppRoles.adminEmpresa)) return AppRoles.adminEmpresa;
    return AppRoles.cajero;
  }

  Widget _loginButton(BuildContext context, {bool compact = false}) {
    return FilledButton.icon(
      onPressed: () => context.go('/acceso/login'),
      icon: Icon(Icons.login, size: compact ? 16 : 18),
      label: Text(compact ? 'Acceso' : 'Acceso personal'),
      style: FilledButton.styleFrom(
        visualDensity: compact ? VisualDensity.compact : null,
        backgroundColor: Colors.white.withValues(alpha: 0.95),
        foregroundColor: AppColors.primaryDark,
      ),
    );
  }

  Widget _authTrailing(BuildContext context, AuthProvider auth, {required bool compact}) {
    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RoleBadge(role: _roleBadgeKey(auth.roles), inverted: true),
          IconButton(
            tooltip: 'Salir',
            onPressed: () async {
              await auth.logout();
              if (context.mounted) context.go('/');
            },
            icon: const Icon(Icons.logout, color: Colors.white, size: 20),
          ),
        ],
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        RoleBadge(role: _roleBadgeKey(auth.roles), inverted: true),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 140),
          child: Chip(
            avatar: CircleAvatar(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: Text(
                (auth.username ?? 'U')[0].toUpperCase(),
                style: const TextStyle(fontSize: 11, color: Colors.white),
              ),
            ),
            label: Text(
              auth.username ?? '',
              style: const TextStyle(color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
            backgroundColor: Colors.white.withValues(alpha: 0.15),
            side: BorderSide.none,
            visualDensity: VisualDensity.compact,
          ),
        ),
        TextButton.icon(
          onPressed: () async {
            await auth.logout();
            if (context.mounted) context.go('/');
          },
          icon: const Icon(Icons.logout, color: Colors.white, size: 18),
          label: const Text('Salir', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  List<Widget> _navButtons(BuildContext context, String path, AuthProvider auth, bool panelAdmin, bool panelCajero) {
    if (!auth.isAuthenticated) {
      return [
        _NavButton(label: 'Inicio', active: path == '/', onTap: () => context.go('/')),
        _NavButton(
          label: 'Consultar viajes',
          active: path.startsWith('/consulta'),
          onTap: () => context.go('/consulta'),
        ),
      ];
    }
    if (panelCajero) {
      return [
        _NavButton(
          label: 'Mi terminal',
          active: path.startsWith('/cajero'),
          onTap: () => context.go('/cajero'),
        ),
        _NavButton(
          label: 'Horarios públicos',
          active: path.startsWith('/consulta'),
          onTap: () => context.go('/consulta'),
          muted: true,
        ),
      ];
    }
    if (panelAdmin && !panelCajero) {
      return [
        _NavButton(
          label: esAdminGlobal(auth.roles) ? 'Plataforma' : 'Mi cooperativa',
          active: path.startsWith('/admin'),
          onTap: () => context.go('/admin'),
        ),
        _NavButton(
          label: 'Consulta pública',
          active: path.startsWith('/consulta'),
          onTap: () => context.go('/consulta'),
          muted: true,
        ),
      ];
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final path = GoRouterState.of(context).uri.path;
    final panelAdmin = isAdmin(auth.roles);
    final panelCajero = puedeUsarPanelCajero(auth.roles);
    final nav = _navButtons(context, path, auth, panelAdmin, panelCajero);
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 640;

    return Scaffold(
      body: Column(
        children: [
          Material(
            color: AppColors.primary,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(Icons.directions_bus_filled, color: Colors.white, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () => context.go(_homeRoute(auth)),
                            child: const Text(
                              'Transporte B–M',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: auth.isAuthenticated
                                ? _authTrailing(context, auth, compact: compact)
                                : _loginButton(context, compact: compact),
                          ),
                        ),
                      ],
                    ),
                    if (nav.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: nav,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          if (!auth.isAuthenticated && (path == '/' || path.startsWith('/consulta')))
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: AppColors.primary,
              child: Text(
                'Pasajeros: consulte horarios sin cuenta · Personal: use Acceso personal',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.sizeOf(context).height - 120,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                Text(
                  'Sistema de Gestión de Transporte Interurbano · Bluefields – Managua',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Multi-tenant · Venta en terminal · Demo académica',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.label,
    required this.active,
    required this.onTap,
    this.muted = false,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: active ? Colors.white.withValues(alpha: 0.16) : Colors.transparent,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          color: Colors.white.withValues(alpha: active ? 1 : muted ? 0.72 : 0.88),
        ),
      ),
    );
  }
}
