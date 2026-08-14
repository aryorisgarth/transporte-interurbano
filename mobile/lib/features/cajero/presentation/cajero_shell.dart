import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/api/transporte_api.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/auth/jwt_utils.dart';
import '../../../core/utils/terminal_cajero.dart';
import '../../../shared/layout/operative_shell.dart';
import '../widgets/cajero_nav.dart';

class CajeroPerfil {
  const CajeroPerfil({
    required this.nombreCompleto,
    this.empresaNombre,
    this.empresaId,
    this.sede,
  });

  final String nombreCompleto;
  final String? empresaNombre;
  final int? empresaId;
  final String? sede;
}

class CajeroShell extends StatefulWidget {
  const CajeroShell({super.key, required this.child});

  final Widget child;

  @override
  State<CajeroShell> createState() => _CajeroShellState();
}

class _CajeroShellState extends State<CajeroShell> {
  CajeroPerfil? _perfil;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPerfil();
  }

  Future<void> _loadPerfil() async {
    final token = context.read<AuthProvider>().token;
    if (token == null) return;
    try {
      final p = await TransporteApi().obtenerPerfil(token);
      if (!mounted) return;
      setState(() {
        _perfil = CajeroPerfil(
          nombreCompleto: p.nombreCompleto,
          empresaNombre: p.empresaNombre,
          empresaId: p.empresaId,
          sede: p.sede,
        );
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _perfil == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final path = GoRouterState.of(context).uri.path;
    final section = CajeroNav.resolveSection(path);
    final meta = CajeroNav.sectionMeta(section);
    final auth = context.watch<AuthProvider>();
    final terminal = resolverTerminalCajero(sede: _perfil?.sede, username: auth.username);

    final description = section == CajeroSectionId.venta
        ? meta.description
        : [
            _perfil?.nombreCompleto,
            _perfil?.empresaNombre,
            if (terminal != null) 'Terminal $terminal',
          ].whereType<String>().where((s) => s.isNotEmpty).join(' · ').ifEmpty(meta.description);

    return OperativeShell(
      brandSubtitle: 'Terminal · venta en mostrador',
      role: AppRoles.cajero,
      title: meta.title,
      description: description,
      nav: const CajeroNav(),
      scrollContent: section != CajeroSectionId.venta,
      fillHeight: section == CajeroSectionId.venta,
      sidebarFooter: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'TERMINAL ASIGNADA',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: terminal != null
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.amber.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: terminal != null
                    ? Colors.white.withValues(alpha: 0.22)
                    : Colors.amber.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  etiquetaTerminal(terminal),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                ),
                if (terminal == null)
                  Text(
                    'Contacte al administrador de su cooperativa.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 11),
                  ),
              ],
            ),
          ),
        ],
      ),
      child: CajeroScope(perfil: _perfil, terminal: terminal, child: widget.child),
    );
  }
}

class CajeroScope extends InheritedWidget {
  const CajeroScope({super.key, required this.perfil, this.terminal, required super.child});

  final CajeroPerfil? perfil;
  final String? terminal;

  static CajeroPerfil? perfilOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CajeroScope>()?.perfil;
  }

  static String? terminalOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CajeroScope>()?.terminal;
  }

  @override
  bool updateShouldNotify(CajeroScope oldWidget) =>
      perfil != oldWidget.perfil || terminal != oldWidget.terminal;
}

extension _StringExt on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
