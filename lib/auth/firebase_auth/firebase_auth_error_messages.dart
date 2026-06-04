/// User-facing messages for Firebase Auth error codes.
String firebaseAuthErrorMessage(String code, {String? fallbackMessage}) {
  return switch (code) {
    'wrong-password' => 'Incorrect password. Please try again.',
    'invalid-credential' => 'Incorrect email or password. Please try again.',
    'user-not-found' => 'No account found for this email.',
    'invalid-email' => 'Please enter a valid email address.',
    'user-disabled' => 'This account has been disabled. Contact your admin.',
    'too-many-requests' =>
      'Too many failed attempts. Please wait a moment and try again.',
    'network-request-failed' =>
      'Network error. Check your connection and try again.',
    'email-already-in-use' =>
      'This email is already registered. Try signing in instead.',
    'INVALID_LOGIN_CREDENTIALS' =>
      'Incorrect email or password. Please try again.',
    _ => fallbackMessage?.isNotEmpty == true
        ? fallbackMessage!
        : 'Login failed. Please check your email and password.',
  };
}
