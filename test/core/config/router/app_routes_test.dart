import 'package:flutter_pecha/core/config/router/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppRoutes.isGuestAccessible', () {
    test('allows settings and its linked informational screens', () {
      expect(AppRoutes.isGuestAccessible('/home/settings'), isTrue);
      expect(AppRoutes.isGuestAccessible(AppRoutes.about), isTrue);
      expect(AppRoutes.isGuestAccessible(AppRoutes.legal), isTrue);
      expect(AppRoutes.isGuestAccessible(AppRoutes.termsOfService), isTrue);
      expect(AppRoutes.isGuestAccessible(AppRoutes.privacyPolicy), isTrue);
    });

    test('still blocks login-gated settings destinations', () {
      expect(AppRoutes.isGuestAccessible(AppRoutes.profile), isFalse);
      expect(AppRoutes.isGuestAccessible(AppRoutes.deleteAccount), isFalse);
    });
  });
}
