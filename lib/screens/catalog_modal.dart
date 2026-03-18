import 'dart:ui';
import 'package:flutter/material.dart';

class SoundObject {
  final String id;
  final String name;
  final String imagePath;
  final String description;
  final int rewardCoins;
  final bool isUnlocked;
  final String effectType;

  const SoundObject({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.description,
    required this.rewardCoins,
    required this.isUnlocked,
    required this.effectType,
  });
}

class CatalogModal extends StatefulWidget {
  const CatalogModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CatalogModal(),
    );
  }

  @override
  State<CatalogModal> createState() => _CatalogModalState();
}

class _CatalogModalState extends State<CatalogModal> {
  static const String _title = '風の音コレクション 和の音オブジェクト図鑑';
  static String? _lastSelectedId;

  final List<SoundObject> _objects = const [
    SoundObject(
      id: 'huurin',
      name: '風鈴',
      imagePath: 'assets/images/objects/huurine.png',
      description: '声を軽く高域寄りに整え、鈴の余韻を重ねる音色です。',
      rewardCoins: 22,
      isUnlocked: true,
      effectType: 'bright_chime',
    ),
    SoundObject(
      id: 'semi',
      name: '蝉',
      imagePath: 'assets/images/objects/semie.png',
      description: '夏の空気感を含んだ細かな周期ノイズを付与します。',
      rewardCoins: 16,
      isUnlocked: true,
      effectType: 'cicada_noise',
    ),
    SoundObject(
      id: 'shishi-odoshi',
      name: 'ししおどし',
      imagePath: 'assets/images/objects/sisiodosie.png',
      description: '低域に木の打音を重ね、間を活かした和風パーカッション化。',
      rewardCoins: 20,
      isUnlocked: false,
      effectType: 'wood_click',
    ),
    SoundObject(
      id: 'kane',
      name: '鐘',
      imagePath: 'assets/images/objects/kanee.png',
      description: 'アタックを丸めたうえで鐘の倍音成分を加えます。',
      rewardCoins: 24,
      isUnlocked: false,
      effectType: 'temple_bell',
    ),
    SoundObject(
      id: 'mattya',
      name: '抹茶',
      imagePath: 'assets/images/objects/mattyae.png',
      description: '中高域を穏やかにし、柔らかな布フィルタを適用します。',
      rewardCoins: 14,
      isUnlocked: true,
      effectType: 'soft_filter',
    ),
    SoundObject(
      id: 'takibi',
      name: '焚き火',
      imagePath: 'assets/images/objects/takibie.png',
      description: '低域に火のはぜる粒立ちを追加し温かい質感へ。',
      rewardCoins: 18,
      isUnlocked: false,
      effectType: 'fire_crackle',
    ),
    SoundObject(
      id: 'kaeru',
      name: '蛙',
      imagePath: 'assets/images/objects/kaerue.png',
      description: '低めのうねりを重ね、湿度感のある鳴きの揺れを作ります。',
      rewardCoins: 19,
      isUnlocked: true,
      effectType: 'frog_wobble',
    ),
    SoundObject(
      id: 'hanabi',
      name: '花火',
      imagePath: 'assets/images/objects/hanabie.png',
      description: '高域に拡散ディレイを加え、夜空に散るような響きを作成。',
      rewardCoins: 28,
      isUnlocked: false,
      effectType: 'spark_delay',
    ),
    SoundObject(
      id: 'suzume',
      name: '雀',
      imagePath: 'assets/images/objects/suzumee.png',
      description: '短いピッチ変動で軽快なさえずり感を付けます。',
      rewardCoins: 17,
      isUnlocked: false,
      effectType: 'chirp_pitch',
    ),
    SoundObject(
      id: 'obake',
      name: 'お化け',
      imagePath: 'assets/images/objects/obakee.png',
      description: 'フォルマントを下げて怪異感のあるボイスに変換。',
      rewardCoins: 30,
      isUnlocked: true,
      effectType: 'ghost_formant',
    ),
    SoundObject(
      id: 'akimusi',
      name: '秋虫',
      imagePath: 'assets/images/objects/akimusie.png',
      description: '細い高域トレモロで秋の夜らしい気配を追加。',
      rewardCoins: 15,
      isUnlocked: true,
      effectType: 'autumn_tremolo',
    ),
    SoundObject(
      id: 'hagoita',
      name: '羽子板',
      imagePath: 'assets/images/objects/hagoitae.png',
      description: '木と羽根の乾いた反射音をリズミカルに重ねます。',
      rewardCoins: 21,
      isUnlocked: true,
      effectType: 'bat_hit',
    ),
    SoundObject(
      id: 'haka',
      name: '墓',
      imagePath: 'assets/images/objects/hakae.png',
      description: '残響を長めに設定し、石室のような空間を演出。',
      rewardCoins: 23,
      isUnlocked: true,
      effectType: 'stone_reverb',
    ),
    SoundObject(
      id: 'hue',
      name: '笛',
      imagePath: 'assets/images/objects/huee.png',
      description: '鼻腔寄りの倍音を持ち上げ、和笛ライクな音色へ。',
      rewardCoins: 20,
      isUnlocked: true,
      effectType: 'flute_formant',
    ),
    SoundObject(
      id: 'huro',
      name: '風呂',
      imagePath: 'assets/images/objects/huroe.png',
      description: '浴室反射を模した短い多段リバーブを適用。',
      rewardCoins: 12,
      isUnlocked: true,
      effectType: 'bath_reverb',
    ),
    SoundObject(
      id: 'ka',
      name: '蚊',
      imagePath: 'assets/images/objects/kae.png',
      description: '高周波のうなりを薄く追加し耳元感を演出。',
      rewardCoins: 11,
      isUnlocked: true,
      effectType: 'mosquito_whine',
    ),
    SoundObject(
      id: 'kame',
      name: '亀',
      imagePath: 'assets/images/objects/kamee.png',
      description: '低速モジュレーションで重心の低い鳴りに寄せます。',
      rewardCoins: 13,
      isUnlocked: true,
      effectType: 'slow_wobble',
    ),
    SoundObject(
      id: 'sansin',
      name: '三線',
      imagePath: 'assets/images/objects/sansine.png',
      description: '胴鳴り感のある中域を強調した弦系テイスト。',
      rewardCoins: 25,
      isUnlocked: true,
      effectType: 'sanshin_string',
    ),
    SoundObject(
      id: 'saru',
      name: '猿',
      imagePath: 'assets/images/objects/sarue.png',
      description: '歪みを抑えつつ跳ねるような中高域を付与。',
      rewardCoins: 17,
      isUnlocked: true,
      effectType: 'playful_peak',
    ),
    SoundObject(
      id: 'suzu',
      name: '鈴',
      imagePath: 'assets/images/objects/suzue.png',
      description: '金属の短い余韻を重ねて明るいトーンに補正。',
      rewardCoins: 18,
      isUnlocked: true,
      effectType: 'small_bell',
    ),
    SoundObject(
      id: 'tako',
      name: '凧',
      imagePath: 'assets/images/objects/takoe.png',
      description: '風切り成分を追加し、空を切るような質感へ。',
      rewardCoins: 16,
      isUnlocked: true,
      effectType: 'wind_slice',
    ),
    SoundObject(
      id: 'tyoutyo',
      name: '蝶々',
      imagePath: 'assets/images/objects/tyoutyoe.png',
      description: '左右に揺れるパンニングで羽ばたきの軽さを表現。',
      rewardCoins: 19,
      isUnlocked: true,
      effectType: 'flutter_pan',
    ),
    SoundObject(
      id: 'youko',
      name: '妖狐',
      imagePath: 'assets/images/objects/youkoe.png',
      description: '神秘的な広がりを持つ深いリバーブを適用します。',
      rewardCoins: 32,
      isUnlocked: true,
      effectType: 'mystic_tail',
    ),
  ];

  SoundObject? _selectedObject;

  @override
  void initState() {
    super.initState();
    _selectedObject = _resolveInitialSelection();
  }

  SoundObject _resolveInitialSelection() {
    if (_objects.isEmpty) {
      throw StateError('Sound objects must not be empty.');
    }

    final savedId = _lastSelectedId;
    if (savedId != null) {
      final index = _objects.indexWhere((o) => o.id == savedId);
      if (index >= 0) return _objects[index];
    }
    return _objects.first;
  }

  void _selectObject(SoundObject object) {
    setState(() {
      _selectedObject = object;
      _lastSelectedId = object.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final modalHeight = media.size.height * 0.92;
    final selected = _selectedObject;
    if (selected == null) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _title,
                        style: const TextStyle(
                          color: Color(0xFFF8E8CC),
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Noto Serif JP',
                          height: 1.25,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('閉じる'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFF3E6D1),
                        side: BorderSide(
                          color: const Color(0xFFE0C9A5).withValues(alpha: 0.7),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Divider(
                color: const Color(0xFFD4BA93).withValues(alpha: 0.3),
                height: 1,
                indent: 24,
                endIndent: 24,
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 880;
                      if (isWide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 4,
                              child: _buildDetailPanel(selected),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              flex: 5,
                              child: _buildGridPanel(isWide: true),
                            ),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          _buildDetailPanel(selected),
                          const SizedBox(height: 12),
                          Expanded(child: _buildGridPanel(isWide: false)),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailPanel(SoundObject selected) {
    final isUnlocked = selected.isUnlocked;
    final displayName = isUnlocked ? selected.name : '？？？';
    final description = isUnlocked ? selected.description : '未解放です';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2118),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF9D7B55).withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4D3A2C),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '1回の再生報酬: ${selected.rewardCoins}コイン',
                  style: const TextStyle(
                    color: Color(0xFFF0DDC1),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF6F5A45),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  '試作中',
                  style: TextStyle(
                    color: Color(0xFFF6EAD7),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Center(
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE9DCC8),
                border: Border.all(color: const Color(0xFFA07A4D), width: 2),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    selected.imagePath,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                    color: isUnlocked
                        ? null
                        : Colors.black.withValues(alpha: 0.5),
                    colorBlendMode: isUnlocked ? null : BlendMode.srcATop,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: Color(0x8A5A4735),
                          size: 34,
                        ),
                      );
                    },
                  ),
                  if (!isUnlocked)
                    const Center(
                      child: Icon(
                        Icons.lock_rounded,
                        color: Color(0xFFEDE0CD),
                        size: 32,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              displayName,
              style: const TextStyle(
                color: Color(0xFFF7E8D0),
                fontSize: 22,
                fontWeight: FontWeight.w700,
                fontFamily: 'Noto Serif JP',
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF433023),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFD6BB92).withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              description,
              style: const TextStyle(
                color: Color(0xFFF1E5D3),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'エフェクトID: ${selected.effectType}',
            style: TextStyle(
              color: const Color(0xFFE0C9A5).withValues(alpha: 0.82),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridPanel({required bool isWide}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2D2118),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF9D7B55).withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'オブジェクト サムネイルを押して詳細を切り替え',
              style: TextStyle(
                color: Color(0xFFF5E7D0),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: GridView.builder(
                itemCount: _objects.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isWide ? 4 : 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.84,
                ),
                itemBuilder: (context, index) {
                  final object = _objects[index];
                  final selected = _selectedObject?.id == object.id;
                  return _buildObjectTile(object: object, selected: selected);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildObjectTile({
    required SoundObject object,
    required bool selected,
  }) {
    final isUnlocked = object.isUnlocked;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _selectObject(object),
      child: Ink(
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF4D3A2C) : const Color(0xFF3B2C22),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? const Color(0xFFE6C898)
                : const Color(0xFF8C6D4B).withValues(alpha: 0.45),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFE8D6B7),
                    border: Border.all(color: const Color(0xFFA07A4D)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        object.imagePath,
                        fit: BoxFit.cover,
                        color: isUnlocked
                            ? null
                            : Colors.black.withValues(alpha: 0.55),
                        colorBlendMode: isUnlocked ? null : BlendMode.srcATop,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.image_not_supported_outlined,
                            color: Color(0x8A5A4735),
                            size: 18,
                          );
                        },
                      ),
                      if (!isUnlocked)
                        const Align(
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.lock_rounded,
                            color: Color(0xFFECE0CD),
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isUnlocked ? object.name : '？？？',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isUnlocked
                      ? const Color(0xFFF4E6CF)
                      : const Color(0xAAA48A6F),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
