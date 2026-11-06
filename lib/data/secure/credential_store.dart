import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/network/redaction.dart';

/// Result of reading a secret. Never throws.
sealed class SecretRead {
  const SecretRead();
}

class SecretFound extends SecretRead {
  const SecretFound(this.value);
  final String value;
}

/// Nothing stored (or it was wiped, e.g. after an iOS re-sign changed the
/// keychain scope). The UI says "Enter your password again to continue".
class SecretMissing extends SecretRead {
  const SecretMissing();
}

/// The platform store threw (Android keystore errors after a restore, etc).
/// Treated like [SecretMissing] by the UI, but logged.
class SecretUnavailable extends SecretRead {
  const SecretUnavailable(this.reason);
  final String reason;
}

/// Passwords and credential-bearing URLs, keyed by provider id. Secrets
/// live only here: never in the database, preferences or logs (brief 5.8).
abstract interface class CredentialStore {
  Future<SecretRead> readPassword(String providerId);
  Future<bool> writePassword(String providerId, String password);

  /// M3U links that contain credentials are secrets too.
  Future<SecretRead> readSecretUrl(String providerId);
  Future<bool> writeSecretUrl(String providerId, String url);

  Future<void> deleteAll(String providerId);
}

/// Low-level key/value backend, so tests can inject one that throws.
abstract interface class SecretBackend {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class FlutterSecureBackend implements SecretBackend {
  FlutterSecureBackend([FlutterSecureStorage? storage])
    // Default options: no iCloud sync, no paid-only entitlements (brief 2).
    : _s = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _s;

  @override
  Future<String?> read(String key) => _s.read(key: key);
  @override
  Future<void> write(String key, String value) =>
      _s.write(key: key, value: value);
  @override
  Future<void> delete(String key) => _s.delete(key: key);
}

class SecureCredentialStore implements CredentialStore {
  SecureCredentialStore([SecretBackend? backend])
    : _b = backend ?? FlutterSecureBackend();

  final SecretBackend _b;

  static String _pwKey(String id) => 'provider.$id.password';
  static String _urlKey(String id) => 'provider.$id.url';

  Future<SecretRead> _read(String key) async {
    try {
      final v = await _b.read(key);
      if (v == null || v.isEmpty) return const SecretMissing();
      return SecretFound(v);
    } catch (e) {
      NetLog.w(
        'secure storage read failed for ${key.split('.').last}: '
        '${e.runtimeType}',
      );
      return SecretUnavailable('${e.runtimeType}');
    }
  }

  Future<bool> _write(String key, String value) async {
    try {
      await _b.write(key, value);
      return true;
    } catch (e) {
      NetLog.w('secure storage write failed: ${e.runtimeType}');
      return false;
    }
  }

  @override
  Future<SecretRead> readPassword(String providerId) =>
      _read(_pwKey(providerId));

  @override
  Future<bool> writePassword(String providerId, String password) =>
      _write(_pwKey(providerId), password);

  @override
  Future<SecretRead> readSecretUrl(String providerId) =>
      _read(_urlKey(providerId));

  @override
  Future<bool> writeSecretUrl(String providerId, String url) =>
      _write(_urlKey(providerId), url);

  @override
  Future<void> deleteAll(String providerId) async {
    for (final k in [_pwKey(providerId), _urlKey(providerId)]) {
      try {
        await _b.delete(k);
      } catch (_) {}
    }
  }
}
