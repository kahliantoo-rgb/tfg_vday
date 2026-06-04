import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/auth/firebase_auth/firebase_auth_error_messages.dart';

void main() {
  test('firebaseAuthErrorMessage maps wrong password codes', () {
    expect(
      firebaseAuthErrorMessage('wrong-password'),
      'Incorrect password. Please try again.',
    );
    expect(
      firebaseAuthErrorMessage('invalid-credential'),
      'Incorrect email or password. Please try again.',
    );
    expect(
      firebaseAuthErrorMessage('INVALID_LOGIN_CREDENTIALS'),
      'Incorrect email or password. Please try again.',
    );
  });
}
