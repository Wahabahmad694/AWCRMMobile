import 'package:flutter/foundation.dart';

enum ViewState { idle, busy, error, success }

class BaseViewModel extends ChangeNotifier {
  ViewState _state = ViewState.idle;
  String? _errorMessage;
  String? _successMessage;

  ViewState get state => _state;
  bool get isBusy => _state == ViewState.busy;
  bool get hasError => _errorMessage != null && _errorMessage!.isNotEmpty;
  bool get hasSuccess => _successMessage != null && _successMessage!.isNotEmpty;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  void setState(ViewState viewState) {
    _state = viewState;
    notifyListeners();
  }

  void setBusy(bool busy) {
    if (busy) {
      _state = ViewState.busy;
      _errorMessage = null;
    } else {
      _state = ViewState.idle;
    }
    notifyListeners();
  }

  void setError(String? message) {
    _errorMessage = message;
    if (message != null) {
      _state = ViewState.error;
    } else if (_state == ViewState.error) {
      _state = ViewState.idle;
    }
    notifyListeners();
  }

  void setSuccess(String? message) {
    _successMessage = message;
    if (message != null) {
      _state = ViewState.success;
    }
    notifyListeners();
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    if (_state != ViewState.busy) {
      _state = ViewState.idle;
    }
    notifyListeners();
  }

  Future<T?> runBusyFuture<T>(Future<T> Function() busyFunc, {bool throwException = false}) async {
    setBusy(true);
    try {
      final result = await busyFunc();
      setBusy(false);
      return result;
    } catch (e) {
      setError(e.toString());
      setBusy(false);
      if (throwException) rethrow;
      return null;
    }
  }
}
