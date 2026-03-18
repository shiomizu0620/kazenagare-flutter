import 'package:flutter/material.dart';

import 'title_screen.dart';

class GardenPublishScreen extends StatefulWidget {
  final String gardenName;
  final String seasonLabel;
  final String timeLabel;
  final int objectCount;
  final String previewImageAsset;

  const GardenPublishScreen({
    super.key,
    this.gardenName = '庭-春',
    this.seasonLabel = '春',
    this.timeLabel = '昼',
    this.objectCount = 0,
    this.previewImageAsset = 'assets/images/庭-春.png',
  });

  @override
  State<GardenPublishScreen> createState() => _GardenPublishScreenState();
}

class _GardenPublishScreenState extends State<GardenPublishScreen> {
  bool _isPublished = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F2EE),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '庭をお披露目する',
                style: TextStyle(
                  color: Color(0xFF1D1B18),
                  fontSize: 44,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'あなたの作り上げた空間を、回廊に展示します。',
                style: TextStyle(
                  color: Color(0xFF2A2724),
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 26),
              const Text(
                '庭のプレビュー',
                style: TextStyle(
                  color: Color(0xFF1D1B18),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              _buildPreviewCard(),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isPublished = true;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('庭を公開しました（モック）')),
                    );
                  },
                  icon: const Icon(Icons.send_rounded, size: 22),
                  label: const Text(
                    'この庭を公開する',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8D8D8D),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      '回廊へ向かう',
                      style: TextStyle(
                        color: Color(0xFF1D1B18),
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const TitleScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    child: const Text(
                      'トップへ戻る',
                      style: TextStyle(
                        color: Color(0xFF1D1B18),
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildGuideCard(),
              const SizedBox(height: 16),
              _buildUnpublishCard(),
              if (_isPublished) ...[
                const SizedBox(height: 12),
                const Text(
                  '※ 公開中です（モック表示）',
                  style: TextStyle(
                    color: Color(0xFF6E5A4A),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2D2925), width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 1.6,
            child: Image.asset(widget.previewImageAsset, fit: BoxFit.cover),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: _chip('オブジェクト ${widget.objectCount}個'),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFBAA57F).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'まだ音オブジェクトは置かれていません',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 10,
            bottom: 10,
            child: Wrap(
              spacing: 8,
              children: [
                _smallTag(widget.gardenName),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE9E8E5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2724), width: 2),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              '公開の準備',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D1B18),
              ),
            ),
          ),
          SizedBox(height: 14),
          Text(
            '庭の背景・季節・時間帯を確認し、整ったら回廊へ公開できます。公開後は、あなたの庭ページとして訪れた人に見てもらえます。',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF1F1D1A),
              height: 1.7,
            ),
          ),
          SizedBox(height: 16),
          Divider(color: Color(0xFF282522), thickness: 1),
          SizedBox(height: 14),
          Center(
            child: Text(
              '※公開した庭は回廊に展示され、3日間経過すると自然に消えゆきます。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF262320),
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnpublishCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2EEEE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD1B5AF), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFF8D4C3E)),
              SizedBox(width: 6),
              Text(
                '公開の取り下げ',
                style: TextStyle(
                  color: Color(0xFF8D4C3E),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '回廊に展示中の庭を取り下げます。必要なときに再公開できます。',
            style: TextStyle(
              color: Color(0xFF2D2926),
              fontSize: 16,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text(
                '公開中の庭を取り下げる',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFB89D97),
                side: const BorderSide(color: Color(0xFFD4BFB9), width: 2),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '※公開は回廊画面の管理からいつでも調整できます。',
            style: TextStyle(
              color: Color(0xFF6E6461),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFD6C28F).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _smallTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE8E7E3).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF22201D), width: 2),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF1E1B18),
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
