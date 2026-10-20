import '../../../data/base_vm.dart';
import '../../../di_container.dart';
import '../../../repositories/auth_repository.dart';

class LoginViewModel extends BaseViewModel {
  final AuthRepository _authRepo = sl<AuthRepository>();

  bool _isPasswordVisible = false;
  bool get isPasswordVisible => _isPasswordVisible;

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  Future<bool> login(String identifier, String password) async {
    final result = await runBusyFuture(() => _authRepo.login(
          identifier: identifier,
          password: password,
        ));
    if (result != null && result.isSuccess) {
      return true;
    }
    setError(result?.error ?? 'Invalid email/phone or password.');
    return false;
  }

  Future<bool> register({
    required String name,
    required String email,
    String? phone,
    required String organizationName,
    required String password,
  }) async {
    final result = await runBusyFuture(() => _authRepo.register(
          name: name,
          email: email,
          phone: phone,
          organizationName: organizationName,
          password: password,
        ));
    if (result != null && result.isSuccess) {
      return true;
    }
    setError(result?.error ?? 'Registration failed.');
    return false;
  }

  Future<void> enterPreviewMode() async {
    await _authRepo.enterPreviewMode();
  }

  Future<String?> forgotPassword(String identifier) async {
    try {
      final msg = await _authRepo.forgotPassword(identifier);
      setSuccess(msg);
      return msg;
    } catch (e) {
      setError(e.toString());
      return null;
    }
  }
}
