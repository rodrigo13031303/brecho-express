import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../app/main_shell.dart';
import '../appearance/app_palette.dart';
import '../branding/animated_brand_intro.dart';
import '../branding/brecho_mark.dart';
import 'brecho_session.dart';
import 'google_auth_service.dart';
import 'session_store.dart';

class GoogleLoginPage extends StatefulWidget {
  const GoogleLoginPage({
    required this.palette,
    required this.onPaletteChanged,
    super.key,
  });
  final AppPalette palette;
  final ValueChanged<AppPalette> onPaletteChanged;

  @override
  State<GoogleLoginPage> createState() => _GoogleLoginPageState();
}

class _GoogleLoginPageState extends State<GoogleLoginPage> {
  late final GoogleAuthService _authService;
  late final SessionStore _sessionStore;
  bool _loading = true;
  bool _introComplete = false;
  String? _message;
  BrechoSession? _session;
  Timer? _expirationTimer;

  @override
  void initState() {
    super.initState();
    _authService = GoogleAuthService();
    _sessionStore = SessionStore();
    _restoreSession();
  }

  @override
  void dispose() {
    _expirationTimer?.cancel();
    _authService.close();
    super.dispose();
  }

  Future<void> _restoreSession() async {
    final session = await _sessionStore.restore();
    if (!mounted) return;
    setState(() {
      _session = session;
      _loading = false;
    });
    if (session != null) _scheduleExpiration(session);
  }

  void _scheduleExpiration(BrechoSession session) {
    _expirationTimer?.cancel();
    final remaining = session.expiresAt.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      _expireSession();
      return;
    }
    _expirationTimer = Timer(remaining, _expireSession);
  }

  Future<void> _expireSession() async {
    await _sessionStore.clear();
    if (mounted) {
      setState(() {
        _session = null;
        _message = 'Sua sessão expirou. Entre novamente.';
      });
    }
  }

  Future<void> _signIn() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      final session = await _authService.signIn();
      await _sessionStore.save(session);
      if (!mounted) return;
      setState(() {
        _session = session;
        _message = null;
      });
      _scheduleExpiration(session);
    } on GoogleSignInException catch (exception) {
      if (!mounted) return;
      setState(
        () => _message = exception.code == GoogleSignInExceptionCode.canceled
            ? 'Login cancelado.'
            : 'Não foi possível abrir o login Google.',
      );
    } on GoogleLoginException catch (exception) {
      if (mounted) setState(() => _message = exception.message);
    } on SessionExpiredException {
      if (mounted) {
        setState(() => _message = 'O servidor retornou uma sessão expirada.');
      }
    } on Exception {
      if (mounted) {
        setState(() => _message = 'Falha de comunicação. Tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    final session = _session;
    if (_loading || session == null) return;
    setState(() {
      _loading = true;
      _message = null;
    });
    var message = 'Sessão encerrada.';
    try {
      await _authService.logout(session.accessToken);
    } on Exception {
      message =
          'A sessão foi removida deste aparelho, mas o servidor não confirmou o logout.';
    } finally {
      _expirationTimer?.cancel();
      await _sessionStore.clear();
      if (mounted) {
        setState(() {
          _session = null;
          _loading = false;
          _message = message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_introComplete) {
      return AnimatedBrandIntro(
        onFinished: () {
          if (mounted) {
            setState(() => _introComplete = true);
          }
        },
      );
    }

    final session = _session;
    if (session != null) {
      return MainShell(
        session: session,
        palette: widget.palette,
        onPaletteChanged: widget.onPaletteChanged,
        onLogout: _logout,
        loggingOut: _loading,
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const BrechoMark(),
                  const SizedBox(height: 20),
                  Text(
                    'Brechó Express',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Entre para comprar, vender e dar uma nova história às suas peças.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: _loading ? null : _signIn,
                    icon: _loading
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login),
                    label: Text(
                      _loading ? 'Carregando…' : 'Continuar com o Google',
                    ),
                  ),
                  if (_message case final message?) ...[
                    const SizedBox(height: 16),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
