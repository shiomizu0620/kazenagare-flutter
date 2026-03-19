import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/setup_local_storage.dart';

import 'title_screen.dart';

class GardenPublishScreen extends StatefulWidget {
  final String gardenName;
  final String seasonId;
  final String seasonLabel;
  final String timeLabel;
  final int objectCount;
  final List<Map<String, dynamic>> objectPlacements;
  final String previewImageAsset;

  const GardenPublishScreen({
    super.key,
    this.gardenName = '庭-春',
    this.seasonId = 'spring',
    this.seasonLabel = '春',
    this.timeLabel = '昼',
    this.objectCount = 0,
    this.objectPlacements = const <Map<String, dynamic>>[],
    this.previewImageAsset = 'assets/images/庭-春.png',
  });

  @override
  State<GardenPublishScreen> createState() => _GardenPublishScreenState();
}

class _GardenPublishScreenState extends State<GardenPublishScreen> {
  bool _isPublished = false;
  bool _isPublishing = false;
  final GardenSetupLocalStorage _localStorage = GardenSetupLocalStorage();

  List<Map<String, dynamic>> _normalizedPlacements() {
    final mapped = <Map<String, dynamic>>[];
    for (final raw in widget.objectPlacements) {
      final objectId = (raw['object_id'] ?? raw['id'] ?? raw['objectId'])
          ?.toString()
          .trim();
      if (objectId == null || objectId.isEmpty) continue;

      final displayName = (raw['display_name'] ?? raw['name'])
          ?.toString()
          .trim();
      final imagePath = (raw['image_path'] ?? raw['imagePath'] ?? raw['asset'])
          ?.toString()
          .trim();

      final x =
          _asDouble(raw['x'] ?? raw['pos_x'] ?? raw['position_x']) ?? 1000.0;
      final y =
          _asDouble(raw['y'] ?? raw['pos_y'] ?? raw['position_y']) ?? 750.0;

      mapped.add({
        'object_id': objectId,
        'display_name': (displayName != null && displayName.isNotEmpty)
            ? displayName
            : objectId,
        'image_path': imagePath ?? '',
        'x': x,
        'y': y,
      });
    }
    return mapped;
  }

  double? _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  bool _isMissingRelation(Object error) {
    final text = error.toString();
    return text.contains('PGRST205') ||
        (text.contains('relation') && text.contains('does not exist'));
  }

  Future<bool> _insertWithFallbacks({
    required String table,
    required List<Map<String, dynamic>> payloads,
  }) async {
    final client = Supabase.instance.client;

    for (final payload in payloads) {
      try {
        await client.from(table).insert(payload);
        return true;
      } catch (_) {
        // 列違いなどは次のpayloadで再試行
      }
    }

    return false;
  }

  Future<void> _publishGarden() async {
    if (_isPublishing) return;

    setState(() {
      _isPublishing = true;
    });

    try {
      final now = DateTime.now().toIso8601String();
      final saved = await _localStorage.load();
      final userId = Supabase.instance.client.auth.currentUser?.id;
      final ownerName = (saved.name?.trim().isNotEmpty ?? false)
          ? saved.name!.trim()
          : '匿名';
      final objects = _normalizedPlacements();
      final objectCount = widget.objectCount > 0
          ? widget.objectCount
          : objects.length;

      final payloadCandidates = <Map<String, dynamic>>[
        {
          'user_id': userId,
          'owner_display_name': ownerName,
          'garden_name': widget.gardenName,
          'season_id': widget.seasonId,
          'object_count': objectCount,
          'placed_objects': objects,
          'preview_asset': widget.previewImageAsset,
          'published_at': now,
        },
        {
          'owner_name': ownerName,
          'title': widget.gardenName,
          'season': widget.seasonId,
          'objects_count': objectCount,
          'objects': objects,
          'preview_asset': widget.previewImageAsset,
          'published_at': now,
        },
        {
          'garden_name': widget.gardenName,
          'season_id': widget.seasonId,
          'placed_objects': objects,
          'object_count': objectCount,
        },
      ];

      var success = false;
      Object? lastError;
      for (final table in const ['garden_posts', 'gardens']) {
        try {
          success = await _insertWithFallbacks(
            table: table,
            payloads: payloadCandidates,
          );
          if (success) break;
        } catch (error) {
          lastError = error;
          if (_isMissingRelation(error)) {
            continue;
          }
        }
      }

      if (!mounted) return;

      if (success) {
        setState(() {
          _isPublished = true;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('庭を公開しました')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '公開に失敗しました${lastError != null ? ' (${lastError.toString()})' : ''}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPublishing = false;
        });
      }
    }
  }

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
                  onPressed: _isPublishing ? null : _publishGarden,
                  icon: const Icon(Icons.send_rounded, size: 22),
                  label: Text(
                    _isPublishing ? '公開中…' : 'この庭を公開する',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
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
                      Navigator.of(
                        context,
                        rootNavigator: true,
                      ).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) =>
                              const TitleScreen(stayOnTitle: true),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFBAA57F).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'この庭のしつらえを公開します',
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
            child: Wrap(spacing: 8, children: [_smallTag(widget.gardenName)]),
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
            style: TextStyle(color: Color(0xFF6E6461), fontSize: 13),
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
