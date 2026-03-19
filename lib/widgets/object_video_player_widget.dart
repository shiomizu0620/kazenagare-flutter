import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class PlacedStageObject {
  final String objectId;
  final String imagePath;
  final String videoAssetPath;
  final bool isMyGarden;
  final int rewardCoins;
  final int playSignal;

  const PlacedStageObject({
    required this.objectId,
    required this.imagePath,
    required this.videoAssetPath,
    required this.isMyGarden,
    required this.rewardCoins,
    required this.playSignal,
  });
}

class ObjectVideoPlayerWidget extends StatefulWidget {
  final PlacedStageObject object;
  final double imageSize;
  final double videoSize;
  final ValueChanged<int>? onRewardEarned;

  const ObjectVideoPlayerWidget({
    super.key,
    required this.object,
    required this.imageSize,
    required this.videoSize,
    this.onRewardEarned,
  });

  @override
  State<ObjectVideoPlayerWidget> createState() =>
      _ObjectVideoPlayerWidgetState();
}

class _ObjectVideoPlayerWidgetState extends State<ObjectVideoPlayerWidget> {
  static const Duration _playDuration = Duration(milliseconds: 2400);

  VideoPlayerController? _videoController;
  bool _isPlayingVideo = false;
  bool _showCoinAnimation = false;

  @override
  void initState() {
    super.initState();
    _initVideoController();
  }

  @override
  void didUpdateWidget(covariant ObjectVideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.object.videoAssetPath != widget.object.videoAssetPath) {
      _disposeVideoController();
      _initVideoController();
      return;
    }

    if (widget.object.playSignal != oldWidget.object.playSignal) {
      _triggerPlayback();
    }
  }

  Future<void> _initVideoController() async {
    final controller = VideoPlayerController.asset(
      widget.object.videoAssetPath,
    );
    _videoController = controller;

    try {
      await controller.initialize();
      if (!mounted || _videoController != controller) return;
      await controller.setLooping(false);
      await controller.setVolume(0);
      setState(() {});
    } catch (_) {
      if (_videoController == controller) {
        _videoController = null;
      }
    }
  }

  Future<void> _triggerPlayback() async {
    final controller = _videoController;
    if (controller == null ||
        !controller.value.isInitialized ||
        _isPlayingVideo) {
      return;
    }

    setState(() {
      _isPlayingVideo = true;
      if (widget.object.isMyGarden) {
        _showCoinAnimation = true;
      }
    });

    if (widget.object.isMyGarden && widget.onRewardEarned != null) {
      widget.onRewardEarned!(widget.object.rewardCoins);
    }

    try {
      await controller.seekTo(Duration.zero);
      await controller.play();
    } catch (_) {
      // ignore and fallback to image after duration
    }

    Future<void>.delayed(_playDuration, () async {
      if (!mounted) return;
      try {
        await controller.pause();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _isPlayingVideo = false;
        _showCoinAnimation = false;
      });
    });
  }

  void _disposeVideoController() {
    _videoController?.dispose();
    _videoController = null;
  }

  @override
  void dispose() {
    _disposeVideoController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxSize = widget.imageSize > widget.videoSize
        ? widget.imageSize
        : widget.videoSize;

    return SizedBox(
      width: maxSize,
      height: maxSize,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _isPlayingVideo ? widget.videoSize : widget.imageSize,
            height: _isPlayingVideo ? widget.videoSize : widget.imageSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: _buildContent(),
          ),
          if (_showCoinAnimation)
            Positioned(
              top: -26,
              child: _RewardBubble(amount: widget.object.rewardCoins),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final controller = _videoController;

    if (_isPlayingVideo &&
        controller != null &&
        controller.value.isInitialized) {
      return FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      );
    }

    return Image.asset(widget.object.imagePath, fit: BoxFit.cover);
  }
}

class _RewardBubble extends StatelessWidget {
  final int amount;

  const _RewardBubble({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '+$amount コイン',
        style: const TextStyle(
          color: Color(0xFFFFE082),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
