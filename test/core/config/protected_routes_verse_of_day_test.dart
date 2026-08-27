import 'package:flutter_pecha/core/config/protected_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProtectedRoutes verse-of-day / language', () {
    test('verse-of-day/today is optional auth, not required', () {
      expect(ProtectedRoutes.isOptional('/verse-of-day/today'), isTrue);
      expect(ProtectedRoutes.isProtected('/verse-of-day/today'), isFalse);
    });

    test('users/me/language is protected via /users/me/ prefix', () {
      expect(ProtectedRoutes.isProtected('/users/me/language'), isTrue);
    });

    test('community chat REST is protected via /chat/ prefix', () {
      expect(ProtectedRoutes.isProtected('/chat/rooms'), isTrue);
      expect(ProtectedRoutes.isProtected('/chat/groups/g1/messages'), isTrue);
    });
  });
}
