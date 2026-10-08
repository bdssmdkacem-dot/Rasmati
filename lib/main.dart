import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const RasmatiApp());
}

const _ink = Color(0xFF253047);
const _purple = Color(0xFF7558E8);
const _mint = Color(0xFFBDF4D7);
const _paper = Color(0xFFFFFBF4);

class RasmatiApp extends StatelessWidget {
  const RasmatiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'رسوماتي',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: _paper,
        colorScheme: ColorScheme.fromSeed(seedColor: _purple),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: _paper,
          foregroundColor: _ink,
          elevation: 0,
          centerTitle: false,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _busy = false;

  Future<void> _chooseDrawing(ImageSource source) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 95,
        maxWidth: 2400,
        maxHeight: 2400,
      );
      if (!mounted || image == null) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AnimationStudio(imageFile: File(image.path)),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذّر فتح الصورة. حاول مرة أخرى.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_purple, Color(0xFF9C7BFF)],
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                            ),
                            borderRadius: BorderRadius.circular(17),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 27,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'رسوماتي',
                                style: TextStyle(
                                  color: _ink,
                                  fontSize: 25,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.6,
                                ),
                              ),
                              Text(
                                'كل رسمة لها حكاية',
                                style: TextStyle(
                                  color: Color(0xFF778095),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const _TinyBadge(),
                      ],
                    ),
                    const SizedBox(height: 28),
                    const _HeroCard(),
                    const SizedBox(height: 24),
                    const Text(
                      'لنبدأ المغامرة!',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'اختر رسمة من عالمك، ثم اختر الحركة التي تحبها.',
                      style: TextStyle(
                        color: Color(0xFF778095),
                        height: 1.5,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _PrimaryAction(
                      icon: Icons.camera_alt_rounded,
                      title: 'صوّر رسمة',
                      subtitle: 'استخدم كاميرا الهاتف',
                      onTap: _busy ? null : () => _chooseDrawing(ImageSource.camera),
                      loading: _busy,
                    ),
                    const SizedBox(height: 12),
                    _SecondaryAction(
                      icon: Icons.photo_library_rounded,
                      title: 'اختر من المعرض',
                      subtitle: 'استخدم صورة محفوظة',
                      onTap: _busy ? null : () => _chooseDrawing(ImageSource.gallery),
                    ),
                    const SizedBox(height: 26),
                    const Text(
                      'ماذا يمكنك أن تفعل؟',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Row(
                      children: [
                        Expanded(
                          child: _FeatureCard(
                            icon: Icons.brush_rounded,
                            color: Color(0xFFFFE4B9),
                            iconColor: Color(0xFFB56B20),
                            title: 'رسمة طفلك',
                            subtitle: 'احتفظ بألوانها',
                          ),
                        ),
                        SizedBox(width: 11),
                        Expanded(
                          child: _FeatureCard(
                            icon: Icons.animation_rounded,
                            color: Color(0xFFE8E0FF),
                            iconColor: _purple,
                            title: 'حركات ممتعة',
                            subtitle: 'اختر بنفسك',
                          ),
                        ),
                        SizedBox(width: 11),
                        Expanded(
                          child: _FeatureCard(
                            icon: Icons.lock_rounded,
                            color: Color(0xFFDDF6E8),
                            iconColor: Color(0xFF27855B),
                            title: 'خصوصية',
                            subtitle: 'على جهازك',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const Center(
                      child: Text(
                        'نسخة تجريبية • رسوماتك تبقى ملكك',
                        style: TextStyle(
                          color: Color(0xFF969CAE),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TinyBadge extends StatelessWidget {
  const _TinyBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFE9E3FF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'إبداع +',
        style: TextStyle(
          color: _purple,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(21, 23, 21, 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7659E8), Color(0xFF9276F5), Color(0xFFB49AFF)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: _purple.withValues(alpha: 0.20),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: -7,
            top: 0,
            child: Icon(
              Icons.auto_awesome,
              size: 32,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
          Positioned(
            right: 5,
            bottom: 4,
            child: Icon(
              Icons.star_rounded,
              size: 26,
              color: Colors.white.withValues(alpha: 0.45),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.17),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'مرحبًا أيها الفنان الصغير!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'حوّل خيالك\nإلى حركة!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 31,
                  height: 1.15,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'صوّر رسمتك واختر كيف تتحرك.',
                style: TextStyle(
                  color: Color(0xFFF3EFFF),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              const Row(
                children: [
                  _DoodleEmoji(emoji: '🦁', angle: -0.08),
                  SizedBox(width: 8),
                  _DoodleEmoji(emoji: '🚀', angle: 0.07),
                  SizedBox(width: 8),
                  _DoodleEmoji(emoji: '🐠', angle: -0.06),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DoodleEmoji extends StatelessWidget {
  const _DoodleEmoji({required this.emoji, required this.angle});

  final String emoji;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: 53,
        height: 53,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 30)),
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.loading = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return _ActionSurface(
      onTap: onTap,
      background: _purple,
      icon: icon,
      iconBackground: Colors.white.withValues(alpha: 0.16),
      iconColor: Colors.white,
      title: title,
      subtitle: subtitle,
      titleColor: Colors.white,
      subtitleColor: const Color(0xFFE9E2FF),
      trailing: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.arrow_back_rounded, color: Colors.white),
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  const _SecondaryAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _ActionSurface(
      onTap: onTap,
      background: Colors.white,
      icon: icon,
      iconBackground: const Color(0xFFEDE8FF),
      iconColor: _purple,
      title: title,
      subtitle: subtitle,
      titleColor: _ink,
      subtitleColor: const Color(0xFF858CA0),
      trailing: const Icon(Icons.arrow_back_rounded, color: _purple),
      border: Border.all(color: const Color(0xFFEDEAF3)),
    );
  }
}

class _ActionSurface extends StatelessWidget {
  const _ActionSurface({
    required this.onTap,
    required this.background,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.titleColor,
    required this.subtitleColor,
    required this.trailing,
    this.border,
  });

  final VoidCallback? onTap;
  final Color background;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Color titleColor;
  final Color subtitleColor;
  final Widget trailing;
  final Border? border;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: border,
          ),
          child: Row(
            children: [
              Container(
                width: 49,
                height: 49,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor, size: 25),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: titleColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(color: subtitleColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFF0EDF4)),
      ),
      child: Column(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 23),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ink,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF8A91A3), fontSize: 10),
          ),
        ],
      ),
    );
  }
}

enum DrawingMotion { bounce, walk, dance, wave, float }

extension DrawingMotionLabel on DrawingMotion {
  String get label {
    switch (this) {
      case DrawingMotion.bounce:
        return 'القفز';
      case DrawingMotion.walk:
        return 'المشي';
      case DrawingMotion.dance:
        return 'الرقص';
      case DrawingMotion.wave:
        return 'التلويح';
      case DrawingMotion.float:
        return 'الطفو';
    }
  }

  IconData get icon {
    switch (this) {
      case DrawingMotion.bounce:
        return Icons.south_rounded;
      case DrawingMotion.walk:
        return Icons.directions_walk_rounded;
      case DrawingMotion.dance:
        return Icons.music_note_rounded;
      case DrawingMotion.wave:
        return Icons.waving_hand_rounded;
      case DrawingMotion.float:
        return Icons.air_rounded;
    }
  }
}

class AnimationStudio extends StatefulWidget {
  const AnimationStudio({super.key, required this.imageFile});

  final File imageFile;

  @override
  State<AnimationStudio> createState() => _AnimationStudioState();
}

class _AnimationStudioState extends State<AnimationStudio>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  DrawingMotion _motion = DrawingMotion.bounce;
  bool _playing = true;
  int _backgroundIndex = 0;

  static const _backgrounds = [
    Color(0xFFFFF3D9),
    Color(0xFFE3F7EF),
    Color(0xFFECE6FF),
    Color(0xFFE3F1FF),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectMotion(DrawingMotion motion) {
    setState(() => _motion = motion);
    _controller
      ..reset()
      ..repeat(reverse: true);
  }

  Widget _animatedDrawing() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final wave = math.sin(t * math.pi * 2);
        double dy = 0;
        double dx = 0;
        double angle = 0;
        double scale = 1;

        switch (_motion) {
          case DrawingMotion.bounce:
            dy = -18 * t;
            scale = 1 + (0.025 * wave.abs());
          case DrawingMotion.walk:
            dx = 9 * wave;
            angle = 0.035 * wave;
          case DrawingMotion.dance:
            angle = 0.10 * wave;
            dy = -7 * wave.abs();
          case DrawingMotion.wave:
            angle = 0.045 * wave;
            dx = 3 * wave;
          case DrawingMotion.float:
            dy = -13 * wave;
            dx = 4 * math.cos(t * math.pi * 2);
        }

        return Transform.translate(
          offset: Offset(dx, dy),
          child: Transform.rotate(
            angle: angle,
            child: Transform.scale(
              scale: scale,
              child: child,
            ),
          ),
        );
      },
      child: Image.file(
        widget.imageFile,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.broken_image_outlined,
          size: 64,
          color: _ink,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'استوديو الحركة',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          actions: [
            IconButton(
              tooltip: _playing ? 'إيقاف الحركة' : 'تشغيل الحركة',
              onPressed: () {
                setState(() => _playing = !_playing);
                if (_playing) {
                  _controller.repeat(reverse: true);
                } else {
                  _controller.stop();
                }
              },
              icon: Icon(_playing ? Icons.pause_circle : Icons.play_circle),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'رسمتك تتحرك!',
                            style: TextStyle(
                              color: _ink,
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'جرّب الحركات واختر ما يعجبك',
                            style: TextStyle(
                              color: Color(0xFF7C8497),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F7ED),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Color(0xFF30966A),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _backgrounds[_backgroundIndex],
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        Positioned(
                          top: 17,
                          right: 17,
                          child: Icon(
                            Icons.auto_awesome,
                            color: _purple.withValues(alpha: 0.35),
                          ),
                        ),
                        Positioned(
                          bottom: 18,
                          left: 17,
                          child: Icon(
                            Icons.star_rounded,
                            size: 29,
                            color: _purple.withValues(alpha: 0.25),
                          ),
                        ),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: _animatedDrawing(),
                          ),
                        ),
                        Positioned(
                          right: 14,
                          bottom: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.88),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _motion.label,
                              style: const TextStyle(
                                color: _ink,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'اختر الحركة',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 83,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: DrawingMotion.values.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 9),
                        itemBuilder: (context, index) {
                          final motion = DrawingMotion.values[index];
                          final selected = motion == _motion;
                          return InkWell(
                            onTap: () => _selectMotion(motion),
                            borderRadius: BorderRadius.circular(18),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 76,
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: selected ? _purple : Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: selected
                                      ? _purple
                                      : const Color(0xFFE9E5F0),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    motion.icon,
                                    color: selected ? Colors.white : _ink,
                                    size: 23,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    motion.label,
                                    style: TextStyle(
                                      color: selected ? Colors.white : _ink,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'الخلفية',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: List.generate(_backgrounds.length, (index) {
                        final selected = _backgroundIndex == index;
                        return GestureDetector(
                          onTap: () => setState(() => _backgroundIndex = index),
                          child: Container(
                            margin: const EdgeInsetsDirectional.only(end: 10),
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: _backgrounds[index],
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected ? _purple : Colors.white,
                                width: selected ? 3 : 2,
                              ),
                            ),
                            child: selected
                                ? const Icon(
                                    Icons.check,
                                    size: 17,
                                    color: _ink,
                                  )
                                : null,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'حفظ الحركة كفيديو قيد التطوير في النسخة التجريبية.',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.video_library_rounded),
                        label: const Text('حفظ كفيديو — قريبًا'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFE9E4F8),
                          foregroundColor: _purple,
                          disabledBackgroundColor: const Color(0xFFE9E4F8),
                          minimumSize: const Size.fromHeight(53),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
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
}
