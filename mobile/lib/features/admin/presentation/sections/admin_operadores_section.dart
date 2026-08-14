import 'package:flutter/material.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/transporte_api.dart';
import '../../../../core/auth/jwt_utils.dart';
import '../../../../core/models/usuario.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/corredor.dart';
import '../../../../shared/widgets/section_card.dart';

const _etiquetasRol = {
  'CAJERO': 'Cajero',
  'ADMIN_EMPRESA': 'Admin empresa',
  'RESERVA_EXCEPCIONAL': 'Reserva excepcional',
  'ADMIN_GENERAL': 'Admin plataforma',
};

class AdminOperadoresSection extends StatefulWidget {
  const AdminOperadoresSection({super.key, required this.token, required this.empresaId});

  final String token;
  final int empresaId;

  @override
  State<AdminOperadoresSection> createState() => _AdminOperadoresSectionState();
}

class _AdminOperadoresSectionState extends State<AdminOperadoresSection> {
  final _api = TransporteApi();
  List<UsuarioPerfil> _operadores = [];
  bool _loading = true;
  String? _msg;
  bool _msgError = false;

  final _usuarioCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController(text: 'password');
  bool _esAdmin = false;
  bool _reservaExcepcional = false;
  String _sede = ciudadesCorredor.first;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _usuarioCtrl.dispose();
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _msg = null;
    });
    try {
      final list = await _api.listarOperadores(widget.token, empresaId: widget.empresaId);
      if (!mounted) return;
      setState(() => _operadores = list);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
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

  Future<void> _crear() async {
    setState(() => _saving = true);
    final roles = [_esAdmin ? AppRoles.adminEmpresa : AppRoles.cajero];
    if (_reservaExcepcional) roles.add(AppRoles.reservaExcepcional);
    try {
      await _api.crearOperador(widget.token, {
        'empresaId': widget.empresaId,
        'nombreUsuario': _usuarioCtrl.text.trim().toLowerCase(),
        'nombreCompleto': _nombreCtrl.text.trim(),
        'password': _passwordCtrl.text,
        'roles': roles,
        if (_emailCtrl.text.trim().isNotEmpty) 'email': _emailCtrl.text.trim(),
        if (!_esAdmin) 'sede': _sede,
      });
      _setMsg('Operador creado. Ya puede iniciar sesión con Keycloak.');
      _usuarioCtrl.clear();
      _nombreCtrl.clear();
      _emailCtrl.clear();
      _passwordCtrl.text = 'password';
      setState(() {
        _esAdmin = false;
        _reservaExcepcional = false;
      });
      await _cargar();
    } on ApiException catch (e) {
      _setMsg(e.message, error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggleActivo(UsuarioPerfil op) async {
    try {
      await _api.actualizarOperador(widget.token, op.id, {'activo': !(op.activo ?? true)});
      await _cargar();
      _setMsg((op.activo ?? true) ? 'Operador desactivado' : 'Operador activado');
    } on ApiException catch (e) {
      _setMsg(e.message, error: true);
    }
  }

  bool _esCajeroPuro(UsuarioPerfil op) =>
      op.roles.contains(AppRoles.cajero) && !op.roles.contains(AppRoles.adminEmpresa);

  Future<void> _abrirEditar(UsuarioPerfil op) async {
    final nombreCtrl = TextEditingController(text: op.nombreCompleto);
    var sede = op.sede ?? ciudadesCorredor.first;
    var activo = op.activo ?? true;
    var reserva = op.roles.contains(AppRoles.reservaExcepcional);
    var guardando = false;
    final esCajero = _esCajeroPuro(op);

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Editar operador'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Usuario: ${op.nombreUsuario} — el login no se cambia; cree otro usuario si necesita otro acceso.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),
                TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre completo *')),
                if (esCajero) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: ciudadesCorredor.contains(sede) ? sede : ciudadesCorredor.first,
                    decoration: const InputDecoration(labelText: 'Terminal'),
                    items: ciudadesCorredor.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setDlg(() => sede = v ?? sede),
                  ),
                ],
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Cuenta activa'),
                  value: activo,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setDlg(() => activo = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Permiso reserva excepcional'),
                  value: reserva,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setDlg(() => reserva = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: guardando ? null : () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              onPressed: guardando
                  ? null
                  : () async {
                      setDlg(() => guardando = true);
                      try {
                        await _api.actualizarOperador(widget.token, op.id, {
                          'nombreCompleto': nombreCtrl.text.trim(),
                          'activo': activo,
                          if (esCajero) 'sede': sede,
                          'reservaExcepcional': reserva,
                        });
                        _setMsg('Operador actualizado');
                        await _cargar();
                        if (ctx.mounted) Navigator.pop(ctx);
                      } on ApiException catch (e) {
                        _setMsg(e.message, error: true);
                        setDlg(() => guardando = false);
                      }
                    },
              child: Text(guardando ? 'Guardando…' : 'Guardar'),
            ),
          ],
        ),
      ),
    );
    nombreCtrl.dispose();
  }

  Future<void> _confirmarEliminar(UsuarioPerfil op) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar operador'),
        content: Text(
          'Desactiva la cuenta de ${op.nombreUsuario} (baja lógica). El historial de ventas se conserva. '
          'Puede reactivarlo desde editar.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _api.actualizarOperador(widget.token, op.id, {'activo': false});
      _setMsg('Operador eliminado (desactivado) — no puede iniciar sesión');
      await _cargar();
    } on ApiException catch (e) {
      _setMsg(e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Registre cajeros de su cooperativa indicando la terminal donde venden. '
          'Cada cajero solo ve viajes que salen desde su sede.',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 12),
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
        LayoutBuilder(
          builder: (context, c) {
            final row = c.maxWidth > 800;
            return row
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _formCrear()),
                      const SizedBox(width: 16),
                      Expanded(flex: 2, child: _lista()),
                    ],
                  )
                : Column(children: [_formCrear(), const SizedBox(height: 16), _lista()]);
          },
        ),
      ],
    );
  }

  Widget _formCrear() {
    return SectionCard(
      title: 'Nuevo operador',
      child: Column(
        children: [
          TextField(
            controller: _usuarioCtrl,
            decoration: const InputDecoration(
              labelText: 'Usuario de login *',
              helperText: 'Lo que escribe en Acceso personal',
            ),
          ),
          const SizedBox(height: 12),
          TextField(controller: _nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre completo *')),
          const SizedBox(height: 12),
          TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email Keycloak (opcional)')),
          const SizedBox(height: 12),
          TextField(controller: _passwordCtrl, decoration: const InputDecoration(labelText: 'Contraseña inicial *'), obscureText: true),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Es administrador de empresa'),
            value: _esAdmin,
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _esAdmin = v),
          ),
          if (!_esAdmin) ...[
            DropdownButtonFormField<String>(
              value: _sede,
              decoration: const InputDecoration(labelText: 'Terminal del cajero *'),
              items: ciudadesCorredor.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _sede = v ?? _sede),
            ),
            const SizedBox(height: 12),
          ],
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Permiso reserva excepcional'),
            value: _reservaExcepcional,
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _reservaExcepcional = v),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _saving ? null : _crear,
            icon: _saving
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.person_add),
            label: Text(_saving ? 'Creando…' : 'Crear operador'),
          ),
        ],
      ),
    );
  }

  Widget _lista() {
    return SectionCard(
      title: 'Equipo (${_operadores.length})',
      child: _operadores.isEmpty
          ? Text('No hay operadores registrados para esta cooperativa.', style: TextStyle(color: Colors.grey.shade600))
          : Column(
              children: _operadores.map((op) {
                final activo = op.activo ?? true;
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(op.nombreCompleto, style: const TextStyle(fontWeight: FontWeight.w500)),
                            Text(
                              'Login: ${op.nombreUsuario}'
                              '${op.sede != null ? ' · Terminal ${op.sede}' : op.roles.contains(AppRoles.adminEmpresa) ? ' · Todas las terminales' : ''}',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: [
                                ...op.roles.map((r) => Chip(
                                      label: Text(_etiquetasRol[r] ?? r, style: const TextStyle(fontSize: 10)),
                                      backgroundColor: r == AppRoles.adminEmpresa ? Colors.purple.shade50 : null,
                                      visualDensity: VisualDensity.compact,
                                    )),
                                if (!activo)
                                  Chip(
                                    label: const Text('Inactivo', style: TextStyle(fontSize: 10)),
                                    backgroundColor: Colors.orange.shade50,
                                    visualDensity: VisualDensity.compact,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _abrirEditar(op)),
                      if (activo)
                        IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.red.shade700),
                          onPressed: () => _confirmarEliminar(op),
                        ),
                      Switch(
                        value: activo,
                        activeColor: AppColors.primary,
                        onChanged: (_) => _toggleActivo(op),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}
