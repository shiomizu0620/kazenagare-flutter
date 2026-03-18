import 'dart:ui';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'screens/setup_screen.dart'; // 👈 ファイルを分けた場合はこれを追加

void main() {
  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const KazenagareApp(),
    ),
  );
}

class KazenagareApp extends StatelessWidget {
  const KazenagareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      title: '風流れ - Kazenagare',
      theme: ThemeData(
        // 全体的に暗く、風流なテーマに設定
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF05080C), // wa-blackに近い色
        fontFamily: 'Noto Serif JP', // ※あとでpubspec.yamlにフォントを追加推奨
        useMaterial3: true,
      ),
      home: const TitleScreen(),
    );
  }
}

class TitleScreen extends StatefulWidget {
  const TitleScreen({super.key});

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
    // Web版にある波紋音（RippleTransitionSound）などは後でここに追加します
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
            // 1. 背景画像レイヤー（ぼかし＋暗くするフィルター）
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(
                  sigmaX: 10,
                  sigmaY: 10,
                ), // blur(20px)の再現
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(
                      alpha: 0.3,
                    ), // brightness(0.7)の再現
                    // 実際はここに Image.asset で庭の背景を入れます
                    // image: DecorationImage(image: AssetImage('assets/images/bg.png'), fit: BoxFit.cover),
                  ),
                ),
              ),
            ),

            // 2. タイトル文字レイヤー ("風流")
            AnimatedOpacity(
              opacity: _isLoginPanelVisible ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOut,
              child: Align(
                alignment: const Alignment(0, -0.16), // top-[42%] の再現
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '風流',
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 14, // tracking-[0.22em]
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
                        letterSpacing: 6, // tracking-[0.3em]
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. ログインパネル（下からスライドイン）
            AnimatedPositioned(
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeOutCubic,
              bottom: _isLoginPanelVisible ? 0 : -600, // 画面外からスライド
              left: 0,
              right: 0,
              child: AuthPanel(onClose: _hideLoginPanel),
            ),
          ],
        ),
      ),
    );
  }
}

// Web版の auth-section.tsx (variant="mist") の再現
class AuthPanel extends StatefulWidget {
  final VoidCallback onClose;

  const AuthPanel({super.key, required this.onClose});

  @override
  State<AuthPanel> createState() => _AuthPanelState();
}

class _AuthPanelState extends State<AuthPanel> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoggingIn = false;

  Future<void> _goToSetupScreen() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const GardenSetupScreen()));
  }

  Future<void> _handleAuth(String method) async {
    setState(() => _isLoggingIn = true);
    // TODO: ここにSupabaseの認証ロジックを実装します
    await Future.delayed(const Duration(seconds: 1)); // ローディングのモック
    setState(() => _isLoggingIn = false);

    // 成功したら庭画面へ遷移する処理を後で追加
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$methodでログインを試みました')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 16,
              sigmaY: 16,
            ), // backdrop-blur-xl
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1), // bg-white/10
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 閉じるボタンとラベル
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

                  // メールアドレス入力欄 (Mist Variant)
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

                  // SNS・ゲストボタン群
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoggingIn
                              ? null
                              : () => _goToSetupScreen(),
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
