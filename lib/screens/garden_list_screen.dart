import 'package:flutter/material.dart';

import 'garden_screen.dart';
import 'title_screen.dart';

class GardenListItem {
  final String id;
  final String ownerName;
  final String gardenTitle;
  final String seasonId;
  final String expiresIn;
  final bool isMine;
  final String previewAsset;

  const GardenListItem({
    required this.id,
    required this.ownerName,
    required this.gardenTitle,
    required this.seasonId,
    required this.expiresIn,
    required this.isMine,
    required this.previewAsset,
  });
}

class GardenListScreen extends StatelessWidget {
  const GardenListScreen({super.key});

  // TODO: Supabaseから投稿済みの庭一覧を取得して差し込む
  static const List<GardenListItem> _postedGardens = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF30221A), Color(0xFF1B1820), Color(0xFF090A0F)],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.05),
                      Colors.black.withValues(alpha: 0.28),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: Row(
                  children: List.generate(5, (index) {
                    return Expanded(
                      child: Align(
                        alignment: Alignment.center,
                        child: Container(
                          width: 1,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TOKONOMA GALLERY',
                          style: TextStyle(
                            color: const Color(
                              0xFFE7D1AF,
                            ).withValues(alpha: 0.72),
                            fontSize: 14,
                            letterSpacing: 8,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '座敷の掛け軸',
                          style: TextStyle(
                            color: Color(0xFFF1E8D6),
                            fontSize: 52,
                            fontWeight: FontWeight.w700,
                            height: 1.02,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '畳の縁に沿ってなぞり、気になる景色の掛け軸を開く',
                          style: TextStyle(
                            color: const Color(
                              0xFFF0DEC1,
                            ).withValues(alpha: 0.78),
                            fontSize: 18,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
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
                                label: '自分の庭へ',
                                onTap: () {
                                  if (Navigator.of(context).canPop()) {
                                    Navigator.of(context).pop();
                                    return;
                                  }
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const GardenScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (_postedGardens.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        width: 160,
                        height: 12,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF65513F), Color(0xFFE1C08F)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFE1C08F,
                              ).withValues(alpha: 0.28),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          return _GardenCard(item: _postedGardens[index]);
                        },
                        separatorBuilder: (_, __) => const SizedBox(width: 16),
                        itemCount: _postedGardens.length,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GardenCard extends StatelessWidget {
  final GardenListItem item;

  const _GardenCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final cardWidth = MediaQuery.of(context).size.width * 0.82;

    return SizedBox(
      width: cardWidth,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF2ECDF),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFFCCBEA7), width: 1.4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.24),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '掛け軸',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF776857),
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: 6,
              ),
            ),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 1.35,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.asset(item.previewAsset, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 12),
            Container(height: 1, color: const Color(0xFFCCBEA7)),
            Expanded(
              child: Center(
                child: Text(
                  _toVerticalText(item.gardenTitle),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF3B352E),
                    fontSize: 22,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF2ECDF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFD2C4AD), width: 1.2),
              ),
              child: Text(
                item.expiresIn,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF6C6357),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (!item.isMine) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => GardenScreen(seasonId: item.seasonId),
                    ),
                  );
                },
                child: const Text(
                  '訪れる',
                  style: TextStyle(
                    color: Color(0xFF302B23),
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _toVerticalText(String text) {
    return text.split('').join('\n');
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
