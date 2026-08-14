import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/transporte_api.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/auth/jwt_utils.dart';
import '../../../core/models/bus.dart';
import '../../../core/models/empresa.dart';
import '../../../core/models/viaje.dart';
import '../../../core/utils/formato.dart';
import '../../../shared/layout/operative_shell.dart';
import '../admin_section.dart';
import '../widgets/admin_nav.dart';
import '../widgets/tenant_selector.dart';
import 'sections/admin_buses_section.dart';
import 'sections/admin_ingresos_section.dart';
import 'sections/admin_ocupacion_section.dart';
import 'sections/admin_operadores_section.dart';
import 'sections/admin_paradas_section.dart';
import 'sections/admin_pasajeros_section.dart';
import 'sections/admin_perfil_section.dart';
import 'sections/admin_plataforma_section.dart';
import 'sections/admin_viajes_section.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final _api = TransporteApi();

  late AdminSectionId _section;
  List<Empresa> _empresas = [];
  int? _empresaId;
  String _empresaNombre = '';
  List<Bus> _buses = [];
  List<ViajeOperador> _viajes = [];
  String _fechaViajes = fechaHoyIso();
  String _filtroOrigenViajes = '';
  bool _loading = true;
  String? _msg;
  bool _msgError = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _section = esAdminGlobal(auth.roles) ? AdminSectionId.plataforma : AdminSectionId.perfil;
    _init();
  }

  Future<void> _init() async {
    final auth = context.read<AuthProvider>();
    final token = auth.token;
    if (token == null) return;

    setState(() => _loading = true);
    try {
      if (esAdminGlobal(auth.roles)) {
        final list = await _api.listarEmpresas(token);
        _empresas = list;
        if (list.isNotEmpty) {
          _empresaId = list.first.id;
          _empresaNombre = list.first.nombre;
        }
      } else {
        final tenant = await _api.miEmpresa(token);
        _empresaId = tenant.id;
        _empresaNombre = tenant.nombre;
      }
      await _cargarDatos(token, auth);
    } on ApiException catch (e) {
      _setMsg(e.message, error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _cargarDatos(String token, AuthProvider auth) async {
    if (_empresaId == null) return;
    try {
      final origenFiltro = _filtroOrigenViajes.isEmpty ? null : _filtroOrigenViajes;
      final buses = esAdminGlobal(auth.roles)
          ? await _api.busesPorEmpresa(token, _empresaId!)
          : await _api.busesMiEmpresa(token);
      final viajes = esAdminGlobal(auth.roles)
          ? await _api.viajesPorEmpresa(token, _empresaId!, _fechaViajes, origen: origenFiltro)
          : await _api.viajesMiEmpresa(token, _fechaViajes, origen: origenFiltro);
      if (!mounted) return;
      setState(() {
        _buses = buses;
        _viajes = viajes;
      });
    } on ApiException catch (e) {
      _setMsg(e.message, error: true);
    }
  }

  void _setMsg(String text, {bool error = false}) {
    setState(() {
      _msg = text;
      _msgError = error;
    });
  }

  bool get _requiereTenant => _section != AdminSectionId.plataforma && _section != AdminSectionId.paradas;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final token = auth.token;
    final esGlobal = esAdminGlobal(auth.roles);
    final navGroups = buildAdminNav(esGlobal);
    final currentNav = findNavItem(navGroups, _section);

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (token == null) {
      return const Scaffold(body: Center(child: Text('Sesión requerida')));
    }

    final tenantBar = (_section != AdminSectionId.plataforma || !esGlobal)
        ? TenantSelector(
            esGlobal: esGlobal,
            empresas: _empresas,
            empresaId: _empresaId,
            empresaNombre: _empresaNombre,
            onChange: (id, nombre) {
              setState(() {
                _empresaId = id;
                _empresaNombre = nombre;
              });
              _cargarDatos(token, auth);
            },
            compact: true,
          )
        : null;

    return OperativeShell(
      brandSubtitle: esGlobal ? 'Consola de plataforma' : 'Panel cooperativa',
      role: esGlobal ? AppRoles.adminGeneral : AppRoles.adminEmpresa,
      title: currentNav?.label ?? 'Administración',
      description: currentNav?.description,
      nav: AdminNav(
        section: _section,
        esGlobal: esGlobal,
        onSectionChange: (id) => setState(() => _section = id),
      ),
      sidebarFooter: esGlobal && _section != AdminSectionId.plataforma
          ? TenantSelector(
              esGlobal: esGlobal,
              empresas: _empresas,
              empresaId: _empresaId,
              empresaNombre: _empresaNombre,
              onChange: (id, nombre) {
                setState(() {
                  _empresaId = id;
                  _empresaNombre = nombre;
                });
                _cargarDatos(token, auth);
              },
              sidebar: true,
            )
          : null,
      topBarExtra: tenantBar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => _msg = null),
                  ),
                ],
              ),
            ),
          if (esGlobal && _section == AdminSectionId.plataforma)
            AdminPlataformaSection(
              token: token,
              empresas: _empresas,
              empresaIdSeleccionada: _empresaId,
              onSeleccionarEmpresa: (id) {
                setState(() {
                  _empresaId = id;
                  _empresaNombre = _empresas.firstWhere((e) => e.id == id).nombre;
                });
                _cargarDatos(token, auth);
              },
              onEmpresasActualizadas: (list, [seleccionarId]) {
                setState(() {
                  _empresas = list;
                  if (seleccionarId != null) {
                    _empresaId = seleccionarId;
                    _empresaNombre = list.firstWhere((e) => e.id == seleccionarId!, orElse: () => list.first).nombre;
                  }
                });
              },
            ),
          if (_requiereTenant && _empresaId == null && esGlobal)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
              child: const Text('Seleccione o registre una cooperativa para usar esta sección.'),
            ),
          if (_section == AdminSectionId.perfil && _empresaId != null)
            AdminPerfilSection(
              token: token,
              empresaId: _empresaId!,
              esGlobal: esGlobal,
              onActualizado: (e) => setState(() => _empresaNombre = e.nombre),
            ),
          if (_section == AdminSectionId.buses && _empresaId != null)
            AdminBusesSection(
              token: token,
              empresaId: _empresaId!,
              esGlobal: esGlobal,
              buses: _buses,
              onActualizado: () => _cargarDatos(token, auth),
              onMsg: _setMsg,
            ),
          if (_section == AdminSectionId.viajes && _empresaId != null)
            AdminViajesSection(
              token: token,
              empresaId: _empresaId!,
              buses: _buses,
              viajes: _viajes,
              fechaViajes: _fechaViajes,
              filtroOrigen: _filtroOrigenViajes,
              onFechaChange: (f) {
                setState(() => _fechaViajes = f);
                _cargarDatos(token, auth);
              },
              onFiltroOrigenChange: (o) {
                setState(() => _filtroOrigenViajes = o);
                _cargarDatos(token, auth);
              },
              onActualizado: () => _cargarDatos(token, auth),
              onMsg: _setMsg,
            ),
          if (!esGlobal && _section == AdminSectionId.operadores && _empresaId != null)
            AdminOperadoresSection(token: token, empresaId: _empresaId!),
          if (!esGlobal && _section == AdminSectionId.pasajeros && _empresaId != null)
            AdminPasajerosSection(token: token, empresaId: _empresaId!),
          if (_section == AdminSectionId.ocupacion && _empresaId != null)
            AdminOcupacionSection(token: token, empresaId: _empresaId!, esGlobal: esGlobal),
          if (_section == AdminSectionId.ingresos && _empresaId != null)
            AdminIngresosSection(token: token, empresaId: _empresaId!, esGlobal: esGlobal),
          if (_section == AdminSectionId.paradas)
            AdminParadasSection(token: token),
        ],
      ),
    );
  }
}
