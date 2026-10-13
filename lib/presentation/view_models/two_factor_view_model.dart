import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/repositories/auth_repository.dart';

enum TwoFactorStatus { loading, disabled, enrolling, enabled, error }

/// Pengaturan 2FA (aplikasi authenticator / TOTP). Satu instance per layar.
class TwoFactorViewModel extends ChangeNotifier {
  final AuthRepository _repository;

  TwoFactorViewModel(this._repository);

  TwoFactorStatus _status = TwoFactorStatus.loading;
  MfaEnrollment? _enrollment;
  bool _isBusy = false;
  String? _errorMessage;
  bool _disposed = false;

  TwoFactorStatus get status => _status;
  MfaEnrollment? get enrollment => _enrollment;
  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;
  void clearError() => _errorMessage = null;

  @override
  void dispose() {
    _disposed = true;
    // Keluar di tengah pemasangan: buang faktor yang belum terverifikasi.
    final pending = _enrollment;
    if (_status == TwoFactorStatus.enrolling && pending != null) {
      unawaited(_repository.cancelMfaEnrollment(pending.factorId));
    }
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  Future<void> load() async {
    _status = TwoFactorStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      final factor = await _repository.fetchVerifiedTotpFactor();
      _status = factor == null ? TwoFactorStatus.disabled : TwoFactorStatus.enabled;
    } catch (e) {
      _status = TwoFactorStatus.error;
      _errorMessage = AuthFlowException.from(e).message;
    }
    notifyListeners();
  }

  Future<bool> _run(Future<void> Function() action) async {
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (e) {
      _errorMessage = AuthFlowException.from(e).message;
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  /// Minta QR + kunci baru dari server.
  Future<bool> startEnrollment() async {
    return _run(() async {
      _enrollment = await _repository.startMfaEnrollment();
      _status = TwoFactorStatus.enrolling;
    });
  }

  /// Kode pertama dari aplikasi authenticator mengaktifkan 2FA.
  Future<bool> confirmEnrollment(String code) async {
    final pending = _enrollment;
    if (pending == null) return false;
    final ok = await _run(
      () => _repository.confirmMfaEnrollment(factorId: pending.factorId, code: code),
    );
    if (ok) {
      _enrollment = null;
      _status = TwoFactorStatus.enabled;
      notifyListeners();
    }
    return ok;
  }

  Future<void> cancelEnrollment() async {
    final pending = _enrollment;
    _enrollment = null;
    _status = TwoFactorStatus.disabled;
    notifyListeners();
    if (pending != null) {
      await _repository.cancelMfaEnrollment(pending.factorId);
    }
  }

  Future<bool> disable() async {
    final ok = await _run(() => _repository.disableMfa());
    if (ok) {
      _status = TwoFactorStatus.disabled;
      notifyListeners();
    }
    return ok;
  }
}
