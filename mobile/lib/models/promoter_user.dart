/// Categorías oficiales del programa municipal EDUCCA Cusco.
enum PromoterCategory {
  escolar,
  juvenil,
  comunitario,
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
    }
  }

  String get codeName => name.toUpperCase();
}

/// Modelo del promotor ambiental en EDUCCA Cusco.
///
/// Diseñado con deserialización tolerante para mantener compatibilidad
/// con esquemas previos de `StudentUser`.
class PromoterUser {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final PromoterCategory promoterCategory;
  final bool isAdult;
  final bool privacyConsentAccepted;

  const PromoterUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.promoterCategory,
    required this.isAdult,
    required this.privacyConsentAccepted,
  });

  factory PromoterUser.fromJson(Map<String, dynamic> json) {
    final rawCat = json['promoterCategory']?.toString().toUpperCase();
    PromoterCategory category;
    switch (rawCat) {
      case 'ESCOLAR':
        category = PromoterCategory.escolar;
        break;
      case 'COMUNITARIO':
        category = PromoterCategory.comunitario;
        break;
      default:
        category = PromoterCategory.juvenil;
    }

    return PromoterUser(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'PROMOTOR',
      promoterCategory: category,
      isAdult: json['isAdult'] as bool? ?? true,
      privacyConsentAccepted: json['privacyConsentAccepted'] as bool? ?? true,
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
  };
}
