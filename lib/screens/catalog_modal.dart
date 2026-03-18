import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';

// ---------------------------------------------------
// 1. 図鑑のデータモデル
// ---------------------------------------------------
class CatalogItem {
  final String id;
  final String name;
  final IconData placeholderIcon; // 画像がない時の仮アイコン
  final bool isUnlocked; // 取得済みかどうか

  CatalogItem({
    required this.id,
    required this.name,
    required this.placeholderIcon,
    required this.isUnlocked,
  });
}

// ---------------------------------------------------
// 2. 図鑑モーダルのUIコンポーネント
// ---------------------------------------------------
class CatalogModal extends StatefulWidget {
  const CatalogModal({Key? key}) : super(key: key);

  // 外部からモーダルを呼び出すためのヘルパーメソッド
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 画面の高さを柔軟に使えるようにする
      backgroundColor: Colors.transparent, // すりガラス効果のために透明に
      builder: (context) => const CatalogModal(),
    );
  }

  @override
  State<CatalogModal> createState() => _CatalogModalState();
}

class _CatalogModalState extends State<CatalogModal> {
  static const int _itemsPerPage = 4;
  static const int _itemsPerSpread = _itemsPerPage * 2;
  int _currentSpread = 0;

  // Web版(Next.js)のディレクトリ構成に合わせた仮のアイテムリスト
  // TODO: 本番ではSupabaseから「ユーザーが取得したアイテムID一覧」を取得して突合する
  final List<CatalogItem> _items = [
    CatalogItem(
      id: 'furin',
      name: '風鈴',
      placeholderIcon: Icons.notifications,
      isUnlocked: true,
    ),
    CatalogItem(
      id: 'semi',
      name: '蝉',
      placeholderIcon: Icons.bug_report,
      isUnlocked: true,
    ),
    CatalogItem(
      id: 'shishi-odoshi',
      name: 'ししおどし',
      placeholderIcon: Icons.water_drop,
      isUnlocked: false,
    ),
    CatalogItem(
      id: 'kane',
      name: '鐘',
      placeholderIcon: Icons.sports_mma,
      isUnlocked: false,
    ),
    CatalogItem(
      id: 'mattya',
      name: '抹茶',
      placeholderIcon: Icons.coffee_rounded,
      isUnlocked: true,
    ),
    CatalogItem(
      id: 'takibi',
      name: '焚き火',
      placeholderIcon: Icons.local_fire_department,
      isUnlocked: false,
    ),
    CatalogItem(
      id: 'kaeru',
      name: '蛙',
      placeholderIcon: Icons.pest_control,
      isUnlocked: true,
    ),
    CatalogItem(
      id: 'hanabi',
      name: '花火',
      placeholderIcon: Icons.celebration,
      isUnlocked: false,
    ),
    CatalogItem(
      id: 'suzume',
      name: '雀',
      placeholderIcon: Icons.flutter_dash,
      isUnlocked: false,
    ),
    CatalogItem(
      id: 'obake',
      name: 'お化け',
      placeholderIcon: Icons.coronavirus,
      isUnlocked: false,
    ),
  ];

  int get _totalSpreads => (_items.length / _itemsPerSpread).ceil();

  List<CatalogItem> _sliceItems(int start, int count) {
    if (start >= _items.length) return const [];
    final end = math.min(start + count, _items.length);
    return _items.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    // 画面の高さの86%を占めるモーダルにする
    final modalHeight = MediaQuery.of(context).size.height * 0.86;
    final spreadStart = _currentSpread * _itemsPerSpread;
    final leftItems = _sliceItems(spreadStart, _itemsPerPage);
    final rightItems = _sliceItems(spreadStart + _itemsPerPage, _itemsPerPage);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        // 背景の庭をぼかして、モーダルを前景として際立たせる
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: modalHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF3B2C22).withValues(alpha: 0.96),
                const Color(0xFF221711).withValues(alpha: 0.98),
              ],
            ),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.18),
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              // モーダル上部の引っ張りバー
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // ヘッダー（タイトル・ページ番号・閉じるボタン）
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '音の図鑑',
                          style: TextStyle(
                            color: Color(0xFFF8E8CC),
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.8,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'SOUND BESTIARY',
                          style: TextStyle(
                            color: Color(0xFFE0C9A5),
                            fontSize: 10,
                            letterSpacing: 2.2,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4D3A2C),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: const Color(0xFF8F6E4D).withValues(alpha: 0.6),
                        ),
                      ),
                      child: Text(
                        '${_currentSpread + 1} / $_totalSpreads',
                        style: const TextStyle(
                          color: Color(0xFFF0DDC1),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Color(0xFFF3E6D1),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Divider(
                color: const Color(0xFFD4BA93).withValues(alpha: 0.3),
                height: 18,
                indent: 24,
                endIndent: 24,
              ),

              // 本の見開き
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2D2118),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.28),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xFF9D7B55).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildBookPage(
                              pageNumber: _currentSpread * 2 + 1,
                              items: leftItems,
                              isLeft: true,
                            ),
                          ),
                          Container(
                            width: 14,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  const Color(
                                    0xFF573D2A,
                                  ).withValues(alpha: 0.95),
                                  const Color(
                                    0xFF2B1E15,
                                  ).withValues(alpha: 0.95),
                                  const Color(
                                    0xFF573D2A,
                                  ).withValues(alpha: 0.95),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          Expanded(
                            child: _buildBookPage(
                              pageNumber: _currentSpread * 2 + 2,
                              items: rightItems,
                              isLeft: false,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ページ送り
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 6, 18, 18),
                child: Row(
                  children: [
                    _buildPageButton(
                      icon: Icons.keyboard_double_arrow_left_rounded,
                      label: '前の見開き',
                      enabled: _currentSpread > 0,
                      onTap: () {
                        if (_currentSpread == 0) return;
                        setState(() {
                          _currentSpread -= 1;
                        });
                      },
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF4B3628,
                          ).withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(
                              0xFFD6BB92,
                            ).withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          '${_currentSpread * _itemsPerSpread + 1} - ${math.min((_currentSpread + 1) * _itemsPerSpread, _items.length)} / ${_items.length} 件',
                          style: const TextStyle(
                            color: Color(0xFFF4E6CF),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _buildPageButton(
                      icon: Icons.keyboard_double_arrow_right_rounded,
                      label: '次の見開き',
                      enabled: _currentSpread < _totalSpreads - 1,
                      onTap: () {
                        if (_currentSpread >= _totalSpreads - 1) return;
                        setState(() {
                          _currentSpread += 1;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookPage({
    required int pageNumber,
    required List<CatalogItem> items,
    required bool isLeft,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4E8D2),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isLeft ? 14 : 6),
          bottomLeft: Radius.circular(isLeft ? 14 : 6),
          topRight: Radius.circular(isLeft ? 6 : 14),
          bottomRight: Radius.circular(isLeft ? 6 : 14),
        ),
        border: Border.all(color: const Color(0xFFD8C0A0)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  '第$pageNumber頁',
                  style: const TextStyle(
                    color: Color(0xFF8A6B49),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.auto_stories_rounded,
                  size: 14,
                  color: Color(0xFFA6845F),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Column(
                children: [
                  for (var i = 0; i < _itemsPerPage; i++) ...[
                    Expanded(
                      child: i < items.length
                          ? _buildBookEntry(items[i])
                          : _buildEmptyBookEntry(),
                    ),
                    if (i < _itemsPerPage - 1)
                      const Divider(height: 1, color: Color(0x1A6F5234)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookEntry(CatalogItem item) {
    final unlocked = item.isUnlocked;

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: unlocked
                ? const Color(0xFFE8D6B7)
                : const Color(0xFFC9B59A).withValues(alpha: 0.7),
            shape: BoxShape.circle,
            border: Border.all(
              color: unlocked
                  ? const Color(0xFFA07A4D)
                  : const Color(0x8A7B5A3B),
            ),
          ),
          child: Icon(
            unlocked ? item.placeholderIcon : Icons.question_mark_rounded,
            color: unlocked ? const Color(0xFF5F432A) : const Color(0x8A5A4735),
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                unlocked ? item.name : '？？？',
                style: TextStyle(
                  color: unlocked
                      ? const Color(0xFF4A3320)
                      : const Color(0xAA6C5845),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                unlocked ? '採集済み' : '未発見',
                style: TextStyle(
                  color: unlocked
                      ? const Color(0xFF8C6D4B)
                      : const Color(0x8A6C5845),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyBookEntry() {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFEADCC6),
            border: Border.all(color: const Color(0x40A68561)),
          ),
          child: const Icon(
            Icons.horizontal_rule,
            color: Color(0x6A8E7458),
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Container(height: 1, color: const Color(0x3C8D7153))),
      ],
    );
  }

  Widget _buildPageButton({
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 40,
      child: TextButton.icon(
        onPressed: enabled ? onTap : null,
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFFF3E6CF),
          disabledForegroundColor: const Color(0x66F3E6CF),
          backgroundColor: enabled
              ? const Color(0xFF5D4431).withValues(alpha: 0.85)
              : const Color(0xFF5D4431).withValues(alpha: 0.45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: const Color(
                0xFFD6BB92,
              ).withValues(alpha: enabled ? 0.45 : 0.18),
            ),
          ),
        ),
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
