import 'package:flutter_test/flutter_test.dart';
import 'package:sistema_capacitaciones/models/promoter_user.dart';

void main() {
  group('PromoterUser Model Tests (HU-01 / RNF-01)', () {
    test('PromoterUser parses complete JSON with category and consent', () {
      final json = {
        'id': 'prom-001',
        'fullName': 'Yadira Mendoza',
        'email': 'yadira@cusco.gob.pe',
        'role': 'PROMOTOR',
        'promoterCategory': 'COMUNITARIO',
        'isAdult': true,
        'privacyConsentAccepted': true,
      };

      final user = PromoterUser.fromJson(json);
      expect(user.id, 'prom-001');
      expect(user.fullName, 'Yadira Mendoza');
      expect(user.email, 'yadira@cusco.gob.pe');
      expect(user.role, 'PROMOTOR');
      expect(user.promoterCategory, PromoterCategory.comunitario);
      expect(user.isAdult, isTrue);
      expect(user.privacyConsentAccepted, isTrue);
    });

    test('PromoterUser parses escolar category and default values gracefully', () {
      final json = {
        'id': 'prom-002',
        'name': 'Mateo Colque',
        'email': 'mateo@colegio.edu.pe',
        'promoterCategory': 'ESCOLAR',
        'isAdult': false,
        'privacyConsentAccepted': false,
      };

      final user = PromoterUser.fromJson(json);
      expect(user.fullName, 'Mateo Colque');
      expect(user.role, 'PROMOTOR');
      expect(user.promoterCategory, PromoterCategory.escolar);
      expect(user.isAdult, isFalse);
      expect(user.privacyConsentAccepted, isFalse);
    });

    test('PromoterUser falls back to juvenil if category is missing or unexpected', () {
      final json = {
        'id': 'prom-003',
        'name': 'Luciana Montalvo',
        'email': 'luciana@unsaac.edu.pe',
      };

      final user = PromoterUser.fromJson(json);
      expect(user.promoterCategory, PromoterCategory.juvenil);
      expect(user.isAdult, isTrue);
      expect(user.privacyConsentAccepted, isTrue);
    });

    test('PromoterUser toJson outputs expected map and uppercase category', () {
      const user = PromoterUser(
        id: 'prom-004',
        fullName: 'Fidel Magaña',
        email: 'fidel@cusco.gob.pe',
        role: 'PROMOTOR',
        promoterCategory: PromoterCategory.comunitario,
        isAdult: true,
        privacyConsentAccepted: true,
      );

      final map = user.toJson();
      expect(map['id'], 'prom-004');
      expect(map['fullName'], 'Fidel Magaña');
      expect(map['promoterCategory'], 'COMUNITARIO');
      expect(map['isAdult'], isTrue);
      expect(map['privacyConsentAccepted'], isTrue);
    });
  });
}
