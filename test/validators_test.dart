import 'package:flutter_test/flutter_test.dart';
import 'package:intertwined/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('accepts a normal address', () {
      expect(Validators.email('budi@example.com'), isNull);
    });
    test('rejects empty and malformed input', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email(null), isNotNull);
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email('a@b'), isNotNull);
    });
  });

  group('Validators.username', () {
    test('accepts letters, numbers, underscore and dot', () {
      expect(Validators.username('budi_santoso.1'), isNull);
    });
    test('rejects too short, too long, spaces and @', () {
      expect(Validators.username('ab'), isNotNull);
      expect(Validators.username('a' * 21), isNotNull);
      expect(Validators.username('bad name'), isNotNull);
      expect(Validators.username('bad@name'), isNotNull);
    });
  });

  group('Validators.password', () {
    test('accepts a strong password', () {
      expect(Validators.password('Str0ngPass'), isNull);
    });
    test('rejects short, letters-only and digits-only passwords', () {
      expect(Validators.password('Ab1'), isNotNull);
      expect(Validators.password('abcdefgh'), isNotNull);
      expect(Validators.password('12345678'), isNotNull);
    });
    test('rejects common passwords', () {
      expect(Validators.password('Password123'), isNotNull);
    });
    test('rejects a password containing the username', () {
      expect(Validators.password('budi12345', username: 'budi'), isNotNull);
      expect(Validators.password('Zx9kLmQ2', username: 'budi'), isNull);
    });
  });

  group('Validators helpers', () {
    test('passwordStrength grows with complexity', () {
      expect(Validators.passwordStrength(''), 0);
      expect(Validators.passwordStrength('password'), 1);
      expect(Validators.passwordStrength('Str0ng!Passw0rd'), 4);
    });
    test('looksLikeEmail tells email from username', () {
      expect(Validators.looksLikeEmail('a@b.com'), isTrue);
      expect(Validators.looksLikeEmail('budi'), isFalse);
    });
    test('maskEmail hides the local part', () {
      expect(Validators.maskEmail('budi.santoso@gmail.com'), 'b***@gmail.com');
      expect(Validators.maskEmail('nomail'), 'nomail');
    });
  });

  group('Validators.otpCode (authenticator code)', () {
    test('accepts exactly 6 digits, ignoring surrounding spaces', () {
      expect(Validators.otpCode('123456'), isNull);
      expect(Validators.otpCode(' 123456 '), isNull);
    });
    test('rejects empty, short, long and non-digit codes', () {
      expect(Validators.otpCode(''), isNotNull);
      expect(Validators.otpCode(null), isNotNull);
      expect(Validators.otpCode('12345'), isNotNull);
      expect(Validators.otpCode('1234567'), isNotNull);
      expect(Validators.otpCode('12a456'), isNotNull);
    });
  });

  group('Validators.isDeleteConfirmation', () {
    test('accepts DELETE in any case', () {
      expect(Validators.isDeleteConfirmation('DELETE'), isTrue);
      expect(Validators.isDeleteConfirmation(' delete '), isTrue);
    });
    test('rejects anything else', () {
      expect(Validators.isDeleteConfirmation(''), isFalse);
      expect(Validators.isDeleteConfirmation(null), isFalse);
      expect(Validators.isDeleteConfirmation('DELET'), isFalse);
      expect(Validators.isDeleteConfirmation('delete my account'), isFalse);
    });
  });
}
