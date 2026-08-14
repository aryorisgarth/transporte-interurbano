import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/role_badge.dart';
import '../widgets/mock_mode_banner.dart';

class OperativeShellLink {
  const OperativeShellLink({required this.label, required this.to});

  final String label;
  final String to;
}

class OperativeShell extends StatefulWidget {
  const OperativeShell({
    super.key,
    required this.brandSubtitle,
    required this.role,
    required this.title,
    required this.nav,
    required this.child,
    this.description,
    this.sidebarFooter,
    this.topBarExtra,
    this.footerLinks = const [OperativeShellLink(label: 'Consulta pública', to: '/consulta')],
    this.scrollContent = true,
    this.fillHeight = false,
  });

  final String brandSubtitle;
  final String role;
  final String title;
  final String? description;
  final Widget nav;
  final Widget? sidebarFooter;
  final Widget? topBarExtra;
  final List<OperativeShellLink> footerLinks;
  final bool scrollContent;
  final bool fillHeight;
  final Widget child;

  @override
  State<OperativeShell> createState() => _OperativeShellState();
}

class _OperativeShellState extends State<OperativeShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  Widget _buildSidebar(BuildContext context, {bool drawer = false}) {
    final auth = context.watch<AuthProvider>();
    final username = auth.username ?? 'U';
    final initial = username.isNotEmpty ? username[0].toUpperCase() : 'U';

    return Container(
      color: AppColors.primaryDark,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.directions_bus_filled, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Transporte B–M',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                        Text(
                          widget.brandSubtitle,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  if (drawer)
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                ],
              ),
            ),
            Expanded(child: SingleChildScrollView(child: widget.nav)),
            if (widget.sidebarFooter != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: widget.sidebarFooter,
              ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              username,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                            RoleBadge(role: widget.role, inverted: true),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      ...widget.footerLinks.map(
                        (link) => InkWell(
                          onTap: () {
                            if (drawer) Navigator.of(context).pop();
                            context.go(link.to);
                          },
                          child: Text(
                            link.label,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () async {
                          await auth.logout();
                          if (context.mounted) context.go('/acceso/login');
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.logout, size: 14, color: Colors.white.withValues(alpha: 0.7)),
                            const SizedBox(width: 4),
                            Text(
                              'Salir',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final mobile = width < 900;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: mobile
          ? Drawer(
              width: 280,
              child: _buildSidebar(context, drawer: true),
            )
          : null,
      body: Row(
        children: [
          if (!mobile)
            SizedBox(
              width: 260,
              child: _buildSidebar(context),
            ),
          Expanded(
            child: Column(
              children: [
                const MockModeBanner(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: LayoutBuilder(
                    builder: (context, barConstraints) {
                      final stackExtra = widget.topBarExtra != null && barConstraints.maxWidth < 960;
                      final titleBlock = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.description != null)
                            Text(
                              widget.description!,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                        ],
                      );

                      if (stackExtra) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (mobile)
                                  IconButton(
                                    icon: const Icon(Icons.menu),
                                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                                  ),
                                Expanded(child: titleBlock),
                              ],
                            ),
                            const SizedBox(height: 8),
                            widget.topBarExtra!,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (mobile)
                            IconButton(
                              icon: const Icon(Icons.menu),
                              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                            ),
                          Expanded(child: titleBlock),
                          if (widget.topBarExtra != null)
                            Flexible(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: widget.topBarExtra!,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                Expanded(
                  child: widget.scrollContent
                      ? SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: widget.child,
                        )
                      : Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          child: widget.fillHeight
                              ? SizedBox.expand(child: widget.child)
                              : widget.child,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
