import 'package:flutter/material.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/api/transporte_api.dart';
import '../../../../core/models/empresa.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../widgets/cooperativa_detalle_panel.dart';

const _avatarPalette = [
  Color(0xFF0F766E),
  Color(0xFF0C4A6E),
  Color(0xFF7C3AED),
  Color(0xFF0369A1),
  Color(0xFFC2410C),
  Color(0xFFBE123C),
];

const _pasos = ['Datos de la cooperativa', 'Administrador inicial'];

bool _correoValido(String correo) {
  if (correo.trim().isEmpty) return true;
  return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(correo.trim());
}

String _sugerirUsuarioAdmin(String nombreCoop) {
  var slug = nombreCoop.toLowerCase();
  slug = slug.replaceAll(RegExp(r'[^a-z0-9]+'), '.').replaceAll(RegExp(r'^\.+|\.+$'), '');
  if (slug.length > 24) slug = slug.substring(0, 24);
  return slug.isNotEmpty ? 'admin.$slug' : 'admin.nueva.coop';
}

String _iniciales(String nombre) {
  final partes = nombre.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (partes.isEmpty) return '?';
  if (partes.length == 1) return partes[0].substring(0, partes[0].length >= 2 ? 2 : 1).toUpperCase();
  return (partes[0][0] + partes[1][0]).toUpperCase();
}

Color _avatarColor(int id) => _avatarPalette[id % _avatarPalette.length];

class AdminPlataformaSection extends StatefulWidget {
  const AdminPlataformaSection({
    super.key,
    required this.token,
    required this.empresas,
    this.empresaIdSeleccionada,
    required this.onSeleccionarEmpresa,
    required this.onEmpresasActualizadas,
  });

  final String token;
  final List<Empresa> empresas;
  final int? empresaIdSeleccionada;
  final ValueChanged<int> onSeleccionarEmpresa;
  final void Function(List<Empresa> list, [int? seleccionarId]) onEmpresasActualizadas;

  @override
  State<AdminPlataformaSection> createState() => _AdminPlataformaSectionState();
}

class _AdminPlataformaSectionState extends State<AdminPlataformaSection> {
  final _api = TransporteApi();
  List<ResumenEmpresa> _resumen = [];
  bool _loadingResumen = true;
  String _busqueda = '';

  String? _msg;
  bool _msgError = false;
  int? _desactivarId;
  bool _desactivando = false;

  bool _wizardLoading = false;
  int _wizardStep = 0;
  int? _wizardEmpresaId;

  final _nombreCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _logoCtrl = TextEditingController();
  double _tarifaEquipaje = 100;

  final _adminUsuarioCtrl = TextEditingController();
  final _adminNombreCtrl = TextEditingController();
  final _adminEmailCtrl = TextEditingController();
  final _adminPasswordCtrl = TextEditingController(text: 'password');

  @override
  void initState() {
    super.initState();
    _cargarResumen();
  }

  @override
  void didUpdateWidget(covariant AdminPlataformaSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.empresas.length != widget.empresas.length) _cargarResumen();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _correoCtrl.dispose();
    _logoCtrl.dispose();
    _adminUsuarioCtrl.dispose();
    _adminNombreCtrl.dispose();
    _adminEmailCtrl.dispose();
    _adminPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarResumen() async {
    setState(() => _loadingResumen = true);
    try {
      final r = await _api.resumenPlataforma(widget.token);
      if (!mounted) return;
      setState(() => _resumen = r);
    } on ApiException {
      if (mounted) setState(() => _resumen = []);
    } finally {
      if (mounted) setState(() => _loadingResumen = false);
    }
  }

  void _setMsg(String text, {bool error = false}) {
    setState(() {
      _msg = text;
      _msgError = error;
    });
  }

  void _resetWizard() {
    _wizardStep = 0;
    _wizardEmpresaId = null;
    _nombreCtrl.clear();
    _telefonoCtrl.clear();
    _correoCtrl.clear();
    _logoCtrl.clear();
    _tarifaEquipaje = 100;
    _adminUsuarioCtrl.clear();
    _adminNombreCtrl.clear();
    _adminEmailCtrl.clear();
    _adminPasswordCtrl.text = 'password';
  }

  void _abrirWizardNueva() {
    _resetWizard();
    _mostrarWizard();
  }

  void _abrirWizardSoloAdmin(int empresaId, String nombreCoop) {
    _resetWizard();
    _wizardEmpresaId = empresaId;
    _wizardStep = 1;
    _nombreCtrl.text = nombreCoop;
    _adminUsuarioCtrl.text = _sugerirUsuarioAdmin(nombreCoop);
    widget.onSeleccionarEmpresa(empresaId);
    _mostrarWizard();
  }

  Future<void> _mostrarWizard() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: !_wizardLoading,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) {
          final nombreCoopWizard = widget.empresas.where((e) => e.id == _wizardEmpresaId).firstOrNull?.nombre ??
              (_nombreCtrl.text.trim().isNotEmpty ? _nombreCtrl.text.trim() : 'la cooperativa');
          return AlertDialog(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Registrar cooperativa', style: TextStyle(fontWeight: FontWeight.w700)),
                Text('Complete los dos pasos para dejar la cooperativa operativa.', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stepper(
                      currentStep: _wizardStep,
                      controlsBuilder: (_, __) => const SizedBox.shrink(),
                      steps: _pasos.map((label) => Step(title: Text(label, style: const TextStyle(fontSize: 13)), content: const SizedBox.shrink())).toList(),
                    ),
                    if (_wizardStep == 0) ...[
                      TextField(controller: _nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre comercial *'), autofocus: true),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: TextField(controller: _telefonoCtrl, decoration: const InputDecoration(labelText: 'Teléfono'))),
                          const SizedBox(width: 12),
                          Expanded(child: TextField(controller: _correoCtrl, decoration: const InputDecoration(labelText: 'Correo de contacto'), keyboardType: TextInputType.emailAddress)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(labelText: 'Equipaje extra (C\$)'),
                              keyboardType: TextInputType.number,
                              initialValue: '$_tarifaEquipaje',
                              onChanged: (v) => _tarifaEquipaje = double.tryParse(v) ?? _tarifaEquipaje,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: TextField(controller: _logoCtrl, decoration: const InputDecoration(labelText: 'URL del logo'))),
                        ],
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Text('Primer administrador de $nombreCoopWizard'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _adminUsuarioCtrl,
                        decoration: const InputDecoration(labelText: 'Usuario de login *', helperText: 'Campo de acceso personal — no es el correo comercial'),
                        autofocus: true,
                      ),
                      const SizedBox(height: 12),
                      TextField(controller: _adminNombreCtrl, decoration: const InputDecoration(labelText: 'Nombre completo *')),
                      const SizedBox(height: 12),
                      TextField(controller: _adminEmailCtrl, decoration: const InputDecoration(labelText: 'Email Keycloak (opcional)'), keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 12),
                      TextField(controller: _adminPasswordCtrl, decoration: const InputDecoration(labelText: 'Contraseña inicial *'), obscureText: true),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: _wizardLoading ? null : () => Navigator.pop(ctx), child: const Text('Cancelar')),
              if (_wizardStep == 1 && _wizardEmpresaId == null)
                TextButton(onPressed: _wizardLoading ? null : () => setDlg(() => _wizardStep = 0), child: const Text('Atrás')),
              if (_wizardStep == 0)
                FilledButton(
                  onPressed: _wizardLoading
                      ? null
                      : () async {
                          await _wizardPaso1();
                          if (mounted) setDlg(() {});
                          if (_wizardStep == 1 && ctx.mounted) setState(() {});
                        },
                  child: Text(_wizardLoading ? 'Guardando…' : 'Continuar'),
                )
              else
                FilledButton(
                  onPressed: _wizardLoading
                      ? null
                      : () async {
                          await _wizardPaso2();
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                  child: Text(_wizardLoading ? 'Creando…' : 'Finalizar registro'),
                ),
            ],
          );
        },
      ),
    );
    _resetWizard();
  }

  Future<void> _mostrarDesactivarDialog(int id) async {
    final empresa = widget.empresas.where((e) => e.id == id).firstOrNull;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desactivar cooperativa'),
        content: Text('¿Confirma desactivar ${empresa?.nombre ?? ''}? Dejará de mostrarse en consulta pública.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _desactivarId = id);
    await _confirmarDesactivar();
  }

  Future<void> _wizardPaso1() async {
    if (_nombreCtrl.text.trim().isEmpty) {
      _setMsg('El nombre comercial es obligatorio (RN E1).', error: true);
      return;
    }
    if (!_correoValido(_correoCtrl.text)) {
      _setMsg('El correo no tiene un formato válido (RN E2).', error: true);
      return;
    }
    if (_tarifaEquipaje < 0) {
      _setMsg('La tarifa de equipaje extra no puede ser negativa.', error: true);
      return;
    }

    setState(() => _wizardLoading = true);
    try {
      final creada = await _api.crearEmpresa(widget.token, {
        'nombre': _nombreCtrl.text.trim(),
        if (_telefonoCtrl.text.trim().isNotEmpty) 'telefono': _telefonoCtrl.text.trim(),
        if (_correoCtrl.text.trim().isNotEmpty) 'correo': _correoCtrl.text.trim(),
        'tarifaEquipajeExtra': _tarifaEquipaje,
        if (_logoCtrl.text.trim().isNotEmpty) 'logoUrl': _logoCtrl.text.trim(),
      });
      final list = await _api.listarEmpresas(widget.token);
      widget.onEmpresasActualizadas(list, creada.id);
      widget.onSeleccionarEmpresa(creada.id);
      setState(() {
        _wizardEmpresaId = creada.id;
        _adminUsuarioCtrl.text = _sugerirUsuarioAdmin(creada.nombre);
        _wizardStep = 1;
      });
      await _cargarResumen();
    } on ApiException catch (e) {
      _setMsg(e.message, error: true);
    } finally {
      if (mounted) setState(() => _wizardLoading = false);
    }
  }

  Future<void> _wizardPaso2() async {
    final empresaId = _wizardEmpresaId ?? widget.empresaIdSeleccionada;
    if (empresaId == null) {
      _setMsg('No hay cooperativa vinculada. Complete el paso 1 primero.', error: true);
      return;
    }

    setState(() => _wizardLoading = true);
    try {
      await _api.crearOperador(widget.token, {
        'empresaId': empresaId,
        'nombreUsuario': _adminUsuarioCtrl.text.trim().toLowerCase(),
        'nombreCompleto': _adminNombreCtrl.text.trim(),
        'password': _adminPasswordCtrl.text,
        'roles': ['ADMIN_EMPRESA'],
        if (_adminEmailCtrl.text.trim().isNotEmpty) 'email': _adminEmailCtrl.text.trim(),
      });
      await _cargarResumen();
      _setMsg('Cooperativa activa: «${_adminUsuarioCtrl.text.trim()}» puede iniciar sesión.');
    } on ApiException catch (e) {
      _setMsg(e.message, error: true);
    } finally {
      if (mounted) setState(() => _wizardLoading = false);
    }
  }

  Future<void> _confirmarDesactivar() async {
    if (_desactivarId == null) return;
    setState(() => _desactivando = true);
    try {
      await _api.desactivarEmpresa(widget.token, _desactivarId!);
      final list = await _api.listarEmpresas(widget.token);
      final siguiente = list.where((e) => e.id != _desactivarId).firstOrNull?.id;
      widget.onEmpresasActualizadas(list, siguiente);
      await _cargarResumen();
      _setMsg('Cooperativa desactivada correctamente (RN E4).');
    } on ApiException catch (e) {
      _setMsg(e.message, error: true);
    } finally {
      if (mounted) {
        setState(() {
          _desactivando = false;
          _desactivarId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final resumenPorId = {for (final r in _resumen) r.id: r};
    final totales = (
      cooperativas: _resumen.length,
      buses: _resumen.fold<int>(0, (s, r) => s + r.busesActivos),
      viajes: _resumen.fold<int>(0, (s, r) => s + r.viajesHoy),
      boletos: _resumen.fold<int>(0, (s, r) => s + r.boletosVendidosHoy),
      sinAdmin: _resumen.where((r) => r.operadoresActivos == 0).length,
    );

    final q = _busqueda.trim().toLowerCase();
    final empresasFiltradas = q.isEmpty
        ? widget.empresas
        : widget.empresas.where((e) {
            return e.nombre.toLowerCase().contains(q) ||
                (e.correo ?? '').toLowerCase().contains(q) ||
                (e.telefono ?? '').contains(q);
          }).toList();

    final empresaSeleccionada = widget.empresaIdSeleccionada != null
        ? widget.empresas.where((e) => e.id == widget.empresaIdSeleccionada).firstOrNull
        : null;
    final coopSinAdmin = widget.empresaIdSeleccionada != null &&
        (resumenPorId[widget.empresaIdSeleccionada!]?.operadoresActivos ?? 0) == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_loadingResumen)
          const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
        else
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth > 900 ? 4 : (c.maxWidth > 500 ? 2 : 1);
              return GridView.count(
                crossAxisCount: cols,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: cols == 1 ? 3.2 : 2.4,
                children: [
                  StatCard(
                    compact: true,
                    label: 'Cooperativas',
                    value: '${totales.cooperativas}',
                    icon: Icons.business,
                    accent: AppColors.primary,
                    hint: totales.sinAdmin > 0 ? '${totales.sinAdmin} pendientes de admin' : 'Activas en plataforma',
                  ),
                  StatCard(compact: true, label: 'Flota total', value: '${totales.buses}', icon: Icons.directions_bus, accent: AppColors.primaryDark),
                  StatCard(compact: true, label: 'Viajes hoy', value: '${totales.viajes}', icon: Icons.event_note, accent: const Color(0xFF7C3AED)),
                  StatCard(compact: true, label: 'Boletos hoy', value: '${totales.boletos}', icon: Icons.confirmation_number, accent: AppColors.secondary),
                ],
              );
            },
          ),
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
        Card(
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: 560,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 280,
                  child: ColoredBox(
                    color: Colors.grey.shade50,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text('Cooperativas', style: TextStyle(fontWeight: FontWeight.w700)),
                              Text('${widget.empresas.length} registradas', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              const SizedBox(height: 12),
                              TextField(
                                decoration: InputDecoration(
                                  hintText: 'Buscar por nombre o contacto…',
                                  prefixIcon: const Icon(Icons.search, size: 20),
                                  isDense: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onChanged: (v) => setState(() => _busqueda = v),
                              ),
                              const SizedBox(height: 10),
                              FilledButton.icon(
                                onPressed: _abrirWizardNueva,
                                icon: const Icon(Icons.add_business, size: 18),
                                label: const Text('Nueva cooperativa'),
                                style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: widget.empresas.isEmpty
                              ? Center(child: Text('No hay cooperativas aún.', style: TextStyle(color: Colors.grey.shade600)))
                              : empresasFiltradas.isEmpty
                                  ? Center(child: Text('Sin coincidencias para «$_busqueda»', style: TextStyle(color: Colors.grey.shade600)))
                                  : ListView.builder(
                                      itemCount: empresasFiltradas.length,
                                      itemBuilder: (context, i) {
                                        final em = empresasFiltradas[i];
                                        final stats = resumenPorId[em.id];
                                        final sinAdmin = (stats?.operadoresActivos ?? 0) == 0;
                                        final selected = em.id == widget.empresaIdSeleccionada;
                                        return Material(
                                          color: selected ? AppColors.primary.withValues(alpha: 0.08) : null,
                                          child: InkWell(
                                            onTap: () => widget.onSeleccionarEmpresa(em.id),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                              child: Row(
                                                children: [
                                                  CircleAvatar(
                                                    radius: 18,
                                                    backgroundColor: _avatarColor(em.id),
                                                    child: Text(_iniciales(em.nombre),
                                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Expanded(
                                                              child: Text(em.nombre,
                                                                  style: TextStyle(
                                                                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600, fontSize: 13),
                                                                  overflow: TextOverflow.ellipsis),
                                                            ),
                                                            if (sinAdmin) Icon(Icons.warning_amber, size: 15, color: Colors.orange.shade700),
                                                          ],
                                                        ),
                                                        if (stats != null)
                                                          Text('${stats.busesActivos} buses · ${stats.boletosVendidosHoy} ventas hoy',
                                                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                                              overflow: TextOverflow.ellipsis),
                                                      ],
                                                    ),
                                                  ),
                                                  Icon(Icons.chevron_right, size: 18, color: selected ? AppColors.primary : Colors.grey.shade400),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                        ),
                      ],
                    ),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: empresaSeleccionada != null
                        ? SingleChildScrollView(
                            child: CooperativaDetallePanel(
                              embedded: true,
                              token: widget.token,
                              empresaId: empresaSeleccionada.id,
                              sinAdmin: coopSinAdmin,
                              onAsignarAdmin: () => _abrirWizardSoloAdmin(empresaSeleccionada.id, empresaSeleccionada.nombre),
                              onDesactivar: () => _mostrarDesactivarDialog(empresaSeleccionada.id),
                              canDesactivar: widget.empresas.length > 1,
                              onEmpresaActualizada: (e) {
                                widget.onEmpresasActualizadas(
                                  widget.empresas.map((em) => em.id == e.id ? e : em).toList(),
                                  e.id,
                                );
                              },
                              onRecargarLista: _cargarResumen,
                            ),
                          )
                        : Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.business, size: 48, color: AppColors.primary.withValues(alpha: 0.4)),
                                const SizedBox(height: 12),
                                const Text('Seleccione una cooperativa', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                const SizedBox(height: 8),
                                Text(
                                  'Elija una cooperativa del panel izquierdo para administrar accesos, datos comerciales y flota.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
