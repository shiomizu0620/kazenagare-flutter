import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'catalog_modal.dart'; // ←追加
import 'options_modal.dart'; // ←これを追加

class _GardenControlsConfig {
  static const double moveSpeedPerSecond = 300;
  static const double stickBaseSize = 120;
  static const double stickKnobSize = 44;
  static const double stickPadding = 16;
}

class GardenScreen extends StatefulWidget {
  final String seasonId;

  const GardenScreen({super.key, this.seasonId = 'spring'});

  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen>
    with SingleTickerProviderStateMixin {
  static const Map<String, String> _seasonBackgroundAssets = {
    'spring': 'assets/images/庭-春.png',
    'summer': 'assets/images/庭-夏.png',
    'autumn': 'assets/images/庭-秋.png',
    'winter': 'assets/images/庭-冬.png',
  };

  String get _gardenBackgroundAsset =>
      _seasonBackgroundAssets[widget.seasonId] ??
      _seasonBackgroundAssets['spring']!;

  // 庭のワールドサイズ（背景画像の論理サイズ）
  static const double _logicalGardenWidth = 2000.0;
  static const double _logicalGardenHeight = 1500.0;
  static const double _zoom = 1.6;

  // 仮のプレイヤー座標（ワールド座標）
  double _playerX = _logicalGardenWidth / 2;
  double _playerY = _logicalGardenHeight / 2;
  final ValueNotifier<Offset> _cameraPosition = ValueNotifier(Offset.zero);

  // 画面サイズ（ドラッグ時の移動制限計算で使用）
  Size _viewportSize = Size.zero;

  bool _didPrecache = false;

  final FocusNode _keyboardFocusNode = FocusNode();
  late final Ticker _movementTicker;
  Duration _lastTickElapsed = Duration.zero;

  bool _moveUp = false;
  bool _moveDown = false;
  bool _moveLeft = false;
  bool _moveRight = false;

  Offset _stickInput = Offset.zero;

  @override
  void initState() {
    super.initState();
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
  }

  @override
  void dispose() {
    _movementTicker.dispose();
    _cameraPosition.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrecache) return;
    _didPrecache = true;
    precacheImage(AssetImage(_gardenBackgroundAsset), context);
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

  void _movePlayerByDelta(double deltaX, double deltaY) {
    if (_viewportSize == Size.zero) return;

    final bounds = _cameraBounds(_viewportSize);

    final nextX = (_playerX + deltaX).clamp(bounds.minX, bounds.maxX);
    final nextY = (_playerY + deltaY).clamp(bounds.minY, bounds.maxY);
    if (nextX == _playerX && nextY == _playerY) return;

    _playerX = nextX;
    _playerY = nextY;
    _cameraPosition.value = Offset(_playerX, _playerY);
  }

  void _tickMovement(double deltaSeconds) {
    if (!mounted || _viewportSize == Size.zero) return;
    if (deltaSeconds <= 0) return;

    final keyboardInput = Offset(
      ((_moveRight ? 1 : 0) - (_moveLeft ? 1 : 0)).toDouble(),
      ((_moveDown ? 1 : 0) - (_moveUp ? 1 : 0)).toDouble(),
    );

    final input = keyboardInput.distanceSquared > 0
        ? keyboardInput
        : _stickInput;
    if (input.distanceSquared == 0) return;

    final normalized = input.distance > 1 ? input / input.distance : input;
    final step = _GardenControlsConfig.moveSpeedPerSecond * deltaSeconds;
    _movePlayerByDelta(normalized.dx * step, normalized.dy * step);
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
            buildChip('あなた'), // TODO: Supabaseから取得したユーザー名に変更
            buildChip('わたしの庭'), // TODO: 庭の名前に変更
            buildChip('季節: $_seasonLabel'),
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
                onPressed: () {
                  CatalogModal.show(context);
                },
              ),
              const SizedBox(width: 8),
              // 右上：オプションボタン
              buildCircleButton(
                icon: Icons.settings_rounded,
                tooltip: 'オプション',
                onPressed: () {
                  OptionsModal.show(context, isMe: true);
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
          final mobileControls = _isMobileControls(_viewportSize);

          return Focus(
            focusNode: _keyboardFocusNode,
            autofocus: true,
            onKeyEvent: _handleKeyEvent,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _keyboardFocusNode.requestFocus(),
              child: Stack(
                children: [
                  // 1) 背景: 庭全体画像を拡大した上で、カメラ位置に応じてずらして表示
                  ValueListenableBuilder<Offset>(
                    valueListenable: _cameraPosition,
                    builder: (context, camera, _) {
                      final bounds = _cameraBounds(_viewportSize);
                      final cameraX = camera.dx.clamp(bounds.minX, bounds.maxX);
                      final cameraY = camera.dy.clamp(bounds.minY, bounds.maxY);

                      final backgroundLeft =
                          -(cameraX * _zoom - _viewportSize.width / 2);
                      final backgroundTop =
                          -(cameraY * _zoom - _viewportSize.height / 2);

                      return Positioned(
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
                      );
                    },
                  ),

                  // 2) 中央固定の仮キャラクター
                  Align(
                    alignment: Alignment.center,
                    child: _buildPlayerCharacter(),
                  ),

                  // 3) HUD: 新しいUI群

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
                  if (mobileControls)
                    Positioned(
                      right: _GardenControlsConfig.stickPadding,
                      bottom: _GardenControlsConfig.stickPadding,
                      child: _buildVirtualStick(),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlayerCharacter() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFB2EBF2), Color(0xFF80DEEA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              '旅',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0B1A21),
              ),
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

  Widget _buildVirtualStick() {
    const double baseSize = _GardenControlsConfig.stickBaseSize;
    const double knobSize = _GardenControlsConfig.stickKnobSize;
    const double radius = (baseSize - knobSize) / 2;

    return GestureDetector(
      onPanStart: (details) {
        _updateStickInput(details.localPosition, baseSize, radius);
      },
      onPanUpdate: (details) {
        _updateStickInput(details.localPosition, baseSize, radius);
      },
      onPanEnd: (_) {
        setState(() {
          _stickInput = Offset.zero;
        });
      },
      onPanCancel: () {
        setState(() {
          _stickInput = Offset.zero;
        });
      },
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
    );
  }

  void _updateStickInput(Offset localPosition, double baseSize, double radius) {
    final center = Offset(baseSize / 2, baseSize / 2);
    final delta = localPosition - center;
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
