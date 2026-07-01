import '/app_state.dart';

const _rememberKey = 'ff_remember_login';
const _emailKey = 'ff_saved_login_email';
const _passwordKey = 'ff_saved_login_password';

class SavedLoginCredentials {
  const SavedLoginCredentials({
    this.email,
    this.password,
    this.remember = false,
  });

  final String? email;
  final String? password;
  final bool remember;
}

Future<SavedLoginCredentials> loadSavedLoginCredentials() async {
  final storage = FFAppState().secureStorage;
  final remember = await storage.getBool(_rememberKey) ?? false;
  if (!remember) {
    return const SavedLoginCredentials();
  }
  return SavedLoginCredentials(
    email: await storage.getString(_emailKey),
    password: await storage.getString(_passwordKey),
    remember: true,
  );
}

Future<void> persistSavedLoginCredentials({
  required bool remember,
  required String email,
  required String password,
}) async {
  final storage = FFAppState().secureStorage;
  if (!remember) {
    await storage.delete(key: _rememberKey);
    await storage.delete(key: _emailKey);
    await storage.delete(key: _passwordKey);
    return;
  }
  await storage.setBool(_rememberKey, true);
  await storage.setString(_emailKey, email);
  await storage.setString(_passwordKey, password);
}
