import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'garden_screen.dart';
import 'title_screen.dart';

class GardenListItem {
  final String id;
  final String ownerName;
  final String gardenTitle;
  final String seasonId;
  final int objectCount;
  final List<GardenPlacedObject> placedObjects;
  final String expiresIn;
  final bool isMine;
  final String previewAsset;

  const GardenListItem({
    required this.id,
    required this.ownerName,
    required this.gardenTitle,
    required this.seasonId,
    required this.objectCount,
    required this.placedObjects,
    required this.expiresIn,
    required this.isMine,
    required this.previewAsset,
  });
}

class GardenListScreen extends StatefulWidget {
  const GardenListScreen({super.key});

  @override
  State<GardenListScreen> createState() => _GardenListScreenState();
}

class _GardenListScreenState extends State<GardenListScreen> {
  late final Future<List<GardenListItem>> _postedGardensFuture;
  static const double _worldWidth = 2000.0;
  static const double _worldHeight = 1500.0;
  // クロスプレイ座標の全体ずれ補正（相対位置は維持したまま平行移動）
  static const double _crossPlayWorldOffsetX = -930.0;
  static const double _crossPlayWorldOffsetY = -400.0;

  static const List<String> _tableCandidates = ['garden_posts', 'gardens'];

  static const Map<String, String> _seasonPreviewAssets = {
    'spring': 'assets/images/庭-春.png',
    'summer': 'assets/images/庭-夏.png',
    'autumn': 'assets/images/庭-秋.png',
    'winter': 'assets/images/庭-冬.png',
  };

  @override
  void initState() {
    super.initState();
    _postedGardensFuture = _fetchPostedGardens();
  }

  Future<List<GardenListItem>> _fetchPostedGardens() async {
    final client = Supabase.instance.client;

    for (final table in _tableCandidates) {
      try {
        final rows = await client
            .from(table)
            .select()
            .order('published_at', ascending: false)
            .limit(40);

        final items = _mapRowsToGardenItems(rows, tableName: table);

        if (items.isNotEmpty) {
          return items;
        }
      } catch (error) {
        if (_isMissingRelation(error)) {
          continue;
        }
        debugPrint('庭一覧の取得に失敗: $error');
      }
    }

    return const <GardenListItem>[];
  }

  bool _isMissingRelation(Object error) {
    final message = error.toString();
    return message.contains('PGRST205') ||
        (message.contains('relation') && message.contains('does not exist'));
  }

  List<GardenListItem> _mapRowsToGardenItems(
    List<dynamic> rows, {
    required String tableName,
  }) {
    final mapped = <GardenListItem>[];

    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      if (row is! Map) continue;

      final map = Map<String, dynamic>.from(
        row.map((key, value) => MapEntry(key.toString(), value)),
      );

      final seasonId = (_readString(map, ['season_id', 'season']) ?? 'spring');

      final previewAsset =
          _readString(map, ['preview_asset', 'previewAsset']) ??
          _seasonPreviewAssets[seasonId] ??
          _seasonPreviewAssets['spring']!;

      mapped.add(
        GardenListItem(
          id: _readString(map, ['id', 'post_id']) ?? '$tableName-$i',
          ownerName:
              _readString(map, [
                'owner_display_name',
                'owner_name',
                'user_name',
              ]) ??
              '匿名',
          gardenTitle:
              _readString(map, ['garden_name', 'title', 'garden_title']) ??
              '無題の庭',
          seasonId: seasonId,
          objectCount:
              _readInt(map, [
                'object_count',
                'objects_count',
                'placed_object_count',
              ]) ??
              _parsePlacedObjects(map).length,
          placedObjects: _parsePlacedObjects(map),
          expiresIn: _buildExpiresLabel(map),
          isMine: _readBool(map, ['is_mine']) ?? false,
          previewAsset: previewAsset,
        ),
      );
    }

    return mapped;
  }

  String _buildExpiresLabel(Map<String, dynamic> row) {
    final direct = _readString(row, ['expires_in', 'expiresIn']);
    if (direct != null && direct.trim().isNotEmpty) {
      return direct;
    }

    final publishedAtRaw = row['published_at'] ?? row['created_at'];
    if (publishedAtRaw is String && publishedAtRaw.isNotEmpty) {
      final publishedAt = DateTime.tryParse(publishedAtRaw);
      if (publishedAt != null) {
        final left =
            const Duration(days: 7) - DateTime.now().difference(publishedAt);
        if (left.isNegative) return '公開期限切れ';
        final days = left.inDays;
        if (days <= 0) return '本日まで';
        return 'あと$days日';
      }
    }

    return '公開中';
  }

  String? _readString(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  bool? _readBool(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];
      if (value is bool) return value;
      if (value is int) return value != 0;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized == 'true' || normalized == '1') return true;
        if (normalized == 'false' || normalized == '0') return false;
      }
    }
    return null;
  }

  int? _readInt(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];
      if (value is int) return value;
      if (value is String) {
        final parsed = int.tryParse(value.trim());
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  List<GardenPlacedObject> _parsePlacedObjects(Map<String, dynamic> row) {
    dynamic raw =
        row['placed_objects'] ??
        row['placedObjects'] ??
        row['objects'] ??
        row['object_layout'] ??
        row['layout'] ??
        row['placements'];

    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return const <GardenPlacedObject>[];
      try {
        raw = jsonDecode(trimmed);
      } catch (_) {
        return const <GardenPlacedObject>[];
      }
    }

    if (raw is! List) return const <GardenPlacedObject>[];

    final rawObjects = <Map<String, dynamic>>[];
    for (var i = 0; i < raw.length; i++) {
      final item = raw[i];
      if (item is! Map) continue;

      final map = Map<String, dynamic>.from(
        item.map((key, value) => MapEntry(key.toString(), value)),
      );

      final objectType = _readString(map, [
        'objectType',
        'object_type',
        'type',
        'soundType',
      ]);

      final objectId =
          _normalizeObjectType(
            objectType ?? _readString(map, ['object_id', 'objectId']),
          ) ??
          '';
      if (objectId.isEmpty) continue;

      final xRaw = _readAny(map, ['x', 'pos_x', 'position_x', 'world_x']);
      final yRaw = _readAny(map, ['y', 'pos_y', 'position_y', 'world_y']);

      final positionMap = map['position'];
      final posXRaw = positionMap is Map
          ? _readAny(
              Map<String, dynamic>.from(
                positionMap.map(
                  (key, value) => MapEntry(key.toString(), value),
                ),
              ),
              ['x', 'left', 'dx'],
            )
          : null;
      final posYRaw = positionMap is Map
          ? _readAny(
              Map<String, dynamic>.from(
                positionMap.map(
                  (key, value) => MapEntry(key.toString(), value),
                ),
              ),
              ['y', 'top', 'dy'],
            )
          : null;

      final xParsed = _parseCoordinateValue(xRaw ?? posXRaw);
      final yParsed = _parseCoordinateValue(yRaw ?? posYRaw);

      rawObjects.add({
        'objectId': objectId,
        'displayName':
            _readString(map, ['display_name', 'name', 'objectType']) ??
            objectId,
        'imagePath':
            _readString(map, ['image_path', 'imagePath', 'asset']) ?? '',
        'x': xParsed?.$1,
        'y': yParsed?.$1,
        'xPercent': xParsed?.$2 ?? false,
        'yPercent': yParsed?.$2 ?? false,
      });
    }

    if (rawObjects.isEmpty) return const <GardenPlacedObject>[];

    final validXs = rawObjects
        .map((e) => e['x'])
        .whereType<double>()
        .where((e) => e.isFinite)
        .toList(growable: false);
    final validYs = rawObjects
        .map((e) => e['y'])
        .whereType<double>()
        .where((e) => e.isFinite)
        .toList(growable: false);

    final maxX = validXs.isEmpty ? 0.0 : validXs.reduce(math.max);
    final maxY = validYs.isEmpty ? 0.0 : validYs.reduce(math.max);
    final anyPercent = rawObjects.any(
      (e) =>
          (e['xPercent'] as bool? ?? false) ||
          (e['yPercent'] as bool? ?? false),
    );

    final isNormalized = !anyPercent && maxX <= 1.2 && maxY <= 1.2;
    final isPercentage =
        anyPercent || (!isNormalized && maxX <= 100 && maxY <= 100);

    final objects = <GardenPlacedObject>[];
    for (final rawObject in rawObjects) {
      var x = (rawObject['x'] as double?) ?? (_worldWidth / 2);
      var y = (rawObject['y'] as double?) ?? (_worldHeight / 2);
      final objectId = rawObject['objectId'] as String;

      if (isNormalized) {
        x = x * _worldWidth;
        y = y * _worldHeight;
      } else if (isPercentage) {
        x = (x / 100.0) * _worldWidth;
        y = (y / 100.0) * _worldHeight;
      }

      // 全体座標の平行移動補正（相対位置関係は維持）
      x += _crossPlayWorldOffsetX;
      y += _crossPlayWorldOffsetY;

      objects.add(
        GardenPlacedObject(
          objectId: objectId,
          displayName: rawObject['displayName'] as String,
          imagePath: rawObject['imagePath'] as String,
          position: Offset(
            x.clamp(0.0, _worldWidth).toDouble(),
            y.clamp(0.0, _worldHeight).toDouble(),
          ),
        ),
      );
    }

    return objects;
  }

  Object? _readAny(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      if (row.containsKey(key)) return row[key];
    }
    return null;
  }

  (double, bool)? _parseCoordinateValue(Object? value) {
    if (value == null) return null;
    if (value is num) return (value.toDouble(), false);
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      if (trimmed.endsWith('%')) {
        final parsed = double.tryParse(
          trimmed.substring(0, trimmed.length - 1),
        );
        if (parsed == null) return null;
        return (parsed, true);
      }
      final parsed = double.tryParse(trimmed);
      if (parsed == null) return null;
      return (parsed, false);
    }
    return null;
  }

  String? _normalizeObjectType(String? rawType) {
    if (rawType == null) return null;
    final normalized = rawType.trim().toLowerCase();
    if (normalized.isEmpty) return null;

    const aliases = <String, String>{
      // Next.js側 objectType の別名吸収
      'furin': 'huurin',
      'huurin': 'huurin',
      'shishi-odoshi': 'shishi-odoshi',
      'shishiodoshi': 'shishi-odoshi',
      'shishi_odoshi': 'shishi-odoshi',
      'cicada': 'semi',
      'bell': 'kane',
      'tea': 'mattya',
      'fire': 'takibi',
      'frog': 'kaeru',
      'fireworks': 'hanabi',
      'sparrow': 'suzume',
      'ghost': 'obake',
      'insect': 'akimusi',
    };

    return aliases[normalized] ?? normalized;
  }

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
                                  Navigator.of(
                                    context,
                                    rootNavigator: true,
                                  ).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const TitleScreen(stayOnTitle: true),
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
                  Expanded(
                    child: FutureBuilder<List<GardenListItem>>(
                      future: _postedGardensFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              '庭一覧の取得に失敗しました',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }

                        final gardens =
                            snapshot.data ?? const <GardenListItem>[];
                        if (gardens.isEmpty) {
                          return Center(
                            child: Text(
                              '公開中の庭がまだありません',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.82),
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Container(
                                width: 160,
                                height: 12,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF65513F),
                                      Color(0xFFE1C08F),
                                    ],
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
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  0,
                                  20,
                                  24,
                                ),
                                scrollDirection: Axis.horizontal,
                                itemBuilder: (context, index) {
                                  return _GardenCard(item: gardens[index]);
                                },
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 16),
                                itemCount: gardens.length,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
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
              child: Column(
                children: [
                  Text(
                    '${item.ownerName} / ${_seasonLabel(item.seasonId)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF5E5549),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'オブジェクト ${item.objectCount}個',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF6C6357),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.expiresIn,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF6C6357),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (!item.isMine) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => GardenScreen(
                        seasonId: item.seasonId,
                        allowObjectPlacement: false,
                        ownerName: item.ownerName,
                        gardenName: item.gardenTitle,
                        initialPlacedObjects: item.placedObjects,
                      ),
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

  String _seasonLabel(String seasonId) {
    switch (seasonId) {
      case 'spring':
        return '春';
      case 'summer':
        return '夏';
      case 'autumn':
        return '秋';
      case 'winter':
        return '冬';
      default:
        return '春';
    }
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
