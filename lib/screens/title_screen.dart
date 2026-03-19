import 'dart:async'; // 👈 StreamSubscription用に必須です
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_local_storage.dart';
import '../services/setup_local_storage.dart';
import 'garden_screen.dart';
import 'setup_screen.dart';

class TitleScreen extends StatefulWidget {
  final bool stayOnTitle;

  const TitleScreen({super.key, this.stayOnTitle = false});

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen> {
  bool _isLoginPanelVisible = false;

  void _showLoginPanel() {
    if (_isLoginPanelVisible) return;
    setState(() {
      _isLoginPanelVisible = true;
    });
  }

  void _hideLoginPanel() {
    setState(() {
      _isLoginPanelVisible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: _showLoginPanel,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // 背景画像レイヤー
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),

            // タイトル文字レイヤー
            AnimatedOpacity(
              opacity: _isLoginPanelVisible ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              child: Align(
                alignment: const Alignment(0, -0.16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '風流',
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 14,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            blurRadius: 30,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '画面をタップ',
                      style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 6,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ログインパネル
            AnimatedPositioned(
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeOutCubic,
              bottom: _isLoginPanelVisible ? 0 : -600,
              left: 0,
              right: 0,
              child: AuthPanel(
                onClose: _hideLoginPanel,
                stayOnTitle: widget.stayOnTitle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthPanel extends StatefulWidget {
  final VoidCallback onClose;
  final bool stayOnTitle;

  const AuthPanel({super.key, required this.onClose, this.stayOnTitle = false});

  @override
  State<AuthPanel> createState() => _AuthPanelState();
}

class _AuthPanelState extends State<AuthPanel> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final GardenSetupLocalStorage _localStorage = GardenSetupLocalStorage();
  final AuthLocalStorage _authLocalStorage = AuthLocalStorage();
  bool _isLoggingIn = false;
  bool _hasNavigatedAfterSignIn = false;

  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _restoreSavedLoginInfo();

    final auth = _safeAuthClient();
    if (auth != null) {
      // ブラウザからアプリに戻ってきたとき等、認証状態の変更を監視する
      _authSubscription = auth.onAuthStateChange.listen(
        (data) => unawaited(_handleAuthStateChanged(data)),
      );
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel(); // メモリリーク防止
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  GoTrueClient? _safeAuthClient() {
    try {
      return Supabase.instance.client.auth;
    } catch (_) {
      return null;
    }
  }

  SupabaseClient? _safeSupabaseClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<void> _goToGardenOrSetup() async {
    final saved = await _localStorage.load();
    if (!mounted) return;

    final hasValidSavedSetup =
        (saved.name?.trim().isNotEmpty ?? false) &&
        (saved.seasonId?.trim().isNotEmpty ?? false);

    if (hasValidSavedSetup) {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => GardenScreen(seasonId: saved.seasonId!),
        ),
      );
      return;
    }

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const GardenSetupScreen()),
    );
  }

  Future<void> _goToGardenOrSetupOnce() async {
    if (!mounted || _hasNavigatedAfterSignIn) return;
    _hasNavigatedAfterSignIn = true;
    await _goToGardenOrSetup();
  }

  Future<void> _restoreSavedLoginInfo() async {
    final saved = await _authLocalStorage.load();
    if (!mounted) return;

    final savedEmail = saved.email?.trim();
    if (savedEmail != null && savedEmail.isNotEmpty) {
      _emailController.text = savedEmail;
    }

    final user = _safeAuthClient()?.currentUser;
    if (user != null) {
      await _persistSignedInLocalData(methodFallback: saved.loginMethod);
      if (!mounted) return;
      if (widget.stayOnTitle) {
        return;
      }
      await _goToGardenOrSetupOnce();
    }
  }

  Future<void> _handleAuthStateChanged(AuthState data) async {
    final event = data.event;

    if (event == AuthChangeEvent.signedIn) {
      await _persistSignedInLocalData();
      if (!mounted) return;
      await _goToGardenOrSetupOnce();
      return;
    }

    if (event == AuthChangeEvent.signedOut) {
      await _authLocalStorage.clearSession();
      _hasNavigatedAfterSignIn = false;
    }
  }

  Future<void> _persistSignedInLocalData({
    String? methodFallback,
    String? emailFallback,
    bool? isGuestOverride,
  }) async {
    final user = _safeAuthClient()?.currentUser;
    if (user == null) return;

    final provider = user.appMetadata['provider'];
    final isGuestFromMetadata = provider == 'anonymous';
    final isGuest = isGuestOverride ?? isGuestFromMetadata;

    final method = methodFallback ?? (isGuest ? 'ゲスト' : 'ログイン');
    final email = user.email ?? emailFallback ?? _emailController.text.trim();

    await _authLocalStorage.saveSignedIn(
      userId: user.id,
      method: method,
      isGuest: isGuest,
      email: email,
    );
  }

  Future<void> _handleAuth(String method) async {
    setState(() => _isLoggingIn = true);

    String? emailForStorage;

    try {
      final supabase = _safeSupabaseClient();

      if (method == 'ゲスト') {
        if (supabase != null) {
          await supabase.auth.signInAnonymously();
        } else {
          final emailDraft = _emailController.text.trim();
          await _authLocalStorage.saveSignedIn(
            userId: 'local-guest-${DateTime.now().millisecondsSinceEpoch}',
            method: 'ゲスト',
            isGuest: true,
            email: emailDraft.isEmpty ? null : emailDraft,
          );

          if (!mounted) return;
          setState(() => _isLoggingIn = false);
          await _goToGardenOrSetupOnce();
          return;
        }
      } else if (method == 'ログイン' || method == '新規登録') {
        if (supabase == null) {
          throw Exception('認証基盤が初期化されていません。アプリを再起動してください。');
        }

        final email = _emailController.text.trim();
        final password = _passwordController.text.trim();

        if (email.isEmpty || password.isEmpty) {
          throw Exception('メールアドレスとパスワードを入力してください。');
        }

        await _authLocalStorage.saveEmailDraft(email);
        emailForStorage = email;

        if (method == '新規登録') {
          await supabase.auth.signUp(email: email, password: password);
        } else {
          await supabase.auth.signInWithPassword(
            email: email,
            password: password,
          );
        }
      } else if (method == 'Google') {
        if (supabase == null) {
          throw Exception('認証基盤が初期化されていません。アプリを再起動してください。');
        }

        // Google認証
        await supabase.auth.signInWithOAuth(
          OAuthProvider.google,
          // ブラウザでの認証後、アプリに帰ってくるための合言葉
          redirectTo: 'io.supabase.kazenagare://login-callback/',
        );
        // ブラウザに遷移するため、ここでの処理は一旦終了（戻ってきたら initState のリスナーが拾う）
        setState(() => _isLoggingIn = false);
        return;
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$method は準備中です')));
        setState(() => _isLoggingIn = false);
        return;
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('認証エラー: ${e.message}'),
            backgroundColor: Colors.red[800],
          ),
        );
      }
      setState(() => _isLoggingIn = false);
      return;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('エラーが発生しました: $e'),
            backgroundColor: Colors.red[800],
          ),
        );
      }
      setState(() => _isLoggingIn = false);
      return;
    }

    // Google以外のログインが成功した場合のみここを通る
    if (!mounted) return;

    await _persistSignedInLocalData(
      methodFallback: method,
      emailFallback: emailForStorage,
      isGuestOverride: method == 'ゲスト',
    );

    if (!mounted) return;

    setState(() => _isLoggingIn = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$methodでログインしました'), backgroundColor: Colors.teal),
    );

    // 認証成功後、ストレージをチェックして画面遷移
    await _goToGardenOrSetupOnce();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'GATE LOGIN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: widget.onClose,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'メールアドレスでログイン / 登録',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _emailController,
                          style: const TextStyle(color: Colors.black),
                          decoration: _mistInputDecoration('メールアドレス'),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          style: const TextStyle(color: Colors.black),
                          decoration: _mistInputDecoration('パスワード (6文字以上)'),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isLoggingIn
                                    ? null
                                    : () => _handleAuth('ログイン'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.lightBlue[800],
                                ),
                                child: const Text(
                                  'ログイン',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isLoggingIn
                                    ? null
                                    : () => _handleAuth('新規登録'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal[700],
                                ),
                                child: const Text(
                                  '新規登録',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoggingIn
                              ? null
                              : () => _handleAuth('ゲスト'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.15,
                            ),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                          child: const Text(
                            'ゲスト体験',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoggingIn
                              ? null
                              : () => _handleAuth('Google'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.9,
                            ),
                          ),
                          child: const Text(
                            'Google',
                            style: TextStyle(color: Colors.black87),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoggingIn
                              ? null
                              : () => _handleAuth('X (Twitter)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black87,
                          ),
                          child: const Text(
                            'X (Twitter)',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _mistInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.black.withValues(alpha: 0.5),
        fontSize: 14,
      ),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.55)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.teal),
      ),
    );
  }
}
