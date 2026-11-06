import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/data_providers.dart';
import '../../core/network/connection_error.dart';
import '../../core/network/network_client.dart';
import '../../data/xtream/connection_doctor.dart';
import '../../data/xtream/server_endpoint.dart';

sealed class SignInOutcome {
  const SignInOutcome();
}

class SignInOk extends SignInOutcome {
  const SignInOk(this.providerId, {this.warnings = const {}});
  final String providerId;
  final Set<ProbeWarning> warnings;
}

class SignInFailed extends SignInOutcome {
  const SignInFailed(this.error, {this.attempts = const []});
  final ConnectionError error;
  final List<ProbeAttempt> attempts;
}

/// What the Add provider screen needs. Faked in widget tests.
abstract interface class SignInService {
  Future<SignInOutcome> xtream({
    String? name,
    required String server,
    required String username,
    required String password,
    bool allowUntrustedCert = false,
    CancelSignal? cancel,
  });

  Future<SignInOutcome> m3uUrl({
    String? name,
    required String url,
    String? epgUrl,
  });

  Future<SignInOutcome> m3uFile({
    String? name,
    required String fileName,
    required Uint8List bytes,
  });
}

/// Real sign-in: probe, save, make active, start the first sync. The sync
/// screen then shows progress and lets the user browse once channels are in.
class DefaultSignInService implements SignInService {
  DefaultSignInService(this.ref);

  final Ref ref;

  Future<void> _activate(String id) =>
      ref.read(activeProviderIdProvider.notifier).select(id);

  @override
  Future<SignInOutcome> xtream({
    String? name,
    required String server,
    required String username,
    required String password,
    bool allowUntrustedCert = false,
    CancelSignal? cancel,
  }) async {
    final input = ServerEndpoint.parse(server);
    if (!input.isValid) {
      return SignInFailed(
        input.error ?? const ConnectionError(ConnectionErrorKind.invalidInput),
      );
    }
    final host = input.candidates.first.host;
    final net = DioNetworkClient(
      allowUntrustedCertFor: allowUntrustedCert ? (h) => h == host : null,
    );
    try {
      final r = await ConnectionDoctor(network: net).probe(
        input: input,
        username: username,
        password: password,
        cancel: cancel,
      );
      switch (r) {
        case ProbeFailure(:final error, :final attempts):
          return SignInFailed(error, attempts: attempts);
        case ProbeSuccess():
          final id = await ref
              .read(providerRegistryProvider)
              .addXtream(
                probe: r,
                name: name,
                allowUntrustedCert: allowUntrustedCert,
              );
          await _activate(id);
          unawaited(ref.read(syncControllerProvider.notifier).refresh(id));
          return SignInOk(id, warnings: r.warnings);
      }
    } finally {
      net.close();
    }
  }

  @override
  Future<SignInOutcome> m3uUrl({
    String? name,
    required String url,
    String? epgUrl,
  }) async {
    final u = Uri.tryParse(url.trim());
    if (u == null ||
        (u.scheme != 'http' && u.scheme != 'https') ||
        u.host.isEmpty) {
      return const SignInFailed(
        ConnectionError(
          ConnectionErrorKind.invalidInput,
          details: 'playlist link must start with http:// or https://',
        ),
      );
    }
    final id = await ref
        .read(providerRegistryProvider)
        .addM3uUrl(url: u, name: name, epgUrl: epgUrl);
    await _activate(id);
    unawaited(ref.read(syncControllerProvider.notifier).refresh(id));
    return SignInOk(id);
  }

  @override
  Future<SignInOutcome> m3uFile({
    String? name,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final id = await ref
        .read(providerRegistryProvider)
        .addM3uFile(fileName: fileName, name: name);
    await _activate(id);
    unawaited(ref.read(syncControllerProvider.notifier).importFile(id, bytes));
    return SignInOk(id);
  }
}

final signInServiceProvider = Provider<SignInService>(DefaultSignInService.new);

/// Arguments for a Connection check that isn't for a saved provider (e.g.
/// right after a failed sign-in). Passed in memory, never in a URL.
@immutable
class ConnectionCheckArgs {
  const ConnectionCheckArgs({
    this.providerId,
    this.server,
    this.username,
    this.password,
    this.allowUntrustedCert = false,
  });

  final String? providerId;
  final String? server;
  final String? username;
  final String? password;
  final bool allowUntrustedCert;
}
