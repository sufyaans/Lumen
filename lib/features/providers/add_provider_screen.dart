import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/app_config.dart';
import '../../app/data_providers.dart';
import '../../app/theme.dart';
import '../../core/focus/focus_memory.dart';
import '../../core/focus/focusable_card.dart';
import '../../core/network/connection_error.dart';
import '../../core/network/network_client.dart';
import '../../core/utils/text_clean.dart';
import '../../core/widgets/buttons.dart';
import '../../data/xtream/server_endpoint.dart';
import '../common/error_panel.dart';
import 'sign_in_service.dart';

enum ProviderMethod { xtream, m3uLink, m3uFile }

/// A large text field for TV and phones: label, optional hint, a Paste
/// button (typing on a remote is painful), never autofocused, and the
/// D-pad can always leave it (brief section 8).
class LumenField extends StatefulWidget {
  const LumenField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.optional = false,
    this.obscure = false,
    this.keyboardType,
    this.helper,
    this.onPasted,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction = TextInputAction.next,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool optional;
  final bool obscure;
  final TextInputType? keyboardType;

  /// Gentle hint under the field (e.g. "contains a space").
  final String? helper;
  final ValueChanged<String>? onPasted;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction textInputAction;

  @override
  State<LumenField> createState() => _LumenFieldState();
}

class _LumenFieldState extends State<LumenField> {
  bool _show = false;

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) return;
    widget.controller.text = text;
    widget.onPasted?.call(text);
    widget.onChanged?.call(text);
  }

  @override
  Widget build(BuildContext context) {
    final c = LumenColors.of(context);
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              text: widget.label,
              style: t.labelLarge,
              children: [
                if (widget.optional)
                  TextSpan(text: '  (optional)', style: t.labelSmall),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: DpadEscapableField(
                  controller: widget.controller,
                  child: TextField(
                    controller: widget.controller,
                    obscureText: widget.obscure && !_show,
                    keyboardType: widget.keyboardType,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: widget.textInputAction,
                    onChanged: widget.onChanged,
                    onSubmitted: widget.onSubmitted,
                    decoration: InputDecoration(hintText: widget.hint),
                  ),
                ),
              ),
              if (widget.obscure) ...[
                const SizedBox(width: 8),
                PillButton(
                  label: _show ? 'Hide' : 'Show',
                  onPressed: () => setState(() => _show = !_show),
                ),
              ],
              const SizedBox(width: 8),
              RoundIconButton(
                icon: Icons.content_paste,
                label: 'Paste into ${widget.label}',
                size: 44,
                onPressed: _paste,
              ),
            ],
          ),
          if (widget.helper != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                widget.helper!,
                style: t.bodySmall?.copyWith(color: c.muted),
              ),
            ),
        ],
      ),
    );
  }
}

/// Add provider (brief sections 3 and 5.2): Xtream Codes, M3U link, M3U
/// file, plus a single "Paste a link from your provider" field that works
/// out which one it is and fills the form in.
class AddProviderScreen extends ConsumerStatefulWidget {
  const AddProviderScreen({super.key});

  @override
  ConsumerState<AddProviderScreen> createState() => _AddProviderScreenState();
}

class _AddProviderScreenState extends ConsumerState<AddProviderScreen> {
  ProviderMethod _method = ProviderMethod.xtream;
  final _smart = TextEditingController();
  final _name = TextEditingController();
  final _server = TextEditingController();
  final _user = TextEditingController();
  final _pass = TextEditingController();
  final _url = TextEditingController();
  final _epg = TextEditingController();
  bool _allowUntrusted = false;
  bool _advanced = false;

  String? _notice;
  String? _formError;
  ConnectionError? _error;
  bool _busy = false;
  CancelSignal? _cancel;

  String? _fileName;
  Uint8List? _fileBytes;

  @override
  void dispose() {
    for (final c in [_smart, _name, _server, _user, _pass, _url, _epg]) {
      c.dispose();
    }
    _cancel?.cancel();
    super.dispose();
  }

  void _clearMessages() {
    if (_notice != null || _formError != null || _error != null) {
      setState(() {
        _formError = null;
        _error = null;
      });
    }
  }

  /// The smart field: a playlist link with credentials becomes an Xtream
  /// login; a plain .m3u link goes to M3U link; anything else is a server.
  void _applySmart(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return;
    final r = ServerEndpoint.parse(text);
    setState(() {
      _error = null;
      _formError = null;
      if (r.kind == InputKind.m3uLink) {
        _method = ProviderMethod.m3uLink;
        _url.text = r.cleaned;
        _notice = 'That looks like a playlist link, so it went into M3U link.';
      } else if (r.isValid) {
        _method = ProviderMethod.xtream;
        _server.text = r.candidates.first.toString();
        if (r.credentialsFromLink) {
          _user.text = r.username!;
          _pass.text = r.password!;
          _notice = ServerInput.foundCredentialsMessage;
        } else {
          _notice =
              'Server address filled in. Now enter your username and password.';
        }
      } else {
        _notice = null;
        _formError = r.error?.title ?? "That address doesn't look right";
      }
    });
  }

  Future<void> _connect() async {
    if (_busy) return;
    final svc = ref.read(signInServiceProvider);
    setState(() {
      _formError = null;
      _error = null;
    });
    SignInOutcome? r;
    switch (_method) {
      case ProviderMethod.xtream:
        if (_server.text.trim().isEmpty) {
          return setState(
            () => _formError = 'Enter the server address, for example http://provider.example:8080',
          );
        }
        if (cleanCredential(_user.text).isEmpty) {
          return setState(() => _formError = 'Enter your username.');
        }
        if (cleanCredential(_pass.text).isEmpty) {
          return setState(() => _formError = 'Enter your password.');
        }
        setState(() {
          _busy = true;
          _cancel = CancelSignal();
        });
        r = await svc.xtream(
          name: _name.text,
          server: _server.text,
          username: _user.text,
          password: _pass.text,
          allowUntrustedCert: _allowUntrusted,
          cancel: _cancel,
        );
      case ProviderMethod.m3uLink:
        final u = Uri.tryParse(_url.text.trim());
        if (u == null ||
            (u.scheme != 'http' && u.scheme != 'https') ||
            u.host.isEmpty) {
          return setState(
            () => _formError = 'Enter the full playlist link, starting with http:// or https://',
          );
        }
        setState(() => _busy = true);
        r = await svc.m3uUrl(
          name: _name.text,
          url: _url.text,
          epgUrl: _epg.text,
        );
      case ProviderMethod.m3uFile:
        if (_fileBytes == null) {
          return setState(() => _formError = 'Choose an M3U file first.');
        }
        setState(() => _busy = true);
        r = await svc.m3uFile(
          name: _name.text,
          fileName: _fileName!,
          bytes: _fileBytes!,
        );
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _cancel = null;
    });
    switch (r) {
      case SignInOk(:final providerId):
        _pass.clear();
        context.go('/syncing/$providerId');
      case SignInFailed(:final error):
        if (error.details == 'cancelled') return;
        setState(() => _error = error);
    }
  }

  Future<void> _pickFile() async {
    try {
      final f = await FilePicker.pickFile(dialogTitle: 'Choose a playlist');
      if (f == null) return;
      final bytes = await f.readAsBytes();
      final head = String.fromCharCodes(bytes.take(2048));
      if (!head.contains('#EXTM3U') && !head.contains('#EXTINF')) {
        return setState(() {
          _fileBytes = null;
          _fileName = null;
          _error = const ConnectionError(ConnectionErrorKind.m3uInvalid);
        });
      }
      setState(() {
        _fileBytes = bytes;
        _fileName = f.name;
        _error = null;
        _formError = null;
      });
    } catch (_) {
      setState(() => _formError = "Couldn't read that file. Try again.");
    }
  }

  void _openConnectionCheck() {
    context.push(
      '/connection-check',
      extra: ConnectionCheckArgs(
        server: _server.text,
        username: _user.text,
        password: _pass.text,
        allowUntrustedCert: _allowUntrusted,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = LumenColors.of(context);
    final t = Theme.of(context).textTheme;
    final canClose = context.canPop();
    final saved = ref.watch(providersListProvider).value ?? const [];
    final userHint =
        hasInnerWhitespace(cleanCredential(_user.text)) ||
            hasInnerWhitespace(cleanCredential(_pass.text))
        ? 'This contains a space. If that was a copy-paste mistake, remove it. We will try it as typed.'
        : null;

    return Scaffold(
      body: SafeArea(
        child: FocusMemory(
          debugLabel: 'add-provider',
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 560),
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                decoration: BoxDecoration(
                  color: c.surface,
                  border: Border.all(color: c.line),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            AppConfig.appName,
                            style: t.headlineSmall?.copyWith(
                              color: c.accent,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (canClose)
                          RoundIconButton(
                            icon: Icons.close,
                            label: 'Close',
                            onPressed: () => context.pop(),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      canClose
                          ? 'Add a provider'
                          : 'Connect your IPTV provider',
                      style: t.headlineMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${AppConfig.appName} only plays what your provider supplies. Sign in with the details they gave you.',
                      style: t.bodyMedium?.copyWith(color: c.muted),
                    ),
                    const SizedBox(height: 18),
                    LumenField(
                      label: 'Paste a link from your provider',
                      optional: true,
                      controller: _smart,
                      hint: 'Server address or playlist link',
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.done,
                      onPasted: _applySmart,
                      onSubmitted: _applySmart,
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: PillButton(
                        label: 'Fill in from link',
                        onPressed: () => _applySmart(_smart.text),
                      ),
                    ),
                    if (_notice != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          _notice!,
                          style: t.bodyMedium?.copyWith(
                            color: const Color(0xFF18A05A),
                          ),
                        ),
                      ),
                    const SizedBox(height: 18),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Segmented<ProviderMethod>(
                        options: const [
                          (ProviderMethod.xtream, 'Xtream Codes'),
                          (ProviderMethod.m3uLink, 'M3U link'),
                          (ProviderMethod.m3uFile, 'M3U file'),
                        ],
                        value: _method,
                        onChanged: (m) => setState(() {
                          _method = m;
                          _formError = null;
                          _error = null;
                        }),
                      ),
                    ),
                    const SizedBox(height: 18),
                    LumenField(
                      label: 'Name',
                      optional: true,
                      controller: _name,
                      hint: 'Living room',
                    ),
                    ..._formFields(userHint),
                    if (_formError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          _formError!,
                          style: t.bodyMedium?.copyWith(
                            color: c.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: ErrorPanel(
                          error: _error!,
                          secrets: [_pass.text, _user.text],
                          onRetry: _connect,
                          onConnectionCheck: _method == ProviderMethod.xtream
                              ? _openConnectionCheck
                              : null,
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: PillButton(
                            label: _busy ? 'Connecting…' : 'Connect',
                            tone: PillTone.accent,
                            expand: true,
                            onPressed: _busy ? null : _connect,
                          ),
                        ),
                        if (_busy && _cancel != null) ...[
                          const SizedBox(width: 10),
                          PillButton(
                            label: 'Cancel',
                            onPressed: () {
                              _cancel?.cancel();
                              setState(() {
                                _busy = false;
                                _cancel = null;
                              });
                            },
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _method == ProviderMethod.m3uFile
                          ? 'Your file is read on this device. Nothing is uploaded.'
                          : 'Your login details stay on this device.',
                      style: t.bodySmall,
                    ),
                    if (saved.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Divider(color: c.line),
                      const SizedBox(height: 12),
                      Text('Saved providers', style: t.titleSmall),
                      for (final p in saved)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  p.name,
                                  style: t.bodyLarge,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              PillButton(
                                label: 'Use',
                                onPressed: () async {
                                  await ref
                                      .read(activeProviderIdProvider.notifier)
                                      .select(p.id);
                                  if (context.mounted) context.go('/home');
                                },
                              ),
                            ],
                          ),
                        ),
                    ],
                    if (!canClose && saved.isEmpty && kDebugMode) ...[
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: PillButton(
                          label: 'Browse preview (debug)',
                          onPressed: () => context.go('/home'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _formFields(String? userHint) {
    final t = Theme.of(context).textTheme;
    final c = LumenColors.of(context);
    switch (_method) {
      case ProviderMethod.xtream:
        return [
          LumenField(
            label: 'Server address',
            controller: _server,
            hint: 'http://provider.example:8080',
            keyboardType: TextInputType.url,
            onChanged: (_) => _clearMessages(),
            onPasted: (text) {
              final r = ServerEndpoint.parse(text);
              if (r.credentialsFromLink) _applySmart(text);
            },
          ),
          LumenField(
            label: 'Username',
            controller: _user,
            onChanged: (_) => setState(() {}),
          ),
          LumenField(
            label: 'Password',
            controller: _pass,
            obscure: true,
            helper: userHint,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _connect(),
          ),
          FocusableCard(
            focusScale: 1.0,
            semanticLabel: 'Advanced',
            onPressed: () => setState(() => _advanced = !_advanced),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(
                    _advanced ? Icons.expand_less : Icons.expand_more,
                    color: c.muted,
                  ),
                  const SizedBox(width: 6),
                  Text('Advanced', style: t.labelLarge),
                ],
              ),
            ),
          ),
          if (_advanced)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Allow untrusted certificate for this provider',
                          style: t.bodyMedium,
                        ),
                      ),
                      Segmented<bool>(
                        options: const [(false, 'Off'), (true, 'On')],
                        value: _allowUntrusted,
                        onChanged: (v) => setState(() => _allowUntrusted = v),
                      ),
                    ],
                  ),
                  if (_allowUntrusted)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Only turn this on if your provider uses a self-made certificate. '
                        'The connection to this provider can no longer be verified.',
                        style: t.bodySmall?.copyWith(color: c.accent),
                      ),
                    ),
                ],
              ),
            ),
        ];
      case ProviderMethod.m3uLink:
        return [
          LumenField(
            label: 'Playlist link',
            controller: _url,
            hint: 'https://provider.example/playlist.m3u',
            keyboardType: TextInputType.url,
          ),
          LumenField(
            label: 'TV guide link',
            optional: true,
            controller: _epg,
            hint: 'https://provider.example/epg.xml',
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
          ),
        ];
      case ProviderMethod.m3uFile:
        return [
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: c.line, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                PillButton(
                  label: 'Choose file',
                  icon: Icons.folder_open,
                  onPressed: _pickFile,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    _fileName ??
                        'An .m3u or .m3u8 playlist saved on this device',
                    style: t.bodyMedium?.copyWith(color: c.muted),
                  ),
                ),
              ],
            ),
          ),
        ];
    }
  }
}
