import 'dart:ui';
import 'package:flutter/material.dart';

// ---------------------------------------------------
// 1. オプションのアクションモデル（Next.jsのGardenOptionAction相当）
// ---------------------------------------------------
class OptionAction {
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  OptionAction({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });
}

// ---------------------------------------------------
// 2. オプションモーダルUI
// ---------------------------------------------------
class OptionsModal extends StatelessWidget {
  final bool isMe; // 自分の庭かどうかでメニューを切り替えるフラグ

  const OptionsModal({super.key, this.isMe = true});

  // 外部からモーダルを呼び出すためのヘルパー
  static void show(BuildContext context, {bool isMe = true}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // すりガラスのために透明に
      builder: (context) => OptionsModal(isMe: isMe),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ---------------------------------------------------
    // Web版のロジックに合わせたリストの出し分け
    // ---------------------------------------------------
    final List<OptionAction> myActions = [
      OptionAction(
        icon: Icons.tune_rounded,
        label: '設定を変更する',
        description: '背景・季節・時間帯を選び直す',
        onTap: () {
          debugPrint('設定変更');
          Navigator.pop(context);
        },
      ),
      OptionAction(
        icon: Icons.qr_code_2_rounded,
        label: 'この庭のQRを表示する',
        description: 'スマホ共有用のQRコードを開く',
        onTap: () {
          debugPrint('QR表示');
          Navigator.pop(context);
        },
      ),
      OptionAction(
        icon: Icons.public_rounded,
        label: 'この庭を投稿する',
        description: '他の人があなたの庭を訪問できるようにする',
        onTap: () {
          debugPrint('投稿する');
          Navigator.pop(context);
        },
      ),
      OptionAction(
        icon: Icons.explore_rounded,
        label: '庭一覧へ',
        description: '他の人の庭を見に行く',
        onTap: () {
          debugPrint('庭一覧へ');
          Navigator.pop(context);
        },
      ),
      OptionAction(
        icon: Icons.home_rounded,
        label: 'トップへ戻る',
        description: '最初のページへ戻る',
        onTap: () {
          debugPrint('トップへ');
          Navigator.pop(context);
        },
      ),
    ];

    final List<OptionAction> visitorActions = [
      OptionAction(
        icon: Icons.build_circle_rounded,
        label: '自分の庭で配置する',
        description: '自分の庭へ戻って配置を続ける',
        onTap: () {
          debugPrint('自分の庭へ');
          Navigator.pop(context);
        },
      ),
      OptionAction(
        icon: Icons.explore_rounded,
        label: '庭一覧へ',
        description: '他の人の庭を見に行く',
        onTap: () {
          debugPrint('庭一覧へ');
          Navigator.pop(context);
        },
      ),
      OptionAction(
        icon: Icons.home_rounded,
        label: 'トップへ戻る',
        description: '最初のページへ戻る',
        onTap: () {
          debugPrint('トップへ');
          Navigator.pop(context);
        },
      ),
    ];

    final actions = isMe ? myActions : visitorActions;
    final title = isMe ? '自分の庭オプション' : '〇〇の庭'; // TODO: 訪問先の名前に

    // モーダルの高さ（画面の65%くらい）
    final modalHeight = MediaQuery.of(context).size.height * 0.65;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: modalHeight,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // 引っ張るバー
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // ヘッダー
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24, height: 24),

              // アクションリスト
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: actions.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _buildActionTile(actions[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // リストの各項目を作るウィジェット
  Widget _buildActionTile(OptionAction action) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.white.withValues(alpha: 0.1),
        highlightColor: Colors.white.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            borderRadius: BorderRadius.circular(12),
            color: Colors.black.withValues(alpha: 0.2),
          ),
          child: Row(
            children: [
              // アイコン
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(action.icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              // テキスト（タイトルと説明）
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      action.description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // 右端の矢印
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
