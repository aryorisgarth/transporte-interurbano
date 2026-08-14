import 'package:flutter/material.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/transporte_api.dart';
import '../../../core/auth/jwt_utils.dart';
import '../../../core/models/empresa.dart';
import '../../../core/theme/app_colors.dart';
import '../presentation/sections/admin_perfil_section.dart';

const _avatarPalette = [
  Color(0xFF0F766E),
  Color(0xFF0C4A6E),
  Color(0xFF7C3AED),
  Color(0xFF0369A1),
  Color(0xFFC2410C),
  Color(0xFFBE123C),
];

const _etiquetasRol = {
  'CAJERO': 'Cajero',
  'ADMIN_EMPRESA': 'Admin empresa',
  'RESERVA_EXCEPCIONAL': 'Reserva excepcional',
};

String _iniciales(String nombre) {
  final partes = nombre.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (partes.isEmpty) return '?';
  if (partes.length == 1) return partes[0].substring(0, partes[0].length >= 2 ? 2 : 1).toUpperCase();
  return (partes[0][0] + partes[1][0]).toUpperCase();
}

bool _esAdminEmpresa(List<dynamic> roles) => roles.map((r) => r.toString()).contains(AppRoles.adminEmpresa);

class CooperativaDetallePanel extends StatefulWidget {
  const CooperativaDetallePanel({
    super.key,
    required this.token,
    required this.empresaId,
    this.embedded = false,
    this.onEmpresaActualizada,
    this.onRecargarLista,
    this.onDesactivar,
    this.canDesactivar = true,
    this.onAsignarAdmin,
    this.sinAdmin = false,
  });

  final String token;
  final int empresaId;
  final bool embedded;
  final ValueChanged<Empresa>? onEmpresaActualizada;
  final VoidCallback? onRecargarLista;
  final VoidCallback? onDesactivar;
  final bool canDesactivar;
  final VoidCallback? onAsignarAdmin;
  final bool sinAdmin;

  @override
  State<CooperativaDetallePanel> createState() => _CooperativaDetallePanelState();
}

class _CooperativaDetallePanelState extends State<CooperativaDetallePanel> with SingleTickerProviderStateMixin {
  final _api = TransporteApi();
  late TabController _tabCtrl;

  DetalleCooperativa? _detalle;
  bool _loading = true;
  String? _msg;
  bool _msgError = false;

  final _adminUsuarioCtrl = TextEditingController();
  final _adminNombreCtrl = TextEditingController();
  final _adminEmailCtrl = TextEditingController();
  final _adminPasswordCtrl = TextEditingController(text: 'password');
  bool _creandoAdmin = false;

  final _editNombreCtrl = TextEditingController();
  bool _editActivo = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _cargar();
  }

  @override
  void didUpdateWidget(covariant CooperativaDetallePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.empresaId != widget.empresaId) _cargar();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _adminUsuarioCtrl.dispose();
    _adminNombreCtrl.dispose();
    _adminEmailCtrl.dispose();
    _adminPasswordCtrl.dispose();
    _editNombreCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _loading = true);
    try {
      final d = await _api.detalleCooperativa(widget.token, widget.empresaId);
      if (!mounted) return;
      setState(() {
        _detalle = d;
        _msg = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _detalle = null;
        _msg = e.message;
        _msgError = true;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _setMsg(String text, {bool error = false}) {
    setState(() {
      _msg = text;
      _msgError = error;
    });
  }

  Future<void> _crearAdmin() async {
    setState(() => _creandoAdmin = true);
    try {
      await _api.crearOperador(widget.token, {
        'empresaId': widget.empresaId,
        'nombreUsuario': _adminUsuarioCtrl.text.trim().toLowerCase(),
        'nombreCompleto': _adminNombreCtrl.text.trim(),
        'password': _adminPasswordCtrl.text,
        'roles': [AppRoles.adminEmpresa],
        if (_adminEmailCtrl.text.trim().isNotEmpty) 'email': _adminEmailCtrl.text.trim(),
      });
      _setMsg('Administrador «${_adminUsuarioCtrl.text.trim()}» creado correctamente.');
      _adminUsuarioCtrl.clear();
      _adminNombreCtrl.clear();
      _adminEmailCtrl.clear();
      _adminPasswordCtrl.text = 'password';
      await _cargar();
      widget.onRecargarLista?.call();
    } on ApiException catch (e) {
      _setMsg(e.message, error: true);
    } finally {
      if (mounted) setState(() => _creandoAdmin = false);
    }
  }

  Future<void> _abrirEditar(Map<String, dynamic> op) async {
    if (!_esAdminEmpresa(op['roles'] as List? ?? [])) return;
    _editNombreCtrl.text = op['nombreCompleto'] as String? ?? '';
    _editActivo = op['activo'] as bool? ?? true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Editar administrador'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Login: ${op['nombreUsuario']}', style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 12),
                TextField(controller: _editNombreCtrl, decoration: const InputDecoration(labelText: 'Nombre completo *')),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FilterChip(
                      label: Text(_editActivo ? 'Activo' : 'Inactivo'),
                      selected: _editActivo,
                      onSelected: (_) => setDlg(() => _editActivo = !_editActivo),
                      selectedColor: Colors.green.shade100,
                    ),
                    Text('Clic para cambiar estado', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar')),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;

    try {
      await _api.actualizarOperador(widget.token, op['id'] as int, {
        'nombreCompleto': _editNombreCtrl.text.trim(),
        'activo': _editActivo,
      });
      _setMsg('Administrador actualizado');
      await _cargar();
      widget.onRecargarLista?.call();
    } on ApiException catch (e) {
      _setMsg(e.message, error: true);
    }
  }

  Future<void> _confirmarEliminar(Map<String, dynamic> op) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desactivar administrador'),
        content: Text('¿Desactivar ${op['nombreUsuario']}? No podrá iniciar sesión.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    try {
      await _api.actualizarOperador(widget.token, op['id'] as int, {'activo': false});
      _setMsg('Administrador desactivado');
      await _cargar();
      widget.onRecargarLista?.call();
    } on ApiException catch (e) {
      _setMsg(e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }
    if (_detalle == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
        child: Text(_msg ?? 'No se pudo cargar la cooperativa', style: TextStyle(color: Colors.red.shade800)),
      );
    }

    final detalle = _detalle!;
    final empresa = detalle.empresa;
    final avatarBg = _avatarPalette[empresa.id % _avatarPalette.length];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(empresa, detalle.metricas, avatarBg),
        const SizedBox(height: 16),
        if (_msg != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _msgError ? Colors.red.shade50 : Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(child: Text(_msg!, style: TextStyle(color: _msgError ? Colors.red.shade800 : Colors.green.shade800))),
                IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => setState(() => _msg = null)),
              ],
            ),
          ),
        TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.primary,
          indicatorColor: AppColors.primary,
          tabs: [
            const Tab(text: 'Accesos', icon: Icon(Icons.groups_outlined, size: 18)),
            const Tab(text: 'Datos comerciales', icon: Icon(Icons.storefront_outlined, size: 18)),
            Tab(text: 'Flota (${detalle.buses.length})', icon: const Icon(Icons.directions_bus_outlined, size: 18)),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 480,
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              SingleChildScrollView(child: _tabAccesos(detalle.operadores)),
              SingleChildScrollView(
                child: AdminPerfilSection(
                  token: widget.token,
                  empresaId: widget.empresaId,
                  esGlobal: true,
                  onActualizado: (e) {
                    widget.onEmpresaActualizada?.call(e);
                    _cargar();
                  },
                ),
              ),
              SingleChildScrollView(child: _tabFlota(detalle.buses)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _header(Empresa empresa, Map<String, int> metricas, Color avatarBg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: avatarBg,
              child: Text(_iniciales(empresa.nombre), style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(empresa.nombre, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                      Chip(
                        label: Text(widget.sinAdmin ? 'Sin administrador' : 'Activa', style: const TextStyle(fontSize: 11)),
                        backgroundColor: widget.sinAdmin ? Colors.orange.shade50 : Colors.green.shade50,
                        side: BorderSide(color: widget.sinAdmin ? Colors.orange : Colors.green),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 16,
                    runSpacing: 4,
                    children: [
                      if (empresa.correo != null)
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.email_outlined, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(empresa.correo!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ]),
                      if (empresa.telefono != null)
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.phone_outlined, size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(empresa.telefono!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ]),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.luggage_outlined, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text('Equipaje C\$ ${empresa.tarifaEquipajeExtra.toStringAsFixed(0)}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ]),
                    ],
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 8,
              children: [
                if (widget.sinAdmin && widget.onAsignarAdmin != null)
                  FilledButton.icon(
                    onPressed: widget.onAsignarAdmin,
                    icon: const Icon(Icons.person_add_outlined, size: 18),
                    label: const Text('Asignar admin'),
                    style: FilledButton.styleFrom(backgroundColor: Colors.orange),
                  ),
                if (widget.onDesactivar != null)
                  OutlinedButton.icon(
                    onPressed: widget.canDesactivar ? widget.onDesactivar : null,
                    icon: const Icon(Icons.block_outlined, size: 18),
                    label: const Text('Desactivar'),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _metricBadge('Buses', metricas['busesActivos'] ?? 0),
            _metricBadge('Admins', metricas['adminsActivos'] ?? 0),
            _metricBadge('Cajeros', metricas['cajerosActivos'] ?? 0),
            _metricBadge('Viajes hoy', metricas['viajesHoy'] ?? 0),
            _metricBadge('Boletos hoy', metricas['boletosVendidosHoy'] ?? 0),
          ],
        ),
      ],
    );
  }

  Widget _metricBadge(String label, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$value', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20, height: 1)),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _tabAccesos(List<Map<String, dynamic>> operadores) {
    final cajeros = operadores.where((o) {
      final roles = (o['roles'] as List? ?? []).map((r) => r.toString()).toList();
      return roles.contains(AppRoles.cajero) && !roles.contains(AppRoles.adminEmpresa);
    }).length;

    return LayoutBuilder(
      builder: (context, c) {
        final row = c.maxWidth > 700;
        return row
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 280, child: _formNuevoAdmin()),
                  const SizedBox(width: 16),
                  Expanded(child: _tablaOperadores(operadores, cajeros)),
                ],
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    _formNuevoAdmin(),
                    const SizedBox(height: 16),
                    _tablaOperadores(operadores, cajeros),
                  ],
                ),
              );
      },
    );
  }

  Widget _formNuevoAdmin() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Nuevo administrador', style: TextStyle(fontWeight: FontWeight.w700)),
            Text('Crea cuentas ADMIN_EMPRESA. Los cajeros los gestiona el admin de la cooperativa.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            TextField(controller: _adminUsuarioCtrl, decoration: const InputDecoration(labelText: 'Usuario de login *', isDense: true)),
            const SizedBox(height: 8),
            TextField(controller: _adminNombreCtrl, decoration: const InputDecoration(labelText: 'Nombre completo *', isDense: true)),
            const SizedBox(height: 8),
            TextField(controller: _adminEmailCtrl, decoration: const InputDecoration(labelText: 'Email Keycloak', isDense: true)),
            const SizedBox(height: 8),
            TextField(
              controller: _adminPasswordCtrl,
              decoration: const InputDecoration(labelText: 'Contraseña inicial *', isDense: true),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _creandoAdmin ? null : _crearAdmin,
              icon: _creandoAdmin
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.person_add_outlined),
              label: Text(_creandoAdmin ? 'Creando…' : 'Crear administrador'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tablaOperadores(List<Map<String, dynamic>> operadores, int cajeros) {
    if (operadores.isEmpty) {
      return Center(child: Text('Sin operadores registrados', style: TextStyle(color: Colors.grey.shade600)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 40,
            dataRowMinHeight: 44,
            columns: const [
              DataColumn(label: Text('Nombre')),
              DataColumn(label: Text('Usuario login')),
              DataColumn(label: Text('Email Keycloak')),
              DataColumn(label: Text('Rol / Terminal')),
              DataColumn(label: Text('Acciones')),
            ],
            rows: operadores.map((op) {
              final roles = (op['roles'] as List? ?? []).map((r) => r.toString()).toList();
              final activo = op['activo'] as bool? ?? true;
              final esAdmin = _esAdminEmpresa(roles);
              return DataRow(
                color: activo ? null : WidgetStateProperty.all(Colors.grey.shade50),
                cells: [
                  DataCell(Text(op['nombreCompleto'] as String? ?? '')),
                  DataCell(Text(op['nombreUsuario'] as String? ?? '', style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600))),
                  DataCell(Text(op['emailLogin'] as String? ?? '—', style: TextStyle(color: Colors.grey.shade600, fontSize: 12))),
                  DataCell(Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      ...roles.map((r) => Chip(
                            label: Text(_etiquetasRol[r] ?? r, style: const TextStyle(fontSize: 10)),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          )),
                      if (op['sede'] != null)
                        Chip(
                          label: Text(op['sede'] as String, style: const TextStyle(fontSize: 10)),
                          visualDensity: VisualDensity.compact,
                          side: const BorderSide(color: Colors.grey),
                        ),
                      if (!activo)
                        Chip(
                          label: const Text('Inactivo', style: TextStyle(fontSize: 10)),
                          backgroundColor: Colors.orange.shade50,
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  )),
                  DataCell(esAdmin
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _abrirEditar(op)),
                            if (activo)
                              IconButton(
                                icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade700),
                                onPressed: () => _confirmarEliminar(op),
                              ),
                          ],
                        )
                      : Text('Solo lectura', style: TextStyle(fontSize: 11, color: Colors.grey.shade600))),
                ],
              );
            }).toList(),
          ),
        ),
        if (cajeros > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('$cajeros cajero(s) gestionados por el admin de empresa.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ),
      ],
    );
  }

  Widget _tabFlota(List<Map<String, dynamic>> buses) {
    if (buses.isEmpty) {
      return Center(child: Text('Sin buses registrados', style: TextStyle(color: Colors.grey.shade600)));
    }
    return SingleChildScrollView(
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Número')),
          DataColumn(label: Text('Placa')),
          DataColumn(label: Text('Terminal base')),
          DataColumn(label: Text('Capacidad')),
          DataColumn(label: Text('Estado')),
        ],
        rows: buses.map((b) {
          final activo = b['activo'] as bool? ?? true;
          return DataRow(cells: [
            DataCell(Text(b['numeroInterno'] as String? ?? '')),
            DataCell(Text(b['placa'] as String? ?? '')),
            DataCell(Text(b['sede'] as String? ?? '')),
            DataCell(Text('${b['capacidad'] ?? ''}')),
            DataCell(Chip(
              label: Text(activo ? 'Activo' : 'Inactivo', style: const TextStyle(fontSize: 11)),
              backgroundColor: activo ? Colors.green.shade50 : Colors.grey.shade100,
              visualDensity: VisualDensity.compact,
            )),
          ]);
        }).toList(),
      ),
    );
  }

}
