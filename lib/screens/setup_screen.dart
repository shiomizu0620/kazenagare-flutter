import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/setup_local_storage.dart';
import 'garden_screen.dart';

// --- データモデル（変更なし） ---
class SeasonUiMeta {
  final String id;
  final String name;
  final String icon;
  final String copy;
  final List<Color> accentGradient;
  final Color shadowColor;
  final Color baseColor;

  const SeasonUiMeta({
    required this.id,
    required this.name,
    required this.icon,
    required this.copy,
    required this.accentGradient,
    required this.shadowColor,
    required this.baseColor,
  });
}

const List<SeasonUiMeta> _seasons = [
  SeasonUiMeta(
    id: 'spring',
    name: '春',
    icon: '🌸',
    copy: 'やわらかな光と花の気配で、軽やかな庭になります。',
    accentGradient: [Color(0xFFFDA4AF), Color(0xFFFDE68A)],
    shadowColor: Color(0x40FDA4AF),
    baseColor: Color(0xFFFFF1F2),
  ),
  SeasonUiMeta(
    id: 'summer',
    name: '夏',
    icon: '🌿',
    copy: '青々とした空気感で、瑞々しく澄んだ印象になります。',
    accentGradient: [Color(0xFF6EE7B7), Color(0xFFD9F99D)],
    shadowColor: Color(0x406EE7B7),
    baseColor: Color(0xFFECFDF5),
  ),
  SeasonUiMeta(
    id: 'autumn',
    name: '秋',
    icon: '🍁',
    copy: '落ち着いた色合いで、しっとりと深みのある庭になります。',
    accentGradient: [Color(0xFFFCD34D), Color(0xFFFDBA74)],
    shadowColor: Color(0x40FCD34D),
    baseColor: Color(0xFFFFFBEB),
  ),
  SeasonUiMeta(
    id: 'winter',
    name: '冬',
    icon: '❄️',
    copy: '静寂と透明感を強めた、凛とした庭になります。',
    accentGradient: [Color(0xFF7DD3FC), Color(0xFF93C5FD)],
    shadowColor: Color(0x407DD3FC),
    baseColor: Color(0xFFF0F9FF),
  ),
];

class GardenSetupScreen extends StatefulWidget {
  const GardenSetupScreen({super.key});

  @override
  State<GardenSetupScreen> createState() => _GardenSetupScreenState();
}

class _GardenSetupScreenState extends State<GardenSetupScreen> {
  final GardenSetupLocalStorage _localStorage = GardenSetupLocalStorage();

  final _nameController = TextEditingController();

  // 👇 1. スクロール状態を管理するコントローラーを追加
  final ScrollController _scrollController = ScrollController();

  String _selectedSeasonId = 'spring';
  bool _isSubmitting = false;

  static const int _maxNameLength = 12;
  static const Color _waBlack = Color(0xFF1C1C1E);

  SeasonUiMeta get _selectedSeason =>
      _seasons.firstWhere((s) => s.id == _selectedSeasonId);

  @override
  void initState() {
    super.initState();
    _restoreFromLocalStorage();
  }

  Future<void> _restoreFromLocalStorage() async {
    final saved = await _localStorage.load();

    if (!mounted) return;
    setState(() {
      if (saved.seasonId != null && _seasons.any((s) => s.id == saved.seasonId)) {
        _selectedSeasonId = saved.seasonId!;
      }
      if (saved.name != null && saved.name!.isNotEmpty) {
        _nameController.text = saved.name!;
      }
    });
  }

  Future<void> _saveToLocalStorage({String? name, String? seasonId}) {
    return _localStorage.save(
      name: name ?? _nameController.text,
      seasonId: seasonId ?? _selectedSeasonId,
    );
  }

  // 👇 2. メモリリークを防ぐため、画面が破棄される時にコントローラーも破棄
  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleProceed() async {
    if (_isSubmitting) return;

    final trimmedName = _nameController.text.trim();
    if (trimmedName.isEmpty) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('旅人よ、名を記してください。'),
          backgroundColor: Color.fromARGB(221, 247, 247, 247),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);

    await _saveToLocalStorage(name: trimmedName, seasonId: _selectedSeasonId);

    // TODO: Supabaseへの保存処理
    await Future.delayed(const Duration(seconds: 1)); // モック

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$trimmedNameさん、${_selectedSeason.name}の庭へ移動します'),
        backgroundColor: _selectedSeason.accentGradient[0],
        behavior: SnackBarBehavior.floating,
      ),
    );

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => GardenScreen(seasonId: _selectedSeasonId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(color: _selectedSeason.baseColor),
        child: Stack(
          children: [
            _buildAnimatedBackgroundOrbs(),

            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: const SizedBox(),
              ),
            ),

            SafeArea(
              // 👇 3. RawScrollbar でスクロールビューをラップし、デザインを調整
              child: RawScrollbar(
                controller: _scrollController,
                thumbVisibility: true, // 常にスクロールバーを表示
                thickness: 6.0, // 少し細めでスタイリッシュに
                radius: const Radius.circular(10), // 丸みを持たせる
                thumbColor: _waBlack.withValues(
                  alpha: 0.25,
                ), // 半透明の黒で悪目立ちしないように
                fadeDuration: const Duration(milliseconds: 300),
                child: CustomScrollView(
                  controller: _scrollController, // コントローラーを紐付け
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverAppBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      centerTitle: true,
                      title: Column(
                        children: [
                          const Text(
                            '庭園の準備',
                            style: TextStyle(
                              color: _waBlack,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          Text(
                            '風の便りを待つ場所',
                            style: TextStyle(
                              color: _waBlack.withValues(alpha: 0.5),
                              fontSize: 11,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 16.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildNameInputSection(),
                            const SizedBox(height: 32),
                            const Text(
                              '季節の気配',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _waBlack,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildSeasonGrid(),
                            const SizedBox(height: 48),
                            _buildSubmitButton(),
                            const SizedBox(height: 32), // 一番下までスクロールできるように余白を確保
                          ],
                        ),
                      ),
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

  Widget _buildAnimatedBackgroundOrbs() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeInOut,
      top: _selectedSeasonId == 'spring' || _selectedSeasonId == 'summer'
          ? -100
          : 100,
      right: _selectedSeasonId == 'autumn' ? -50 : -100,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 800),
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              _selectedSeason.accentGradient[0].withValues(alpha: 0.6),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameInputSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'お名前',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _waBlack,
                ),
              ),
              Text(
                '${_nameController.text.length}/$_maxNameLength',
                style: TextStyle(
                  fontSize: 12,
                  color: _waBlack.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
          TextField(
            controller: _nameController,
            maxLength: _maxNameLength,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: _waBlack,
            ),
            decoration: InputDecoration(
              hintText: '例: 風流 太郎',
              hintStyle: TextStyle(color: _waBlack.withValues(alpha: 0.2)),
              counterText: '',
              border: InputBorder.none,
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: _selectedSeason.accentGradient[0],
                  width: 2,
                ),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: _waBlack.withValues(alpha: 0.1)),
              ),
            ),
            onChanged: (value) {
              setState(() {});
              _saveToLocalStorage(name: value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonGrid() {
    return Column(
      children: _seasons.map((season) {
        final isSelected = season.id == _selectedSeasonId;

        return GestureDetector(
          onTap: () async {
            if (!isSelected) {
              HapticFeedback.selectionClick();
              setState(() => _selectedSeasonId = season.id);
              await _saveToLocalStorage(seasonId: season.id);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.only(bottom: 16),
            transform: Matrix4.translationValues(0, isSelected ? -4 : 0, 0),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? season.accentGradient[0] : Colors.white,
                width: isSelected ? 2 : 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: season.shadowColor,
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ]
                  : [],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? season.baseColor
                          : Colors.white.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      season.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          season.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: _waBlack,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          season.copy,
                          style: TextStyle(
                            fontSize: 12,
                            color: _waBlack.withValues(
                              alpha: isSelected ? 0.8 : 0.5,
                            ),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    FadeTransition(
                      opacity: const AlwaysStoppedAnimation(1.0),
                      child: Icon(
                        Icons.check_circle,
                        color: season.accentGradient[0],
                        size: 24,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSubmitButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(colors: _selectedSeason.accentGradient),
        boxShadow: [
          BoxShadow(
            color: _selectedSeason.shadowColor,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: _isSubmitting ? null : _handleProceed,
          child: Center(
            child: _isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                : const Text(
                    'この景色で庭へ向かう',
                    style: TextStyle(
                      color: _waBlack,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
