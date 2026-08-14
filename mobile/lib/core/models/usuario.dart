class UsuarioPerfil {
  UsuarioPerfil({
    required this.id,
    this.empresaId,
    this.empresaNombre,
    required this.nombreUsuario,
    this.emailLogin,
    required this.nombreCompleto,
    this.sede,
    this.activo,
    required this.roles,
  });

  final int id;
  final int? empresaId;
  final String? empresaNombre;
  final String nombreUsuario;
  final String? emailLogin;
  final String nombreCompleto;
  final String? sede;
  final bool? activo;
  final List<String> roles;

  factory UsuarioPerfil.fromJson(Map<String, dynamic> json) => UsuarioPerfil(
        id: json['id'] as int,
        empresaId: json['empresaId'] as int?,
        empresaNombre: json['empresaNombre'] as String?,
        nombreUsuario: json['nombreUsuario'] as String,
        emailLogin: json['emailLogin'] as String?,
        nombreCompleto: json['nombreCompleto'] as String,
        sede: json['sede'] as String?,
        activo: json['activo'] as bool?,
        roles: (json['roles'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      );
}
