/// Categorías oficiales del programa municipal EDUCCA Cusco y backend Go.
enum PromoterCategory {
  escolar,
  juvenil,
  comunitario,
  paj,
  pac,
  comerciante,
  reciclador,
}

extension PromoterCategoryExtension on PromoterCategory {
  String get displayName {
    switch (this) {
      case PromoterCategory.escolar:
        return 'Escolar (I.E. Cusco)';
      case PromoterCategory.juvenil:
        return 'Juvenil (Superior / Técnico)';
      case PromoterCategory.comunitario:
        return 'Comunitario (Vecinal / Ciudadano)';
      case PromoterCategory.paj:
        return 'Promotor Ambiental Juvenil (PAJ)';
      case PromoterCategory.pac:
        return 'Promotor Ambiental Comunitario (PAC)';
      case PromoterCategory.comerciante:
        return 'Comerciante Ambiental';
      case PromoterCategory.reciclador:
        return 'Reciclador Formalizado';
    }
  }

  String get codeName => name.toUpperCase();

  /// Código compatible con las restricciones de PostgreSQL del backend Go:
  /// CHECK (categoria IN ('COMERCIANTE', 'RECICLADOR', 'PAC', 'PAJ'))
  String get backendCode {
    switch (this) {
      case PromoterCategory.paj:
      case PromoterCategory.juvenil:
        return 'PAJ';
      case PromoterCategory.pac:
      case PromoterCategory.comunitario:
        return 'PAC';
      case PromoterCategory.comerciante:
        return 'COMERCIANTE';
      case PromoterCategory.reciclador:
        return 'RECICLADOR';
      case PromoterCategory.escolar:
        return 'PAJ'; // Alias por compatibilidad de registro
    }
  }
}

/// Modelo del promotor ambiental en EDUCCA Cusco.
///
/// Diseñado con deserialización tolerante para mantener compatibilidad
/// con esquemas previos de `StudentUser` y los modelos `Persona` del backend Go.
class PromoterUser {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final PromoterCategory promoterCategory;
  final bool isAdult;
  final bool privacyConsentAccepted;

  // Campos adicionales procedentes de la entidad Persona de Go
  final String? dni;
  final String? nombres;
  final String? apellidos;
  final String? sexo;
  final String? fechaNacimiento;
  final String? telefono;
  final List<String> roles;

  const PromoterUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.promoterCategory,
    required this.isAdult,
    required this.privacyConsentAccepted,
    this.dni,
    this.nombres,
    this.apellidos,
    this.sexo,
    this.fechaNacimiento,
    this.telefono,
    this.roles = const [],
  });

  factory PromoterUser.fromJson(Map<String, dynamic> json) {
    // Si viene la respuesta enriquecida de GET /me con estructura { "persona": {...}, "roles": [...] }
    final Map<String, dynamic> source = (json['persona'] != null && json['persona'] is Map)
        ? json['persona'] as Map<String, dynamic>
        : json;

    final rawCat = (source['categoria'] ?? source['promoterCategory'])?.toString().toUpperCase();
    PromoterCategory category;
    switch (rawCat) {
      case 'PAJ':
        category = PromoterCategory.paj;
        break;
      case 'PAC':
        category = PromoterCategory.pac;
        break;
      case 'COMERCIANTE':
        category = PromoterCategory.comerciante;
        break;
      case 'RECICLADOR':
        category = PromoterCategory.reciclador;
        break;
      case 'ESCOLAR':
        category = PromoterCategory.escolar;
        break;
      case 'COMUNITARIO':
        category = PromoterCategory.comunitario;
        break;
      default:
        category = PromoterCategory.juvenil;
    }

    final nombres = source['nombres'] as String?;
    final apellidos = source['apellidos'] as String?;
    String computedFullName = source['fullName'] as String? ?? source['name'] as String? ?? '';
    if (computedFullName.isEmpty && (nombres != null || apellidos != null)) {
      computedFullName = '${nombres ?? ''} ${apellidos ?? ''}'.trim();
    }

    List<String> rolesList = [];
    if (json['roles'] != null && json['roles'] is List) {
      rolesList = (json['roles'] as List).map((r) => r.toString()).toList();
    }

    final rawId = source['id'];
    final idStr = rawId != null ? rawId.toString() : '';

    return PromoterUser(
      id: idStr,
      fullName: computedFullName,
      email: source['email'] as String? ?? '',
      role: rolesList.isNotEmpty ? rolesList.first.toUpperCase() : (source['role'] as String? ?? 'PROMOTOR'),
      promoterCategory: category,
      isAdult: source['isAdult'] as bool? ?? true,
      privacyConsentAccepted: source['privacyConsentAccepted'] as bool? ??
          (source.containsKey('consentimiento_at') ? (source['consentimiento_at'] != null) : true),
      dni: source['dni'] as String?,
      nombres: nombres,
      apellidos: apellidos,
      sexo: source['sexo'] as String?,
      fechaNacimiento: source['fecha_nacimiento']?.toString(),
      telefono: source['telefono'] as String?,
      roles: rolesList,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'email': email,
    'role': role,
    'promoterCategory': promoterCategory.codeName,
    'isAdult': isAdult,
    'privacyConsentAccepted': privacyConsentAccepted,
    if (dni != null) 'dni': dni,
    if (nombres != null) 'nombres': nombres,
    if (apellidos != null) 'apellidos': apellidos,
    if (sexo != null) 'sexo': sexo,
    if (fechaNacimiento != null) 'fecha_nacimiento': fechaNacimiento,
    if (telefono != null) 'telefono': telefono,
    'roles': roles,
  };
}
