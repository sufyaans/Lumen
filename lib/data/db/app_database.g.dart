// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ProvidersTable extends Providers
    with TableInfo<$ProvidersTable, ProviderRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProvidersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayHostMeta = const VerificationMeta(
    'displayHost',
  );
  @override
  late final GeneratedColumn<String> displayHost = GeneratedColumn<String>(
    'display_host',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endpointJsonMeta = const VerificationMeta(
    'endpointJson',
  );
  @override
  late final GeneratedColumn<String> endpointJson = GeneratedColumn<String>(
    'endpoint_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userAgentIdMeta = const VerificationMeta(
    'userAgentId',
  );
  @override
  late final GeneratedColumn<String> userAgentId = GeneratedColumn<String>(
    'user_agent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _liveExtensionMeta = const VerificationMeta(
    'liveExtension',
  );
  @override
  late final GeneratedColumn<String> liveExtension = GeneratedColumn<String>(
    'live_extension',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _allowUntrustedCertMeta =
      const VerificationMeta('allowUntrustedCert');
  @override
  late final GeneratedColumn<bool> allowUntrustedCert = GeneratedColumn<bool>(
    'allow_untrusted_cert',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("allow_untrusted_cert" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _epgUrlMeta = const VerificationMeta('epgUrl');
  @override
  late final GeneratedColumn<String> epgUrl = GeneratedColumn<String>(
    'epg_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncAtMeta = const VerificationMeta(
    'lastSyncAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncAt = GeneratedColumn<DateTime>(
    'last_sync_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncErrorMeta = const VerificationMeta(
    'lastSyncError',
  );
  @override
  late final GeneratedColumn<String> lastSyncError = GeneratedColumn<String>(
    'last_sync_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userInfoJsonMeta = const VerificationMeta(
    'userInfoJson',
  );
  @override
  late final GeneratedColumn<String> userInfoJson = GeneratedColumn<String>(
    'user_info_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _serverInfoJsonMeta = const VerificationMeta(
    'serverInfoJson',
  );
  @override
  late final GeneratedColumn<String> serverInfoJson = GeneratedColumn<String>(
    'server_info_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    name,
    displayHost,
    username,
    endpointJson,
    userAgentId,
    liveExtension,
    allowUntrustedCert,
    epgUrl,
    fileName,
    lastSyncAt,
    lastSyncError,
    userInfoJson,
    serverInfoJson,
    createdAt,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'providers';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProviderRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('display_host')) {
      context.handle(
        _displayHostMeta,
        displayHost.isAcceptableOrUnknown(
          data['display_host']!,
          _displayHostMeta,
        ),
      );
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    }
    if (data.containsKey('endpoint_json')) {
      context.handle(
        _endpointJsonMeta,
        endpointJson.isAcceptableOrUnknown(
          data['endpoint_json']!,
          _endpointJsonMeta,
        ),
      );
    }
    if (data.containsKey('user_agent_id')) {
      context.handle(
        _userAgentIdMeta,
        userAgentId.isAcceptableOrUnknown(
          data['user_agent_id']!,
          _userAgentIdMeta,
        ),
      );
    }
    if (data.containsKey('live_extension')) {
      context.handle(
        _liveExtensionMeta,
        liveExtension.isAcceptableOrUnknown(
          data['live_extension']!,
          _liveExtensionMeta,
        ),
      );
    }
    if (data.containsKey('allow_untrusted_cert')) {
      context.handle(
        _allowUntrustedCertMeta,
        allowUntrustedCert.isAcceptableOrUnknown(
          data['allow_untrusted_cert']!,
          _allowUntrustedCertMeta,
        ),
      );
    }
    if (data.containsKey('epg_url')) {
      context.handle(
        _epgUrlMeta,
        epgUrl.isAcceptableOrUnknown(data['epg_url']!, _epgUrlMeta),
      );
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    }
    if (data.containsKey('last_sync_at')) {
      context.handle(
        _lastSyncAtMeta,
        lastSyncAt.isAcceptableOrUnknown(
          data['last_sync_at']!,
          _lastSyncAtMeta,
        ),
      );
    }
    if (data.containsKey('last_sync_error')) {
      context.handle(
        _lastSyncErrorMeta,
        lastSyncError.isAcceptableOrUnknown(
          data['last_sync_error']!,
          _lastSyncErrorMeta,
        ),
      );
    }
    if (data.containsKey('user_info_json')) {
      context.handle(
        _userInfoJsonMeta,
        userInfoJson.isAcceptableOrUnknown(
          data['user_info_json']!,
          _userInfoJsonMeta,
        ),
      );
    }
    if (data.containsKey('server_info_json')) {
      context.handle(
        _serverInfoJsonMeta,
        serverInfoJson.isAcceptableOrUnknown(
          data['server_info_json']!,
          _serverInfoJsonMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProviderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProviderRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      displayHost: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_host'],
      )!,
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      ),
      endpointJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}endpoint_json'],
      ),
      userAgentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_agent_id'],
      ),
      liveExtension: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}live_extension'],
      ),
      allowUntrustedCert: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}allow_untrusted_cert'],
      )!,
      epgUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}epg_url'],
      ),
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      ),
      lastSyncAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_sync_at'],
      ),
      lastSyncError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_sync_error'],
      ),
      userInfoJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_info_json'],
      ),
      serverInfoJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_info_json'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $ProvidersTable createAlias(String alias) {
    return $ProvidersTable(attachedDatabase, alias);
  }
}

class ProviderRow extends DataClass implements Insertable<ProviderRow> {
  final String id;

  /// `xtream`, `m3u_url` or `m3u_file`.
  final String kind;
  final String name;

  /// Host and port only, for display. Never contains credentials.
  final String displayHost;

  /// Xtream username. Not a secret on its own (shown in Account), but
  /// still never logged.
  final String? username;

  /// [ServerEndpoint] JSON: scheme, host, port, basePath.
  final String? endpointJson;
  final String? userAgentId;

  /// `ts` or `m3u8`, whichever last worked.
  final String? liveExtension;
  final bool allowUntrustedCert;
  final String? epgUrl;
  final String? fileName;
  final DateTime? lastSyncAt;
  final String? lastSyncError;
  final String? userInfoJson;
  final String? serverInfoJson;
  final DateTime createdAt;
  final int sortOrder;
  const ProviderRow({
    required this.id,
    required this.kind,
    required this.name,
    required this.displayHost,
    this.username,
    this.endpointJson,
    this.userAgentId,
    this.liveExtension,
    required this.allowUntrustedCert,
    this.epgUrl,
    this.fileName,
    this.lastSyncAt,
    this.lastSyncError,
    this.userInfoJson,
    this.serverInfoJson,
    required this.createdAt,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    map['name'] = Variable<String>(name);
    map['display_host'] = Variable<String>(displayHost);
    if (!nullToAbsent || username != null) {
      map['username'] = Variable<String>(username);
    }
    if (!nullToAbsent || endpointJson != null) {
      map['endpoint_json'] = Variable<String>(endpointJson);
    }
    if (!nullToAbsent || userAgentId != null) {
      map['user_agent_id'] = Variable<String>(userAgentId);
    }
    if (!nullToAbsent || liveExtension != null) {
      map['live_extension'] = Variable<String>(liveExtension);
    }
    map['allow_untrusted_cert'] = Variable<bool>(allowUntrustedCert);
    if (!nullToAbsent || epgUrl != null) {
      map['epg_url'] = Variable<String>(epgUrl);
    }
    if (!nullToAbsent || fileName != null) {
      map['file_name'] = Variable<String>(fileName);
    }
    if (!nullToAbsent || lastSyncAt != null) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt);
    }
    if (!nullToAbsent || lastSyncError != null) {
      map['last_sync_error'] = Variable<String>(lastSyncError);
    }
    if (!nullToAbsent || userInfoJson != null) {
      map['user_info_json'] = Variable<String>(userInfoJson);
    }
    if (!nullToAbsent || serverInfoJson != null) {
      map['server_info_json'] = Variable<String>(serverInfoJson);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  ProvidersCompanion toCompanion(bool nullToAbsent) {
    return ProvidersCompanion(
      id: Value(id),
      kind: Value(kind),
      name: Value(name),
      displayHost: Value(displayHost),
      username: username == null && nullToAbsent
          ? const Value.absent()
          : Value(username),
      endpointJson: endpointJson == null && nullToAbsent
          ? const Value.absent()
          : Value(endpointJson),
      userAgentId: userAgentId == null && nullToAbsent
          ? const Value.absent()
          : Value(userAgentId),
      liveExtension: liveExtension == null && nullToAbsent
          ? const Value.absent()
          : Value(liveExtension),
      allowUntrustedCert: Value(allowUntrustedCert),
      epgUrl: epgUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(epgUrl),
      fileName: fileName == null && nullToAbsent
          ? const Value.absent()
          : Value(fileName),
      lastSyncAt: lastSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAt),
      lastSyncError: lastSyncError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncError),
      userInfoJson: userInfoJson == null && nullToAbsent
          ? const Value.absent()
          : Value(userInfoJson),
      serverInfoJson: serverInfoJson == null && nullToAbsent
          ? const Value.absent()
          : Value(serverInfoJson),
      createdAt: Value(createdAt),
      sortOrder: Value(sortOrder),
    );
  }

  factory ProviderRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProviderRow(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      name: serializer.fromJson<String>(json['name']),
      displayHost: serializer.fromJson<String>(json['displayHost']),
      username: serializer.fromJson<String?>(json['username']),
      endpointJson: serializer.fromJson<String?>(json['endpointJson']),
      userAgentId: serializer.fromJson<String?>(json['userAgentId']),
      liveExtension: serializer.fromJson<String?>(json['liveExtension']),
      allowUntrustedCert: serializer.fromJson<bool>(json['allowUntrustedCert']),
      epgUrl: serializer.fromJson<String?>(json['epgUrl']),
      fileName: serializer.fromJson<String?>(json['fileName']),
      lastSyncAt: serializer.fromJson<DateTime?>(json['lastSyncAt']),
      lastSyncError: serializer.fromJson<String?>(json['lastSyncError']),
      userInfoJson: serializer.fromJson<String?>(json['userInfoJson']),
      serverInfoJson: serializer.fromJson<String?>(json['serverInfoJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'name': serializer.toJson<String>(name),
      'displayHost': serializer.toJson<String>(displayHost),
      'username': serializer.toJson<String?>(username),
      'endpointJson': serializer.toJson<String?>(endpointJson),
      'userAgentId': serializer.toJson<String?>(userAgentId),
      'liveExtension': serializer.toJson<String?>(liveExtension),
      'allowUntrustedCert': serializer.toJson<bool>(allowUntrustedCert),
      'epgUrl': serializer.toJson<String?>(epgUrl),
      'fileName': serializer.toJson<String?>(fileName),
      'lastSyncAt': serializer.toJson<DateTime?>(lastSyncAt),
      'lastSyncError': serializer.toJson<String?>(lastSyncError),
      'userInfoJson': serializer.toJson<String?>(userInfoJson),
      'serverInfoJson': serializer.toJson<String?>(serverInfoJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  ProviderRow copyWith({
    String? id,
    String? kind,
    String? name,
    String? displayHost,
    Value<String?> username = const Value.absent(),
    Value<String?> endpointJson = const Value.absent(),
    Value<String?> userAgentId = const Value.absent(),
    Value<String?> liveExtension = const Value.absent(),
    bool? allowUntrustedCert,
    Value<String?> epgUrl = const Value.absent(),
    Value<String?> fileName = const Value.absent(),
    Value<DateTime?> lastSyncAt = const Value.absent(),
    Value<String?> lastSyncError = const Value.absent(),
    Value<String?> userInfoJson = const Value.absent(),
    Value<String?> serverInfoJson = const Value.absent(),
    DateTime? createdAt,
    int? sortOrder,
  }) => ProviderRow(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    name: name ?? this.name,
    displayHost: displayHost ?? this.displayHost,
    username: username.present ? username.value : this.username,
    endpointJson: endpointJson.present ? endpointJson.value : this.endpointJson,
    userAgentId: userAgentId.present ? userAgentId.value : this.userAgentId,
    liveExtension: liveExtension.present
        ? liveExtension.value
        : this.liveExtension,
    allowUntrustedCert: allowUntrustedCert ?? this.allowUntrustedCert,
    epgUrl: epgUrl.present ? epgUrl.value : this.epgUrl,
    fileName: fileName.present ? fileName.value : this.fileName,
    lastSyncAt: lastSyncAt.present ? lastSyncAt.value : this.lastSyncAt,
    lastSyncError: lastSyncError.present
        ? lastSyncError.value
        : this.lastSyncError,
    userInfoJson: userInfoJson.present ? userInfoJson.value : this.userInfoJson,
    serverInfoJson: serverInfoJson.present
        ? serverInfoJson.value
        : this.serverInfoJson,
    createdAt: createdAt ?? this.createdAt,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  ProviderRow copyWithCompanion(ProvidersCompanion data) {
    return ProviderRow(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      name: data.name.present ? data.name.value : this.name,
      displayHost: data.displayHost.present
          ? data.displayHost.value
          : this.displayHost,
      username: data.username.present ? data.username.value : this.username,
      endpointJson: data.endpointJson.present
          ? data.endpointJson.value
          : this.endpointJson,
      userAgentId: data.userAgentId.present
          ? data.userAgentId.value
          : this.userAgentId,
      liveExtension: data.liveExtension.present
          ? data.liveExtension.value
          : this.liveExtension,
      allowUntrustedCert: data.allowUntrustedCert.present
          ? data.allowUntrustedCert.value
          : this.allowUntrustedCert,
      epgUrl: data.epgUrl.present ? data.epgUrl.value : this.epgUrl,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      lastSyncAt: data.lastSyncAt.present
          ? data.lastSyncAt.value
          : this.lastSyncAt,
      lastSyncError: data.lastSyncError.present
          ? data.lastSyncError.value
          : this.lastSyncError,
      userInfoJson: data.userInfoJson.present
          ? data.userInfoJson.value
          : this.userInfoJson,
      serverInfoJson: data.serverInfoJson.present
          ? data.serverInfoJson.value
          : this.serverInfoJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProviderRow(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('name: $name, ')
          ..write('displayHost: $displayHost, ')
          ..write('username: $username, ')
          ..write('endpointJson: $endpointJson, ')
          ..write('userAgentId: $userAgentId, ')
          ..write('liveExtension: $liveExtension, ')
          ..write('allowUntrustedCert: $allowUntrustedCert, ')
          ..write('epgUrl: $epgUrl, ')
          ..write('fileName: $fileName, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('lastSyncError: $lastSyncError, ')
          ..write('userInfoJson: $userInfoJson, ')
          ..write('serverInfoJson: $serverInfoJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    name,
    displayHost,
    username,
    endpointJson,
    userAgentId,
    liveExtension,
    allowUntrustedCert,
    epgUrl,
    fileName,
    lastSyncAt,
    lastSyncError,
    userInfoJson,
    serverInfoJson,
    createdAt,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProviderRow &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.name == this.name &&
          other.displayHost == this.displayHost &&
          other.username == this.username &&
          other.endpointJson == this.endpointJson &&
          other.userAgentId == this.userAgentId &&
          other.liveExtension == this.liveExtension &&
          other.allowUntrustedCert == this.allowUntrustedCert &&
          other.epgUrl == this.epgUrl &&
          other.fileName == this.fileName &&
          other.lastSyncAt == this.lastSyncAt &&
          other.lastSyncError == this.lastSyncError &&
          other.userInfoJson == this.userInfoJson &&
          other.serverInfoJson == this.serverInfoJson &&
          other.createdAt == this.createdAt &&
          other.sortOrder == this.sortOrder);
}

class ProvidersCompanion extends UpdateCompanion<ProviderRow> {
  final Value<String> id;
  final Value<String> kind;
  final Value<String> name;
  final Value<String> displayHost;
  final Value<String?> username;
  final Value<String?> endpointJson;
  final Value<String?> userAgentId;
  final Value<String?> liveExtension;
  final Value<bool> allowUntrustedCert;
  final Value<String?> epgUrl;
  final Value<String?> fileName;
  final Value<DateTime?> lastSyncAt;
  final Value<String?> lastSyncError;
  final Value<String?> userInfoJson;
  final Value<String?> serverInfoJson;
  final Value<DateTime> createdAt;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const ProvidersCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.name = const Value.absent(),
    this.displayHost = const Value.absent(),
    this.username = const Value.absent(),
    this.endpointJson = const Value.absent(),
    this.userAgentId = const Value.absent(),
    this.liveExtension = const Value.absent(),
    this.allowUntrustedCert = const Value.absent(),
    this.epgUrl = const Value.absent(),
    this.fileName = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.lastSyncError = const Value.absent(),
    this.userInfoJson = const Value.absent(),
    this.serverInfoJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProvidersCompanion.insert({
    required String id,
    required String kind,
    required String name,
    this.displayHost = const Value.absent(),
    this.username = const Value.absent(),
    this.endpointJson = const Value.absent(),
    this.userAgentId = const Value.absent(),
    this.liveExtension = const Value.absent(),
    this.allowUntrustedCert = const Value.absent(),
    this.epgUrl = const Value.absent(),
    this.fileName = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.lastSyncError = const Value.absent(),
    this.userInfoJson = const Value.absent(),
    this.serverInfoJson = const Value.absent(),
    required DateTime createdAt,
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind),
       name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<ProviderRow> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<String>? name,
    Expression<String>? displayHost,
    Expression<String>? username,
    Expression<String>? endpointJson,
    Expression<String>? userAgentId,
    Expression<String>? liveExtension,
    Expression<bool>? allowUntrustedCert,
    Expression<String>? epgUrl,
    Expression<String>? fileName,
    Expression<DateTime>? lastSyncAt,
    Expression<String>? lastSyncError,
    Expression<String>? userInfoJson,
    Expression<String>? serverInfoJson,
    Expression<DateTime>? createdAt,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (name != null) 'name': name,
      if (displayHost != null) 'display_host': displayHost,
      if (username != null) 'username': username,
      if (endpointJson != null) 'endpoint_json': endpointJson,
      if (userAgentId != null) 'user_agent_id': userAgentId,
      if (liveExtension != null) 'live_extension': liveExtension,
      if (allowUntrustedCert != null)
        'allow_untrusted_cert': allowUntrustedCert,
      if (epgUrl != null) 'epg_url': epgUrl,
      if (fileName != null) 'file_name': fileName,
      if (lastSyncAt != null) 'last_sync_at': lastSyncAt,
      if (lastSyncError != null) 'last_sync_error': lastSyncError,
      if (userInfoJson != null) 'user_info_json': userInfoJson,
      if (serverInfoJson != null) 'server_info_json': serverInfoJson,
      if (createdAt != null) 'created_at': createdAt,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProvidersCompanion copyWith({
    Value<String>? id,
    Value<String>? kind,
    Value<String>? name,
    Value<String>? displayHost,
    Value<String?>? username,
    Value<String?>? endpointJson,
    Value<String?>? userAgentId,
    Value<String?>? liveExtension,
    Value<bool>? allowUntrustedCert,
    Value<String?>? epgUrl,
    Value<String?>? fileName,
    Value<DateTime?>? lastSyncAt,
    Value<String?>? lastSyncError,
    Value<String?>? userInfoJson,
    Value<String?>? serverInfoJson,
    Value<DateTime>? createdAt,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return ProvidersCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      name: name ?? this.name,
      displayHost: displayHost ?? this.displayHost,
      username: username ?? this.username,
      endpointJson: endpointJson ?? this.endpointJson,
      userAgentId: userAgentId ?? this.userAgentId,
      liveExtension: liveExtension ?? this.liveExtension,
      allowUntrustedCert: allowUntrustedCert ?? this.allowUntrustedCert,
      epgUrl: epgUrl ?? this.epgUrl,
      fileName: fileName ?? this.fileName,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      lastSyncError: lastSyncError ?? this.lastSyncError,
      userInfoJson: userInfoJson ?? this.userInfoJson,
      serverInfoJson: serverInfoJson ?? this.serverInfoJson,
      createdAt: createdAt ?? this.createdAt,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (displayHost.present) {
      map['display_host'] = Variable<String>(displayHost.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (endpointJson.present) {
      map['endpoint_json'] = Variable<String>(endpointJson.value);
    }
    if (userAgentId.present) {
      map['user_agent_id'] = Variable<String>(userAgentId.value);
    }
    if (liveExtension.present) {
      map['live_extension'] = Variable<String>(liveExtension.value);
    }
    if (allowUntrustedCert.present) {
      map['allow_untrusted_cert'] = Variable<bool>(allowUntrustedCert.value);
    }
    if (epgUrl.present) {
      map['epg_url'] = Variable<String>(epgUrl.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (lastSyncAt.present) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt.value);
    }
    if (lastSyncError.present) {
      map['last_sync_error'] = Variable<String>(lastSyncError.value);
    }
    if (userInfoJson.present) {
      map['user_info_json'] = Variable<String>(userInfoJson.value);
    }
    if (serverInfoJson.present) {
      map['server_info_json'] = Variable<String>(serverInfoJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProvidersCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('name: $name, ')
          ..write('displayHost: $displayHost, ')
          ..write('username: $username, ')
          ..write('endpointJson: $endpointJson, ')
          ..write('userAgentId: $userAgentId, ')
          ..write('liveExtension: $liveExtension, ')
          ..write('allowUntrustedCert: $allowUntrustedCert, ')
          ..write('epgUrl: $epgUrl, ')
          ..write('fileName: $fileName, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('lastSyncError: $lastSyncError, ')
          ..write('userInfoJson: $userInfoJson, ')
          ..write('serverInfoJson: $serverInfoJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, CategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
    'provider_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isAdultMeta = const VerificationMeta(
    'isAdult',
  );
  @override
  late final GeneratedColumn<bool> isAdult = GeneratedColumn<bool>(
    'is_adult',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_adult" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isKidsMeta = const VerificationMeta('isKids');
  @override
  late final GeneratedColumn<bool> isKids = GeneratedColumn<bool>(
    'is_kids',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_kids" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _syncTokenMeta = const VerificationMeta(
    'syncToken',
  );
  @override
  late final GeneratedColumn<int> syncToken = GeneratedColumn<int>(
    'sync_token',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    providerId,
    kind,
    remoteId,
    name,
    isAdult,
    isKids,
    sortOrder,
    syncToken,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_remoteIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('is_adult')) {
      context.handle(
        _isAdultMeta,
        isAdult.isAcceptableOrUnknown(data['is_adult']!, _isAdultMeta),
      );
    }
    if (data.containsKey('is_kids')) {
      context.handle(
        _isKidsMeta,
        isKids.isAcceptableOrUnknown(data['is_kids']!, _isKidsMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('sync_token')) {
      context.handle(
        _syncTokenMeta,
        syncToken.isAcceptableOrUnknown(data['sync_token']!, _syncTokenMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {providerId, kind, remoteId};
  @override
  CategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryRow(
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      isAdult: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_adult'],
      )!,
      isKids: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_kids'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      syncToken: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_token'],
      )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class CategoryRow extends DataClass implements Insertable<CategoryRow> {
  final String providerId;

  /// [ContentKind.live], [ContentKind.movie] or [ContentKind.series].
  final String kind;
  final String remoteId;
  final String name;
  final bool isAdult;
  final bool isKids;
  final int sortOrder;
  final int syncToken;
  const CategoryRow({
    required this.providerId,
    required this.kind,
    required this.remoteId,
    required this.name,
    required this.isAdult,
    required this.isKids,
    required this.sortOrder,
    required this.syncToken,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['provider_id'] = Variable<String>(providerId);
    map['kind'] = Variable<String>(kind);
    map['remote_id'] = Variable<String>(remoteId);
    map['name'] = Variable<String>(name);
    map['is_adult'] = Variable<bool>(isAdult);
    map['is_kids'] = Variable<bool>(isKids);
    map['sort_order'] = Variable<int>(sortOrder);
    map['sync_token'] = Variable<int>(syncToken);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      providerId: Value(providerId),
      kind: Value(kind),
      remoteId: Value(remoteId),
      name: Value(name),
      isAdult: Value(isAdult),
      isKids: Value(isKids),
      sortOrder: Value(sortOrder),
      syncToken: Value(syncToken),
    );
  }

  factory CategoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryRow(
      providerId: serializer.fromJson<String>(json['providerId']),
      kind: serializer.fromJson<String>(json['kind']),
      remoteId: serializer.fromJson<String>(json['remoteId']),
      name: serializer.fromJson<String>(json['name']),
      isAdult: serializer.fromJson<bool>(json['isAdult']),
      isKids: serializer.fromJson<bool>(json['isKids']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      syncToken: serializer.fromJson<int>(json['syncToken']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'providerId': serializer.toJson<String>(providerId),
      'kind': serializer.toJson<String>(kind),
      'remoteId': serializer.toJson<String>(remoteId),
      'name': serializer.toJson<String>(name),
      'isAdult': serializer.toJson<bool>(isAdult),
      'isKids': serializer.toJson<bool>(isKids),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'syncToken': serializer.toJson<int>(syncToken),
    };
  }

  CategoryRow copyWith({
    String? providerId,
    String? kind,
    String? remoteId,
    String? name,
    bool? isAdult,
    bool? isKids,
    int? sortOrder,
    int? syncToken,
  }) => CategoryRow(
    providerId: providerId ?? this.providerId,
    kind: kind ?? this.kind,
    remoteId: remoteId ?? this.remoteId,
    name: name ?? this.name,
    isAdult: isAdult ?? this.isAdult,
    isKids: isKids ?? this.isKids,
    sortOrder: sortOrder ?? this.sortOrder,
    syncToken: syncToken ?? this.syncToken,
  );
  CategoryRow copyWithCompanion(CategoriesCompanion data) {
    return CategoryRow(
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      kind: data.kind.present ? data.kind.value : this.kind,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      name: data.name.present ? data.name.value : this.name,
      isAdult: data.isAdult.present ? data.isAdult.value : this.isAdult,
      isKids: data.isKids.present ? data.isKids.value : this.isKids,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      syncToken: data.syncToken.present ? data.syncToken.value : this.syncToken,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryRow(')
          ..write('providerId: $providerId, ')
          ..write('kind: $kind, ')
          ..write('remoteId: $remoteId, ')
          ..write('name: $name, ')
          ..write('isAdult: $isAdult, ')
          ..write('isKids: $isKids, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('syncToken: $syncToken')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    providerId,
    kind,
    remoteId,
    name,
    isAdult,
    isKids,
    sortOrder,
    syncToken,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryRow &&
          other.providerId == this.providerId &&
          other.kind == this.kind &&
          other.remoteId == this.remoteId &&
          other.name == this.name &&
          other.isAdult == this.isAdult &&
          other.isKids == this.isKids &&
          other.sortOrder == this.sortOrder &&
          other.syncToken == this.syncToken);
}

class CategoriesCompanion extends UpdateCompanion<CategoryRow> {
  final Value<String> providerId;
  final Value<String> kind;
  final Value<String> remoteId;
  final Value<String> name;
  final Value<bool> isAdult;
  final Value<bool> isKids;
  final Value<int> sortOrder;
  final Value<int> syncToken;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.providerId = const Value.absent(),
    this.kind = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.name = const Value.absent(),
    this.isAdult = const Value.absent(),
    this.isKids = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.syncToken = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String providerId,
    required String kind,
    required String remoteId,
    required String name,
    this.isAdult = const Value.absent(),
    this.isKids = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.syncToken = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : providerId = Value(providerId),
       kind = Value(kind),
       remoteId = Value(remoteId),
       name = Value(name);
  static Insertable<CategoryRow> custom({
    Expression<String>? providerId,
    Expression<String>? kind,
    Expression<String>? remoteId,
    Expression<String>? name,
    Expression<bool>? isAdult,
    Expression<bool>? isKids,
    Expression<int>? sortOrder,
    Expression<int>? syncToken,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (providerId != null) 'provider_id': providerId,
      if (kind != null) 'kind': kind,
      if (remoteId != null) 'remote_id': remoteId,
      if (name != null) 'name': name,
      if (isAdult != null) 'is_adult': isAdult,
      if (isKids != null) 'is_kids': isKids,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (syncToken != null) 'sync_token': syncToken,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith({
    Value<String>? providerId,
    Value<String>? kind,
    Value<String>? remoteId,
    Value<String>? name,
    Value<bool>? isAdult,
    Value<bool>? isKids,
    Value<int>? sortOrder,
    Value<int>? syncToken,
    Value<int>? rowid,
  }) {
    return CategoriesCompanion(
      providerId: providerId ?? this.providerId,
      kind: kind ?? this.kind,
      remoteId: remoteId ?? this.remoteId,
      name: name ?? this.name,
      isAdult: isAdult ?? this.isAdult,
      isKids: isKids ?? this.isKids,
      sortOrder: sortOrder ?? this.sortOrder,
      syncToken: syncToken ?? this.syncToken,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isAdult.present) {
      map['is_adult'] = Variable<bool>(isAdult.value);
    }
    if (isKids.present) {
      map['is_kids'] = Variable<bool>(isKids.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (syncToken.present) {
      map['sync_token'] = Variable<int>(syncToken.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('providerId: $providerId, ')
          ..write('kind: $kind, ')
          ..write('remoteId: $remoteId, ')
          ..write('name: $name, ')
          ..write('isAdult: $isAdult, ')
          ..write('isKids: $isKids, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('syncToken: $syncToken, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChannelsTable extends Channels
    with TableInfo<$ChannelsTable, ChannelRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChannelsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
    'provider_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<int> number = GeneratedColumn<int>(
    'number',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _logoMeta = const VerificationMeta('logo');
  @override
  late final GeneratedColumn<String> logo = GeneratedColumn<String>(
    'logo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _epgIdMeta = const VerificationMeta('epgId');
  @override
  late final GeneratedColumn<String> epgId = GeneratedColumn<String>(
    'epg_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tvArchiveMeta = const VerificationMeta(
    'tvArchive',
  );
  @override
  late final GeneratedColumn<bool> tvArchive = GeneratedColumn<bool>(
    'tv_archive',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("tv_archive" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _archiveDaysMeta = const VerificationMeta(
    'archiveDays',
  );
  @override
  late final GeneratedColumn<int> archiveDays = GeneratedColumn<int>(
    'archive_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _headersJsonMeta = const VerificationMeta(
    'headersJson',
  );
  @override
  late final GeneratedColumn<String> headersJson = GeneratedColumn<String>(
    'headers_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isAdultMeta = const VerificationMeta(
    'isAdult',
  );
  @override
  late final GeneratedColumn<bool> isAdult = GeneratedColumn<bool>(
    'is_adult',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_adult" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _syncTokenMeta = const VerificationMeta(
    'syncToken',
  );
  @override
  late final GeneratedColumn<int> syncToken = GeneratedColumn<int>(
    'sync_token',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    providerId,
    remoteId,
    name,
    number,
    logo,
    epgId,
    categoryId,
    tvArchive,
    archiveDays,
    url,
    headersJson,
    isAdult,
    sortOrder,
    syncToken,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'channels';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChannelRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_remoteIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    }
    if (data.containsKey('logo')) {
      context.handle(
        _logoMeta,
        logo.isAcceptableOrUnknown(data['logo']!, _logoMeta),
      );
    }
    if (data.containsKey('epg_id')) {
      context.handle(
        _epgIdMeta,
        epgId.isAcceptableOrUnknown(data['epg_id']!, _epgIdMeta),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('tv_archive')) {
      context.handle(
        _tvArchiveMeta,
        tvArchive.isAcceptableOrUnknown(data['tv_archive']!, _tvArchiveMeta),
      );
    }
    if (data.containsKey('archive_days')) {
      context.handle(
        _archiveDaysMeta,
        archiveDays.isAcceptableOrUnknown(
          data['archive_days']!,
          _archiveDaysMeta,
        ),
      );
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    }
    if (data.containsKey('headers_json')) {
      context.handle(
        _headersJsonMeta,
        headersJson.isAcceptableOrUnknown(
          data['headers_json']!,
          _headersJsonMeta,
        ),
      );
    }
    if (data.containsKey('is_adult')) {
      context.handle(
        _isAdultMeta,
        isAdult.isAcceptableOrUnknown(data['is_adult']!, _isAdultMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('sync_token')) {
      context.handle(
        _syncTokenMeta,
        syncToken.isAcceptableOrUnknown(data['sync_token']!, _syncTokenMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {providerId, remoteId};
  @override
  ChannelRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChannelRow(
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_id'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}number'],
      ),
      logo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}logo'],
      ),
      epgId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}epg_id'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      tvArchive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}tv_archive'],
      )!,
      archiveDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}archive_days'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      ),
      headersJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}headers_json'],
      ),
      isAdult: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_adult'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      syncToken: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_token'],
      )!,
    );
  }

  @override
  $ChannelsTable createAlias(String alias) {
    return $ChannelsTable(attachedDatabase, alias);
  }
}

class ChannelRow extends DataClass implements Insertable<ChannelRow> {
  final String providerId;
  final String remoteId;
  final String name;
  final int? number;
  final String? logo;
  final String? epgId;
  final String? categoryId;
  final bool tvArchive;
  final int archiveDays;

  /// M3U entries only. Known credentials are replaced with placeholders
  /// (see [SecretTemplate]); Xtream URLs are built at play time.
  final String? url;

  /// M3U per-entry HTTP headers as JSON.
  final String? headersJson;
  final bool isAdult;
  final int sortOrder;
  final int syncToken;
  const ChannelRow({
    required this.providerId,
    required this.remoteId,
    required this.name,
    this.number,
    this.logo,
    this.epgId,
    this.categoryId,
    required this.tvArchive,
    required this.archiveDays,
    this.url,
    this.headersJson,
    required this.isAdult,
    required this.sortOrder,
    required this.syncToken,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['provider_id'] = Variable<String>(providerId);
    map['remote_id'] = Variable<String>(remoteId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || number != null) {
      map['number'] = Variable<int>(number);
    }
    if (!nullToAbsent || logo != null) {
      map['logo'] = Variable<String>(logo);
    }
    if (!nullToAbsent || epgId != null) {
      map['epg_id'] = Variable<String>(epgId);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['tv_archive'] = Variable<bool>(tvArchive);
    map['archive_days'] = Variable<int>(archiveDays);
    if (!nullToAbsent || url != null) {
      map['url'] = Variable<String>(url);
    }
    if (!nullToAbsent || headersJson != null) {
      map['headers_json'] = Variable<String>(headersJson);
    }
    map['is_adult'] = Variable<bool>(isAdult);
    map['sort_order'] = Variable<int>(sortOrder);
    map['sync_token'] = Variable<int>(syncToken);
    return map;
  }

  ChannelsCompanion toCompanion(bool nullToAbsent) {
    return ChannelsCompanion(
      providerId: Value(providerId),
      remoteId: Value(remoteId),
      name: Value(name),
      number: number == null && nullToAbsent
          ? const Value.absent()
          : Value(number),
      logo: logo == null && nullToAbsent ? const Value.absent() : Value(logo),
      epgId: epgId == null && nullToAbsent
          ? const Value.absent()
          : Value(epgId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      tvArchive: Value(tvArchive),
      archiveDays: Value(archiveDays),
      url: url == null && nullToAbsent ? const Value.absent() : Value(url),
      headersJson: headersJson == null && nullToAbsent
          ? const Value.absent()
          : Value(headersJson),
      isAdult: Value(isAdult),
      sortOrder: Value(sortOrder),
      syncToken: Value(syncToken),
    );
  }

  factory ChannelRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChannelRow(
      providerId: serializer.fromJson<String>(json['providerId']),
      remoteId: serializer.fromJson<String>(json['remoteId']),
      name: serializer.fromJson<String>(json['name']),
      number: serializer.fromJson<int?>(json['number']),
      logo: serializer.fromJson<String?>(json['logo']),
      epgId: serializer.fromJson<String?>(json['epgId']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      tvArchive: serializer.fromJson<bool>(json['tvArchive']),
      archiveDays: serializer.fromJson<int>(json['archiveDays']),
      url: serializer.fromJson<String?>(json['url']),
      headersJson: serializer.fromJson<String?>(json['headersJson']),
      isAdult: serializer.fromJson<bool>(json['isAdult']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      syncToken: serializer.fromJson<int>(json['syncToken']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'providerId': serializer.toJson<String>(providerId),
      'remoteId': serializer.toJson<String>(remoteId),
      'name': serializer.toJson<String>(name),
      'number': serializer.toJson<int?>(number),
      'logo': serializer.toJson<String?>(logo),
      'epgId': serializer.toJson<String?>(epgId),
      'categoryId': serializer.toJson<String?>(categoryId),
      'tvArchive': serializer.toJson<bool>(tvArchive),
      'archiveDays': serializer.toJson<int>(archiveDays),
      'url': serializer.toJson<String?>(url),
      'headersJson': serializer.toJson<String?>(headersJson),
      'isAdult': serializer.toJson<bool>(isAdult),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'syncToken': serializer.toJson<int>(syncToken),
    };
  }

  ChannelRow copyWith({
    String? providerId,
    String? remoteId,
    String? name,
    Value<int?> number = const Value.absent(),
    Value<String?> logo = const Value.absent(),
    Value<String?> epgId = const Value.absent(),
    Value<String?> categoryId = const Value.absent(),
    bool? tvArchive,
    int? archiveDays,
    Value<String?> url = const Value.absent(),
    Value<String?> headersJson = const Value.absent(),
    bool? isAdult,
    int? sortOrder,
    int? syncToken,
  }) => ChannelRow(
    providerId: providerId ?? this.providerId,
    remoteId: remoteId ?? this.remoteId,
    name: name ?? this.name,
    number: number.present ? number.value : this.number,
    logo: logo.present ? logo.value : this.logo,
    epgId: epgId.present ? epgId.value : this.epgId,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    tvArchive: tvArchive ?? this.tvArchive,
    archiveDays: archiveDays ?? this.archiveDays,
    url: url.present ? url.value : this.url,
    headersJson: headersJson.present ? headersJson.value : this.headersJson,
    isAdult: isAdult ?? this.isAdult,
    sortOrder: sortOrder ?? this.sortOrder,
    syncToken: syncToken ?? this.syncToken,
  );
  ChannelRow copyWithCompanion(ChannelsCompanion data) {
    return ChannelRow(
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      name: data.name.present ? data.name.value : this.name,
      number: data.number.present ? data.number.value : this.number,
      logo: data.logo.present ? data.logo.value : this.logo,
      epgId: data.epgId.present ? data.epgId.value : this.epgId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      tvArchive: data.tvArchive.present ? data.tvArchive.value : this.tvArchive,
      archiveDays: data.archiveDays.present
          ? data.archiveDays.value
          : this.archiveDays,
      url: data.url.present ? data.url.value : this.url,
      headersJson: data.headersJson.present
          ? data.headersJson.value
          : this.headersJson,
      isAdult: data.isAdult.present ? data.isAdult.value : this.isAdult,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      syncToken: data.syncToken.present ? data.syncToken.value : this.syncToken,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChannelRow(')
          ..write('providerId: $providerId, ')
          ..write('remoteId: $remoteId, ')
          ..write('name: $name, ')
          ..write('number: $number, ')
          ..write('logo: $logo, ')
          ..write('epgId: $epgId, ')
          ..write('categoryId: $categoryId, ')
          ..write('tvArchive: $tvArchive, ')
          ..write('archiveDays: $archiveDays, ')
          ..write('url: $url, ')
          ..write('headersJson: $headersJson, ')
          ..write('isAdult: $isAdult, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('syncToken: $syncToken')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    providerId,
    remoteId,
    name,
    number,
    logo,
    epgId,
    categoryId,
    tvArchive,
    archiveDays,
    url,
    headersJson,
    isAdult,
    sortOrder,
    syncToken,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChannelRow &&
          other.providerId == this.providerId &&
          other.remoteId == this.remoteId &&
          other.name == this.name &&
          other.number == this.number &&
          other.logo == this.logo &&
          other.epgId == this.epgId &&
          other.categoryId == this.categoryId &&
          other.tvArchive == this.tvArchive &&
          other.archiveDays == this.archiveDays &&
          other.url == this.url &&
          other.headersJson == this.headersJson &&
          other.isAdult == this.isAdult &&
          other.sortOrder == this.sortOrder &&
          other.syncToken == this.syncToken);
}

class ChannelsCompanion extends UpdateCompanion<ChannelRow> {
  final Value<String> providerId;
  final Value<String> remoteId;
  final Value<String> name;
  final Value<int?> number;
  final Value<String?> logo;
  final Value<String?> epgId;
  final Value<String?> categoryId;
  final Value<bool> tvArchive;
  final Value<int> archiveDays;
  final Value<String?> url;
  final Value<String?> headersJson;
  final Value<bool> isAdult;
  final Value<int> sortOrder;
  final Value<int> syncToken;
  final Value<int> rowid;
  const ChannelsCompanion({
    this.providerId = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.name = const Value.absent(),
    this.number = const Value.absent(),
    this.logo = const Value.absent(),
    this.epgId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.tvArchive = const Value.absent(),
    this.archiveDays = const Value.absent(),
    this.url = const Value.absent(),
    this.headersJson = const Value.absent(),
    this.isAdult = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.syncToken = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChannelsCompanion.insert({
    required String providerId,
    required String remoteId,
    required String name,
    this.number = const Value.absent(),
    this.logo = const Value.absent(),
    this.epgId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.tvArchive = const Value.absent(),
    this.archiveDays = const Value.absent(),
    this.url = const Value.absent(),
    this.headersJson = const Value.absent(),
    this.isAdult = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.syncToken = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : providerId = Value(providerId),
       remoteId = Value(remoteId),
       name = Value(name);
  static Insertable<ChannelRow> custom({
    Expression<String>? providerId,
    Expression<String>? remoteId,
    Expression<String>? name,
    Expression<int>? number,
    Expression<String>? logo,
    Expression<String>? epgId,
    Expression<String>? categoryId,
    Expression<bool>? tvArchive,
    Expression<int>? archiveDays,
    Expression<String>? url,
    Expression<String>? headersJson,
    Expression<bool>? isAdult,
    Expression<int>? sortOrder,
    Expression<int>? syncToken,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (providerId != null) 'provider_id': providerId,
      if (remoteId != null) 'remote_id': remoteId,
      if (name != null) 'name': name,
      if (number != null) 'number': number,
      if (logo != null) 'logo': logo,
      if (epgId != null) 'epg_id': epgId,
      if (categoryId != null) 'category_id': categoryId,
      if (tvArchive != null) 'tv_archive': tvArchive,
      if (archiveDays != null) 'archive_days': archiveDays,
      if (url != null) 'url': url,
      if (headersJson != null) 'headers_json': headersJson,
      if (isAdult != null) 'is_adult': isAdult,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (syncToken != null) 'sync_token': syncToken,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChannelsCompanion copyWith({
    Value<String>? providerId,
    Value<String>? remoteId,
    Value<String>? name,
    Value<int?>? number,
    Value<String?>? logo,
    Value<String?>? epgId,
    Value<String?>? categoryId,
    Value<bool>? tvArchive,
    Value<int>? archiveDays,
    Value<String?>? url,
    Value<String?>? headersJson,
    Value<bool>? isAdult,
    Value<int>? sortOrder,
    Value<int>? syncToken,
    Value<int>? rowid,
  }) {
    return ChannelsCompanion(
      providerId: providerId ?? this.providerId,
      remoteId: remoteId ?? this.remoteId,
      name: name ?? this.name,
      number: number ?? this.number,
      logo: logo ?? this.logo,
      epgId: epgId ?? this.epgId,
      categoryId: categoryId ?? this.categoryId,
      tvArchive: tvArchive ?? this.tvArchive,
      archiveDays: archiveDays ?? this.archiveDays,
      url: url ?? this.url,
      headersJson: headersJson ?? this.headersJson,
      isAdult: isAdult ?? this.isAdult,
      sortOrder: sortOrder ?? this.sortOrder,
      syncToken: syncToken ?? this.syncToken,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (number.present) {
      map['number'] = Variable<int>(number.value);
    }
    if (logo.present) {
      map['logo'] = Variable<String>(logo.value);
    }
    if (epgId.present) {
      map['epg_id'] = Variable<String>(epgId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (tvArchive.present) {
      map['tv_archive'] = Variable<bool>(tvArchive.value);
    }
    if (archiveDays.present) {
      map['archive_days'] = Variable<int>(archiveDays.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (headersJson.present) {
      map['headers_json'] = Variable<String>(headersJson.value);
    }
    if (isAdult.present) {
      map['is_adult'] = Variable<bool>(isAdult.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (syncToken.present) {
      map['sync_token'] = Variable<int>(syncToken.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChannelsCompanion(')
          ..write('providerId: $providerId, ')
          ..write('remoteId: $remoteId, ')
          ..write('name: $name, ')
          ..write('number: $number, ')
          ..write('logo: $logo, ')
          ..write('epgId: $epgId, ')
          ..write('categoryId: $categoryId, ')
          ..write('tvArchive: $tvArchive, ')
          ..write('archiveDays: $archiveDays, ')
          ..write('url: $url, ')
          ..write('headersJson: $headersJson, ')
          ..write('isAdult: $isAdult, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('syncToken: $syncToken, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MoviesTable extends Movies with TableInfo<$MoviesTable, MovieRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MoviesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
    'provider_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _posterMeta = const VerificationMeta('poster');
  @override
  late final GeneratedColumn<String> poster = GeneratedColumn<String>(
    'poster',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _containerExtensionMeta =
      const VerificationMeta('containerExtension');
  @override
  late final GeneratedColumn<String> containerExtension =
      GeneratedColumn<String>(
        'container_extension',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('mp4'),
      );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<double> rating = GeneratedColumn<double>(
    'rating',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _addedMeta = const VerificationMeta('added');
  @override
  late final GeneratedColumn<DateTime> added = GeneratedColumn<DateTime>(
    'added',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _headersJsonMeta = const VerificationMeta(
    'headersJson',
  );
  @override
  late final GeneratedColumn<String> headersJson = GeneratedColumn<String>(
    'headers_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isAdultMeta = const VerificationMeta(
    'isAdult',
  );
  @override
  late final GeneratedColumn<bool> isAdult = GeneratedColumn<bool>(
    'is_adult',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_adult" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _syncTokenMeta = const VerificationMeta(
    'syncToken',
  );
  @override
  late final GeneratedColumn<int> syncToken = GeneratedColumn<int>(
    'sync_token',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    providerId,
    remoteId,
    name,
    poster,
    categoryId,
    containerExtension,
    rating,
    year,
    added,
    url,
    headersJson,
    isAdult,
    sortOrder,
    syncToken,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'movies';
  @override
  VerificationContext validateIntegrity(
    Insertable<MovieRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_remoteIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('poster')) {
      context.handle(
        _posterMeta,
        poster.isAcceptableOrUnknown(data['poster']!, _posterMeta),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('container_extension')) {
      context.handle(
        _containerExtensionMeta,
        containerExtension.isAcceptableOrUnknown(
          data['container_extension']!,
          _containerExtensionMeta,
        ),
      );
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('added')) {
      context.handle(
        _addedMeta,
        added.isAcceptableOrUnknown(data['added']!, _addedMeta),
      );
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    }
    if (data.containsKey('headers_json')) {
      context.handle(
        _headersJsonMeta,
        headersJson.isAcceptableOrUnknown(
          data['headers_json']!,
          _headersJsonMeta,
        ),
      );
    }
    if (data.containsKey('is_adult')) {
      context.handle(
        _isAdultMeta,
        isAdult.isAcceptableOrUnknown(data['is_adult']!, _isAdultMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('sync_token')) {
      context.handle(
        _syncTokenMeta,
        syncToken.isAcceptableOrUnknown(data['sync_token']!, _syncTokenMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {providerId, remoteId};
  @override
  MovieRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MovieRow(
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_id'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      poster: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}poster'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      containerExtension: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}container_extension'],
      )!,
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rating'],
      ),
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      ),
      added: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added'],
      ),
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      ),
      headersJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}headers_json'],
      ),
      isAdult: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_adult'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      syncToken: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_token'],
      )!,
    );
  }

  @override
  $MoviesTable createAlias(String alias) {
    return $MoviesTable(attachedDatabase, alias);
  }
}

class MovieRow extends DataClass implements Insertable<MovieRow> {
  final String providerId;
  final String remoteId;
  final String name;
  final String? poster;
  final String? categoryId;
  final String containerExtension;
  final double? rating;
  final int? year;
  final DateTime? added;
  final String? url;
  final String? headersJson;
  final bool isAdult;
  final int sortOrder;
  final int syncToken;
  const MovieRow({
    required this.providerId,
    required this.remoteId,
    required this.name,
    this.poster,
    this.categoryId,
    required this.containerExtension,
    this.rating,
    this.year,
    this.added,
    this.url,
    this.headersJson,
    required this.isAdult,
    required this.sortOrder,
    required this.syncToken,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['provider_id'] = Variable<String>(providerId);
    map['remote_id'] = Variable<String>(remoteId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || poster != null) {
      map['poster'] = Variable<String>(poster);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['container_extension'] = Variable<String>(containerExtension);
    if (!nullToAbsent || rating != null) {
      map['rating'] = Variable<double>(rating);
    }
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<int>(year);
    }
    if (!nullToAbsent || added != null) {
      map['added'] = Variable<DateTime>(added);
    }
    if (!nullToAbsent || url != null) {
      map['url'] = Variable<String>(url);
    }
    if (!nullToAbsent || headersJson != null) {
      map['headers_json'] = Variable<String>(headersJson);
    }
    map['is_adult'] = Variable<bool>(isAdult);
    map['sort_order'] = Variable<int>(sortOrder);
    map['sync_token'] = Variable<int>(syncToken);
    return map;
  }

  MoviesCompanion toCompanion(bool nullToAbsent) {
    return MoviesCompanion(
      providerId: Value(providerId),
      remoteId: Value(remoteId),
      name: Value(name),
      poster: poster == null && nullToAbsent
          ? const Value.absent()
          : Value(poster),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      containerExtension: Value(containerExtension),
      rating: rating == null && nullToAbsent
          ? const Value.absent()
          : Value(rating),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      added: added == null && nullToAbsent
          ? const Value.absent()
          : Value(added),
      url: url == null && nullToAbsent ? const Value.absent() : Value(url),
      headersJson: headersJson == null && nullToAbsent
          ? const Value.absent()
          : Value(headersJson),
      isAdult: Value(isAdult),
      sortOrder: Value(sortOrder),
      syncToken: Value(syncToken),
    );
  }

  factory MovieRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MovieRow(
      providerId: serializer.fromJson<String>(json['providerId']),
      remoteId: serializer.fromJson<String>(json['remoteId']),
      name: serializer.fromJson<String>(json['name']),
      poster: serializer.fromJson<String?>(json['poster']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      containerExtension: serializer.fromJson<String>(
        json['containerExtension'],
      ),
      rating: serializer.fromJson<double?>(json['rating']),
      year: serializer.fromJson<int?>(json['year']),
      added: serializer.fromJson<DateTime?>(json['added']),
      url: serializer.fromJson<String?>(json['url']),
      headersJson: serializer.fromJson<String?>(json['headersJson']),
      isAdult: serializer.fromJson<bool>(json['isAdult']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      syncToken: serializer.fromJson<int>(json['syncToken']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'providerId': serializer.toJson<String>(providerId),
      'remoteId': serializer.toJson<String>(remoteId),
      'name': serializer.toJson<String>(name),
      'poster': serializer.toJson<String?>(poster),
      'categoryId': serializer.toJson<String?>(categoryId),
      'containerExtension': serializer.toJson<String>(containerExtension),
      'rating': serializer.toJson<double?>(rating),
      'year': serializer.toJson<int?>(year),
      'added': serializer.toJson<DateTime?>(added),
      'url': serializer.toJson<String?>(url),
      'headersJson': serializer.toJson<String?>(headersJson),
      'isAdult': serializer.toJson<bool>(isAdult),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'syncToken': serializer.toJson<int>(syncToken),
    };
  }

  MovieRow copyWith({
    String? providerId,
    String? remoteId,
    String? name,
    Value<String?> poster = const Value.absent(),
    Value<String?> categoryId = const Value.absent(),
    String? containerExtension,
    Value<double?> rating = const Value.absent(),
    Value<int?> year = const Value.absent(),
    Value<DateTime?> added = const Value.absent(),
    Value<String?> url = const Value.absent(),
    Value<String?> headersJson = const Value.absent(),
    bool? isAdult,
    int? sortOrder,
    int? syncToken,
  }) => MovieRow(
    providerId: providerId ?? this.providerId,
    remoteId: remoteId ?? this.remoteId,
    name: name ?? this.name,
    poster: poster.present ? poster.value : this.poster,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    containerExtension: containerExtension ?? this.containerExtension,
    rating: rating.present ? rating.value : this.rating,
    year: year.present ? year.value : this.year,
    added: added.present ? added.value : this.added,
    url: url.present ? url.value : this.url,
    headersJson: headersJson.present ? headersJson.value : this.headersJson,
    isAdult: isAdult ?? this.isAdult,
    sortOrder: sortOrder ?? this.sortOrder,
    syncToken: syncToken ?? this.syncToken,
  );
  MovieRow copyWithCompanion(MoviesCompanion data) {
    return MovieRow(
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      name: data.name.present ? data.name.value : this.name,
      poster: data.poster.present ? data.poster.value : this.poster,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      containerExtension: data.containerExtension.present
          ? data.containerExtension.value
          : this.containerExtension,
      rating: data.rating.present ? data.rating.value : this.rating,
      year: data.year.present ? data.year.value : this.year,
      added: data.added.present ? data.added.value : this.added,
      url: data.url.present ? data.url.value : this.url,
      headersJson: data.headersJson.present
          ? data.headersJson.value
          : this.headersJson,
      isAdult: data.isAdult.present ? data.isAdult.value : this.isAdult,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      syncToken: data.syncToken.present ? data.syncToken.value : this.syncToken,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MovieRow(')
          ..write('providerId: $providerId, ')
          ..write('remoteId: $remoteId, ')
          ..write('name: $name, ')
          ..write('poster: $poster, ')
          ..write('categoryId: $categoryId, ')
          ..write('containerExtension: $containerExtension, ')
          ..write('rating: $rating, ')
          ..write('year: $year, ')
          ..write('added: $added, ')
          ..write('url: $url, ')
          ..write('headersJson: $headersJson, ')
          ..write('isAdult: $isAdult, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('syncToken: $syncToken')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    providerId,
    remoteId,
    name,
    poster,
    categoryId,
    containerExtension,
    rating,
    year,
    added,
    url,
    headersJson,
    isAdult,
    sortOrder,
    syncToken,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MovieRow &&
          other.providerId == this.providerId &&
          other.remoteId == this.remoteId &&
          other.name == this.name &&
          other.poster == this.poster &&
          other.categoryId == this.categoryId &&
          other.containerExtension == this.containerExtension &&
          other.rating == this.rating &&
          other.year == this.year &&
          other.added == this.added &&
          other.url == this.url &&
          other.headersJson == this.headersJson &&
          other.isAdult == this.isAdult &&
          other.sortOrder == this.sortOrder &&
          other.syncToken == this.syncToken);
}

class MoviesCompanion extends UpdateCompanion<MovieRow> {
  final Value<String> providerId;
  final Value<String> remoteId;
  final Value<String> name;
  final Value<String?> poster;
  final Value<String?> categoryId;
  final Value<String> containerExtension;
  final Value<double?> rating;
  final Value<int?> year;
  final Value<DateTime?> added;
  final Value<String?> url;
  final Value<String?> headersJson;
  final Value<bool> isAdult;
  final Value<int> sortOrder;
  final Value<int> syncToken;
  final Value<int> rowid;
  const MoviesCompanion({
    this.providerId = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.name = const Value.absent(),
    this.poster = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.containerExtension = const Value.absent(),
    this.rating = const Value.absent(),
    this.year = const Value.absent(),
    this.added = const Value.absent(),
    this.url = const Value.absent(),
    this.headersJson = const Value.absent(),
    this.isAdult = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.syncToken = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MoviesCompanion.insert({
    required String providerId,
    required String remoteId,
    required String name,
    this.poster = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.containerExtension = const Value.absent(),
    this.rating = const Value.absent(),
    this.year = const Value.absent(),
    this.added = const Value.absent(),
    this.url = const Value.absent(),
    this.headersJson = const Value.absent(),
    this.isAdult = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.syncToken = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : providerId = Value(providerId),
       remoteId = Value(remoteId),
       name = Value(name);
  static Insertable<MovieRow> custom({
    Expression<String>? providerId,
    Expression<String>? remoteId,
    Expression<String>? name,
    Expression<String>? poster,
    Expression<String>? categoryId,
    Expression<String>? containerExtension,
    Expression<double>? rating,
    Expression<int>? year,
    Expression<DateTime>? added,
    Expression<String>? url,
    Expression<String>? headersJson,
    Expression<bool>? isAdult,
    Expression<int>? sortOrder,
    Expression<int>? syncToken,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (providerId != null) 'provider_id': providerId,
      if (remoteId != null) 'remote_id': remoteId,
      if (name != null) 'name': name,
      if (poster != null) 'poster': poster,
      if (categoryId != null) 'category_id': categoryId,
      if (containerExtension != null) 'container_extension': containerExtension,
      if (rating != null) 'rating': rating,
      if (year != null) 'year': year,
      if (added != null) 'added': added,
      if (url != null) 'url': url,
      if (headersJson != null) 'headers_json': headersJson,
      if (isAdult != null) 'is_adult': isAdult,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (syncToken != null) 'sync_token': syncToken,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MoviesCompanion copyWith({
    Value<String>? providerId,
    Value<String>? remoteId,
    Value<String>? name,
    Value<String?>? poster,
    Value<String?>? categoryId,
    Value<String>? containerExtension,
    Value<double?>? rating,
    Value<int?>? year,
    Value<DateTime?>? added,
    Value<String?>? url,
    Value<String?>? headersJson,
    Value<bool>? isAdult,
    Value<int>? sortOrder,
    Value<int>? syncToken,
    Value<int>? rowid,
  }) {
    return MoviesCompanion(
      providerId: providerId ?? this.providerId,
      remoteId: remoteId ?? this.remoteId,
      name: name ?? this.name,
      poster: poster ?? this.poster,
      categoryId: categoryId ?? this.categoryId,
      containerExtension: containerExtension ?? this.containerExtension,
      rating: rating ?? this.rating,
      year: year ?? this.year,
      added: added ?? this.added,
      url: url ?? this.url,
      headersJson: headersJson ?? this.headersJson,
      isAdult: isAdult ?? this.isAdult,
      sortOrder: sortOrder ?? this.sortOrder,
      syncToken: syncToken ?? this.syncToken,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (poster.present) {
      map['poster'] = Variable<String>(poster.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (containerExtension.present) {
      map['container_extension'] = Variable<String>(containerExtension.value);
    }
    if (rating.present) {
      map['rating'] = Variable<double>(rating.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (added.present) {
      map['added'] = Variable<DateTime>(added.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (headersJson.present) {
      map['headers_json'] = Variable<String>(headersJson.value);
    }
    if (isAdult.present) {
      map['is_adult'] = Variable<bool>(isAdult.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (syncToken.present) {
      map['sync_token'] = Variable<int>(syncToken.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MoviesCompanion(')
          ..write('providerId: $providerId, ')
          ..write('remoteId: $remoteId, ')
          ..write('name: $name, ')
          ..write('poster: $poster, ')
          ..write('categoryId: $categoryId, ')
          ..write('containerExtension: $containerExtension, ')
          ..write('rating: $rating, ')
          ..write('year: $year, ')
          ..write('added: $added, ')
          ..write('url: $url, ')
          ..write('headersJson: $headersJson, ')
          ..write('isAdult: $isAdult, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('syncToken: $syncToken, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SeriesTableTable extends SeriesTable
    with TableInfo<$SeriesTableTable, SeriesRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SeriesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
    'provider_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _posterMeta = const VerificationMeta('poster');
  @override
  late final GeneratedColumn<String> poster = GeneratedColumn<String>(
    'poster',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _backdropMeta = const VerificationMeta(
    'backdrop',
  );
  @override
  late final GeneratedColumn<String> backdrop = GeneratedColumn<String>(
    'backdrop',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _plotMeta = const VerificationMeta('plot');
  @override
  late final GeneratedColumn<String> plot = GeneratedColumn<String>(
    'plot',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _genreMeta = const VerificationMeta('genre');
  @override
  late final GeneratedColumn<String> genre = GeneratedColumn<String>(
    'genre',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<double> rating = GeneratedColumn<double>(
    'rating',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastModifiedMeta = const VerificationMeta(
    'lastModified',
  );
  @override
  late final GeneratedColumn<DateTime> lastModified = GeneratedColumn<DateTime>(
    'last_modified',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _headersJsonMeta = const VerificationMeta(
    'headersJson',
  );
  @override
  late final GeneratedColumn<String> headersJson = GeneratedColumn<String>(
    'headers_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isAdultMeta = const VerificationMeta(
    'isAdult',
  );
  @override
  late final GeneratedColumn<bool> isAdult = GeneratedColumn<bool>(
    'is_adult',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_adult" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _syncTokenMeta = const VerificationMeta(
    'syncToken',
  );
  @override
  late final GeneratedColumn<int> syncToken = GeneratedColumn<int>(
    'sync_token',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    providerId,
    remoteId,
    name,
    poster,
    backdrop,
    plot,
    genre,
    rating,
    year,
    categoryId,
    lastModified,
    url,
    headersJson,
    isAdult,
    sortOrder,
    syncToken,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'series';
  @override
  VerificationContext validateIntegrity(
    Insertable<SeriesRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_remoteIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('poster')) {
      context.handle(
        _posterMeta,
        poster.isAcceptableOrUnknown(data['poster']!, _posterMeta),
      );
    }
    if (data.containsKey('backdrop')) {
      context.handle(
        _backdropMeta,
        backdrop.isAcceptableOrUnknown(data['backdrop']!, _backdropMeta),
      );
    }
    if (data.containsKey('plot')) {
      context.handle(
        _plotMeta,
        plot.isAcceptableOrUnknown(data['plot']!, _plotMeta),
      );
    }
    if (data.containsKey('genre')) {
      context.handle(
        _genreMeta,
        genre.isAcceptableOrUnknown(data['genre']!, _genreMeta),
      );
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('last_modified')) {
      context.handle(
        _lastModifiedMeta,
        lastModified.isAcceptableOrUnknown(
          data['last_modified']!,
          _lastModifiedMeta,
        ),
      );
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    }
    if (data.containsKey('headers_json')) {
      context.handle(
        _headersJsonMeta,
        headersJson.isAcceptableOrUnknown(
          data['headers_json']!,
          _headersJsonMeta,
        ),
      );
    }
    if (data.containsKey('is_adult')) {
      context.handle(
        _isAdultMeta,
        isAdult.isAcceptableOrUnknown(data['is_adult']!, _isAdultMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('sync_token')) {
      context.handle(
        _syncTokenMeta,
        syncToken.isAcceptableOrUnknown(data['sync_token']!, _syncTokenMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {providerId, remoteId};
  @override
  SeriesRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SeriesRow(
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_id'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      poster: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}poster'],
      ),
      backdrop: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}backdrop'],
      ),
      plot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plot'],
      ),
      genre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}genre'],
      ),
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rating'],
      ),
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      lastModified: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_modified'],
      ),
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      ),
      headersJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}headers_json'],
      ),
      isAdult: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_adult'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      syncToken: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_token'],
      )!,
    );
  }

  @override
  $SeriesTableTable createAlias(String alias) {
    return $SeriesTableTable(attachedDatabase, alias);
  }
}

class SeriesRow extends DataClass implements Insertable<SeriesRow> {
  final String providerId;
  final String remoteId;
  final String name;
  final String? poster;
  final String? backdrop;
  final String? plot;
  final String? genre;
  final double? rating;
  final int? year;
  final String? categoryId;
  final DateTime? lastModified;

  /// M3U `/series/` entries are playable on their own.
  final String? url;
  final String? headersJson;
  final bool isAdult;
  final int sortOrder;
  final int syncToken;
  const SeriesRow({
    required this.providerId,
    required this.remoteId,
    required this.name,
    this.poster,
    this.backdrop,
    this.plot,
    this.genre,
    this.rating,
    this.year,
    this.categoryId,
    this.lastModified,
    this.url,
    this.headersJson,
    required this.isAdult,
    required this.sortOrder,
    required this.syncToken,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['provider_id'] = Variable<String>(providerId);
    map['remote_id'] = Variable<String>(remoteId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || poster != null) {
      map['poster'] = Variable<String>(poster);
    }
    if (!nullToAbsent || backdrop != null) {
      map['backdrop'] = Variable<String>(backdrop);
    }
    if (!nullToAbsent || plot != null) {
      map['plot'] = Variable<String>(plot);
    }
    if (!nullToAbsent || genre != null) {
      map['genre'] = Variable<String>(genre);
    }
    if (!nullToAbsent || rating != null) {
      map['rating'] = Variable<double>(rating);
    }
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<int>(year);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    if (!nullToAbsent || lastModified != null) {
      map['last_modified'] = Variable<DateTime>(lastModified);
    }
    if (!nullToAbsent || url != null) {
      map['url'] = Variable<String>(url);
    }
    if (!nullToAbsent || headersJson != null) {
      map['headers_json'] = Variable<String>(headersJson);
    }
    map['is_adult'] = Variable<bool>(isAdult);
    map['sort_order'] = Variable<int>(sortOrder);
    map['sync_token'] = Variable<int>(syncToken);
    return map;
  }

  SeriesTableCompanion toCompanion(bool nullToAbsent) {
    return SeriesTableCompanion(
      providerId: Value(providerId),
      remoteId: Value(remoteId),
      name: Value(name),
      poster: poster == null && nullToAbsent
          ? const Value.absent()
          : Value(poster),
      backdrop: backdrop == null && nullToAbsent
          ? const Value.absent()
          : Value(backdrop),
      plot: plot == null && nullToAbsent ? const Value.absent() : Value(plot),
      genre: genre == null && nullToAbsent
          ? const Value.absent()
          : Value(genre),
      rating: rating == null && nullToAbsent
          ? const Value.absent()
          : Value(rating),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      lastModified: lastModified == null && nullToAbsent
          ? const Value.absent()
          : Value(lastModified),
      url: url == null && nullToAbsent ? const Value.absent() : Value(url),
      headersJson: headersJson == null && nullToAbsent
          ? const Value.absent()
          : Value(headersJson),
      isAdult: Value(isAdult),
      sortOrder: Value(sortOrder),
      syncToken: Value(syncToken),
    );
  }

  factory SeriesRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SeriesRow(
      providerId: serializer.fromJson<String>(json['providerId']),
      remoteId: serializer.fromJson<String>(json['remoteId']),
      name: serializer.fromJson<String>(json['name']),
      poster: serializer.fromJson<String?>(json['poster']),
      backdrop: serializer.fromJson<String?>(json['backdrop']),
      plot: serializer.fromJson<String?>(json['plot']),
      genre: serializer.fromJson<String?>(json['genre']),
      rating: serializer.fromJson<double?>(json['rating']),
      year: serializer.fromJson<int?>(json['year']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      lastModified: serializer.fromJson<DateTime?>(json['lastModified']),
      url: serializer.fromJson<String?>(json['url']),
      headersJson: serializer.fromJson<String?>(json['headersJson']),
      isAdult: serializer.fromJson<bool>(json['isAdult']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      syncToken: serializer.fromJson<int>(json['syncToken']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'providerId': serializer.toJson<String>(providerId),
      'remoteId': serializer.toJson<String>(remoteId),
      'name': serializer.toJson<String>(name),
      'poster': serializer.toJson<String?>(poster),
      'backdrop': serializer.toJson<String?>(backdrop),
      'plot': serializer.toJson<String?>(plot),
      'genre': serializer.toJson<String?>(genre),
      'rating': serializer.toJson<double?>(rating),
      'year': serializer.toJson<int?>(year),
      'categoryId': serializer.toJson<String?>(categoryId),
      'lastModified': serializer.toJson<DateTime?>(lastModified),
      'url': serializer.toJson<String?>(url),
      'headersJson': serializer.toJson<String?>(headersJson),
      'isAdult': serializer.toJson<bool>(isAdult),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'syncToken': serializer.toJson<int>(syncToken),
    };
  }

  SeriesRow copyWith({
    String? providerId,
    String? remoteId,
    String? name,
    Value<String?> poster = const Value.absent(),
    Value<String?> backdrop = const Value.absent(),
    Value<String?> plot = const Value.absent(),
    Value<String?> genre = const Value.absent(),
    Value<double?> rating = const Value.absent(),
    Value<int?> year = const Value.absent(),
    Value<String?> categoryId = const Value.absent(),
    Value<DateTime?> lastModified = const Value.absent(),
    Value<String?> url = const Value.absent(),
    Value<String?> headersJson = const Value.absent(),
    bool? isAdult,
    int? sortOrder,
    int? syncToken,
  }) => SeriesRow(
    providerId: providerId ?? this.providerId,
    remoteId: remoteId ?? this.remoteId,
    name: name ?? this.name,
    poster: poster.present ? poster.value : this.poster,
    backdrop: backdrop.present ? backdrop.value : this.backdrop,
    plot: plot.present ? plot.value : this.plot,
    genre: genre.present ? genre.value : this.genre,
    rating: rating.present ? rating.value : this.rating,
    year: year.present ? year.value : this.year,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    lastModified: lastModified.present ? lastModified.value : this.lastModified,
    url: url.present ? url.value : this.url,
    headersJson: headersJson.present ? headersJson.value : this.headersJson,
    isAdult: isAdult ?? this.isAdult,
    sortOrder: sortOrder ?? this.sortOrder,
    syncToken: syncToken ?? this.syncToken,
  );
  SeriesRow copyWithCompanion(SeriesTableCompanion data) {
    return SeriesRow(
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      name: data.name.present ? data.name.value : this.name,
      poster: data.poster.present ? data.poster.value : this.poster,
      backdrop: data.backdrop.present ? data.backdrop.value : this.backdrop,
      plot: data.plot.present ? data.plot.value : this.plot,
      genre: data.genre.present ? data.genre.value : this.genre,
      rating: data.rating.present ? data.rating.value : this.rating,
      year: data.year.present ? data.year.value : this.year,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      lastModified: data.lastModified.present
          ? data.lastModified.value
          : this.lastModified,
      url: data.url.present ? data.url.value : this.url,
      headersJson: data.headersJson.present
          ? data.headersJson.value
          : this.headersJson,
      isAdult: data.isAdult.present ? data.isAdult.value : this.isAdult,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      syncToken: data.syncToken.present ? data.syncToken.value : this.syncToken,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SeriesRow(')
          ..write('providerId: $providerId, ')
          ..write('remoteId: $remoteId, ')
          ..write('name: $name, ')
          ..write('poster: $poster, ')
          ..write('backdrop: $backdrop, ')
          ..write('plot: $plot, ')
          ..write('genre: $genre, ')
          ..write('rating: $rating, ')
          ..write('year: $year, ')
          ..write('categoryId: $categoryId, ')
          ..write('lastModified: $lastModified, ')
          ..write('url: $url, ')
          ..write('headersJson: $headersJson, ')
          ..write('isAdult: $isAdult, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('syncToken: $syncToken')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    providerId,
    remoteId,
    name,
    poster,
    backdrop,
    plot,
    genre,
    rating,
    year,
    categoryId,
    lastModified,
    url,
    headersJson,
    isAdult,
    sortOrder,
    syncToken,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SeriesRow &&
          other.providerId == this.providerId &&
          other.remoteId == this.remoteId &&
          other.name == this.name &&
          other.poster == this.poster &&
          other.backdrop == this.backdrop &&
          other.plot == this.plot &&
          other.genre == this.genre &&
          other.rating == this.rating &&
          other.year == this.year &&
          other.categoryId == this.categoryId &&
          other.lastModified == this.lastModified &&
          other.url == this.url &&
          other.headersJson == this.headersJson &&
          other.isAdult == this.isAdult &&
          other.sortOrder == this.sortOrder &&
          other.syncToken == this.syncToken);
}

class SeriesTableCompanion extends UpdateCompanion<SeriesRow> {
  final Value<String> providerId;
  final Value<String> remoteId;
  final Value<String> name;
  final Value<String?> poster;
  final Value<String?> backdrop;
  final Value<String?> plot;
  final Value<String?> genre;
  final Value<double?> rating;
  final Value<int?> year;
  final Value<String?> categoryId;
  final Value<DateTime?> lastModified;
  final Value<String?> url;
  final Value<String?> headersJson;
  final Value<bool> isAdult;
  final Value<int> sortOrder;
  final Value<int> syncToken;
  final Value<int> rowid;
  const SeriesTableCompanion({
    this.providerId = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.name = const Value.absent(),
    this.poster = const Value.absent(),
    this.backdrop = const Value.absent(),
    this.plot = const Value.absent(),
    this.genre = const Value.absent(),
    this.rating = const Value.absent(),
    this.year = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.url = const Value.absent(),
    this.headersJson = const Value.absent(),
    this.isAdult = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.syncToken = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SeriesTableCompanion.insert({
    required String providerId,
    required String remoteId,
    required String name,
    this.poster = const Value.absent(),
    this.backdrop = const Value.absent(),
    this.plot = const Value.absent(),
    this.genre = const Value.absent(),
    this.rating = const Value.absent(),
    this.year = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.lastModified = const Value.absent(),
    this.url = const Value.absent(),
    this.headersJson = const Value.absent(),
    this.isAdult = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.syncToken = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : providerId = Value(providerId),
       remoteId = Value(remoteId),
       name = Value(name);
  static Insertable<SeriesRow> custom({
    Expression<String>? providerId,
    Expression<String>? remoteId,
    Expression<String>? name,
    Expression<String>? poster,
    Expression<String>? backdrop,
    Expression<String>? plot,
    Expression<String>? genre,
    Expression<double>? rating,
    Expression<int>? year,
    Expression<String>? categoryId,
    Expression<DateTime>? lastModified,
    Expression<String>? url,
    Expression<String>? headersJson,
    Expression<bool>? isAdult,
    Expression<int>? sortOrder,
    Expression<int>? syncToken,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (providerId != null) 'provider_id': providerId,
      if (remoteId != null) 'remote_id': remoteId,
      if (name != null) 'name': name,
      if (poster != null) 'poster': poster,
      if (backdrop != null) 'backdrop': backdrop,
      if (plot != null) 'plot': plot,
      if (genre != null) 'genre': genre,
      if (rating != null) 'rating': rating,
      if (year != null) 'year': year,
      if (categoryId != null) 'category_id': categoryId,
      if (lastModified != null) 'last_modified': lastModified,
      if (url != null) 'url': url,
      if (headersJson != null) 'headers_json': headersJson,
      if (isAdult != null) 'is_adult': isAdult,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (syncToken != null) 'sync_token': syncToken,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SeriesTableCompanion copyWith({
    Value<String>? providerId,
    Value<String>? remoteId,
    Value<String>? name,
    Value<String?>? poster,
    Value<String?>? backdrop,
    Value<String?>? plot,
    Value<String?>? genre,
    Value<double?>? rating,
    Value<int?>? year,
    Value<String?>? categoryId,
    Value<DateTime?>? lastModified,
    Value<String?>? url,
    Value<String?>? headersJson,
    Value<bool>? isAdult,
    Value<int>? sortOrder,
    Value<int>? syncToken,
    Value<int>? rowid,
  }) {
    return SeriesTableCompanion(
      providerId: providerId ?? this.providerId,
      remoteId: remoteId ?? this.remoteId,
      name: name ?? this.name,
      poster: poster ?? this.poster,
      backdrop: backdrop ?? this.backdrop,
      plot: plot ?? this.plot,
      genre: genre ?? this.genre,
      rating: rating ?? this.rating,
      year: year ?? this.year,
      categoryId: categoryId ?? this.categoryId,
      lastModified: lastModified ?? this.lastModified,
      url: url ?? this.url,
      headersJson: headersJson ?? this.headersJson,
      isAdult: isAdult ?? this.isAdult,
      sortOrder: sortOrder ?? this.sortOrder,
      syncToken: syncToken ?? this.syncToken,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (poster.present) {
      map['poster'] = Variable<String>(poster.value);
    }
    if (backdrop.present) {
      map['backdrop'] = Variable<String>(backdrop.value);
    }
    if (plot.present) {
      map['plot'] = Variable<String>(plot.value);
    }
    if (genre.present) {
      map['genre'] = Variable<String>(genre.value);
    }
    if (rating.present) {
      map['rating'] = Variable<double>(rating.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (lastModified.present) {
      map['last_modified'] = Variable<DateTime>(lastModified.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (headersJson.present) {
      map['headers_json'] = Variable<String>(headersJson.value);
    }
    if (isAdult.present) {
      map['is_adult'] = Variable<bool>(isAdult.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (syncToken.present) {
      map['sync_token'] = Variable<int>(syncToken.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SeriesTableCompanion(')
          ..write('providerId: $providerId, ')
          ..write('remoteId: $remoteId, ')
          ..write('name: $name, ')
          ..write('poster: $poster, ')
          ..write('backdrop: $backdrop, ')
          ..write('plot: $plot, ')
          ..write('genre: $genre, ')
          ..write('rating: $rating, ')
          ..write('year: $year, ')
          ..write('categoryId: $categoryId, ')
          ..write('lastModified: $lastModified, ')
          ..write('url: $url, ')
          ..write('headersJson: $headersJson, ')
          ..write('isAdult: $isAdult, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('syncToken: $syncToken, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EpisodesTable extends Episodes
    with TableInfo<$EpisodesTable, EpisodeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EpisodesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
    'provider_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seriesIdMeta = const VerificationMeta(
    'seriesId',
  );
  @override
  late final GeneratedColumn<String> seriesId = GeneratedColumn<String>(
    'series_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _episodeIdMeta = const VerificationMeta(
    'episodeId',
  );
  @override
  late final GeneratedColumn<String> episodeId = GeneratedColumn<String>(
    'episode_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seasonMeta = const VerificationMeta('season');
  @override
  late final GeneratedColumn<int> season = GeneratedColumn<int>(
    'season',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _episodeNumMeta = const VerificationMeta(
    'episodeNum',
  );
  @override
  late final GeneratedColumn<int> episodeNum = GeneratedColumn<int>(
    'episode_num',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _containerExtensionMeta =
      const VerificationMeta('containerExtension');
  @override
  late final GeneratedColumn<String> containerExtension =
      GeneratedColumn<String>(
        'container_extension',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('mp4'),
      );
  static const VerificationMeta _plotMeta = const VerificationMeta('plot');
  @override
  late final GeneratedColumn<String> plot = GeneratedColumn<String>(
    'plot',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSecsMeta = const VerificationMeta(
    'durationSecs',
  );
  @override
  late final GeneratedColumn<int> durationSecs = GeneratedColumn<int>(
    'duration_secs',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageMeta = const VerificationMeta('image');
  @override
  late final GeneratedColumn<String> image = GeneratedColumn<String>(
    'image',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    providerId,
    seriesId,
    episodeId,
    season,
    episodeNum,
    title,
    containerExtension,
    plot,
    durationSecs,
    image,
    fetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'episodes';
  @override
  VerificationContext validateIntegrity(
    Insertable<EpisodeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('series_id')) {
      context.handle(
        _seriesIdMeta,
        seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta),
      );
    } else if (isInserting) {
      context.missing(_seriesIdMeta);
    }
    if (data.containsKey('episode_id')) {
      context.handle(
        _episodeIdMeta,
        episodeId.isAcceptableOrUnknown(data['episode_id']!, _episodeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_episodeIdMeta);
    }
    if (data.containsKey('season')) {
      context.handle(
        _seasonMeta,
        season.isAcceptableOrUnknown(data['season']!, _seasonMeta),
      );
    } else if (isInserting) {
      context.missing(_seasonMeta);
    }
    if (data.containsKey('episode_num')) {
      context.handle(
        _episodeNumMeta,
        episodeNum.isAcceptableOrUnknown(data['episode_num']!, _episodeNumMeta),
      );
    } else if (isInserting) {
      context.missing(_episodeNumMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('container_extension')) {
      context.handle(
        _containerExtensionMeta,
        containerExtension.isAcceptableOrUnknown(
          data['container_extension']!,
          _containerExtensionMeta,
        ),
      );
    }
    if (data.containsKey('plot')) {
      context.handle(
        _plotMeta,
        plot.isAcceptableOrUnknown(data['plot']!, _plotMeta),
      );
    }
    if (data.containsKey('duration_secs')) {
      context.handle(
        _durationSecsMeta,
        durationSecs.isAcceptableOrUnknown(
          data['duration_secs']!,
          _durationSecsMeta,
        ),
      );
    }
    if (data.containsKey('image')) {
      context.handle(
        _imageMeta,
        image.isAcceptableOrUnknown(data['image']!, _imageMeta),
      );
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {providerId, episodeId};
  @override
  EpisodeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EpisodeRow(
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_id'],
      )!,
      seriesId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}series_id'],
      )!,
      episodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}episode_id'],
      )!,
      season: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}season'],
      )!,
      episodeNum: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}episode_num'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      containerExtension: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}container_extension'],
      )!,
      plot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plot'],
      ),
      durationSecs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_secs'],
      ),
      image: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image'],
      ),
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $EpisodesTable createAlias(String alias) {
    return $EpisodesTable(attachedDatabase, alias);
  }
}

class EpisodeRow extends DataClass implements Insertable<EpisodeRow> {
  final String providerId;
  final String seriesId;
  final String episodeId;
  final int season;
  final int episodeNum;
  final String title;
  final String containerExtension;
  final String? plot;
  final int? durationSecs;
  final String? image;
  final DateTime fetchedAt;
  const EpisodeRow({
    required this.providerId,
    required this.seriesId,
    required this.episodeId,
    required this.season,
    required this.episodeNum,
    required this.title,
    required this.containerExtension,
    this.plot,
    this.durationSecs,
    this.image,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['provider_id'] = Variable<String>(providerId);
    map['series_id'] = Variable<String>(seriesId);
    map['episode_id'] = Variable<String>(episodeId);
    map['season'] = Variable<int>(season);
    map['episode_num'] = Variable<int>(episodeNum);
    map['title'] = Variable<String>(title);
    map['container_extension'] = Variable<String>(containerExtension);
    if (!nullToAbsent || plot != null) {
      map['plot'] = Variable<String>(plot);
    }
    if (!nullToAbsent || durationSecs != null) {
      map['duration_secs'] = Variable<int>(durationSecs);
    }
    if (!nullToAbsent || image != null) {
      map['image'] = Variable<String>(image);
    }
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  EpisodesCompanion toCompanion(bool nullToAbsent) {
    return EpisodesCompanion(
      providerId: Value(providerId),
      seriesId: Value(seriesId),
      episodeId: Value(episodeId),
      season: Value(season),
      episodeNum: Value(episodeNum),
      title: Value(title),
      containerExtension: Value(containerExtension),
      plot: plot == null && nullToAbsent ? const Value.absent() : Value(plot),
      durationSecs: durationSecs == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSecs),
      image: image == null && nullToAbsent
          ? const Value.absent()
          : Value(image),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory EpisodeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EpisodeRow(
      providerId: serializer.fromJson<String>(json['providerId']),
      seriesId: serializer.fromJson<String>(json['seriesId']),
      episodeId: serializer.fromJson<String>(json['episodeId']),
      season: serializer.fromJson<int>(json['season']),
      episodeNum: serializer.fromJson<int>(json['episodeNum']),
      title: serializer.fromJson<String>(json['title']),
      containerExtension: serializer.fromJson<String>(
        json['containerExtension'],
      ),
      plot: serializer.fromJson<String?>(json['plot']),
      durationSecs: serializer.fromJson<int?>(json['durationSecs']),
      image: serializer.fromJson<String?>(json['image']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'providerId': serializer.toJson<String>(providerId),
      'seriesId': serializer.toJson<String>(seriesId),
      'episodeId': serializer.toJson<String>(episodeId),
      'season': serializer.toJson<int>(season),
      'episodeNum': serializer.toJson<int>(episodeNum),
      'title': serializer.toJson<String>(title),
      'containerExtension': serializer.toJson<String>(containerExtension),
      'plot': serializer.toJson<String?>(plot),
      'durationSecs': serializer.toJson<int?>(durationSecs),
      'image': serializer.toJson<String?>(image),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  EpisodeRow copyWith({
    String? providerId,
    String? seriesId,
    String? episodeId,
    int? season,
    int? episodeNum,
    String? title,
    String? containerExtension,
    Value<String?> plot = const Value.absent(),
    Value<int?> durationSecs = const Value.absent(),
    Value<String?> image = const Value.absent(),
    DateTime? fetchedAt,
  }) => EpisodeRow(
    providerId: providerId ?? this.providerId,
    seriesId: seriesId ?? this.seriesId,
    episodeId: episodeId ?? this.episodeId,
    season: season ?? this.season,
    episodeNum: episodeNum ?? this.episodeNum,
    title: title ?? this.title,
    containerExtension: containerExtension ?? this.containerExtension,
    plot: plot.present ? plot.value : this.plot,
    durationSecs: durationSecs.present ? durationSecs.value : this.durationSecs,
    image: image.present ? image.value : this.image,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  EpisodeRow copyWithCompanion(EpisodesCompanion data) {
    return EpisodeRow(
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
      episodeId: data.episodeId.present ? data.episodeId.value : this.episodeId,
      season: data.season.present ? data.season.value : this.season,
      episodeNum: data.episodeNum.present
          ? data.episodeNum.value
          : this.episodeNum,
      title: data.title.present ? data.title.value : this.title,
      containerExtension: data.containerExtension.present
          ? data.containerExtension.value
          : this.containerExtension,
      plot: data.plot.present ? data.plot.value : this.plot,
      durationSecs: data.durationSecs.present
          ? data.durationSecs.value
          : this.durationSecs,
      image: data.image.present ? data.image.value : this.image,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EpisodeRow(')
          ..write('providerId: $providerId, ')
          ..write('seriesId: $seriesId, ')
          ..write('episodeId: $episodeId, ')
          ..write('season: $season, ')
          ..write('episodeNum: $episodeNum, ')
          ..write('title: $title, ')
          ..write('containerExtension: $containerExtension, ')
          ..write('plot: $plot, ')
          ..write('durationSecs: $durationSecs, ')
          ..write('image: $image, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    providerId,
    seriesId,
    episodeId,
    season,
    episodeNum,
    title,
    containerExtension,
    plot,
    durationSecs,
    image,
    fetchedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EpisodeRow &&
          other.providerId == this.providerId &&
          other.seriesId == this.seriesId &&
          other.episodeId == this.episodeId &&
          other.season == this.season &&
          other.episodeNum == this.episodeNum &&
          other.title == this.title &&
          other.containerExtension == this.containerExtension &&
          other.plot == this.plot &&
          other.durationSecs == this.durationSecs &&
          other.image == this.image &&
          other.fetchedAt == this.fetchedAt);
}

class EpisodesCompanion extends UpdateCompanion<EpisodeRow> {
  final Value<String> providerId;
  final Value<String> seriesId;
  final Value<String> episodeId;
  final Value<int> season;
  final Value<int> episodeNum;
  final Value<String> title;
  final Value<String> containerExtension;
  final Value<String?> plot;
  final Value<int?> durationSecs;
  final Value<String?> image;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const EpisodesCompanion({
    this.providerId = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.episodeId = const Value.absent(),
    this.season = const Value.absent(),
    this.episodeNum = const Value.absent(),
    this.title = const Value.absent(),
    this.containerExtension = const Value.absent(),
    this.plot = const Value.absent(),
    this.durationSecs = const Value.absent(),
    this.image = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EpisodesCompanion.insert({
    required String providerId,
    required String seriesId,
    required String episodeId,
    required int season,
    required int episodeNum,
    required String title,
    this.containerExtension = const Value.absent(),
    this.plot = const Value.absent(),
    this.durationSecs = const Value.absent(),
    this.image = const Value.absent(),
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  }) : providerId = Value(providerId),
       seriesId = Value(seriesId),
       episodeId = Value(episodeId),
       season = Value(season),
       episodeNum = Value(episodeNum),
       title = Value(title),
       fetchedAt = Value(fetchedAt);
  static Insertable<EpisodeRow> custom({
    Expression<String>? providerId,
    Expression<String>? seriesId,
    Expression<String>? episodeId,
    Expression<int>? season,
    Expression<int>? episodeNum,
    Expression<String>? title,
    Expression<String>? containerExtension,
    Expression<String>? plot,
    Expression<int>? durationSecs,
    Expression<String>? image,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (providerId != null) 'provider_id': providerId,
      if (seriesId != null) 'series_id': seriesId,
      if (episodeId != null) 'episode_id': episodeId,
      if (season != null) 'season': season,
      if (episodeNum != null) 'episode_num': episodeNum,
      if (title != null) 'title': title,
      if (containerExtension != null) 'container_extension': containerExtension,
      if (plot != null) 'plot': plot,
      if (durationSecs != null) 'duration_secs': durationSecs,
      if (image != null) 'image': image,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EpisodesCompanion copyWith({
    Value<String>? providerId,
    Value<String>? seriesId,
    Value<String>? episodeId,
    Value<int>? season,
    Value<int>? episodeNum,
    Value<String>? title,
    Value<String>? containerExtension,
    Value<String?>? plot,
    Value<int?>? durationSecs,
    Value<String?>? image,
    Value<DateTime>? fetchedAt,
    Value<int>? rowid,
  }) {
    return EpisodesCompanion(
      providerId: providerId ?? this.providerId,
      seriesId: seriesId ?? this.seriesId,
      episodeId: episodeId ?? this.episodeId,
      season: season ?? this.season,
      episodeNum: episodeNum ?? this.episodeNum,
      title: title ?? this.title,
      containerExtension: containerExtension ?? this.containerExtension,
      plot: plot ?? this.plot,
      durationSecs: durationSecs ?? this.durationSecs,
      image: image ?? this.image,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (seriesId.present) {
      map['series_id'] = Variable<String>(seriesId.value);
    }
    if (episodeId.present) {
      map['episode_id'] = Variable<String>(episodeId.value);
    }
    if (season.present) {
      map['season'] = Variable<int>(season.value);
    }
    if (episodeNum.present) {
      map['episode_num'] = Variable<int>(episodeNum.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (containerExtension.present) {
      map['container_extension'] = Variable<String>(containerExtension.value);
    }
    if (plot.present) {
      map['plot'] = Variable<String>(plot.value);
    }
    if (durationSecs.present) {
      map['duration_secs'] = Variable<int>(durationSecs.value);
    }
    if (image.present) {
      map['image'] = Variable<String>(image.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EpisodesCompanion(')
          ..write('providerId: $providerId, ')
          ..write('seriesId: $seriesId, ')
          ..write('episodeId: $episodeId, ')
          ..write('season: $season, ')
          ..write('episodeNum: $episodeNum, ')
          ..write('title: $title, ')
          ..write('containerExtension: $containerExtension, ')
          ..write('plot: $plot, ')
          ..write('durationSecs: $durationSecs, ')
          ..write('image: $image, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EpgProgramsTable extends EpgPrograms
    with TableInfo<$EpgProgramsTable, EpgProgramRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EpgProgramsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
    'provider_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _channelEpgIdMeta = const VerificationMeta(
    'channelEpgId',
  );
  @override
  late final GeneratedColumn<String> channelEpgId = GeneratedColumn<String>(
    'channel_epg_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startMeta = const VerificationMeta('start');
  @override
  late final GeneratedColumn<DateTime> start = GeneratedColumn<DateTime>(
    'start',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stopMeta = const VerificationMeta('stop');
  @override
  late final GeneratedColumn<DateTime> stop = GeneratedColumn<DateTime>(
    'stop',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    providerId,
    channelEpgId,
    start,
    stop,
    title,
    description,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'epg_programs';
  @override
  VerificationContext validateIntegrity(
    Insertable<EpgProgramRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('channel_epg_id')) {
      context.handle(
        _channelEpgIdMeta,
        channelEpgId.isAcceptableOrUnknown(
          data['channel_epg_id']!,
          _channelEpgIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_channelEpgIdMeta);
    }
    if (data.containsKey('start')) {
      context.handle(
        _startMeta,
        start.isAcceptableOrUnknown(data['start']!, _startMeta),
      );
    } else if (isInserting) {
      context.missing(_startMeta);
    }
    if (data.containsKey('stop')) {
      context.handle(
        _stopMeta,
        stop.isAcceptableOrUnknown(data['stop']!, _stopMeta),
      );
    } else if (isInserting) {
      context.missing(_stopMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EpgProgramRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EpgProgramRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_id'],
      )!,
      channelEpgId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}channel_epg_id'],
      )!,
      start: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start'],
      )!,
      stop: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}stop'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
    );
  }

  @override
  $EpgProgramsTable createAlias(String alias) {
    return $EpgProgramsTable(attachedDatabase, alias);
  }
}

class EpgProgramRow extends DataClass implements Insertable<EpgProgramRow> {
  final int id;
  final String providerId;
  final String channelEpgId;
  final DateTime start;
  final DateTime stop;
  final String title;
  final String? description;
  const EpgProgramRow({
    required this.id,
    required this.providerId,
    required this.channelEpgId,
    required this.start,
    required this.stop,
    required this.title,
    this.description,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['provider_id'] = Variable<String>(providerId);
    map['channel_epg_id'] = Variable<String>(channelEpgId);
    map['start'] = Variable<DateTime>(start);
    map['stop'] = Variable<DateTime>(stop);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    return map;
  }

  EpgProgramsCompanion toCompanion(bool nullToAbsent) {
    return EpgProgramsCompanion(
      id: Value(id),
      providerId: Value(providerId),
      channelEpgId: Value(channelEpgId),
      start: Value(start),
      stop: Value(stop),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
    );
  }

  factory EpgProgramRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EpgProgramRow(
      id: serializer.fromJson<int>(json['id']),
      providerId: serializer.fromJson<String>(json['providerId']),
      channelEpgId: serializer.fromJson<String>(json['channelEpgId']),
      start: serializer.fromJson<DateTime>(json['start']),
      stop: serializer.fromJson<DateTime>(json['stop']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'providerId': serializer.toJson<String>(providerId),
      'channelEpgId': serializer.toJson<String>(channelEpgId),
      'start': serializer.toJson<DateTime>(start),
      'stop': serializer.toJson<DateTime>(stop),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
    };
  }

  EpgProgramRow copyWith({
    int? id,
    String? providerId,
    String? channelEpgId,
    DateTime? start,
    DateTime? stop,
    String? title,
    Value<String?> description = const Value.absent(),
  }) => EpgProgramRow(
    id: id ?? this.id,
    providerId: providerId ?? this.providerId,
    channelEpgId: channelEpgId ?? this.channelEpgId,
    start: start ?? this.start,
    stop: stop ?? this.stop,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
  );
  EpgProgramRow copyWithCompanion(EpgProgramsCompanion data) {
    return EpgProgramRow(
      id: data.id.present ? data.id.value : this.id,
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      channelEpgId: data.channelEpgId.present
          ? data.channelEpgId.value
          : this.channelEpgId,
      start: data.start.present ? data.start.value : this.start,
      stop: data.stop.present ? data.stop.value : this.stop,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EpgProgramRow(')
          ..write('id: $id, ')
          ..write('providerId: $providerId, ')
          ..write('channelEpgId: $channelEpgId, ')
          ..write('start: $start, ')
          ..write('stop: $stop, ')
          ..write('title: $title, ')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    providerId,
    channelEpgId,
    start,
    stop,
    title,
    description,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EpgProgramRow &&
          other.id == this.id &&
          other.providerId == this.providerId &&
          other.channelEpgId == this.channelEpgId &&
          other.start == this.start &&
          other.stop == this.stop &&
          other.title == this.title &&
          other.description == this.description);
}

class EpgProgramsCompanion extends UpdateCompanion<EpgProgramRow> {
  final Value<int> id;
  final Value<String> providerId;
  final Value<String> channelEpgId;
  final Value<DateTime> start;
  final Value<DateTime> stop;
  final Value<String> title;
  final Value<String?> description;
  const EpgProgramsCompanion({
    this.id = const Value.absent(),
    this.providerId = const Value.absent(),
    this.channelEpgId = const Value.absent(),
    this.start = const Value.absent(),
    this.stop = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
  });
  EpgProgramsCompanion.insert({
    this.id = const Value.absent(),
    required String providerId,
    required String channelEpgId,
    required DateTime start,
    required DateTime stop,
    required String title,
    this.description = const Value.absent(),
  }) : providerId = Value(providerId),
       channelEpgId = Value(channelEpgId),
       start = Value(start),
       stop = Value(stop),
       title = Value(title);
  static Insertable<EpgProgramRow> custom({
    Expression<int>? id,
    Expression<String>? providerId,
    Expression<String>? channelEpgId,
    Expression<DateTime>? start,
    Expression<DateTime>? stop,
    Expression<String>? title,
    Expression<String>? description,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (providerId != null) 'provider_id': providerId,
      if (channelEpgId != null) 'channel_epg_id': channelEpgId,
      if (start != null) 'start': start,
      if (stop != null) 'stop': stop,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
    });
  }

  EpgProgramsCompanion copyWith({
    Value<int>? id,
    Value<String>? providerId,
    Value<String>? channelEpgId,
    Value<DateTime>? start,
    Value<DateTime>? stop,
    Value<String>? title,
    Value<String?>? description,
  }) {
    return EpgProgramsCompanion(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      channelEpgId: channelEpgId ?? this.channelEpgId,
      start: start ?? this.start,
      stop: stop ?? this.stop,
      title: title ?? this.title,
      description: description ?? this.description,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (channelEpgId.present) {
      map['channel_epg_id'] = Variable<String>(channelEpgId.value);
    }
    if (start.present) {
      map['start'] = Variable<DateTime>(start.value);
    }
    if (stop.present) {
      map['stop'] = Variable<DateTime>(stop.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EpgProgramsCompanion(')
          ..write('id: $id, ')
          ..write('providerId: $providerId, ')
          ..write('channelEpgId: $channelEpgId, ')
          ..write('start: $start, ')
          ..write('stop: $stop, ')
          ..write('title: $title, ')
          ..write('description: $description')
          ..write(')'))
        .toString();
  }
}

class $ProfilesTable extends Profiles
    with TableInfo<$ProfilesTable, ProfileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isKidsMeta = const VerificationMeta('isKids');
  @override
  late final GeneratedColumn<bool> isKids = GeneratedColumn<bool>(
    'is_kids',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_kids" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _colorIndexMeta = const VerificationMeta(
    'colorIndex',
  );
  @override
  late final GeneratedColumn<int> colorIndex = GeneratedColumn<int>(
    'color_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    isKids,
    colorIndex,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProfileRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('is_kids')) {
      context.handle(
        _isKidsMeta,
        isKids.isAcceptableOrUnknown(data['is_kids']!, _isKidsMeta),
      );
    }
    if (data.containsKey('color_index')) {
      context.handle(
        _colorIndexMeta,
        colorIndex.isAcceptableOrUnknown(data['color_index']!, _colorIndexMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProfileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProfileRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      isKids: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_kids'],
      )!,
      colorIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color_index'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ProfilesTable createAlias(String alias) {
    return $ProfilesTable(attachedDatabase, alias);
  }
}

class ProfileRow extends DataClass implements Insertable<ProfileRow> {
  final int id;
  final String name;
  final bool isKids;
  final int colorIndex;
  final DateTime createdAt;
  const ProfileRow({
    required this.id,
    required this.name,
    required this.isKids,
    required this.colorIndex,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['is_kids'] = Variable<bool>(isKids);
    map['color_index'] = Variable<int>(colorIndex);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  ProfilesCompanion toCompanion(bool nullToAbsent) {
    return ProfilesCompanion(
      id: Value(id),
      name: Value(name),
      isKids: Value(isKids),
      colorIndex: Value(colorIndex),
      createdAt: Value(createdAt),
    );
  }

  factory ProfileRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProfileRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      isKids: serializer.fromJson<bool>(json['isKids']),
      colorIndex: serializer.fromJson<int>(json['colorIndex']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'isKids': serializer.toJson<bool>(isKids),
      'colorIndex': serializer.toJson<int>(colorIndex),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  ProfileRow copyWith({
    int? id,
    String? name,
    bool? isKids,
    int? colorIndex,
    DateTime? createdAt,
  }) => ProfileRow(
    id: id ?? this.id,
    name: name ?? this.name,
    isKids: isKids ?? this.isKids,
    colorIndex: colorIndex ?? this.colorIndex,
    createdAt: createdAt ?? this.createdAt,
  );
  ProfileRow copyWithCompanion(ProfilesCompanion data) {
    return ProfileRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      isKids: data.isKids.present ? data.isKids.value : this.isKids,
      colorIndex: data.colorIndex.present
          ? data.colorIndex.value
          : this.colorIndex,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProfileRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('isKids: $isKids, ')
          ..write('colorIndex: $colorIndex, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, isKids, colorIndex, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfileRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.isKids == this.isKids &&
          other.colorIndex == this.colorIndex &&
          other.createdAt == this.createdAt);
}

class ProfilesCompanion extends UpdateCompanion<ProfileRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<bool> isKids;
  final Value<int> colorIndex;
  final Value<DateTime> createdAt;
  const ProfilesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.isKids = const Value.absent(),
    this.colorIndex = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ProfilesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.isKids = const Value.absent(),
    this.colorIndex = const Value.absent(),
    required DateTime createdAt,
  }) : name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<ProfileRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<bool>? isKids,
    Expression<int>? colorIndex,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (isKids != null) 'is_kids': isKids,
      if (colorIndex != null) 'color_index': colorIndex,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ProfilesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<bool>? isKids,
    Value<int>? colorIndex,
    Value<DateTime>? createdAt,
  }) {
    return ProfilesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      isKids: isKids ?? this.isKids,
      colorIndex: colorIndex ?? this.colorIndex,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isKids.present) {
      map['is_kids'] = Variable<bool>(isKids.value);
    }
    if (colorIndex.present) {
      map['color_index'] = Variable<int>(colorIndex.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('isKids: $isKids, ')
          ..write('colorIndex: $colorIndex, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $FavouritesTable extends Favourites
    with TableInfo<$FavouritesTable, FavouriteRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FavouritesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<int> profileId = GeneratedColumn<int>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
    'provider_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    profileId,
    providerId,
    kind,
    remoteId,
    addedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favourites';
  @override
  VerificationContext validateIntegrity(
    Insertable<FavouriteRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_remoteIdMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    profileId,
    providerId,
    kind,
    remoteId,
  };
  @override
  FavouriteRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FavouriteRow(
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      )!,
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $FavouritesTable createAlias(String alias) {
    return $FavouritesTable(attachedDatabase, alias);
  }
}

class FavouriteRow extends DataClass implements Insertable<FavouriteRow> {
  final int profileId;
  final String providerId;
  final String kind;
  final String remoteId;
  final DateTime addedAt;
  const FavouriteRow({
    required this.profileId,
    required this.providerId,
    required this.kind,
    required this.remoteId,
    required this.addedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['profile_id'] = Variable<int>(profileId);
    map['provider_id'] = Variable<String>(providerId);
    map['kind'] = Variable<String>(kind);
    map['remote_id'] = Variable<String>(remoteId);
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  FavouritesCompanion toCompanion(bool nullToAbsent) {
    return FavouritesCompanion(
      profileId: Value(profileId),
      providerId: Value(providerId),
      kind: Value(kind),
      remoteId: Value(remoteId),
      addedAt: Value(addedAt),
    );
  }

  factory FavouriteRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FavouriteRow(
      profileId: serializer.fromJson<int>(json['profileId']),
      providerId: serializer.fromJson<String>(json['providerId']),
      kind: serializer.fromJson<String>(json['kind']),
      remoteId: serializer.fromJson<String>(json['remoteId']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'profileId': serializer.toJson<int>(profileId),
      'providerId': serializer.toJson<String>(providerId),
      'kind': serializer.toJson<String>(kind),
      'remoteId': serializer.toJson<String>(remoteId),
      'addedAt': serializer.toJson<DateTime>(addedAt),
    };
  }

  FavouriteRow copyWith({
    int? profileId,
    String? providerId,
    String? kind,
    String? remoteId,
    DateTime? addedAt,
  }) => FavouriteRow(
    profileId: profileId ?? this.profileId,
    providerId: providerId ?? this.providerId,
    kind: kind ?? this.kind,
    remoteId: remoteId ?? this.remoteId,
    addedAt: addedAt ?? this.addedAt,
  );
  FavouriteRow copyWithCompanion(FavouritesCompanion data) {
    return FavouriteRow(
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      kind: data.kind.present ? data.kind.value : this.kind,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FavouriteRow(')
          ..write('profileId: $profileId, ')
          ..write('providerId: $providerId, ')
          ..write('kind: $kind, ')
          ..write('remoteId: $remoteId, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(profileId, providerId, kind, remoteId, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FavouriteRow &&
          other.profileId == this.profileId &&
          other.providerId == this.providerId &&
          other.kind == this.kind &&
          other.remoteId == this.remoteId &&
          other.addedAt == this.addedAt);
}

class FavouritesCompanion extends UpdateCompanion<FavouriteRow> {
  final Value<int> profileId;
  final Value<String> providerId;
  final Value<String> kind;
  final Value<String> remoteId;
  final Value<DateTime> addedAt;
  final Value<int> rowid;
  const FavouritesCompanion({
    this.profileId = const Value.absent(),
    this.providerId = const Value.absent(),
    this.kind = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FavouritesCompanion.insert({
    required int profileId,
    required String providerId,
    required String kind,
    required String remoteId,
    required DateTime addedAt,
    this.rowid = const Value.absent(),
  }) : profileId = Value(profileId),
       providerId = Value(providerId),
       kind = Value(kind),
       remoteId = Value(remoteId),
       addedAt = Value(addedAt);
  static Insertable<FavouriteRow> custom({
    Expression<int>? profileId,
    Expression<String>? providerId,
    Expression<String>? kind,
    Expression<String>? remoteId,
    Expression<DateTime>? addedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (profileId != null) 'profile_id': profileId,
      if (providerId != null) 'provider_id': providerId,
      if (kind != null) 'kind': kind,
      if (remoteId != null) 'remote_id': remoteId,
      if (addedAt != null) 'added_at': addedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FavouritesCompanion copyWith({
    Value<int>? profileId,
    Value<String>? providerId,
    Value<String>? kind,
    Value<String>? remoteId,
    Value<DateTime>? addedAt,
    Value<int>? rowid,
  }) {
    return FavouritesCompanion(
      profileId: profileId ?? this.profileId,
      providerId: providerId ?? this.providerId,
      kind: kind ?? this.kind,
      remoteId: remoteId ?? this.remoteId,
      addedAt: addedAt ?? this.addedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavouritesCompanion(')
          ..write('profileId: $profileId, ')
          ..write('providerId: $providerId, ')
          ..write('kind: $kind, ')
          ..write('remoteId: $remoteId, ')
          ..write('addedAt: $addedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MyListTable extends MyList with TableInfo<$MyListTable, MyListRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MyListTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<int> profileId = GeneratedColumn<int>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
    'provider_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    profileId,
    providerId,
    kind,
    remoteId,
    addedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'my_list';
  @override
  VerificationContext validateIntegrity(
    Insertable<MyListRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_remoteIdMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    profileId,
    providerId,
    kind,
    remoteId,
  };
  @override
  MyListRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MyListRow(
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      )!,
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $MyListTable createAlias(String alias) {
    return $MyListTable(attachedDatabase, alias);
  }
}

class MyListRow extends DataClass implements Insertable<MyListRow> {
  final int profileId;
  final String providerId;
  final String kind;
  final String remoteId;
  final DateTime addedAt;
  const MyListRow({
    required this.profileId,
    required this.providerId,
    required this.kind,
    required this.remoteId,
    required this.addedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['profile_id'] = Variable<int>(profileId);
    map['provider_id'] = Variable<String>(providerId);
    map['kind'] = Variable<String>(kind);
    map['remote_id'] = Variable<String>(remoteId);
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  MyListCompanion toCompanion(bool nullToAbsent) {
    return MyListCompanion(
      profileId: Value(profileId),
      providerId: Value(providerId),
      kind: Value(kind),
      remoteId: Value(remoteId),
      addedAt: Value(addedAt),
    );
  }

  factory MyListRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MyListRow(
      profileId: serializer.fromJson<int>(json['profileId']),
      providerId: serializer.fromJson<String>(json['providerId']),
      kind: serializer.fromJson<String>(json['kind']),
      remoteId: serializer.fromJson<String>(json['remoteId']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'profileId': serializer.toJson<int>(profileId),
      'providerId': serializer.toJson<String>(providerId),
      'kind': serializer.toJson<String>(kind),
      'remoteId': serializer.toJson<String>(remoteId),
      'addedAt': serializer.toJson<DateTime>(addedAt),
    };
  }

  MyListRow copyWith({
    int? profileId,
    String? providerId,
    String? kind,
    String? remoteId,
    DateTime? addedAt,
  }) => MyListRow(
    profileId: profileId ?? this.profileId,
    providerId: providerId ?? this.providerId,
    kind: kind ?? this.kind,
    remoteId: remoteId ?? this.remoteId,
    addedAt: addedAt ?? this.addedAt,
  );
  MyListRow copyWithCompanion(MyListCompanion data) {
    return MyListRow(
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      kind: data.kind.present ? data.kind.value : this.kind,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MyListRow(')
          ..write('profileId: $profileId, ')
          ..write('providerId: $providerId, ')
          ..write('kind: $kind, ')
          ..write('remoteId: $remoteId, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(profileId, providerId, kind, remoteId, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MyListRow &&
          other.profileId == this.profileId &&
          other.providerId == this.providerId &&
          other.kind == this.kind &&
          other.remoteId == this.remoteId &&
          other.addedAt == this.addedAt);
}

class MyListCompanion extends UpdateCompanion<MyListRow> {
  final Value<int> profileId;
  final Value<String> providerId;
  final Value<String> kind;
  final Value<String> remoteId;
  final Value<DateTime> addedAt;
  final Value<int> rowid;
  const MyListCompanion({
    this.profileId = const Value.absent(),
    this.providerId = const Value.absent(),
    this.kind = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MyListCompanion.insert({
    required int profileId,
    required String providerId,
    required String kind,
    required String remoteId,
    required DateTime addedAt,
    this.rowid = const Value.absent(),
  }) : profileId = Value(profileId),
       providerId = Value(providerId),
       kind = Value(kind),
       remoteId = Value(remoteId),
       addedAt = Value(addedAt);
  static Insertable<MyListRow> custom({
    Expression<int>? profileId,
    Expression<String>? providerId,
    Expression<String>? kind,
    Expression<String>? remoteId,
    Expression<DateTime>? addedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (profileId != null) 'profile_id': profileId,
      if (providerId != null) 'provider_id': providerId,
      if (kind != null) 'kind': kind,
      if (remoteId != null) 'remote_id': remoteId,
      if (addedAt != null) 'added_at': addedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MyListCompanion copyWith({
    Value<int>? profileId,
    Value<String>? providerId,
    Value<String>? kind,
    Value<String>? remoteId,
    Value<DateTime>? addedAt,
    Value<int>? rowid,
  }) {
    return MyListCompanion(
      profileId: profileId ?? this.profileId,
      providerId: providerId ?? this.providerId,
      kind: kind ?? this.kind,
      remoteId: remoteId ?? this.remoteId,
      addedAt: addedAt ?? this.addedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MyListCompanion(')
          ..write('profileId: $profileId, ')
          ..write('providerId: $providerId, ')
          ..write('kind: $kind, ')
          ..write('remoteId: $remoteId, ')
          ..write('addedAt: $addedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProgressTable extends Progress
    with TableInfo<$ProgressTable, ProgressRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<int> profileId = GeneratedColumn<int>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
    'provider_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seriesIdMeta = const VerificationMeta(
    'seriesId',
  );
  @override
  late final GeneratedColumn<String> seriesId = GeneratedColumn<String>(
    'series_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _positionMsMeta = const VerificationMeta(
    'positionMs',
  );
  @override
  late final GeneratedColumn<int> positionMs = GeneratedColumn<int>(
    'position_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    profileId,
    providerId,
    kind,
    remoteId,
    seriesId,
    positionMs,
    durationMs,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProgressRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_remoteIdMeta);
    }
    if (data.containsKey('series_id')) {
      context.handle(
        _seriesIdMeta,
        seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta),
      );
    }
    if (data.containsKey('position_ms')) {
      context.handle(
        _positionMsMeta,
        positionMs.isAcceptableOrUnknown(data['position_ms']!, _positionMsMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMsMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    } else if (isInserting) {
      context.missing(_durationMsMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    profileId,
    providerId,
    kind,
    remoteId,
  };
  @override
  ProgressRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProgressRow(
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      )!,
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      )!,
      seriesId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}series_id'],
      ),
      positionMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position_ms'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ProgressTable createAlias(String alias) {
    return $ProgressTable(attachedDatabase, alias);
  }
}

class ProgressRow extends DataClass implements Insertable<ProgressRow> {
  final int profileId;
  final String providerId;

  /// [ContentKind.movie] or [ContentKind.episode].
  final String kind;
  final String remoteId;

  /// For episodes: the series, so "Continue watching" can show it.
  final String? seriesId;
  final int positionMs;
  final int durationMs;
  final DateTime updatedAt;
  const ProgressRow({
    required this.profileId,
    required this.providerId,
    required this.kind,
    required this.remoteId,
    this.seriesId,
    required this.positionMs,
    required this.durationMs,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['profile_id'] = Variable<int>(profileId);
    map['provider_id'] = Variable<String>(providerId);
    map['kind'] = Variable<String>(kind);
    map['remote_id'] = Variable<String>(remoteId);
    if (!nullToAbsent || seriesId != null) {
      map['series_id'] = Variable<String>(seriesId);
    }
    map['position_ms'] = Variable<int>(positionMs);
    map['duration_ms'] = Variable<int>(durationMs);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ProgressCompanion toCompanion(bool nullToAbsent) {
    return ProgressCompanion(
      profileId: Value(profileId),
      providerId: Value(providerId),
      kind: Value(kind),
      remoteId: Value(remoteId),
      seriesId: seriesId == null && nullToAbsent
          ? const Value.absent()
          : Value(seriesId),
      positionMs: Value(positionMs),
      durationMs: Value(durationMs),
      updatedAt: Value(updatedAt),
    );
  }

  factory ProgressRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProgressRow(
      profileId: serializer.fromJson<int>(json['profileId']),
      providerId: serializer.fromJson<String>(json['providerId']),
      kind: serializer.fromJson<String>(json['kind']),
      remoteId: serializer.fromJson<String>(json['remoteId']),
      seriesId: serializer.fromJson<String?>(json['seriesId']),
      positionMs: serializer.fromJson<int>(json['positionMs']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'profileId': serializer.toJson<int>(profileId),
      'providerId': serializer.toJson<String>(providerId),
      'kind': serializer.toJson<String>(kind),
      'remoteId': serializer.toJson<String>(remoteId),
      'seriesId': serializer.toJson<String?>(seriesId),
      'positionMs': serializer.toJson<int>(positionMs),
      'durationMs': serializer.toJson<int>(durationMs),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ProgressRow copyWith({
    int? profileId,
    String? providerId,
    String? kind,
    String? remoteId,
    Value<String?> seriesId = const Value.absent(),
    int? positionMs,
    int? durationMs,
    DateTime? updatedAt,
  }) => ProgressRow(
    profileId: profileId ?? this.profileId,
    providerId: providerId ?? this.providerId,
    kind: kind ?? this.kind,
    remoteId: remoteId ?? this.remoteId,
    seriesId: seriesId.present ? seriesId.value : this.seriesId,
    positionMs: positionMs ?? this.positionMs,
    durationMs: durationMs ?? this.durationMs,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ProgressRow copyWithCompanion(ProgressCompanion data) {
    return ProgressRow(
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      kind: data.kind.present ? data.kind.value : this.kind,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
      positionMs: data.positionMs.present
          ? data.positionMs.value
          : this.positionMs,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProgressRow(')
          ..write('profileId: $profileId, ')
          ..write('providerId: $providerId, ')
          ..write('kind: $kind, ')
          ..write('remoteId: $remoteId, ')
          ..write('seriesId: $seriesId, ')
          ..write('positionMs: $positionMs, ')
          ..write('durationMs: $durationMs, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    profileId,
    providerId,
    kind,
    remoteId,
    seriesId,
    positionMs,
    durationMs,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProgressRow &&
          other.profileId == this.profileId &&
          other.providerId == this.providerId &&
          other.kind == this.kind &&
          other.remoteId == this.remoteId &&
          other.seriesId == this.seriesId &&
          other.positionMs == this.positionMs &&
          other.durationMs == this.durationMs &&
          other.updatedAt == this.updatedAt);
}

class ProgressCompanion extends UpdateCompanion<ProgressRow> {
  final Value<int> profileId;
  final Value<String> providerId;
  final Value<String> kind;
  final Value<String> remoteId;
  final Value<String?> seriesId;
  final Value<int> positionMs;
  final Value<int> durationMs;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ProgressCompanion({
    this.profileId = const Value.absent(),
    this.providerId = const Value.absent(),
    this.kind = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.positionMs = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProgressCompanion.insert({
    required int profileId,
    required String providerId,
    required String kind,
    required String remoteId,
    this.seriesId = const Value.absent(),
    required int positionMs,
    required int durationMs,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : profileId = Value(profileId),
       providerId = Value(providerId),
       kind = Value(kind),
       remoteId = Value(remoteId),
       positionMs = Value(positionMs),
       durationMs = Value(durationMs),
       updatedAt = Value(updatedAt);
  static Insertable<ProgressRow> custom({
    Expression<int>? profileId,
    Expression<String>? providerId,
    Expression<String>? kind,
    Expression<String>? remoteId,
    Expression<String>? seriesId,
    Expression<int>? positionMs,
    Expression<int>? durationMs,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (profileId != null) 'profile_id': profileId,
      if (providerId != null) 'provider_id': providerId,
      if (kind != null) 'kind': kind,
      if (remoteId != null) 'remote_id': remoteId,
      if (seriesId != null) 'series_id': seriesId,
      if (positionMs != null) 'position_ms': positionMs,
      if (durationMs != null) 'duration_ms': durationMs,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProgressCompanion copyWith({
    Value<int>? profileId,
    Value<String>? providerId,
    Value<String>? kind,
    Value<String>? remoteId,
    Value<String?>? seriesId,
    Value<int>? positionMs,
    Value<int>? durationMs,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ProgressCompanion(
      profileId: profileId ?? this.profileId,
      providerId: providerId ?? this.providerId,
      kind: kind ?? this.kind,
      remoteId: remoteId ?? this.remoteId,
      seriesId: seriesId ?? this.seriesId,
      positionMs: positionMs ?? this.positionMs,
      durationMs: durationMs ?? this.durationMs,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (seriesId.present) {
      map['series_id'] = Variable<String>(seriesId.value);
    }
    if (positionMs.present) {
      map['position_ms'] = Variable<int>(positionMs.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProgressCompanion(')
          ..write('profileId: $profileId, ')
          ..write('providerId: $providerId, ')
          ..write('kind: $kind, ')
          ..write('remoteId: $remoteId, ')
          ..write('seriesId: $seriesId, ')
          ..write('positionMs: $positionMs, ')
          ..write('durationMs: $durationMs, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RecentsTable extends Recents with TableInfo<$RecentsTable, RecentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RecentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<int> profileId = GeneratedColumn<int>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
    'provider_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteIdMeta = const VerificationMeta(
    'remoteId',
  );
  @override
  late final GeneratedColumn<String> remoteId = GeneratedColumn<String>(
    'remote_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    profileId,
    providerId,
    kind,
    remoteId,
    at,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recents';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('remote_id')) {
      context.handle(
        _remoteIdMeta,
        remoteId.isAcceptableOrUnknown(data['remote_id']!, _remoteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_remoteIdMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    profileId,
    providerId,
    kind,
    remoteId,
  };
  @override
  RecentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecentRow(
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}profile_id'],
      )!,
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      remoteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id'],
      )!,
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
    );
  }

  @override
  $RecentsTable createAlias(String alias) {
    return $RecentsTable(attachedDatabase, alias);
  }
}

class RecentRow extends DataClass implements Insertable<RecentRow> {
  final int profileId;
  final String providerId;
  final String kind;
  final String remoteId;
  final DateTime at;
  const RecentRow({
    required this.profileId,
    required this.providerId,
    required this.kind,
    required this.remoteId,
    required this.at,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['profile_id'] = Variable<int>(profileId);
    map['provider_id'] = Variable<String>(providerId);
    map['kind'] = Variable<String>(kind);
    map['remote_id'] = Variable<String>(remoteId);
    map['at'] = Variable<DateTime>(at);
    return map;
  }

  RecentsCompanion toCompanion(bool nullToAbsent) {
    return RecentsCompanion(
      profileId: Value(profileId),
      providerId: Value(providerId),
      kind: Value(kind),
      remoteId: Value(remoteId),
      at: Value(at),
    );
  }

  factory RecentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecentRow(
      profileId: serializer.fromJson<int>(json['profileId']),
      providerId: serializer.fromJson<String>(json['providerId']),
      kind: serializer.fromJson<String>(json['kind']),
      remoteId: serializer.fromJson<String>(json['remoteId']),
      at: serializer.fromJson<DateTime>(json['at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'profileId': serializer.toJson<int>(profileId),
      'providerId': serializer.toJson<String>(providerId),
      'kind': serializer.toJson<String>(kind),
      'remoteId': serializer.toJson<String>(remoteId),
      'at': serializer.toJson<DateTime>(at),
    };
  }

  RecentRow copyWith({
    int? profileId,
    String? providerId,
    String? kind,
    String? remoteId,
    DateTime? at,
  }) => RecentRow(
    profileId: profileId ?? this.profileId,
    providerId: providerId ?? this.providerId,
    kind: kind ?? this.kind,
    remoteId: remoteId ?? this.remoteId,
    at: at ?? this.at,
  );
  RecentRow copyWithCompanion(RecentsCompanion data) {
    return RecentRow(
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      kind: data.kind.present ? data.kind.value : this.kind,
      remoteId: data.remoteId.present ? data.remoteId.value : this.remoteId,
      at: data.at.present ? data.at.value : this.at,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecentRow(')
          ..write('profileId: $profileId, ')
          ..write('providerId: $providerId, ')
          ..write('kind: $kind, ')
          ..write('remoteId: $remoteId, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(profileId, providerId, kind, remoteId, at);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecentRow &&
          other.profileId == this.profileId &&
          other.providerId == this.providerId &&
          other.kind == this.kind &&
          other.remoteId == this.remoteId &&
          other.at == this.at);
}

class RecentsCompanion extends UpdateCompanion<RecentRow> {
  final Value<int> profileId;
  final Value<String> providerId;
  final Value<String> kind;
  final Value<String> remoteId;
  final Value<DateTime> at;
  final Value<int> rowid;
  const RecentsCompanion({
    this.profileId = const Value.absent(),
    this.providerId = const Value.absent(),
    this.kind = const Value.absent(),
    this.remoteId = const Value.absent(),
    this.at = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecentsCompanion.insert({
    required int profileId,
    required String providerId,
    required String kind,
    required String remoteId,
    required DateTime at,
    this.rowid = const Value.absent(),
  }) : profileId = Value(profileId),
       providerId = Value(providerId),
       kind = Value(kind),
       remoteId = Value(remoteId),
       at = Value(at);
  static Insertable<RecentRow> custom({
    Expression<int>? profileId,
    Expression<String>? providerId,
    Expression<String>? kind,
    Expression<String>? remoteId,
    Expression<DateTime>? at,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (profileId != null) 'profile_id': profileId,
      if (providerId != null) 'provider_id': providerId,
      if (kind != null) 'kind': kind,
      if (remoteId != null) 'remote_id': remoteId,
      if (at != null) 'at': at,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecentsCompanion copyWith({
    Value<int>? profileId,
    Value<String>? providerId,
    Value<String>? kind,
    Value<String>? remoteId,
    Value<DateTime>? at,
    Value<int>? rowid,
  }) {
    return RecentsCompanion(
      profileId: profileId ?? this.profileId,
      providerId: providerId ?? this.providerId,
      kind: kind ?? this.kind,
      remoteId: remoteId ?? this.remoteId,
      at: at ?? this.at,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (profileId.present) {
      map['profile_id'] = Variable<int>(profileId.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (remoteId.present) {
      map['remote_id'] = Variable<String>(remoteId.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecentsCompanion(')
          ..write('profileId: $profileId, ')
          ..write('providerId: $providerId, ')
          ..write('kind: $kind, ')
          ..write('remoteId: $remoteId, ')
          ..write('at: $at, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProvidersTable providers = $ProvidersTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $ChannelsTable channels = $ChannelsTable(this);
  late final $MoviesTable movies = $MoviesTable(this);
  late final $SeriesTableTable seriesTable = $SeriesTableTable(this);
  late final $EpisodesTable episodes = $EpisodesTable(this);
  late final $EpgProgramsTable epgPrograms = $EpgProgramsTable(this);
  late final $ProfilesTable profiles = $ProfilesTable(this);
  late final $FavouritesTable favourites = $FavouritesTable(this);
  late final $MyListTable myList = $MyListTable(this);
  late final $ProgressTable progress = $ProgressTable(this);
  late final $RecentsTable recents = $RecentsTable(this);
  late final Index channelsByCategory = Index(
    'channels_by_category',
    'CREATE INDEX channels_by_category ON channels (provider_id, category_id)',
  );
  late final Index channelsByNumber = Index(
    'channels_by_number',
    'CREATE INDEX channels_by_number ON channels (provider_id, number)',
  );
  late final Index moviesByCategory = Index(
    'movies_by_category',
    'CREATE INDEX movies_by_category ON movies (provider_id, category_id)',
  );
  late final Index moviesByAdded = Index(
    'movies_by_added',
    'CREATE INDEX movies_by_added ON movies (provider_id, added)',
  );
  late final Index seriesByCategory = Index(
    'series_by_category',
    'CREATE INDEX series_by_category ON series (provider_id, category_id)',
  );
  late final Index episodesBySeries = Index(
    'episodes_by_series',
    'CREATE INDEX episodes_by_series ON episodes (provider_id, series_id)',
  );
  late final Index epgByChannelTime = Index(
    'epg_by_channel_time',
    'CREATE INDEX epg_by_channel_time ON epg_programs (provider_id, channel_epg_id, start)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    providers,
    categories,
    channels,
    movies,
    seriesTable,
    episodes,
    epgPrograms,
    profiles,
    favourites,
    myList,
    progress,
    recents,
    channelsByCategory,
    channelsByNumber,
    moviesByCategory,
    moviesByAdded,
    seriesByCategory,
    episodesBySeries,
    epgByChannelTime,
  ];
}

typedef $$ProvidersTableCreateCompanionBuilder = ProvidersCompanion Function({
  required String id,
  required String kind,
  required String name,
  Value<String> displayHost,
  Value<String?> username,
  Value<String?> endpointJson,
  Value<String?> userAgentId,
  Value<String?> liveExtension,
  Value<bool> allowUntrustedCert,
  Value<String?> epgUrl,
  Value<String?> fileName,
  Value<DateTime?> lastSyncAt,
  Value<String?> lastSyncError,
  Value<String?> userInfoJson,
  Value<String?> serverInfoJson,
  required DateTime createdAt,
  Value<int> sortOrder,
  Value<int> rowid,
});
typedef $$ProvidersTableUpdateCompanionBuilder = ProvidersCompanion Function({
  Value<String> id,
  Value<String> kind,
  Value<String> name,
  Value<String> displayHost,
  Value<String?> username,
  Value<String?> endpointJson,
  Value<String?> userAgentId,
  Value<String?> liveExtension,
  Value<bool> allowUntrustedCert,
  Value<String?> epgUrl,
  Value<String?> fileName,
  Value<DateTime?> lastSyncAt,
  Value<String?> lastSyncError,
  Value<String?> userInfoJson,
  Value<String?> serverInfoJson,
  Value<DateTime> createdAt,
  Value<int> sortOrder,
  Value<int> rowid,
});

class $$ProvidersTableFilterComposer
    extends Composer<_$AppDatabase, $ProvidersTable> {
  $$ProvidersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayHost => $composableBuilder(
    column: $table.displayHost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endpointJson => $composableBuilder(
    column: $table.endpointJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userAgentId => $composableBuilder(
    column: $table.userAgentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get liveExtension => $composableBuilder(
    column: $table.liveExtension,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get allowUntrustedCert => $composableBuilder(
    column: $table.allowUntrustedCert,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get epgUrl => $composableBuilder(
    column: $table.epgUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastSyncError => $composableBuilder(
    column: $table.lastSyncError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userInfoJson => $composableBuilder(
    column: $table.userInfoJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverInfoJson => $composableBuilder(
    column: $table.serverInfoJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProvidersTableOrderingComposer
    extends Composer<_$AppDatabase, $ProvidersTable> {
  $$ProvidersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayHost => $composableBuilder(
    column: $table.displayHost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endpointJson => $composableBuilder(
    column: $table.endpointJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userAgentId => $composableBuilder(
    column: $table.userAgentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get liveExtension => $composableBuilder(
    column: $table.liveExtension,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get allowUntrustedCert => $composableBuilder(
    column: $table.allowUntrustedCert,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get epgUrl => $composableBuilder(
    column: $table.epgUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastSyncError => $composableBuilder(
    column: $table.lastSyncError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userInfoJson => $composableBuilder(
    column: $table.userInfoJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverInfoJson => $composableBuilder(
    column: $table.serverInfoJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProvidersTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProvidersTable> {
  $$ProvidersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get displayHost => $composableBuilder(
    column: $table.displayHost,
    builder: (column) => column,
  );

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get endpointJson => $composableBuilder(
    column: $table.endpointJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userAgentId => $composableBuilder(
    column: $table.userAgentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get liveExtension => $composableBuilder(
    column: $table.liveExtension,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get allowUntrustedCert => $composableBuilder(
    column: $table.allowUntrustedCert,
    builder: (column) => column,
  );

  GeneratedColumn<String> get epgUrl =>
      $composableBuilder(column: $table.epgUrl, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastSyncError => $composableBuilder(
    column: $table.lastSyncError,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userInfoJson => $composableBuilder(
    column: $table.userInfoJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get serverInfoJson => $composableBuilder(
    column: $table.serverInfoJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$ProvidersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProvidersTable,
          ProviderRow,
          $$ProvidersTableFilterComposer,
          $$ProvidersTableOrderingComposer,
          $$ProvidersTableAnnotationComposer,
          $$ProvidersTableCreateCompanionBuilder,
          $$ProvidersTableUpdateCompanionBuilder,
          (
            ProviderRow,
            BaseReferences<_$AppDatabase, $ProvidersTable, ProviderRow>,
          ),
          ProviderRow,
          PrefetchHooks Function()
        > {
  $$ProvidersTableTableManager(_$AppDatabase db, $ProvidersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProvidersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProvidersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProvidersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> displayHost = const Value.absent(),
                Value<String?> username = const Value.absent(),
                Value<String?> endpointJson = const Value.absent(),
                Value<String?> userAgentId = const Value.absent(),
                Value<String?> liveExtension = const Value.absent(),
                Value<bool> allowUntrustedCert = const Value.absent(),
                Value<String?> epgUrl = const Value.absent(),
                Value<String?> fileName = const Value.absent(),
                Value<DateTime?> lastSyncAt = const Value.absent(),
                Value<String?> lastSyncError = const Value.absent(),
                Value<String?> userInfoJson = const Value.absent(),
                Value<String?> serverInfoJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProvidersCompanion(
                id: id,
                kind: kind,
                name: name,
                displayHost: displayHost,
                username: username,
                endpointJson: endpointJson,
                userAgentId: userAgentId,
                liveExtension: liveExtension,
                allowUntrustedCert: allowUntrustedCert,
                epgUrl: epgUrl,
                fileName: fileName,
                lastSyncAt: lastSyncAt,
                lastSyncError: lastSyncError,
                userInfoJson: userInfoJson,
                serverInfoJson: serverInfoJson,
                createdAt: createdAt,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String kind,
                required String name,
                Value<String> displayHost = const Value.absent(),
                Value<String?> username = const Value.absent(),
                Value<String?> endpointJson = const Value.absent(),
                Value<String?> userAgentId = const Value.absent(),
                Value<String?> liveExtension = const Value.absent(),
                Value<bool> allowUntrustedCert = const Value.absent(),
                Value<String?> epgUrl = const Value.absent(),
                Value<String?> fileName = const Value.absent(),
                Value<DateTime?> lastSyncAt = const Value.absent(),
                Value<String?> lastSyncError = const Value.absent(),
                Value<String?> userInfoJson = const Value.absent(),
                Value<String?> serverInfoJson = const Value.absent(),
                required DateTime createdAt,
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProvidersCompanion.insert(
                id: id,
                kind: kind,
                name: name,
                displayHost: displayHost,
                username: username,
                endpointJson: endpointJson,
                userAgentId: userAgentId,
                liveExtension: liveExtension,
                allowUntrustedCert: allowUntrustedCert,
                epgUrl: epgUrl,
                fileName: fileName,
                lastSyncAt: lastSyncAt,
                lastSyncError: lastSyncError,
                userInfoJson: userInfoJson,
                serverInfoJson: serverInfoJson,
                createdAt: createdAt,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProvidersTable, ProviderRow>(table),
                  BaseReferences<_$AppDatabase, $ProvidersTable, ProviderRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProvidersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProvidersTable,
      ProviderRow,
      $$ProvidersTableFilterComposer,
      $$ProvidersTableOrderingComposer,
      $$ProvidersTableAnnotationComposer,
      $$ProvidersTableCreateCompanionBuilder,
      $$ProvidersTableUpdateCompanionBuilder,
      (
        ProviderRow,
        BaseReferences<_$AppDatabase, $ProvidersTable, ProviderRow>,
      ),
      ProviderRow,
      PrefetchHooks Function()
    >;
typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  required String providerId,
  required String kind,
  required String remoteId,
  required String name,
  Value<bool> isAdult,
  Value<bool> isKids,
  Value<int> sortOrder,
  Value<int> syncToken,
  Value<int> rowid,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<String> providerId,
  Value<String> kind,
  Value<String> remoteId,
  Value<String> name,
  Value<bool> isAdult,
  Value<bool> isKids,
  Value<int> sortOrder,
  Value<int> syncToken,
  Value<int> rowid,
});

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAdult => $composableBuilder(
    column: $table.isAdult,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isKids => $composableBuilder(
    column: $table.isKids,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncToken => $composableBuilder(
    column: $table.syncToken,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAdult => $composableBuilder(
    column: $table.isAdult,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isKids => $composableBuilder(
    column: $table.isKids,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncToken => $composableBuilder(
    column: $table.syncToken,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get isAdult =>
      $composableBuilder(column: $table.isAdult, builder: (column) => column);

  GeneratedColumn<bool> get isKids =>
      $composableBuilder(column: $table.isKids, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get syncToken =>
      $composableBuilder(column: $table.syncToken, builder: (column) => column);
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          CategoryRow,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (
            CategoryRow,
            BaseReferences<_$AppDatabase, $CategoriesTable, CategoryRow>,
          ),
          CategoryRow,
          PrefetchHooks Function()
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> providerId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> remoteId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> isAdult = const Value.absent(),
                Value<bool> isKids = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> syncToken = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion(
                providerId: providerId,
                kind: kind,
                remoteId: remoteId,
                name: name,
                isAdult: isAdult,
                isKids: isKids,
                sortOrder: sortOrder,
                syncToken: syncToken,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String providerId,
                required String kind,
                required String remoteId,
                required String name,
                Value<bool> isAdult = const Value.absent(),
                Value<bool> isKids = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> syncToken = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion.insert(
                providerId: providerId,
                kind: kind,
                remoteId: remoteId,
                name: name,
                isAdult: isAdult,
                isKids: isKids,
                sortOrder: sortOrder,
                syncToken: syncToken,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CategoriesTable, CategoryRow>(table),
                  BaseReferences<_$AppDatabase, $CategoriesTable, CategoryRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      CategoryRow,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (
        CategoryRow,
        BaseReferences<_$AppDatabase, $CategoriesTable, CategoryRow>,
      ),
      CategoryRow,
      PrefetchHooks Function()
    >;
typedef $$ChannelsTableCreateCompanionBuilder = ChannelsCompanion Function({
  required String providerId,
  required String remoteId,
  required String name,
  Value<int?> number,
  Value<String?> logo,
  Value<String?> epgId,
  Value<String?> categoryId,
  Value<bool> tvArchive,
  Value<int> archiveDays,
  Value<String?> url,
  Value<String?> headersJson,
  Value<bool> isAdult,
  Value<int> sortOrder,
  Value<int> syncToken,
  Value<int> rowid,
});
typedef $$ChannelsTableUpdateCompanionBuilder = ChannelsCompanion Function({
  Value<String> providerId,
  Value<String> remoteId,
  Value<String> name,
  Value<int?> number,
  Value<String?> logo,
  Value<String?> epgId,
  Value<String?> categoryId,
  Value<bool> tvArchive,
  Value<int> archiveDays,
  Value<String?> url,
  Value<String?> headersJson,
  Value<bool> isAdult,
  Value<int> sortOrder,
  Value<int> syncToken,
  Value<int> rowid,
});

class $$ChannelsTableFilterComposer
    extends Composer<_$AppDatabase, $ChannelsTable> {
  $$ChannelsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get logo => $composableBuilder(
    column: $table.logo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get epgId => $composableBuilder(
    column: $table.epgId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get tvArchive => $composableBuilder(
    column: $table.tvArchive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get archiveDays => $composableBuilder(
    column: $table.archiveDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get headersJson => $composableBuilder(
    column: $table.headersJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAdult => $composableBuilder(
    column: $table.isAdult,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncToken => $composableBuilder(
    column: $table.syncToken,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChannelsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChannelsTable> {
  $$ChannelsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get logo => $composableBuilder(
    column: $table.logo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get epgId => $composableBuilder(
    column: $table.epgId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get tvArchive => $composableBuilder(
    column: $table.tvArchive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get archiveDays => $composableBuilder(
    column: $table.archiveDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get headersJson => $composableBuilder(
    column: $table.headersJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAdult => $composableBuilder(
    column: $table.isAdult,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncToken => $composableBuilder(
    column: $table.syncToken,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChannelsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChannelsTable> {
  $$ChannelsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<String> get logo =>
      $composableBuilder(column: $table.logo, builder: (column) => column);

  GeneratedColumn<String> get epgId =>
      $composableBuilder(column: $table.epgId, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get tvArchive =>
      $composableBuilder(column: $table.tvArchive, builder: (column) => column);

  GeneratedColumn<int> get archiveDays => $composableBuilder(
    column: $table.archiveDays,
    builder: (column) => column,
  );

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get headersJson => $composableBuilder(
    column: $table.headersJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isAdult =>
      $composableBuilder(column: $table.isAdult, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get syncToken =>
      $composableBuilder(column: $table.syncToken, builder: (column) => column);
}

class $$ChannelsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChannelsTable,
          ChannelRow,
          $$ChannelsTableFilterComposer,
          $$ChannelsTableOrderingComposer,
          $$ChannelsTableAnnotationComposer,
          $$ChannelsTableCreateCompanionBuilder,
          $$ChannelsTableUpdateCompanionBuilder,
          (
            ChannelRow,
            BaseReferences<_$AppDatabase, $ChannelsTable, ChannelRow>,
          ),
          ChannelRow,
          PrefetchHooks Function()
        > {
  $$ChannelsTableTableManager(_$AppDatabase db, $ChannelsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChannelsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChannelsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChannelsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> providerId = const Value.absent(),
                Value<String> remoteId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int?> number = const Value.absent(),
                Value<String?> logo = const Value.absent(),
                Value<String?> epgId = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<bool> tvArchive = const Value.absent(),
                Value<int> archiveDays = const Value.absent(),
                Value<String?> url = const Value.absent(),
                Value<String?> headersJson = const Value.absent(),
                Value<bool> isAdult = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> syncToken = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChannelsCompanion(
                providerId: providerId,
                remoteId: remoteId,
                name: name,
                number: number,
                logo: logo,
                epgId: epgId,
                categoryId: categoryId,
                tvArchive: tvArchive,
                archiveDays: archiveDays,
                url: url,
                headersJson: headersJson,
                isAdult: isAdult,
                sortOrder: sortOrder,
                syncToken: syncToken,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String providerId,
                required String remoteId,
                required String name,
                Value<int?> number = const Value.absent(),
                Value<String?> logo = const Value.absent(),
                Value<String?> epgId = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<bool> tvArchive = const Value.absent(),
                Value<int> archiveDays = const Value.absent(),
                Value<String?> url = const Value.absent(),
                Value<String?> headersJson = const Value.absent(),
                Value<bool> isAdult = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> syncToken = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChannelsCompanion.insert(
                providerId: providerId,
                remoteId: remoteId,
                name: name,
                number: number,
                logo: logo,
                epgId: epgId,
                categoryId: categoryId,
                tvArchive: tvArchive,
                archiveDays: archiveDays,
                url: url,
                headersJson: headersJson,
                isAdult: isAdult,
                sortOrder: sortOrder,
                syncToken: syncToken,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ChannelsTable, ChannelRow>(table),
                  BaseReferences<_$AppDatabase, $ChannelsTable, ChannelRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChannelsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChannelsTable,
      ChannelRow,
      $$ChannelsTableFilterComposer,
      $$ChannelsTableOrderingComposer,
      $$ChannelsTableAnnotationComposer,
      $$ChannelsTableCreateCompanionBuilder,
      $$ChannelsTableUpdateCompanionBuilder,
      (ChannelRow, BaseReferences<_$AppDatabase, $ChannelsTable, ChannelRow>),
      ChannelRow,
      PrefetchHooks Function()
    >;
typedef $$MoviesTableCreateCompanionBuilder = MoviesCompanion Function({
  required String providerId,
  required String remoteId,
  required String name,
  Value<String?> poster,
  Value<String?> categoryId,
  Value<String> containerExtension,
  Value<double?> rating,
  Value<int?> year,
  Value<DateTime?> added,
  Value<String?> url,
  Value<String?> headersJson,
  Value<bool> isAdult,
  Value<int> sortOrder,
  Value<int> syncToken,
  Value<int> rowid,
});
typedef $$MoviesTableUpdateCompanionBuilder = MoviesCompanion Function({
  Value<String> providerId,
  Value<String> remoteId,
  Value<String> name,
  Value<String?> poster,
  Value<String?> categoryId,
  Value<String> containerExtension,
  Value<double?> rating,
  Value<int?> year,
  Value<DateTime?> added,
  Value<String?> url,
  Value<String?> headersJson,
  Value<bool> isAdult,
  Value<int> sortOrder,
  Value<int> syncToken,
  Value<int> rowid,
});

class $$MoviesTableFilterComposer
    extends Composer<_$AppDatabase, $MoviesTable> {
  $$MoviesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get poster => $composableBuilder(
    column: $table.poster,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get containerExtension => $composableBuilder(
    column: $table.containerExtension,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get added => $composableBuilder(
    column: $table.added,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get headersJson => $composableBuilder(
    column: $table.headersJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAdult => $composableBuilder(
    column: $table.isAdult,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncToken => $composableBuilder(
    column: $table.syncToken,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MoviesTableOrderingComposer
    extends Composer<_$AppDatabase, $MoviesTable> {
  $$MoviesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get poster => $composableBuilder(
    column: $table.poster,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get containerExtension => $composableBuilder(
    column: $table.containerExtension,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get added => $composableBuilder(
    column: $table.added,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get headersJson => $composableBuilder(
    column: $table.headersJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAdult => $composableBuilder(
    column: $table.isAdult,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncToken => $composableBuilder(
    column: $table.syncToken,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MoviesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MoviesTable> {
  $$MoviesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get poster =>
      $composableBuilder(column: $table.poster, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get containerExtension => $composableBuilder(
    column: $table.containerExtension,
    builder: (column) => column,
  );

  GeneratedColumn<double> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<DateTime> get added =>
      $composableBuilder(column: $table.added, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get headersJson => $composableBuilder(
    column: $table.headersJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isAdult =>
      $composableBuilder(column: $table.isAdult, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get syncToken =>
      $composableBuilder(column: $table.syncToken, builder: (column) => column);
}

class $$MoviesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MoviesTable,
          MovieRow,
          $$MoviesTableFilterComposer,
          $$MoviesTableOrderingComposer,
          $$MoviesTableAnnotationComposer,
          $$MoviesTableCreateCompanionBuilder,
          $$MoviesTableUpdateCompanionBuilder,
          (MovieRow, BaseReferences<_$AppDatabase, $MoviesTable, MovieRow>),
          MovieRow,
          PrefetchHooks Function()
        > {
  $$MoviesTableTableManager(_$AppDatabase db, $MoviesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MoviesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MoviesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MoviesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> providerId = const Value.absent(),
                Value<String> remoteId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> poster = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String> containerExtension = const Value.absent(),
                Value<double?> rating = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<DateTime?> added = const Value.absent(),
                Value<String?> url = const Value.absent(),
                Value<String?> headersJson = const Value.absent(),
                Value<bool> isAdult = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> syncToken = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MoviesCompanion(
                providerId: providerId,
                remoteId: remoteId,
                name: name,
                poster: poster,
                categoryId: categoryId,
                containerExtension: containerExtension,
                rating: rating,
                year: year,
                added: added,
                url: url,
                headersJson: headersJson,
                isAdult: isAdult,
                sortOrder: sortOrder,
                syncToken: syncToken,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String providerId,
                required String remoteId,
                required String name,
                Value<String?> poster = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String> containerExtension = const Value.absent(),
                Value<double?> rating = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<DateTime?> added = const Value.absent(),
                Value<String?> url = const Value.absent(),
                Value<String?> headersJson = const Value.absent(),
                Value<bool> isAdult = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> syncToken = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MoviesCompanion.insert(
                providerId: providerId,
                remoteId: remoteId,
                name: name,
                poster: poster,
                categoryId: categoryId,
                containerExtension: containerExtension,
                rating: rating,
                year: year,
                added: added,
                url: url,
                headersJson: headersJson,
                isAdult: isAdult,
                sortOrder: sortOrder,
                syncToken: syncToken,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MoviesTable, MovieRow>(table),
                  BaseReferences<_$AppDatabase, $MoviesTable, MovieRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MoviesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MoviesTable,
      MovieRow,
      $$MoviesTableFilterComposer,
      $$MoviesTableOrderingComposer,
      $$MoviesTableAnnotationComposer,
      $$MoviesTableCreateCompanionBuilder,
      $$MoviesTableUpdateCompanionBuilder,
      (MovieRow, BaseReferences<_$AppDatabase, $MoviesTable, MovieRow>),
      MovieRow,
      PrefetchHooks Function()
    >;
typedef $$SeriesTableTableCreateCompanionBuilder =
    SeriesTableCompanion Function({
      required String providerId,
      required String remoteId,
      required String name,
      Value<String?> poster,
      Value<String?> backdrop,
      Value<String?> plot,
      Value<String?> genre,
      Value<double?> rating,
      Value<int?> year,
      Value<String?> categoryId,
      Value<DateTime?> lastModified,
      Value<String?> url,
      Value<String?> headersJson,
      Value<bool> isAdult,
      Value<int> sortOrder,
      Value<int> syncToken,
      Value<int> rowid,
    });
typedef $$SeriesTableTableUpdateCompanionBuilder =
    SeriesTableCompanion Function({
      Value<String> providerId,
      Value<String> remoteId,
      Value<String> name,
      Value<String?> poster,
      Value<String?> backdrop,
      Value<String?> plot,
      Value<String?> genre,
      Value<double?> rating,
      Value<int?> year,
      Value<String?> categoryId,
      Value<DateTime?> lastModified,
      Value<String?> url,
      Value<String?> headersJson,
      Value<bool> isAdult,
      Value<int> sortOrder,
      Value<int> syncToken,
      Value<int> rowid,
    });

class $$SeriesTableTableFilterComposer
    extends Composer<_$AppDatabase, $SeriesTableTable> {
  $$SeriesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get poster => $composableBuilder(
    column: $table.poster,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get backdrop => $composableBuilder(
    column: $table.backdrop,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plot => $composableBuilder(
    column: $table.plot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get headersJson => $composableBuilder(
    column: $table.headersJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAdult => $composableBuilder(
    column: $table.isAdult,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncToken => $composableBuilder(
    column: $table.syncToken,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SeriesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SeriesTableTable> {
  $$SeriesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get poster => $composableBuilder(
    column: $table.poster,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get backdrop => $composableBuilder(
    column: $table.backdrop,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plot => $composableBuilder(
    column: $table.plot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get genre => $composableBuilder(
    column: $table.genre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get headersJson => $composableBuilder(
    column: $table.headersJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAdult => $composableBuilder(
    column: $table.isAdult,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncToken => $composableBuilder(
    column: $table.syncToken,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SeriesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SeriesTableTable> {
  $$SeriesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get poster =>
      $composableBuilder(column: $table.poster, builder: (column) => column);

  GeneratedColumn<String> get backdrop =>
      $composableBuilder(column: $table.backdrop, builder: (column) => column);

  GeneratedColumn<String> get plot =>
      $composableBuilder(column: $table.plot, builder: (column) => column);

  GeneratedColumn<String> get genre =>
      $composableBuilder(column: $table.genre, builder: (column) => column);

  GeneratedColumn<double> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastModified => $composableBuilder(
    column: $table.lastModified,
    builder: (column) => column,
  );

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get headersJson => $composableBuilder(
    column: $table.headersJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isAdult =>
      $composableBuilder(column: $table.isAdult, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get syncToken =>
      $composableBuilder(column: $table.syncToken, builder: (column) => column);
}

class $$SeriesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SeriesTableTable,
          SeriesRow,
          $$SeriesTableTableFilterComposer,
          $$SeriesTableTableOrderingComposer,
          $$SeriesTableTableAnnotationComposer,
          $$SeriesTableTableCreateCompanionBuilder,
          $$SeriesTableTableUpdateCompanionBuilder,
          (
            SeriesRow,
            BaseReferences<_$AppDatabase, $SeriesTableTable, SeriesRow>,
          ),
          SeriesRow,
          PrefetchHooks Function()
        > {
  $$SeriesTableTableTableManager(_$AppDatabase db, $SeriesTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SeriesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SeriesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SeriesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> providerId = const Value.absent(),
                Value<String> remoteId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> poster = const Value.absent(),
                Value<String?> backdrop = const Value.absent(),
                Value<String?> plot = const Value.absent(),
                Value<String?> genre = const Value.absent(),
                Value<double?> rating = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<DateTime?> lastModified = const Value.absent(),
                Value<String?> url = const Value.absent(),
                Value<String?> headersJson = const Value.absent(),
                Value<bool> isAdult = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> syncToken = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SeriesTableCompanion(
                providerId: providerId,
                remoteId: remoteId,
                name: name,
                poster: poster,
                backdrop: backdrop,
                plot: plot,
                genre: genre,
                rating: rating,
                year: year,
                categoryId: categoryId,
                lastModified: lastModified,
                url: url,
                headersJson: headersJson,
                isAdult: isAdult,
                sortOrder: sortOrder,
                syncToken: syncToken,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String providerId,
                required String remoteId,
                required String name,
                Value<String?> poster = const Value.absent(),
                Value<String?> backdrop = const Value.absent(),
                Value<String?> plot = const Value.absent(),
                Value<String?> genre = const Value.absent(),
                Value<double?> rating = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<DateTime?> lastModified = const Value.absent(),
                Value<String?> url = const Value.absent(),
                Value<String?> headersJson = const Value.absent(),
                Value<bool> isAdult = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> syncToken = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SeriesTableCompanion.insert(
                providerId: providerId,
                remoteId: remoteId,
                name: name,
                poster: poster,
                backdrop: backdrop,
                plot: plot,
                genre: genre,
                rating: rating,
                year: year,
                categoryId: categoryId,
                lastModified: lastModified,
                url: url,
                headersJson: headersJson,
                isAdult: isAdult,
                sortOrder: sortOrder,
                syncToken: syncToken,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SeriesTableTable, SeriesRow>(table),
                  BaseReferences<_$AppDatabase, $SeriesTableTable, SeriesRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SeriesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SeriesTableTable,
      SeriesRow,
      $$SeriesTableTableFilterComposer,
      $$SeriesTableTableOrderingComposer,
      $$SeriesTableTableAnnotationComposer,
      $$SeriesTableTableCreateCompanionBuilder,
      $$SeriesTableTableUpdateCompanionBuilder,
      (SeriesRow, BaseReferences<_$AppDatabase, $SeriesTableTable, SeriesRow>),
      SeriesRow,
      PrefetchHooks Function()
    >;
typedef $$EpisodesTableCreateCompanionBuilder = EpisodesCompanion Function({
  required String providerId,
  required String seriesId,
  required String episodeId,
  required int season,
  required int episodeNum,
  required String title,
  Value<String> containerExtension,
  Value<String?> plot,
  Value<int?> durationSecs,
  Value<String?> image,
  required DateTime fetchedAt,
  Value<int> rowid,
});
typedef $$EpisodesTableUpdateCompanionBuilder = EpisodesCompanion Function({
  Value<String> providerId,
  Value<String> seriesId,
  Value<String> episodeId,
  Value<int> season,
  Value<int> episodeNum,
  Value<String> title,
  Value<String> containerExtension,
  Value<String?> plot,
  Value<int?> durationSecs,
  Value<String?> image,
  Value<DateTime> fetchedAt,
  Value<int> rowid,
});

class $$EpisodesTableFilterComposer
    extends Composer<_$AppDatabase, $EpisodesTable> {
  $$EpisodesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get episodeId => $composableBuilder(
    column: $table.episodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get season => $composableBuilder(
    column: $table.season,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get episodeNum => $composableBuilder(
    column: $table.episodeNum,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get containerExtension => $composableBuilder(
    column: $table.containerExtension,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plot => $composableBuilder(
    column: $table.plot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSecs => $composableBuilder(
    column: $table.durationSecs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get image => $composableBuilder(
    column: $table.image,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EpisodesTableOrderingComposer
    extends Composer<_$AppDatabase, $EpisodesTable> {
  $$EpisodesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get episodeId => $composableBuilder(
    column: $table.episodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get season => $composableBuilder(
    column: $table.season,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get episodeNum => $composableBuilder(
    column: $table.episodeNum,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get containerExtension => $composableBuilder(
    column: $table.containerExtension,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plot => $composableBuilder(
    column: $table.plot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSecs => $composableBuilder(
    column: $table.durationSecs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get image => $composableBuilder(
    column: $table.image,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EpisodesTableAnnotationComposer
    extends Composer<_$AppDatabase, $EpisodesTable> {
  $$EpisodesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get seriesId =>
      $composableBuilder(column: $table.seriesId, builder: (column) => column);

  GeneratedColumn<String> get episodeId =>
      $composableBuilder(column: $table.episodeId, builder: (column) => column);

  GeneratedColumn<int> get season =>
      $composableBuilder(column: $table.season, builder: (column) => column);

  GeneratedColumn<int> get episodeNum => $composableBuilder(
    column: $table.episodeNum,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get containerExtension => $composableBuilder(
    column: $table.containerExtension,
    builder: (column) => column,
  );

  GeneratedColumn<String> get plot =>
      $composableBuilder(column: $table.plot, builder: (column) => column);

  GeneratedColumn<int> get durationSecs => $composableBuilder(
    column: $table.durationSecs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get image =>
      $composableBuilder(column: $table.image, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$EpisodesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EpisodesTable,
          EpisodeRow,
          $$EpisodesTableFilterComposer,
          $$EpisodesTableOrderingComposer,
          $$EpisodesTableAnnotationComposer,
          $$EpisodesTableCreateCompanionBuilder,
          $$EpisodesTableUpdateCompanionBuilder,
          (
            EpisodeRow,
            BaseReferences<_$AppDatabase, $EpisodesTable, EpisodeRow>,
          ),
          EpisodeRow,
          PrefetchHooks Function()
        > {
  $$EpisodesTableTableManager(_$AppDatabase db, $EpisodesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EpisodesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EpisodesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EpisodesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> providerId = const Value.absent(),
                Value<String> seriesId = const Value.absent(),
                Value<String> episodeId = const Value.absent(),
                Value<int> season = const Value.absent(),
                Value<int> episodeNum = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> containerExtension = const Value.absent(),
                Value<String?> plot = const Value.absent(),
                Value<int?> durationSecs = const Value.absent(),
                Value<String?> image = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EpisodesCompanion(
                providerId: providerId,
                seriesId: seriesId,
                episodeId: episodeId,
                season: season,
                episodeNum: episodeNum,
                title: title,
                containerExtension: containerExtension,
                plot: plot,
                durationSecs: durationSecs,
                image: image,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String providerId,
                required String seriesId,
                required String episodeId,
                required int season,
                required int episodeNum,
                required String title,
                Value<String> containerExtension = const Value.absent(),
                Value<String?> plot = const Value.absent(),
                Value<int?> durationSecs = const Value.absent(),
                Value<String?> image = const Value.absent(),
                required DateTime fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => EpisodesCompanion.insert(
                providerId: providerId,
                seriesId: seriesId,
                episodeId: episodeId,
                season: season,
                episodeNum: episodeNum,
                title: title,
                containerExtension: containerExtension,
                plot: plot,
                durationSecs: durationSecs,
                image: image,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EpisodesTable, EpisodeRow>(table),
                  BaseReferences<_$AppDatabase, $EpisodesTable, EpisodeRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EpisodesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EpisodesTable,
      EpisodeRow,
      $$EpisodesTableFilterComposer,
      $$EpisodesTableOrderingComposer,
      $$EpisodesTableAnnotationComposer,
      $$EpisodesTableCreateCompanionBuilder,
      $$EpisodesTableUpdateCompanionBuilder,
      (EpisodeRow, BaseReferences<_$AppDatabase, $EpisodesTable, EpisodeRow>),
      EpisodeRow,
      PrefetchHooks Function()
    >;
typedef $$EpgProgramsTableCreateCompanionBuilder =
    EpgProgramsCompanion Function({
      Value<int> id,
      required String providerId,
      required String channelEpgId,
      required DateTime start,
      required DateTime stop,
      required String title,
      Value<String?> description,
    });
typedef $$EpgProgramsTableUpdateCompanionBuilder =
    EpgProgramsCompanion Function({
      Value<int> id,
      Value<String> providerId,
      Value<String> channelEpgId,
      Value<DateTime> start,
      Value<DateTime> stop,
      Value<String> title,
      Value<String?> description,
    });

class $$EpgProgramsTableFilterComposer
    extends Composer<_$AppDatabase, $EpgProgramsTable> {
  $$EpgProgramsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get channelEpgId => $composableBuilder(
    column: $table.channelEpgId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get start => $composableBuilder(
    column: $table.start,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get stop => $composableBuilder(
    column: $table.stop,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EpgProgramsTableOrderingComposer
    extends Composer<_$AppDatabase, $EpgProgramsTable> {
  $$EpgProgramsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get channelEpgId => $composableBuilder(
    column: $table.channelEpgId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get start => $composableBuilder(
    column: $table.start,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get stop => $composableBuilder(
    column: $table.stop,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EpgProgramsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EpgProgramsTable> {
  $$EpgProgramsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get channelEpgId => $composableBuilder(
    column: $table.channelEpgId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get start =>
      $composableBuilder(column: $table.start, builder: (column) => column);

  GeneratedColumn<DateTime> get stop =>
      $composableBuilder(column: $table.stop, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );
}

class $$EpgProgramsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EpgProgramsTable,
          EpgProgramRow,
          $$EpgProgramsTableFilterComposer,
          $$EpgProgramsTableOrderingComposer,
          $$EpgProgramsTableAnnotationComposer,
          $$EpgProgramsTableCreateCompanionBuilder,
          $$EpgProgramsTableUpdateCompanionBuilder,
          (
            EpgProgramRow,
            BaseReferences<_$AppDatabase, $EpgProgramsTable, EpgProgramRow>,
          ),
          EpgProgramRow,
          PrefetchHooks Function()
        > {
  $$EpgProgramsTableTableManager(_$AppDatabase db, $EpgProgramsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EpgProgramsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EpgProgramsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EpgProgramsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> providerId = const Value.absent(),
                Value<String> channelEpgId = const Value.absent(),
                Value<DateTime> start = const Value.absent(),
                Value<DateTime> stop = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
              }) => EpgProgramsCompanion(
                id: id,
                providerId: providerId,
                channelEpgId: channelEpgId,
                start: start,
                stop: stop,
                title: title,
                description: description,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String providerId,
                required String channelEpgId,
                required DateTime start,
                required DateTime stop,
                required String title,
                Value<String?> description = const Value.absent(),
              }) => EpgProgramsCompanion.insert(
                id: id,
                providerId: providerId,
                channelEpgId: channelEpgId,
                start: start,
                stop: stop,
                title: title,
                description: description,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EpgProgramsTable, EpgProgramRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $EpgProgramsTable,
                    EpgProgramRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EpgProgramsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EpgProgramsTable,
      EpgProgramRow,
      $$EpgProgramsTableFilterComposer,
      $$EpgProgramsTableOrderingComposer,
      $$EpgProgramsTableAnnotationComposer,
      $$EpgProgramsTableCreateCompanionBuilder,
      $$EpgProgramsTableUpdateCompanionBuilder,
      (
        EpgProgramRow,
        BaseReferences<_$AppDatabase, $EpgProgramsTable, EpgProgramRow>,
      ),
      EpgProgramRow,
      PrefetchHooks Function()
    >;
typedef $$ProfilesTableCreateCompanionBuilder = ProfilesCompanion Function({
  Value<int> id,
  required String name,
  Value<bool> isKids,
  Value<int> colorIndex,
  required DateTime createdAt,
});
typedef $$ProfilesTableUpdateCompanionBuilder = ProfilesCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<bool> isKids,
  Value<int> colorIndex,
  Value<DateTime> createdAt,
});

class $$ProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isKids => $composableBuilder(
    column: $table.isKids,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get colorIndex => $composableBuilder(
    column: $table.colorIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isKids => $composableBuilder(
    column: $table.isKids,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get colorIndex => $composableBuilder(
    column: $table.colorIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfilesTable> {
  $$ProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get isKids =>
      $composableBuilder(column: $table.isKids, builder: (column) => column);

  GeneratedColumn<int> get colorIndex => $composableBuilder(
    column: $table.colorIndex,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProfilesTable,
          ProfileRow,
          $$ProfilesTableFilterComposer,
          $$ProfilesTableOrderingComposer,
          $$ProfilesTableAnnotationComposer,
          $$ProfilesTableCreateCompanionBuilder,
          $$ProfilesTableUpdateCompanionBuilder,
          (
            ProfileRow,
            BaseReferences<_$AppDatabase, $ProfilesTable, ProfileRow>,
          ),
          ProfileRow,
          PrefetchHooks Function()
        > {
  $$ProfilesTableTableManager(_$AppDatabase db, $ProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> isKids = const Value.absent(),
                Value<int> colorIndex = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => ProfilesCompanion(
                id: id,
                name: name,
                isKids: isKids,
                colorIndex: colorIndex,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<bool> isKids = const Value.absent(),
                Value<int> colorIndex = const Value.absent(),
                required DateTime createdAt,
              }) => ProfilesCompanion.insert(
                id: id,
                name: name,
                isKids: isKids,
                colorIndex: colorIndex,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProfilesTable, ProfileRow>(table),
                  BaseReferences<_$AppDatabase, $ProfilesTable, ProfileRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProfilesTable,
      ProfileRow,
      $$ProfilesTableFilterComposer,
      $$ProfilesTableOrderingComposer,
      $$ProfilesTableAnnotationComposer,
      $$ProfilesTableCreateCompanionBuilder,
      $$ProfilesTableUpdateCompanionBuilder,
      (ProfileRow, BaseReferences<_$AppDatabase, $ProfilesTable, ProfileRow>),
      ProfileRow,
      PrefetchHooks Function()
    >;
typedef $$FavouritesTableCreateCompanionBuilder = FavouritesCompanion Function({
  required int profileId,
  required String providerId,
  required String kind,
  required String remoteId,
  required DateTime addedAt,
  Value<int> rowid,
});
typedef $$FavouritesTableUpdateCompanionBuilder = FavouritesCompanion Function({
  Value<int> profileId,
  Value<String> providerId,
  Value<String> kind,
  Value<String> remoteId,
  Value<DateTime> addedAt,
  Value<int> rowid,
});

class $$FavouritesTableFilterComposer
    extends Composer<_$AppDatabase, $FavouritesTable> {
  $$FavouritesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FavouritesTableOrderingComposer
    extends Composer<_$AppDatabase, $FavouritesTable> {
  $$FavouritesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FavouritesTableAnnotationComposer
    extends Composer<_$AppDatabase, $FavouritesTable> {
  $$FavouritesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);
}

class $$FavouritesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FavouritesTable,
          FavouriteRow,
          $$FavouritesTableFilterComposer,
          $$FavouritesTableOrderingComposer,
          $$FavouritesTableAnnotationComposer,
          $$FavouritesTableCreateCompanionBuilder,
          $$FavouritesTableUpdateCompanionBuilder,
          (
            FavouriteRow,
            BaseReferences<_$AppDatabase, $FavouritesTable, FavouriteRow>,
          ),
          FavouriteRow,
          PrefetchHooks Function()
        > {
  $$FavouritesTableTableManager(_$AppDatabase db, $FavouritesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FavouritesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FavouritesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FavouritesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> profileId = const Value.absent(),
                Value<String> providerId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> remoteId = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FavouritesCompanion(
                profileId: profileId,
                providerId: providerId,
                kind: kind,
                remoteId: remoteId,
                addedAt: addedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int profileId,
                required String providerId,
                required String kind,
                required String remoteId,
                required DateTime addedAt,
                Value<int> rowid = const Value.absent(),
              }) => FavouritesCompanion.insert(
                profileId: profileId,
                providerId: providerId,
                kind: kind,
                remoteId: remoteId,
                addedAt: addedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FavouritesTable, FavouriteRow>(table),
                  BaseReferences<_$AppDatabase, $FavouritesTable, FavouriteRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FavouritesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FavouritesTable,
      FavouriteRow,
      $$FavouritesTableFilterComposer,
      $$FavouritesTableOrderingComposer,
      $$FavouritesTableAnnotationComposer,
      $$FavouritesTableCreateCompanionBuilder,
      $$FavouritesTableUpdateCompanionBuilder,
      (
        FavouriteRow,
        BaseReferences<_$AppDatabase, $FavouritesTable, FavouriteRow>,
      ),
      FavouriteRow,
      PrefetchHooks Function()
    >;
typedef $$MyListTableCreateCompanionBuilder = MyListCompanion Function({
  required int profileId,
  required String providerId,
  required String kind,
  required String remoteId,
  required DateTime addedAt,
  Value<int> rowid,
});
typedef $$MyListTableUpdateCompanionBuilder = MyListCompanion Function({
  Value<int> profileId,
  Value<String> providerId,
  Value<String> kind,
  Value<String> remoteId,
  Value<DateTime> addedAt,
  Value<int> rowid,
});

class $$MyListTableFilterComposer
    extends Composer<_$AppDatabase, $MyListTable> {
  $$MyListTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MyListTableOrderingComposer
    extends Composer<_$AppDatabase, $MyListTable> {
  $$MyListTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MyListTableAnnotationComposer
    extends Composer<_$AppDatabase, $MyListTable> {
  $$MyListTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);
}

class $$MyListTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MyListTable,
          MyListRow,
          $$MyListTableFilterComposer,
          $$MyListTableOrderingComposer,
          $$MyListTableAnnotationComposer,
          $$MyListTableCreateCompanionBuilder,
          $$MyListTableUpdateCompanionBuilder,
          (MyListRow, BaseReferences<_$AppDatabase, $MyListTable, MyListRow>),
          MyListRow,
          PrefetchHooks Function()
        > {
  $$MyListTableTableManager(_$AppDatabase db, $MyListTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MyListTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MyListTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MyListTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> profileId = const Value.absent(),
                Value<String> providerId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> remoteId = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MyListCompanion(
                profileId: profileId,
                providerId: providerId,
                kind: kind,
                remoteId: remoteId,
                addedAt: addedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int profileId,
                required String providerId,
                required String kind,
                required String remoteId,
                required DateTime addedAt,
                Value<int> rowid = const Value.absent(),
              }) => MyListCompanion.insert(
                profileId: profileId,
                providerId: providerId,
                kind: kind,
                remoteId: remoteId,
                addedAt: addedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MyListTable, MyListRow>(table),
                  BaseReferences<_$AppDatabase, $MyListTable, MyListRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MyListTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MyListTable,
      MyListRow,
      $$MyListTableFilterComposer,
      $$MyListTableOrderingComposer,
      $$MyListTableAnnotationComposer,
      $$MyListTableCreateCompanionBuilder,
      $$MyListTableUpdateCompanionBuilder,
      (MyListRow, BaseReferences<_$AppDatabase, $MyListTable, MyListRow>),
      MyListRow,
      PrefetchHooks Function()
    >;
typedef $$ProgressTableCreateCompanionBuilder = ProgressCompanion Function({
  required int profileId,
  required String providerId,
  required String kind,
  required String remoteId,
  Value<String?> seriesId,
  required int positionMs,
  required int durationMs,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$ProgressTableUpdateCompanionBuilder = ProgressCompanion Function({
  Value<int> profileId,
  Value<String> providerId,
  Value<String> kind,
  Value<String> remoteId,
  Value<String?> seriesId,
  Value<int> positionMs,
  Value<int> durationMs,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$ProgressTableFilterComposer
    extends Composer<_$AppDatabase, $ProgressTable> {
  $$ProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProgressTableOrderingComposer
    extends Composer<_$AppDatabase, $ProgressTable> {
  $$ProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seriesId => $composableBuilder(
    column: $table.seriesId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProgressTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProgressTable> {
  $$ProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<String> get seriesId =>
      $composableBuilder(column: $table.seriesId, builder: (column) => column);

  GeneratedColumn<int> get positionMs => $composableBuilder(
    column: $table.positionMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ProgressTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProgressTable,
          ProgressRow,
          $$ProgressTableFilterComposer,
          $$ProgressTableOrderingComposer,
          $$ProgressTableAnnotationComposer,
          $$ProgressTableCreateCompanionBuilder,
          $$ProgressTableUpdateCompanionBuilder,
          (
            ProgressRow,
            BaseReferences<_$AppDatabase, $ProgressTable, ProgressRow>,
          ),
          ProgressRow,
          PrefetchHooks Function()
        > {
  $$ProgressTableTableManager(_$AppDatabase db, $ProgressTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProgressTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> profileId = const Value.absent(),
                Value<String> providerId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> remoteId = const Value.absent(),
                Value<String?> seriesId = const Value.absent(),
                Value<int> positionMs = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProgressCompanion(
                profileId: profileId,
                providerId: providerId,
                kind: kind,
                remoteId: remoteId,
                seriesId: seriesId,
                positionMs: positionMs,
                durationMs: durationMs,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int profileId,
                required String providerId,
                required String kind,
                required String remoteId,
                Value<String?> seriesId = const Value.absent(),
                required int positionMs,
                required int durationMs,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ProgressCompanion.insert(
                profileId: profileId,
                providerId: providerId,
                kind: kind,
                remoteId: remoteId,
                seriesId: seriesId,
                positionMs: positionMs,
                durationMs: durationMs,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProgressTable, ProgressRow>(table),
                  BaseReferences<_$AppDatabase, $ProgressTable, ProgressRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProgressTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProgressTable,
      ProgressRow,
      $$ProgressTableFilterComposer,
      $$ProgressTableOrderingComposer,
      $$ProgressTableAnnotationComposer,
      $$ProgressTableCreateCompanionBuilder,
      $$ProgressTableUpdateCompanionBuilder,
      (ProgressRow, BaseReferences<_$AppDatabase, $ProgressTable, ProgressRow>),
      ProgressRow,
      PrefetchHooks Function()
    >;
typedef $$RecentsTableCreateCompanionBuilder = RecentsCompanion Function({
  required int profileId,
  required String providerId,
  required String kind,
  required String remoteId,
  required DateTime at,
  Value<int> rowid,
});
typedef $$RecentsTableUpdateCompanionBuilder = RecentsCompanion Function({
  Value<int> profileId,
  Value<String> providerId,
  Value<String> kind,
  Value<String> remoteId,
  Value<DateTime> at,
  Value<int> rowid,
});

class $$RecentsTableFilterComposer
    extends Composer<_$AppDatabase, $RecentsTable> {
  $$RecentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RecentsTableOrderingComposer
    extends Composer<_$AppDatabase, $RecentsTable> {
  $$RecentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteId => $composableBuilder(
    column: $table.remoteId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RecentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RecentsTable> {
  $$RecentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get remoteId =>
      $composableBuilder(column: $table.remoteId, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);
}

class $$RecentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RecentsTable,
          RecentRow,
          $$RecentsTableFilterComposer,
          $$RecentsTableOrderingComposer,
          $$RecentsTableAnnotationComposer,
          $$RecentsTableCreateCompanionBuilder,
          $$RecentsTableUpdateCompanionBuilder,
          (RecentRow, BaseReferences<_$AppDatabase, $RecentsTable, RecentRow>),
          RecentRow,
          PrefetchHooks Function()
        > {
  $$RecentsTableTableManager(_$AppDatabase db, $RecentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RecentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RecentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RecentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> profileId = const Value.absent(),
                Value<String> providerId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> remoteId = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RecentsCompanion(
                profileId: profileId,
                providerId: providerId,
                kind: kind,
                remoteId: remoteId,
                at: at,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int profileId,
                required String providerId,
                required String kind,
                required String remoteId,
                required DateTime at,
                Value<int> rowid = const Value.absent(),
              }) => RecentsCompanion.insert(
                profileId: profileId,
                providerId: providerId,
                kind: kind,
                remoteId: remoteId,
                at: at,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RecentsTable, RecentRow>(table),
                  BaseReferences<_$AppDatabase, $RecentsTable, RecentRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RecentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RecentsTable,
      RecentRow,
      $$RecentsTableFilterComposer,
      $$RecentsTableOrderingComposer,
      $$RecentsTableAnnotationComposer,
      $$RecentsTableCreateCompanionBuilder,
      $$RecentsTableUpdateCompanionBuilder,
      (RecentRow, BaseReferences<_$AppDatabase, $RecentsTable, RecentRow>),
      RecentRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProvidersTableTableManager get providers =>
      $$ProvidersTableTableManager(_db, _db.providers);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$ChannelsTableTableManager get channels =>
      $$ChannelsTableTableManager(_db, _db.channels);
  $$MoviesTableTableManager get movies =>
      $$MoviesTableTableManager(_db, _db.movies);
  $$SeriesTableTableTableManager get seriesTable =>
      $$SeriesTableTableTableManager(_db, _db.seriesTable);
  $$EpisodesTableTableManager get episodes =>
      $$EpisodesTableTableManager(_db, _db.episodes);
  $$EpgProgramsTableTableManager get epgPrograms =>
      $$EpgProgramsTableTableManager(_db, _db.epgPrograms);
  $$ProfilesTableTableManager get profiles =>
      $$ProfilesTableTableManager(_db, _db.profiles);
  $$FavouritesTableTableManager get favourites =>
      $$FavouritesTableTableManager(_db, _db.favourites);
  $$MyListTableTableManager get myList =>
      $$MyListTableTableManager(_db, _db.myList);
  $$ProgressTableTableManager get progress =>
      $$ProgressTableTableManager(_db, _db.progress);
  $$RecentsTableTableManager get recents =>
      $$RecentsTableTableManager(_db, _db.recents);
}
