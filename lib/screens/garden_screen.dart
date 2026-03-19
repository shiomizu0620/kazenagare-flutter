import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'catalog_modal.dart'; // ←追加
import 'options_modal.dart'; // ←これを追加
import '../widgets/object_video_player_widget.dart';

class _GardenControlsConfig {
  static const double moveSpeedPerSecond = 400;
  static const double stickBaseSize = 120;
  static const double stickKnobSize = 44;
}

class _PlacedGardenObject {
  final String instanceId;
  final String objectId;
  final String displayName;
  final String imagePath;
  final int rewardCoins;
  Offset position;
  DateTime? lastAutoPlayAt;
  int playSignal = 0;

  _PlacedGardenObject({
    required this.instanceId,
    required this.objectId,
    required this.displayName,
    required this.imagePath,
    required this.rewardCoins,
    required this.position,
  });
}

class _ObjectStageConfig {
  final String videoAsset;
  final double stageImageSize;
  final double stageVideoSize;
  final int rewardCoins;

  const _ObjectStageConfig({
    required this.videoAsset,
    required this.stageImageSize,
    required this.stageVideoSize,
    required this.rewardCoins,
  });
}

class GardenPlacedObject {
  final String objectId;
  final String displayName;
  final String imagePath;
  final Offset position;

  const GardenPlacedObject({
    required this.objectId,
    required this.displayName,
    required this.imagePath,
    required this.position,
  });
}

abstract class _BlockedShape {
  Rect get bounds;

  bool intersectsCircle(Offset center, double radius);

  Path buildPath();
}

class _BlockedRectShape implements _BlockedShape {
  final Rect rect;

  const _BlockedRectShape(this.rect);

  @override
  Rect get bounds => rect;

  @override
  bool intersectsCircle(Offset center, double radius) {
    final closestX = center.dx.clamp(rect.left, rect.right);
    final closestY = center.dy.clamp(rect.top, rect.bottom);

    final dx = center.dx - closestX;
    final dy = center.dy - closestY;
    return dx * dx + dy * dy < radius * radius;
  }

  @override
  Path buildPath() => Path()..addRect(rect);
}

class _BlockedCircleShape implements _BlockedShape {
  final Offset center;
  final double radius;

  const _BlockedCircleShape({required this.center, required this.radius});

  @override
  Rect get bounds => Rect.fromCircle(center: center, radius: radius);

  @override
  bool intersectsCircle(Offset point, double otherRadius) {
    final dx = point.dx - center.dx;
    final dy = point.dy - center.dy;
    final sum = radius + otherRadius;
    return dx * dx + dy * dy < sum * sum;
  }

  @override
  Path buildPath() => Path()..addOval(bounds);
}

class _BlockedPolygonShape implements _BlockedShape {
  final List<Offset> points;

  const _BlockedPolygonShape(this.points);

  @override
  Rect get bounds {
    var minX = points.first.dx;
    var minY = points.first.dy;
    var maxX = points.first.dx;
    var maxY = points.first.dy;

    for (final p in points.skip(1)) {
      if (p.dx < minX) minX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy > maxY) maxY = p.dy;
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  @override
  bool intersectsCircle(Offset center, double radius) {
    final rect = bounds;
    if (center.dx + radius < rect.left ||
        center.dx - radius > rect.right ||
        center.dy + radius < rect.top ||
        center.dy - radius > rect.bottom) {
      return false;
    }

    if (_containsPoint(center)) {
      return true;
    }

    final radiusSq = radius * radius;
    for (var i = 0; i < points.length; i++) {
      final a = points[i];
      final b = points[(i + 1) % points.length];
      if (_distanceToSegmentSquared(center, a, b) < radiusSq) {
        return true;
      }
    }

    return false;
  }

  @override
  Path buildPath() {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    path.close();
    return path;
  }

  bool _containsPoint(Offset point) {
    var inside = false;
    for (int i = 0, j = points.length - 1; i < points.length; j = i++) {
      final pi = points[i];
      final pj = points[j];
      final intersects =
          ((pi.dy > point.dy) != (pj.dy > point.dy)) &&
          (point.dx <
              (pj.dx - pi.dx) * (point.dy - pi.dy) / (pj.dy - pi.dy) + pi.dx);
      if (intersects) {
        inside = !inside;
      }
    }
    return inside;
  }

  double _distanceToSegmentSquared(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final ap = p - a;
    final abLenSq = ab.dx * ab.dx + ab.dy * ab.dy;
    if (abLenSq == 0) {
      final dx = p.dx - a.dx;
      final dy = p.dy - a.dy;
      return dx * dx + dy * dy;
    }
    final t = ((ap.dx * ab.dx + ap.dy * ab.dy) / abLenSq).clamp(0.0, 1.0);
    final closest = Offset(a.dx + ab.dx * t, a.dy + ab.dy * t);
    final dx = p.dx - closest.dx;
    final dy = p.dy - closest.dy;
    return dx * dx + dy * dy;
  }
}

class _BlockedOverlayPainter extends CustomPainter {
  final List<Object> blockedShapes;
  final double backgroundLeft;
  final double backgroundTop;
  final double zoom;

  const _BlockedOverlayPainter({
    required this.blockedShapes,
    required this.backgroundLeft,
    required this.backgroundTop,
    required this.zoom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final stripePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final transform = Float64List.fromList([
      zoom,
      0,
      0,
      0,
      0,
      zoom,
      0,
      0,
      0,
      0,
      1,
      0,
      backgroundLeft,
      backgroundTop,
      0,
      1,
    ]);

    for (final rawShape in blockedShapes) {
      final shape = _GardenScreenState._asBlockedShape(rawShape);
      final path = shape.buildPath().transform(transform);
      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, strokePaint);

      final clipBounds = path.getBounds();
      canvas.save();
      canvas.clipPath(path);
      const gap = 16.0;
      for (
        double x = clipBounds.left - clipBounds.height;
        x < clipBounds.right + clipBounds.height;
        x += gap
      ) {
        canvas.drawLine(
          Offset(x, clipBounds.bottom),
          Offset(x + clipBounds.height, clipBounds.top),
          stripePaint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _BlockedOverlayPainter oldDelegate) {
    return oldDelegate.backgroundLeft != backgroundLeft ||
        oldDelegate.backgroundTop != backgroundTop ||
        oldDelegate.zoom != zoom ||
        oldDelegate.blockedShapes != blockedShapes;
  }
}

class GardenScreen extends StatefulWidget {
  final String seasonId;
  final bool allowObjectPlacement;
  final String? ownerName;
  final String? gardenName;
  final List<GardenPlacedObject> initialPlacedObjects;

  const GardenScreen({
    super.key,
    this.seasonId = 'spring',
    this.allowObjectPlacement = true,
    this.ownerName,
    this.gardenName,
    this.initialPlacedObjects = const <GardenPlacedObject>[],
  });

  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const Map<String, String> _seasonBackgroundAssets = {
    'spring': 'assets/images/庭-春.png',
    'summer': 'assets/images/庭-夏.png',
    'autumn': 'assets/images/庭-秋.png',
    'winter': 'assets/images/庭-冬.png',
  };

  static const String _catIdleAsset = 'assets/images/charactor/猫1.png';
  static const List<String> _catWalkAssets = [
    'assets/images/charactor/猫1.png',
    'assets/images/charactor/猫2.png',
  ];
  static const double _walkFrameIntervalSeconds = 0.16;

  String get _gardenBackgroundAsset =>
      _seasonBackgroundAssets[widget.seasonId] ??
      _seasonBackgroundAssets['spring']!;

  // 庭のワールドサイズ（背景画像の論理サイズ）
  static const double _logicalGardenWidth = 2000.0;
  static const double _logicalGardenHeight = 1500.0;
  static const double _zoom = 1.6;
  static const double _playerBodySize = 72.0;
  static const double _playerVisualWidth = 72.0;
  static const double _playerVisualHeight = 88.0;
  static const double _playerCollisionRadius = 24.0;
  static const double _placementCollisionRadius = 20.0;
  static const double _placedObjectVisualSize = 64.0;
  static const int _maxPlacedObjects = 120;
  static const double _autoPlayNearDistance = 130.0;
  static const Duration _autoPlayCooldown = Duration(milliseconds: 2400);
  static const String _playerPosXKey = 'garden.player.x';
  static const String _playerPosYKey = 'garden.player.y';

  static const Map<String, String> _objectImageAssets = {
    'huurin': 'assets/images/objects/huurine.png',
    'semi': 'assets/images/objects/semie.png',
    'shishi-odoshi': 'assets/images/objects/sisiodosie.png',
    'kane': 'assets/images/objects/kanee.png',
    'mattya': 'assets/images/objects/mattyae.png',
    'takibi': 'assets/images/objects/takibie.png',
    'kaeru': 'assets/images/objects/kaerue.png',
    'hanabi': 'assets/images/objects/hanabie.png',
    'suzume': 'assets/images/objects/suzumee.png',
    'obake': 'assets/images/objects/obakee.png',
    'akimusi': 'assets/images/objects/akimusie.png',
    'hagoita': 'assets/images/objects/hagoitae.png',
    'haka': 'assets/images/objects/hakae.png',
    'hue': 'assets/images/objects/huee.png',
    'huro': 'assets/images/objects/huroe.png',
    'kamakura': 'assets/images/objects/kamakurae.png',
  };

  static const _ObjectStageConfig _defaultStageConfig = _ObjectStageConfig(
    videoAsset: 'assets/videos/objects/huurin.webm',
    stageImageSize: 64,
    stageVideoSize: 82,
    rewardCoins: 10,
  );

  static const Map<String, _ObjectStageConfig> _stageConfigs = {
    'huurin': _ObjectStageConfig(
      videoAsset: 'assets/videos/objects/huurin.webm',
      stageImageSize: 32,
      stageVideoSize: 50,
      rewardCoins: 22,
    ),
    'shishi-odoshi': _ObjectStageConfig(
      videoAsset: 'assets/videos/objects/sisiodosi.webm',
      stageImageSize: 80,
      stageVideoSize: 100,
      rewardCoins: 20,
    ),
    'semi': _ObjectStageConfig(
      videoAsset: 'assets/videos/objects/semi.webm',
      stageImageSize: 56,
      stageVideoSize: 72,
      rewardCoins: 16,
    ),
    'kane': _ObjectStageConfig(
      videoAsset: 'assets/videos/objects/kane.webm',
      stageImageSize: 66,
      stageVideoSize: 84,
      rewardCoins: 24,
    ),
    'mattya': _ObjectStageConfig(
      videoAsset: 'assets/videos/objects/mattya.webm',
      stageImageSize: 58,
      stageVideoSize: 76,
      rewardCoins: 14,
    ),
    'takibi': _ObjectStageConfig(
      videoAsset: 'assets/videos/objects/takibi.webm',
      stageImageSize: 64,
      stageVideoSize: 88,
      rewardCoins: 18,
    ),
    'kaeru': _ObjectStageConfig(
      videoAsset: 'assets/videos/objects/kaeru.webm',
      stageImageSize: 60,
      stageVideoSize: 80,
      rewardCoins: 19,
    ),
    'hanabi': _ObjectStageConfig(
      videoAsset: 'assets/videos/objects/hanabi.webm',
      stageImageSize: 66,
      stageVideoSize: 92,
      rewardCoins: 28,
    ),
    'suzume': _ObjectStageConfig(
      videoAsset: 'assets/videos/objects/suzume.webm',
      stageImageSize: 56,
      stageVideoSize: 74,
      rewardCoins: 17,
    ),
    'obake': _ObjectStageConfig(
      videoAsset: 'assets/videos/objects/obake.webm',
      stageImageSize: 62,
      stageVideoSize: 84,
      rewardCoins: 30,
    ),
    'akimusi': _ObjectStageConfig(
      videoAsset: 'assets/videos/objects/akimusi.webm',
      stageImageSize: 58,
      stageVideoSize: 76,
      rewardCoins: 15,
    ),
    'hagoita': _ObjectStageConfig(
      videoAsset: 'assets/videos/objects/hagoita.webm',
      stageImageSize: 62,
      stageVideoSize: 82,
      rewardCoins: 21,
    ),
    'haka': _ObjectStageConfig(
      videoAsset: 'assets/videos/objects/haka.webm',
      stageImageSize: 66,
      stageVideoSize: 86,
      rewardCoins: 23,
    ),
    'hue': _ObjectStageConfig(
      videoAsset: 'assets/videos/objects/hue.webm',
      stageImageSize: 58,
      stageVideoSize: 76,
      rewardCoins: 20,
    ),
    'huro': _ObjectStageConfig(
      videoAsset: 'assets/videos/objects/huro.webm',
      stageImageSize: 62,
      stageVideoSize: 80,
      rewardCoins: 12,
    ),
    'ka': _ObjectStageConfig(
      videoAsset: 'assets/videos/objects/ka.webm',
      stageImageSize: 52,
      stageVideoSize: 68,
      rewardCoins: 11,
    ),
    'kame': _ObjectStageConfig(
      videoAsset: 'assets/videos/objects/kame.webm',
      stageImageSize: 62,
      stageVideoSize: 80,
      rewardCoins: 13,
    ),
    'sansin': _ObjectStageConfig(
      videoAsset: 'assets/videos/objects/sansin.webm',
      stageImageSize: 68,
      stageVideoSize: 90,
      rewardCoins: 25,
    ),
    'saru': _ObjectStageConfig(
      videoAsset: 'assets/videos/objects/saru.webm',
      stageImageSize: 60,
      stageVideoSize: 80,
      rewardCoins: 17,
    ),
    'suzu': _ObjectStageConfig(
      videoAsset: 'assets/videos/objects/suzu.webm',
      stageImageSize: 54,
      stageVideoSize: 70,
      rewardCoins: 18,
    ),
    'tako': _ObjectStageConfig(
      videoAsset: 'assets/videos/objects/tako.webm',
      stageImageSize: 62,
      stageVideoSize: 82,
      rewardCoins: 16,
    ),
    'tyoutyo': _ObjectStageConfig(
      videoAsset: 'assets/videos/objects/tyoutyo.webm',
      stageImageSize: 56,
      stageVideoSize: 74,
      rewardCoins: 19,
    ),
    'youko': _ObjectStageConfig(
      videoAsset: 'assets/videos/objects/youko.webm',
      stageImageSize: 70,
      stageVideoSize: 94,
      rewardCoins: 32,
    ),
  };
  static const String _collisionMaskAsset =
      'assets/images/garden_collision_mask.png';
  static const bool _showCollisionMaskOverlay = false;
  static const bool _showLegacyBlockedOverlay = false;
  static const double _collisionMaskOverlayOpacity = 0.55;
  static const int _maskAlphaThreshold = 96;
  static const int _maskDarkThreshold = 52;

  // 添付画像の青塗り領域を高密度に再現した侵入不可エリア（ワールド座標）
  // 基準: 2000x1500
  static final List<Object> _blockedAreas = [
    // =========================
    // 上部の広域ブロック（ギザギザを多点で再現）
    // =========================
    const _BlockedPolygonShape([
      Offset(0, 0),
      Offset(2000, 0),
      Offset(2000, 270),
      Offset(1938, 248),
      Offset(1876, 206),
      Offset(1810, 238),
      Offset(1748, 193),
      Offset(1678, 222),
      Offset(1602, 176),
      Offset(1526, 214),
      Offset(1452, 170),
      Offset(1378, 236),
      Offset(1306, 182),
      Offset(1230, 262),
      Offset(1152, 202),
      Offset(1080, 282),
      Offset(1006, 216),
      Offset(930, 306),
      Offset(854, 230),
      Offset(778, 328),
      Offset(698, 242),
      Offset(618, 312),
      Offset(536, 234),
      Offset(452, 322),
      Offset(362, 248),
      Offset(274, 300),
      Offset(188, 246),
      Offset(104, 286),
      Offset(0, 228),
    ]),
    const _BlockedCircleShape(center: Offset(324, 246), radius: 72),
    const _BlockedCircleShape(center: Offset(486, 268), radius: 74),
    const _BlockedCircleShape(center: Offset(646, 288), radius: 78),
    const _BlockedCircleShape(center: Offset(814, 300), radius: 80),
    const _BlockedCircleShape(center: Offset(980, 318), radius: 82),
    const _BlockedCircleShape(center: Offset(1138, 302), radius: 78),
    const _BlockedCircleShape(center: Offset(1306, 286), radius: 74),
    const _BlockedCircleShape(center: Offset(1472, 272), radius: 72),
    const _BlockedCircleShape(center: Offset(1638, 258), radius: 74),
    const _BlockedCircleShape(center: Offset(1804, 246), radius: 76),

    // 上部の深い切れ込み（中央〜右）
    const _BlockedPolygonShape([
      Offset(778, 282),
      Offset(902, 244),
      Offset(1040, 258),
      Offset(1110, 340),
      Offset(1014, 430),
      Offset(868, 404),
      Offset(780, 336),
    ]),
    const _BlockedPolygonShape([
      Offset(1118, 250),
      Offset(1264, 232),
      Offset(1408, 278),
      Offset(1422, 378),
      Offset(1310, 452),
      Offset(1180, 410),
      Offset(1098, 330),
    ]),
    const _BlockedCircleShape(center: Offset(914, 386), radius: 86),
    const _BlockedCircleShape(center: Offset(1260, 410), radius: 92),

    // =========================
    // 右上の塊（社周辺）
    // =========================
    const _BlockedPolygonShape([
      Offset(1518, 286),
      Offset(1638, 252),
      Offset(1768, 222),
      Offset(1908, 224),
      Offset(2000, 254),
      Offset(2000, 798),
      Offset(1938, 790),
      Offset(1868, 726),
      Offset(1790, 770),
      Offset(1698, 748),
      Offset(1610, 706),
      Offset(1532, 636),
      Offset(1496, 544),
      Offset(1498, 444),
    ]),
    const _BlockedCircleShape(center: Offset(1820, 408), radius: 126),
    const _BlockedCircleShape(center: Offset(1900, 518), radius: 128),
    const _BlockedCircleShape(center: Offset(1948, 646), radius: 118),
    const _BlockedCircleShape(center: Offset(1780, 646), radius: 98),
    const _BlockedCircleShape(center: Offset(1658, 612), radius: 90),
    const _BlockedCircleShape(center: Offset(1590, 516), radius: 88),

    // 右端中腹（青で塗られている縁）
    const _BlockedPolygonShape([
      Offset(1948, 640),
      Offset(2000, 636),
      Offset(2000, 1030),
      Offset(1956, 1042),
      Offset(1916, 980),
      Offset(1922, 882),
    ]),

    // =========================
    // 左下の塊
    // =========================
    const _BlockedPolygonShape([
      Offset(0, 744),
      Offset(132, 760),
      Offset(230, 820),
      Offset(308, 902),
      Offset(372, 1000),
      Offset(430, 1112),
      Offset(472, 1240),
      Offset(462, 1392),
      Offset(420, 1500),
      Offset(0, 1500),
    ]),
    const _BlockedCircleShape(center: Offset(98, 892), radius: 148),
    const _BlockedCircleShape(center: Offset(162, 1032), radius: 152),
    const _BlockedCircleShape(center: Offset(236, 1186), radius: 162),
    const _BlockedCircleShape(center: Offset(288, 1340), radius: 176),
    const _BlockedCircleShape(center: Offset(74, 1266), radius: 164),
    const _BlockedCircleShape(center: Offset(366, 1088), radius: 106),

    // 左下中央寄りの突起（青塗りの飛び出し）
    const _BlockedPolygonShape([
      Offset(404, 1070),
      Offset(566, 1126),
      Offset(610, 1228),
      Offset(548, 1336),
      Offset(444, 1324),
      Offset(388, 1214),
    ]),

    // =========================
    // 右下の塊（池周辺）
    // =========================
    const _BlockedPolygonShape([
      Offset(1498, 1008),
      Offset(1628, 1020),
      Offset(1758, 1062),
      Offset(1888, 1088),
      Offset(2000, 1148),
      Offset(2000, 1500),
      Offset(1508, 1500),
      Offset(1458, 1416),
      Offset(1456, 1302),
      Offset(1472, 1190),
    ]),
    const _BlockedCircleShape(center: Offset(1654, 1244), radius: 168),
    const _BlockedCircleShape(center: Offset(1814, 1248), radius: 186),
    const _BlockedCircleShape(center: Offset(1946, 1310), radius: 196),
    const _BlockedCircleShape(center: Offset(1730, 1410), radius: 156),
    const _BlockedCircleShape(center: Offset(1870, 1450), radius: 148),

    // 右下池そのものの密な判定
    const _BlockedCircleShape(center: Offset(1698, 1326), radius: 86),
    const _BlockedCircleShape(center: Offset(1788, 1318), radius: 92),
    const _BlockedCircleShape(center: Offset(1874, 1326), radius: 88),
    const _BlockedCircleShape(center: Offset(1814, 1386), radius: 78),

    // =========================
    // 微調整: 端抜け防止
    // =========================
    const _BlockedRectShape(Rect.fromLTWH(0, 0, 2000, 20)),
    const _BlockedRectShape(Rect.fromLTWH(0, 1480, 2000, 20)),
    const _BlockedRectShape(Rect.fromLTWH(0, 0, 20, 1500)),
    const _BlockedRectShape(Rect.fromLTWH(1980, 0, 20, 1500)),
  ];

  static _BlockedShape _asBlockedShape(Object area) {
    if (area is _BlockedShape) return area;
    if (area is Rect) return _BlockedRectShape(area);
    throw StateError('Unsupported blocked area type: ${area.runtimeType}');
  }

  // 仮のプレイヤー座標（ワールド座標）
  double _playerX = _logicalGardenWidth / 2;
  double _playerY = _logicalGardenHeight / 2;
  final ValueNotifier<Offset> _cameraPosition = ValueNotifier(Offset.zero);

  // 画面サイズ（ドラッグ時の移動制限計算で使用）
  Size _viewportSize = Size.zero;

  bool _didPrecache = false;
  bool _didLoadCollisionMask = false;
  Uint8List? _collisionMaskRgba;
  int _collisionMaskWidth = 0;
  int _collisionMaskHeight = 0;

  final FocusNode _keyboardFocusNode = FocusNode();
  late final Ticker _movementTicker;
  Duration _lastTickElapsed = Duration.zero;

  bool _moveUp = false;
  bool _moveDown = false;
  bool _moveLeft = false;
  bool _moveRight = false;

  Offset _stickInput = Offset.zero;
  Offset? _floatingStickCenter;
  int? _activeStickPointer;

  String _currentPlayerAsset = _catIdleAsset;
  int _walkFrameIndex = 0;
  double _walkFrameTimer = 0;
  bool _isFacingRight = true;

  List<_PlacedGardenObject>? _placedObjects;
  SoundObject? _pendingPlacementObject;
  Offset? _mobilePlacementPreviewWorld;
  Timer? _positionSaveTimer;
  int _coinBalance = 0;

  List<_PlacedGardenObject> get _placedObjectsSafe =>
      _placedObjects ??= <_PlacedGardenObject>[];

  String _fallbackImagePathForObject(String objectId) {
    return _objectImageAssets[objectId] ?? _objectImageAssets['huurin']!;
  }

  _PlacedGardenObject _toPlacedGardenObject(
    GardenPlacedObject source,
    int index,
  ) {
    final normalizedObjectId = source.objectId.trim().isEmpty
        ? 'huurin'
        : source.objectId.trim();

    final displayName = source.displayName.trim().isEmpty
        ? normalizedObjectId
        : source.displayName.trim();

    final imagePath = source.imagePath.trim().isEmpty
        ? _fallbackImagePathForObject(normalizedObjectId)
        : source.imagePath.trim();

    return _PlacedGardenObject(
      instanceId: 'remote-$index-$normalizedObjectId',
      objectId: normalizedObjectId,
      displayName: displayName,
      imagePath: imagePath,
      rewardCoins: _stageConfigForObject(normalizedObjectId).rewardCoins,
      position: source.position,
    );
  }

  Offset _clampSpawnInsideBounds(Offset source) {
    final padding = _playerCollisionRadius + 16;
    final minX = padding;
    final maxX = _logicalGardenWidth - padding;
    final minY = padding;
    final maxY = _logicalGardenHeight - padding;
    return Offset(
      source.dx.clamp(minX, maxX).toDouble(),
      source.dy.clamp(minY, maxY).toDouble(),
    );
  }

  Offset _findNearestWalkablePosition(Offset target) {
    final clampedTarget = _clampSpawnInsideBounds(target);
    if (!_isBlockedPosition(clampedTarget)) {
      return clampedTarget;
    }

    const maxRadius = 420.0;
    const stepRadius = 24.0;
    const stepDegree = 20;

    for (var radius = stepRadius; radius <= maxRadius; radius += stepRadius) {
      for (var degree = 0; degree < 360; degree += stepDegree) {
        final radian = degree * math.pi / 180.0;
        final candidate = _clampSpawnInsideBounds(
          Offset(
            clampedTarget.dx + math.cos(radian) * radius,
            clampedTarget.dy + math.sin(radian) * radius,
          ),
        );

        if (!_isBlockedPosition(candidate)) {
          return candidate;
        }
      }
    }

    final center = _clampSpawnInsideBounds(
      const Offset(_logicalGardenWidth / 2, _logicalGardenHeight / 2),
    );
    if (!_isBlockedPosition(center)) {
      return center;
    }

    return clampedTarget;
  }

  void _initializeVisitorPlayerPositionFromObjects() {
    if (widget.allowObjectPlacement || widget.initialPlacedObjects.isEmpty) {
      return;
    }

    var sumX = 0.0;
    var sumY = 0.0;
    var validCount = 0;
    for (final object in widget.initialPlacedObjects) {
      final x = object.position.dx;
      final y = object.position.dy;
      if (!x.isFinite || !y.isFinite) continue;
      sumX += x;
      sumY += y;
      validCount += 1;
    }

    if (validCount == 0) {
      final fallback = _findNearestWalkablePosition(
        const Offset(_logicalGardenWidth / 2, _logicalGardenHeight / 2),
      );
      _playerX = fallback.dx;
      _playerY = fallback.dy;
      return;
    }

    final centroid = Offset(sumX / validCount, sumY / validCount);
    final resolved = _findNearestWalkablePosition(centroid);
    _playerX = resolved.dx;
    _playerY = resolved.dy;
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialPlacedObjects.isNotEmpty) {
      _placedObjects = List<_PlacedGardenObject>.generate(
        widget.initialPlacedObjects.length,
        (index) =>
            _toPlacedGardenObject(widget.initialPlacedObjects[index], index),
      );
    } else {
      _placedObjects ??= <_PlacedGardenObject>[];
    }

    _initializeVisitorPlayerPositionFromObjects();
    WidgetsBinding.instance.addObserver(this);
    _cameraPosition.value = Offset(_playerX, _playerY);
    _movementTicker = createTicker((elapsed) {
      if (_lastTickElapsed == Duration.zero) {
        _lastTickElapsed = elapsed;
        return;
      }
      final deltaSeconds =
          (elapsed - _lastTickElapsed).inMicroseconds /
          Duration.microsecondsPerSecond;
      _lastTickElapsed = elapsed;
      _tickMovement(deltaSeconds);
    })..start();

    _loadPlayerPosition();

    if (widget.allowObjectPlacement) {
      _positionSaveTimer = Timer.periodic(const Duration(milliseconds: 900), (
        _,
      ) {
        _savePlayerPosition();
      });
    }
  }

  @override
  void dispose() {
    _positionSaveTimer?.cancel();
    if (widget.allowObjectPlacement) {
      _savePlayerPosition();
    }
    WidgetsBinding.instance.removeObserver(this);
    _movementTicker.dispose();
    _cameraPosition.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      if (widget.allowObjectPlacement) {
        _savePlayerPosition();
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrecache) return;
    _didPrecache = true;
    precacheImage(AssetImage(_gardenBackgroundAsset), context);
    precacheImage(const AssetImage(_collisionMaskAsset), context);
    precacheImage(const AssetImage('assets/images/charactor/猫1.png'), context);
    precacheImage(const AssetImage('assets/images/charactor/猫2.png'), context);

    if (!_didLoadCollisionMask) {
      _didLoadCollisionMask = true;
      _loadCollisionMask();
    }
  }

  Future<void> _loadCollisionMask() async {
    try {
      final data = await rootBundle.load(_collisionMaskAsset);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );

      if (!mounted || byteData == null) return;

      setState(() {
        _collisionMaskRgba = byteData.buffer.asUint8List();
        _collisionMaskWidth = image.width;
        _collisionMaskHeight = image.height;
      });
    } catch (e) {
      debugPrint('Failed to load collision mask: $e');
    }
  }

  ({double minX, double maxX, double minY, double maxY}) _cameraBounds(
    Size viewport,
  ) {
    final visibleWorldWidth = viewport.width / _zoom;
    final visibleWorldHeight = viewport.height / _zoom;

    final worldCenterX = _logicalGardenWidth / 2;
    final worldCenterY = _logicalGardenHeight / 2;

    final minX = visibleWorldWidth >= _logicalGardenWidth
        ? worldCenterX
        : visibleWorldWidth / 2;
    final maxX = visibleWorldWidth >= _logicalGardenWidth
        ? worldCenterX
        : _logicalGardenWidth - visibleWorldWidth / 2;
    final minY = visibleWorldHeight >= _logicalGardenHeight
        ? worldCenterY
        : visibleWorldHeight / 2;
    final maxY = visibleWorldHeight >= _logicalGardenHeight
        ? worldCenterY
        : _logicalGardenHeight - visibleWorldHeight / 2;

    return (minX: minX, maxX: maxX, minY: minY, maxY: maxY);
  }

  String get _seasonLabel {
    switch (widget.seasonId) {
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

  bool _movePlayerByDelta(double deltaX, double deltaY) {
    if (_viewportSize == Size.zero) return false;

    final candidateX = (_playerX + deltaX)
        .clamp(0.0, _logicalGardenWidth)
        .toDouble();
    final candidateY = (_playerY + deltaY)
        .clamp(0.0, _logicalGardenHeight)
        .toDouble();

    var nextX = candidateX;
    var nextY = candidateY;

    if (_isBlockedPosition(Offset(candidateX, candidateY))) {
      final xOnly = Offset(candidateX, _playerY);
      final yOnly = Offset(_playerX, candidateY);

      if (!_isBlockedPosition(xOnly)) {
        nextX = xOnly.dx;
        nextY = xOnly.dy;
      } else if (!_isBlockedPosition(yOnly)) {
        nextX = yOnly.dx;
        nextY = yOnly.dy;
      } else {
        return false;
      }
    }

    if (nextX == _playerX && nextY == _playerY) return false;

    setState(() {
      _playerX = nextX;
      _playerY = nextY;
      _syncCameraToPlayer();
    });

    return true;
  }

  bool _isBlockedPosition(Offset position) {
    if (_collisionMaskRgba != null &&
        _collisionMaskWidth > 0 &&
        _collisionMaskHeight > 0) {
      return _isBlockedByMask(position, _playerCollisionRadius);
    }

    for (final rawArea in _blockedAreas) {
      final area = _asBlockedShape(rawArea);
      if (area.intersectsCircle(position, _playerCollisionRadius)) {
        return true;
      }
    }
    return false;
  }

  bool _isBlockedByMask(Offset center, double radius) {
    final rgba = _collisionMaskRgba;
    if (rgba == null || _collisionMaskWidth <= 0 || _collisionMaskHeight <= 0) {
      return false;
    }

    final clampedX = center.dx.clamp(0.0, _logicalGardenWidth - 1);
    final clampedY = center.dy.clamp(0.0, _logicalGardenHeight - 1);

    final scaleX = (_collisionMaskWidth - 1) / _logicalGardenWidth;
    final scaleY = (_collisionMaskHeight - 1) / _logicalGardenHeight;

    final centerPx = clampedX * scaleX;
    final centerPy = clampedY * scaleY;
    final radiusPxX = radius * scaleX;
    final radiusPxY = radius * scaleY;

    final minPx = (centerPx - radiusPxX).floor().clamp(
      0,
      _collisionMaskWidth - 1,
    );
    final maxPx = (centerPx + radiusPxX).ceil().clamp(
      0,
      _collisionMaskWidth - 1,
    );
    final minPy = (centerPy - radiusPxY).floor().clamp(
      0,
      _collisionMaskHeight - 1,
    );
    final maxPy = (centerPy + radiusPxY).ceil().clamp(
      0,
      _collisionMaskHeight - 1,
    );

    final rx = radiusPxX <= 0 ? 0.5 : radiusPxX;
    final ry = radiusPxY <= 0 ? 0.5 : radiusPxY;
    final invRxSq = 1.0 / (rx * rx);
    final invRySq = 1.0 / (ry * ry);

    for (int py = minPy; py <= maxPy; py++) {
      final dy = py - centerPy;
      final yTerm = (dy * dy) * invRySq;
      if (yTerm > 1.0) continue;

      for (int px = minPx; px <= maxPx; px++) {
        final dx = px - centerPx;
        final distNorm = (dx * dx) * invRxSq + yTerm;
        if (distNorm > 1.0) continue;
        if (_isBlockedMaskPixel(px, py)) return true;
      }
    }

    return false;
  }

  bool _isBlockedMaskPixel(int px, int py) {
    final rgba = _collisionMaskRgba;
    if (rgba == null) return false;

    final index = (py * _collisionMaskWidth + px) * 4;
    if (index < 0 || index + 3 >= rgba.length) return false;

    final r = rgba[index];
    final g = rgba[index + 1];
    final b = rgba[index + 2];
    final a = rgba[index + 3];

    if (a < _maskAlphaThreshold) return false;

    final luma = 0.2126 * r + 0.7152 * g + 0.0722 * b;
    return luma <= _maskDarkThreshold;
  }

  Widget _buildBlockedOverlayLayer(
    double backgroundLeft,
    double backgroundTop,
  ) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _BlockedOverlayPainter(
            blockedShapes: _blockedAreas,
            backgroundLeft: backgroundLeft,
            backgroundTop: backgroundTop,
            zoom: _zoom,
          ),
        ),
      ),
    );
  }

  Widget _buildCollisionMaskOverlayLayer(
    double backgroundLeft,
    double backgroundTop,
  ) {
    return Positioned(
      left: backgroundLeft,
      top: backgroundTop,
      width: _logicalGardenWidth * _zoom,
      height: _logicalGardenHeight * _zoom,
      child: IgnorePointer(
        child: Opacity(
          opacity: _collisionMaskOverlayOpacity,
          child: Image.asset(
            _collisionMaskAsset,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.none,
          ),
        ),
      ),
    );
  }

  void _syncCameraToPlayer() {
    if (_viewportSize == Size.zero) return;

    final bounds = _cameraBounds(_viewportSize);
    final nextCamera = Offset(
      _playerX.clamp(bounds.minX, bounds.maxX).toDouble(),
      _playerY.clamp(bounds.minY, bounds.maxY).toDouble(),
    );

    if (_cameraPosition.value != nextCamera) {
      _cameraPosition.value = nextCamera;
    }
  }

  Future<void> _loadPlayerPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final savedX = prefs.getDouble(_playerPosXKey);
    final savedY = prefs.getDouble(_playerPosYKey);
    if (!mounted || savedX == null || savedY == null) return;

    final next = Offset(
      savedX.clamp(0.0, _logicalGardenWidth),
      savedY.clamp(0.0, _logicalGardenHeight),
    );

    setState(() {
      _playerX = next.dx;
      _playerY = next.dy;
      _syncCameraToPlayer();
    });
  }

  Future<void> _savePlayerPosition() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_playerPosXKey, _playerX);
    await prefs.setDouble(_playerPosYKey, _playerY);
  }

  void _tickMovement(double deltaSeconds) {
    if (!mounted || _viewportSize == Size.zero) return;
    if (deltaSeconds <= 0) return;

    _sanitizePlacedObjects();

    final keyboardInput = Offset(
      ((_moveRight ? 1 : 0) - (_moveLeft ? 1 : 0)).toDouble(),
      ((_moveDown ? 1 : 0) - (_moveUp ? 1 : 0)).toDouble(),
    );

    final input = keyboardInput.distanceSquared > 0
        ? keyboardInput
        : _stickInput;
    final hasInput = input.distanceSquared > 0;
    if (!hasInput) {
      _updatePlayerAnimation(deltaSeconds, isMoving: false);
      return;
    }

    final normalized = input.distance > 1 ? input / input.distance : input;
    _updateFacingDirection(normalized.dx);
    final step = _GardenControlsConfig.moveSpeedPerSecond * deltaSeconds;
    final moved = _movePlayerByDelta(
      normalized.dx * step,
      normalized.dy * step,
    );
    _updatePlayerAnimation(deltaSeconds, isMoving: moved || hasInput);
    _updateObjectAutoPlayback();
  }

  _ObjectStageConfig _stageConfigForObject(String objectId) {
    try {
      return _stageConfigs[objectId] ?? _defaultStageConfig;
    } catch (_) {
      return _defaultStageConfig;
    }
  }

  void _sanitizePlacedObjects() {
    final objects = _placedObjectsSafe;
    objects.removeWhere((object) {
      try {
        final id = object.objectId;
        final image = object.imagePath;
        final name = object.displayName;
        final x = object.position.dx;
        final y = object.position.dy;
        if (id.isEmpty || image.isEmpty || name.isEmpty) return true;
        if (!x.isFinite || !y.isFinite) return true;
        return false;
      } catch (_) {
        return true;
      }
    });
  }

  void _updateObjectAutoPlayback() {
    final now = DateTime.now();
    final objects = _placedObjectsSafe;
    bool changed = false;

    for (final object in objects) {
      final dx = _playerX - object.position.dx;
      final dy = _playerY - object.position.dy;
      final distance = math.sqrt(dx * dx + dy * dy);

      final canTrigger =
          distance <= _autoPlayNearDistance &&
          (object.lastAutoPlayAt == null ||
              now.difference(object.lastAutoPlayAt!) >= _autoPlayCooldown);

      if (!canTrigger) continue;

      object.lastAutoPlayAt = now;
      object.playSignal += 1;
      changed = true;

      if (widget.allowObjectPlacement) {
        _coinBalance += object.rewardCoins;
      }
    }

    if (changed && mounted) {
      setState(() {});
    }
  }

  void _updatePlayerAnimation(double deltaSeconds, {required bool isMoving}) {
    if (!isMoving) {
      _walkFrameTimer = 0;
      _walkFrameIndex = 0;
      if (_currentPlayerAsset != _catIdleAsset) {
        setState(() {
          _currentPlayerAsset = _catIdleAsset;
        });
      }
      return;
    }

    _walkFrameTimer += deltaSeconds;
    if (_walkFrameTimer < _walkFrameIntervalSeconds) return;

    _walkFrameTimer -= _walkFrameIntervalSeconds;
    _walkFrameIndex = (_walkFrameIndex + 1) % _catWalkAssets.length;
    final nextAsset = _catWalkAssets[_walkFrameIndex];
    if (nextAsset == _currentPlayerAsset) return;

    setState(() {
      _currentPlayerAsset = nextAsset;
    });
  }

  void _updateFacingDirection(double dx) {
    const threshold = 0.05;
    if (dx.abs() < threshold) return;

    final shouldFaceRight = dx > 0;
    if (_isFacingRight == shouldFaceRight) return;

    setState(() {
      _isFacingRight = shouldFaceRight;
    });
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    final isPressed = event is! KeyUpEvent;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyW) {
      _moveUp = isPressed;
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.keyS) {
      _moveDown = isPressed;
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA) {
      _moveLeft = isPressed;
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.keyD) {
      _moveRight = isPressed;
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  bool _isMobileControls(Size viewport) {
    if (kIsWeb) {
      return viewport.shortestSide < 700;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return true;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return false;
    }
  }

  // ===================================================
  // 新規追加: UIコンポーネント
  // ===================================================

  // 左上の情報チップ（Next.js版に合わせたデザイン）
  Widget _buildHeaderChips() {
    Widget buildChip(String text) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 16, top: 16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            buildChip(
              widget.ownerName?.trim().isNotEmpty == true
                  ? widget.ownerName!.trim()
                  : (widget.allowObjectPlacement ? 'あなた' : '庭の持ち主'),
            ),
            buildChip(
              widget.gardenName?.trim().isNotEmpty == true
                  ? widget.gardenName!.trim()
                  : (widget.allowObjectPlacement ? 'わたしの庭' : '訪問中の庭'),
            ),
            buildChip('季節: $_seasonLabel'),
            if (widget.allowObjectPlacement) buildChip('音の実り: $_coinBalance'),
          ],
        ),
      ),
    );
  }

  // 図鑑ボタンとオプションボタン（右上に横並び）
  Widget _buildActionButtons() {
    Widget buildCircleButton({
      required IconData icon,
      required String tooltip,
      required VoidCallback onPressed,
    }) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: IconButton(
          icon: Icon(icon, color: Colors.white),
          tooltip: tooltip,
          onPressed: onPressed,
        ),
      );
    }

    return SafeArea(
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.only(top: 16, right: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 右上：図鑑ボタン（オプションの左隣）
              buildCircleButton(
                icon: Icons.menu_book_rounded,
                tooltip: '図鑑を開く',
                onPressed: () async {
                  if (!widget.allowObjectPlacement) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('訪問中の庭では配置できません')),
                    );
                    return;
                  }

                  _deactivateFloatingStick();
                  final selected = await CatalogModal.show(context);
                  if (!mounted || selected == null) return;

                  if (!selected.isUnlocked) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('未解放オブジェクトは設置できません')),
                    );
                    return;
                  }

                  setState(() {
                    _pendingPlacementObject = selected;
                    _mobilePlacementPreviewWorld = null;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '設置モード: ${selected.name}（オブジェクトをタップで持ち上げ/移動）',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              // 右上：オプションボタン
              buildCircleButton(
                icon: Icons.settings_rounded,
                tooltip: 'オプション',
                onPressed: () {
                  _deactivateFloatingStick();
                  final placements = _placedObjectsSafe
                      .map(
                        (object) => <String, dynamic>{
                          'object_id': object.objectId,
                          'display_name': object.displayName,
                          'image_path': object.imagePath,
                          'x': object.position.dx,
                          'y': object.position.dy,
                        },
                      )
                      .toList(growable: false);

                  OptionsModal.show(
                    context,
                    isMe: widget.allowObjectPlacement,
                    seasonId: widget.seasonId,
                    gardenName: widget.gardenName,
                    objectCount: _placedObjectsSafe.length,
                    objectPlacements: placements,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          _viewportSize = Size(constraints.maxWidth, constraints.maxHeight);
          _syncCameraToPlayer();
          final mobileControls = _isMobileControls(_viewportSize);

          return Focus(
            focusNode: _keyboardFocusNode,
            autofocus: true,
            onKeyEvent: _handleKeyEvent,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _keyboardFocusNode.requestFocus(),
              onTapDown: (details) {
                _keyboardFocusNode.requestFocus();
                if (!widget.allowObjectPlacement) return;
                // 2状態のみ: 未選択=配置済み / 選択中=移動モード
                // 移動モード中は「再設置」を優先する
                if (_pendingPlacementObject != null) {
                  _placeObjectAtScreen(details.localPosition);
                  return;
                }
                _pickupPlacedObjectAtScreen(details.localPosition);
              },
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: mobileControls ? _handleMobilePointerDown : null,
                onPointerMove: mobileControls ? _handleMobilePointerMove : null,
                onPointerUp: mobileControls ? _handleMobilePointerUp : null,
                onPointerCancel: mobileControls
                    ? _handleMobilePointerCancel
                    : null,
                child: Stack(
                  children: [
                    // 1) 背景: 庭全体画像を拡大した上で、カメラ位置に応じてずらして表示
                    ValueListenableBuilder<Offset>(
                      valueListenable: _cameraPosition,
                      builder: (context, camera, _) {
                        final bounds = _cameraBounds(_viewportSize);
                        final cameraX = camera.dx.clamp(
                          bounds.minX,
                          bounds.maxX,
                        );
                        final cameraY = camera.dy.clamp(
                          bounds.minY,
                          bounds.maxY,
                        );

                        final backgroundLeft =
                            -(cameraX * _zoom - _viewportSize.width / 2);
                        final backgroundTop =
                            -(cameraY * _zoom - _viewportSize.height / 2);

                        final playerScreenX =
                            (_playerX - cameraX) * _zoom +
                            _viewportSize.width / 2;
                        final playerScreenY =
                            (_playerY - cameraY) * _zoom +
                            _viewportSize.height / 2;

                        return Stack(
                          children: [
                            Positioned(
                              left: backgroundLeft,
                              top: backgroundTop,
                              width: _logicalGardenWidth * _zoom,
                              height: _logicalGardenHeight * _zoom,
                              child: RepaintBoundary(
                                child: Image.asset(
                                  _gardenBackgroundAsset,
                                  fit: BoxFit.fill,
                                  filterQuality: FilterQuality.low,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.black,
                                      alignment: Alignment.center,
                                      child: Text(
                                        '背景画像が見つかりません\n$_gardenBackgroundAsset',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),

                            if (_showCollisionMaskOverlay)
                              _buildCollisionMaskOverlayLayer(
                                backgroundLeft,
                                backgroundTop,
                              ),

                            if (_showLegacyBlockedOverlay)
                              _buildBlockedOverlayLayer(
                                backgroundLeft,
                                backgroundTop,
                              ),

                            ..._buildPlacedObjectWidgets(cameraX, cameraY),

                            if (_mobilePlacementPreviewWorld != null)
                              _buildPlacementPreviewWidget(
                                cameraX,
                                cameraY,
                                _mobilePlacementPreviewWorld!,
                              ),

                            Positioned(
                              left: playerScreenX - _playerVisualWidth / 2,
                              top: playerScreenY - _playerVisualHeight / 2,
                              child: _buildPlayerCharacter(),
                            ),
                          ],
                        );
                      },
                    ),

                    // 2) HUD: 新しいUI群

                    // 左上のヘッダーチップ
                    Positioned(left: 0, top: 0, child: _buildHeaderChips()),

                    // 右上（図鑑・オプション）のボタン
                    Positioned.fill(child: _buildActionButtons()),

                    // PC向け操作ヒント（下部中央）
                    if (!mobileControls)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                            ),
                            child: const Text(
                              'WASD / 矢印キーで移動',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // 仮想スティック (モバイル向け、右下)
                    if (mobileControls && _floatingStickCenter != null)
                      _buildVirtualStick(_floatingStickCenter!),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlacementPreviewWidget(
    double cameraX,
    double cameraY,
    Offset worldPosition,
  ) {
    final selected = _pendingPlacementObject;
    if (selected == null) return const SizedBox.shrink();

    final screenX =
        (worldPosition.dx - cameraX) * _zoom + _viewportSize.width / 2;
    final screenY =
        (worldPosition.dy - cameraY) * _zoom + _viewportSize.height / 2;

    return Positioned(
      left: screenX - (_placedObjectVisualSize / 2),
      top: screenY - (_placedObjectVisualSize / 2),
      width: _placedObjectVisualSize,
      height: _placedObjectVisualSize,
      child: IgnorePointer(
        child: Opacity(
          opacity: 0.55,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(selected.imagePath, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPlacedObjectWidgets(double cameraX, double cameraY) {
    final widgets = <Widget>[];

    _sanitizePlacedObjects();
    final objects = _placedObjectsSafe;
    for (int i = 0; i < objects.length; i++) {
      final object = objects[i];
      final config = _stageConfigForObject(object.objectId);
      final visualSize = math.max(config.stageImageSize, config.stageVideoSize);
      final screenX =
          (object.position.dx - cameraX) * _zoom + _viewportSize.width / 2;
      final screenY =
          (object.position.dy - cameraY) * _zoom + _viewportSize.height / 2;

      widgets.add(
        Positioned(
          left: screenX - (visualSize / 2),
          top: screenY - (visualSize / 2),
          width: visualSize,
          height: visualSize,
          child: Container(
            alignment: Alignment.center,
            child: ObjectVideoPlayerWidget(
              key: ValueKey(object.instanceId),
              object: PlacedStageObject(
                objectId: object.objectId,
                imagePath: object.imagePath,
                videoAssetPath: _stageConfigForObject(
                  object.objectId,
                ).videoAsset,
                isMyGarden: widget.allowObjectPlacement,
                rewardCoins: object.rewardCoins,
                playSignal: object.playSignal,
              ),
              imageSize: config.stageImageSize,
              videoSize: config.stageVideoSize,
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  bool _placeObjectAtScreen(Offset localPosition) {
    if (!widget.allowObjectPlacement) return false;
    final selected = _pendingPlacementObject;
    if (selected == null || _viewportSize == Size.zero) return false;
    if (_isInActionButtonsZone(localPosition)) return false;

    final mobileControls = _isMobileControls(_viewportSize);
    final bounds = _cameraBounds(_viewportSize);
    final cameraX = _cameraPosition.value.dx.clamp(bounds.minX, bounds.maxX);
    final cameraY = _cameraPosition.value.dy.clamp(bounds.minY, bounds.maxY);

    final worldX =
        ((localPosition.dx - _viewportSize.width / 2) / _zoom) + cameraX;
    final worldY =
        ((localPosition.dy - _viewportSize.height / 2) / _zoom) + cameraY;

    final worldPosition = Offset(
      worldX.clamp(0.0, _logicalGardenWidth),
      worldY.clamp(0.0, _logicalGardenHeight),
    );

    if (mobileControls && _mobilePlacementPreviewWorld == null) {
      setState(() {
        _mobilePlacementPreviewWorld = worldPosition;
      });
      return true;
    }

    if (_isBlockedPlacementPosition(worldPosition)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('その場所には設置できません')));
      setState(() {
        _mobilePlacementPreviewWorld = null;
      });
      return true;
    }

    setState(() {
      final objects = _placedObjectsSafe;
      if (objects.length >= _maxPlacedObjects &&
          !objects.any((o) => o.objectId == selected.id)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('設置上限（120個）に達しています')));
        _mobilePlacementPreviewWorld = null;
        return;
      }

      final existingIndex = objects.indexWhere(
        (o) => o.objectId == selected.id,
      );
      if (existingIndex >= 0) {
        objects[existingIndex].position = worldPosition;
      } else {
        objects.add(
          _PlacedGardenObject(
            instanceId:
                '${DateTime.now().microsecondsSinceEpoch}-${objects.length}',
            objectId: selected.id,
            displayName: selected.name,
            imagePath: selected.imagePath,
            rewardCoins: _stageConfigForObject(selected.id).rewardCoins,
            position: worldPosition,
          ),
        );
      }

      // 設置完了で移動モード終了
      _pendingPlacementObject = null;
      _mobilePlacementPreviewWorld = null;
    });

    return true;
  }

  bool _isBlockedPlacementPosition(Offset worldPosition) {
    if (_collisionMaskRgba != null &&
        _collisionMaskWidth > 0 &&
        _collisionMaskHeight > 0) {
      return _isBlockedByMask(worldPosition, _placementCollisionRadius);
    }

    for (final rawArea in _blockedAreas) {
      final area = _asBlockedShape(rawArea);
      if (area.intersectsCircle(worldPosition, _placementCollisionRadius)) {
        return true;
      }
    }
    return false;
  }

  bool _pickupPlacedObjectAtScreen(Offset localPosition) {
    if (!widget.allowObjectPlacement) return false;
    if (_viewportSize == Size.zero) return false;

    final index = _findPlacedObjectIndexAtScreen(localPosition);
    if (index < 0) return false;

    final picked = _placedObjectsSafe[index];

    setState(() {
      _placedObjectsSafe.removeAt(index);
      _pendingPlacementObject = SoundObject(
        id: picked.objectId,
        name: picked.displayName,
        imagePath: picked.imagePath,
        description: '持ち上げ中のオブジェクト',
        rewardCoins: 0,
        isUnlocked: true,
        effectType: 'picked-up',
      );
      _mobilePlacementPreviewWorld = null;
    });

    return true;
  }

  int _findPlacedObjectIndexAtScreen(Offset localPosition) {
    if (_viewportSize == Size.zero) return -1;

    final bounds = _cameraBounds(_viewportSize);
    final cameraX = _cameraPosition.value.dx.clamp(bounds.minX, bounds.maxX);
    final cameraY = _cameraPosition.value.dy.clamp(bounds.minY, bounds.maxY);

    final objects = _placedObjectsSafe;
    for (int i = objects.length - 1; i >= 0; i--) {
      final object = objects[i];
      final screenX =
          (object.position.dx - cameraX) * _zoom + _viewportSize.width / 2;
      final screenY =
          (object.position.dy - cameraY) * _zoom + _viewportSize.height / 2;

      final rect = Rect.fromCenter(
        center: Offset(screenX, screenY),
        width: _placedObjectVisualSize,
        height: _placedObjectVisualSize,
      );

      if (rect.contains(localPosition)) return i;
    }

    return -1;
  }

  Widget _buildPlayerCharacter() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: _playerBodySize,
          height: _playerBodySize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Transform.flip(
            flipX: _isFacingRight,
            child: Image.asset(
              _currentPlayerAsset,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 44,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      ],
    );
  }

  Widget _buildVirtualStick(Offset center) {
    const double baseSize = _GardenControlsConfig.stickBaseSize;
    const double knobSize = _GardenControlsConfig.stickKnobSize;
    const double radius = (baseSize - knobSize) / 2;

    final clampedCenter = Offset(
      center.dx.clamp(baseSize / 2, _viewportSize.width - baseSize / 2),
      center.dy.clamp(baseSize / 2, _viewportSize.height - baseSize / 2),
    );

    return Positioned(
      left: clampedCenter.dx - baseSize / 2,
      top: clampedCenter.dy - baseSize / 2,
      child: IgnorePointer(
        child: Container(
          width: baseSize,
          height: baseSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.3),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: Stack(
            children: [
              Positioned(
                left: (baseSize - knobSize) / 2 + (_stickInput.dx * radius),
                top: (baseSize - knobSize) / 2 + (_stickInput.dy * radius),
                child: Container(
                  width: knobSize,
                  height: knobSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.9),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleMobilePointerDown(PointerDownEvent event) {
    if (!widget.allowObjectPlacement) {
      if (_activeStickPointer != null) return;
      if (_isInActionButtonsZone(event.localPosition)) return;
      _activeStickPointer = event.pointer;
      setState(() {
        _floatingStickCenter = event.localPosition;
        _stickInput = Offset.zero;
      });
      return;
    }

    if (_pendingPlacementObject != null) {
      if (_placeObjectAtScreen(event.localPosition)) return;
    } else {
      if (_pickupPlacedObjectAtScreen(event.localPosition)) return;
    }
    if (_activeStickPointer != null) return;
    if (_isInActionButtonsZone(event.localPosition)) return;

    _activeStickPointer = event.pointer;
    setState(() {
      _floatingStickCenter = event.localPosition;
      _stickInput = Offset.zero;
    });
  }

  bool _isInActionButtonsZone(Offset position) {
    if (_viewportSize == Size.zero) return false;

    final topInset = MediaQuery.paddingOf(context).top;
    const topMargin = 16.0;
    const rightMargin = 16.0;
    const buttonSize = kMinInteractiveDimension;
    const spacing = 8.0;

    final zoneRight = _viewportSize.width - rightMargin;
    final zoneLeft = zoneRight - (buttonSize * 2 + spacing);
    final zoneTop = topInset + topMargin;
    final zoneBottom = zoneTop + buttonSize;

    return position.dx >= zoneLeft &&
        position.dx <= zoneRight &&
        position.dy >= zoneTop &&
        position.dy <= zoneBottom;
  }

  void _handleMobilePointerMove(PointerMoveEvent event) {
    if (_activeStickPointer != event.pointer || _floatingStickCenter == null) {
      return;
    }
    _updateStickInputFromPointer(event.localPosition);
  }

  void _handleMobilePointerUp(PointerUpEvent event) {
    if (_activeStickPointer != event.pointer) return;
    _deactivateFloatingStick();
  }

  void _handleMobilePointerCancel(PointerCancelEvent event) {
    if (_activeStickPointer != event.pointer) return;
    _deactivateFloatingStick();
  }

  void _deactivateFloatingStick() {
    setState(() {
      _activeStickPointer = null;
      _floatingStickCenter = null;
      _stickInput = Offset.zero;
    });
  }

  void _updateStickInputFromPointer(Offset pointerPosition) {
    final center = _floatingStickCenter;
    if (center == null) return;

    const double baseSize = _GardenControlsConfig.stickBaseSize;
    const double knobSize = _GardenControlsConfig.stickKnobSize;
    const double radius = (baseSize - knobSize) / 2;

    final delta = pointerPosition - center;
    final normalized = delta.distance > radius
        ? delta / delta.distance
        : delta / radius;
    final next = Offset(
      normalized.dx.clamp(-1.0, 1.0),
      normalized.dy.clamp(-1.0, 1.0),
    );
    if ((next - _stickInput).distanceSquared < 0.0001) return;
    setState(() {
      _stickInput = next;
    });
  }
}
