import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'title_screen.dart';

class QrInviteScreen extends StatelessWidget {
  final String hostName;
  final String invitePurpose;
  final String inviteUrl;

  /// 後からQR本体を差し替えるための差し込み口。
  /// 例: `QrImageView(data: inviteUrl)` などを渡す。
  final Widget? qrWidget;

  const QrInviteScreen({
    super.key,
    this.hostName = 'いっち',
    this.invitePurpose = '招待・共有・再訪',
    this.inviteUrl = 'https://kazenagare.vercel.app/garden/your-invite-id',
    this.qrWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2B1E17), Color(0xFF17100C), Color(0xFF0E0907)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOKONOMA GALLERY',
                  style: TextStyle(
                    color: const Color(0xFFE7D1AF).withValues(alpha: 0.65),
                    fontSize: 24,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '招待の印',
                  style: TextStyle(
                    color: Color(0xFFF5EAD8),
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '道しるべとしたため、客人を庭へお迎えしましょう',
                  style: TextStyle(
                    color: const Color(0xFFF2E2C8).withValues(alpha: 0.8),
                    fontSize: 18,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _ActionPillButton(
                        label: 'トップへ戻る',
                        onTap: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const TitleScreen(),
                            ),
                            (route) => false,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionPillButton(
                        label: '自分の庭に戻る',
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'しつらえ案内',
                        style: TextStyle(
                          color: const Color(0xFFE6D2B3).withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '客人を迎える手順',
                        style: TextStyle(
                          color: Color(0xFFF7EBDD),
                          fontSize: 46,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'QRを客人に渡すだけで、この庭の風景へすぐご案内できます。案内が終われば、いつでも庭へ戻って新しい飾り付けを続けられます。',
                        style: TextStyle(
                          color: const Color(0xFFF0DFC5).withValues(alpha: 0.9),
                          fontSize: 18,
                          height: 1.7,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _MetaField(text: '庭主: $hostName'),
                      const SizedBox(height: 10),
                      _MetaField(text: '用途: $invitePurpose'),
                      const SizedBox(height: 22),
                      Text(
                        '一.「道標を写し取る」で共有用リンクを控える\n\n二.QRを読み取ってもらい、庭へ招き入れる\n\n三.招待後は「自分の庭に戻る」で景色へ戻る',
                        style: TextStyle(
                          color: const Color(
                            0xFFF2E1C9,
                          ).withValues(alpha: 0.95),
                          fontSize: 17,
                          height: 1.8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '招待の印',
                        style: TextStyle(
                          color: const Color(0xFFE6D2B3).withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '庭への文',
                        style: TextStyle(
                          color: Color(0xFFF7EBDD),
                          fontSize: 56,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'このQRを読み解くか、道を記して客人（まろうど）を招き入れましょう。',
                        style: TextStyle(
                          color: const Color(0xFFF0DFC5).withValues(alpha: 0.9),
                          fontSize: 18,
                          height: 1.7,
                        ),
                      ),
                      const SizedBox(height: 22),
                      _QrFrame(
                        child:
                            qrWidget ?? const _QrPlaceholder(), // ← ここを後から差し替え
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton(
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: inviteUrl),
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('道標を写し取りました')),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE8E4DC),
                            foregroundColor: const Color(0xFF2A1F17),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 34,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Text(
                            '道標を写し取る',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      SelectableText(
                        '道しるべ: $inviteUrl',
                        style: TextStyle(
                          color: const Color(
                            0xFFF2E1C9,
                          ).withValues(alpha: 0.95),
                          fontSize: 18,
                          height: 1.5,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;

  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF211712).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE2CAA6).withValues(alpha: 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ActionPillButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ActionPillButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: const Color(0xFFE6D2B3).withValues(alpha: 0.55),
        ),
        foregroundColor: const Color(0xFFF5EAD8),
        backgroundColor: const Color(0xFF251B15).withValues(alpha: 0.72),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _MetaField extends StatelessWidget {
  final String text;

  const _MetaField({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.26)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: const Color(0xFFF0E0C6).withValues(alpha: 0.95),
          fontSize: 16,
        ),
      ),
    );
  }
}

class _QrFrame extends StatelessWidget {
  final Widget child;

  const _QrFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.65),
          width: 2,
        ),
      ),
      child: child,
    );
  }
}

class _QrPlaceholder extends StatelessWidget {
  const _QrPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: Alignment.center,
      child: const Text(
        'QRをここに配置',
        style: TextStyle(
          color: Color(0xFF242424),
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
