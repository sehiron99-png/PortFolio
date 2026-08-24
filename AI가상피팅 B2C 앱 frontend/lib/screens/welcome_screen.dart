import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/fitting_provider.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _shimmerController;

  late Animation<double> _fadeLogo;
  late Animation<Offset> _slideLogo;

  late Animation<double> _fadeSubtitle;
  late Animation<Offset> _slideSubtitle;

  late Animation<double> _fadeButton;
  late Animation<Offset> _slideButton;

  String _selectedLanguage = '한국어';

  final Map<String, String> _languages = {
    '한국어': '🇰🇷 한국어',
    'English': '🇺🇸 English',
    '中文': '🇨🇳 中文',
    '日本語': '🇯🇵 日本語',
  };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000), // 총 2초 동안 진행
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    // 1. 로고 (0% ~ 40% 구간)
    _fadeLogo = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic)),
    );
    _slideLogo =
        Tween<Offset>(begin: const Offset(0, -1.0), end: Offset.zero).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic)),
    );

    // 2. 부제목 텍스트 (30% ~ 70% 구간 - 살짝 겹치게 시작)
    _fadeSubtitle = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic)),
    );
    _slideSubtitle =
        Tween<Offset>(begin: const Offset(0, -1.0), end: Offset.zero).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic)),
    );

    // 3. 시작하기 버튼 (60% ~ 100% 구간)
    _fadeButton = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic)),
    );
    _slideButton =
        Tween<Offset>(begin: const Offset(0, -1.0), end: Offset.zero).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic)),
    );

    // 강제로 폰트를 한 번 호출하여 로딩 큐에 넣음 (이래야 pendingFonts가 제대로 기다림)
    GoogleFonts.greatVibes();

    // 폰트가 완전히 로드된 후에 애니메이션을 시작하여 기본 폰트가 깜빡이는 현상(FOUT) 방지
    GoogleFonts.pendingFonts().then((value) {
      if (mounted) {
        _controller.forward();
      }
    }).catchError((e) {
      if (mounted) {
        _controller.forward(); // 폰트 로드 실패 시에도 애니메이션은 진행
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FittingProvider>(context, listen: false);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 고급스러운 패션 화보 이미지 배경
          Image.network(
            'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?q=80&w=2070&auto=format&fit=crop',
            fit: BoxFit.cover,
          ),
          // 왓챠 스타일의 어두운 반투명 오버레이
          Container(
            color: Colors.black.withValues(alpha: 0.55),
          ),

          // 반짝이 떨어지는 효과
          FallingSparklesEffect(animation: _controller),

          // 전경 컨텐츠
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: PopupMenuButton<String>(
                      initialValue: _selectedLanguage,
                      onSelected: (String value) {
                        setState(() {
                          _selectedLanguage = value;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  '언어가 $_selectedLanguage(으)로 변경되었습니다. (UI 적용은 준비 중입니다)')),
                        );
                      },
                      color: Colors.black87,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      offset: const Offset(0, 40),
                      itemBuilder: (BuildContext context) {
                        return _languages.keys.map((String key) {
                          return PopupMenuItem<String>(
                            value: key,
                            child: Text(
                              _languages[key]!,
                              style: TextStyle(
                                color: _selectedLanguage == key
                                    ? Colors.white
                                    : Colors.white70,
                                fontWeight: _selectedLanguage == key
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          );
                        }).toList();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.language,
                                color: Colors.white70, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              _languages[_selectedLanguage]!,
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down,
                                color: Colors.white70, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Spacer(flex: 2),

                  // 순차적 애니메이션 (로고 -> 부제목 -> 버튼)
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. 중앙 로고 (고급스러운 필기체 + 하얀 뒷그림자)
                      FadeTransition(
                        opacity: _fadeLogo,
                        child: SlideTransition(
                          position: _slideLogo,
                          child: AnimatedBuilder(
                            animation: _shimmerController,
                            builder: (context, child) {
                              // Shine sweeps from left to right over the animation duration repeatedly
                              double xOffset =
                                  -1.5 + (_shimmerController.value * 3.0);

                              return ShaderMask(
                                blendMode: BlendMode.srcATop,
                                shaderCallback: (bounds) {
                                  return LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      const Color(0xFFFFF5D1).withValues(
                                          alpha:
                                              0.8), // Premium gold/white shine
                                      Colors.transparent,
                                    ],
                                    stops: const [0.0, 0.5, 1.0],
                                    begin: Alignment(xOffset - 0.5, -0.5),
                                    end: Alignment(xOffset + 0.5, 0.5),
                                  ).createShader(bounds);
                                },
                                child: Text(
                                  'Lumière',
                                  style: GoogleFonts.greatVibes(
                                    fontSize: 84,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white,
                                    shadows: [
                                      Shadow(
                                        color: Colors.white.withValues(
                                            alpha: 0.6), // Glow effect
                                        blurRadius: 16,
                                        offset: const Offset(0, 0),
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2. 부제목 텍스트
                      FadeTransition(
                        opacity: _fadeSubtitle,
                        child: SlideTransition(
                          position: _slideSubtitle,
                          child: const Text(
                            '나만의 스타일을 찾아 떠나는 여행',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Colors.white70,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),

                      const SizedBox(height: 60), // Spacer 대신 명시적 간격

                      // 3. 중앙 로고 아래에 배치될 시작하기 버튼 (비율 유지하며 전체 크기 확대 + 드롭 섀도우)
                      FadeTransition(
                        opacity: _fadeButton,
                        child: SlideTransition(
                          position: _slideButton,
                          child: Center(
                            child: Container(
                              width: 280, // 기존 220에서 비율 맞춰 확대
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(40),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: 0.5), // 부드러운 그림자 색상
                                    blurRadius: 20, // 그림자가 퍼지는 정도
                                    spreadRadius: 2, // 그림자 크기
                                    offset: const Offset(
                                        0, 10), // 그림자 위치 (아래로 10만큼)
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () => provider.setScreen('login'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 26), // 기존 22에서 비율 맞춰 확대
                                  elevation:
                                      0, // Container의 그림자를 사용하기 위해 버튼 기본 그림자는 0으로 설정
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(40), // 모서리 라운드
                                  ),
                                ),
                                child: const Text(
                                  '시작하기',
                                  style: TextStyle(
                                    fontSize: 20, // 기존 16에서 확대
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Spacer(flex: 2), // 하단에 Spacer를 추가해 버튼을 더 중앙 쪽으로 밀어올림
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FallingSparklesEffect extends StatelessWidget {
  final Animation<double> animation;

  const FallingSparklesEffect({super.key, required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        // Run animation for longer (0.0 to 0.8, which is 1.6 seconds)
        double t = (animation.value / 0.8).clamp(0.0, 1.0);
        if (t == 1.0 || t == 0.0) return const SizedBox.shrink();

        return CustomPaint(
          size: Size.infinite,
          painter: _FallingSparklesPainter(progress: t),
        );
      },
    );
  }
}

class _FallingSparklesPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final math.Random random = math.Random(42);

  _FallingSparklesPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Fade in gracefully, fade out at the very end (0.8~1.0)
    double opacity = 1.0;
    if (progress < 0.15) opacity = progress / 0.15;
    if (progress > 0.8) opacity = (1.0 - progress) / 0.2;

    final Paint paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity * 0.9);
    final Paint glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: opacity * 0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final double cx = size.width / 2;

    for (int i = 0; i < 3; i++) {
      // Only 3 stars falling one by one
      // Constrain X to fall only around the logo
      double startX = cx - 50.0 + random.nextDouble() * 100.0;

      // Space them out significantly in Y so they appear one by one
      double startY = -50.0 - (i * 200.0) - random.nextDouble() * 50.0;

      // Slower, graceful falling speed
      double speed = 250 + random.nextDouble() * 150;

      double currentY = startY + (speed * progress);

      if (currentY > -10 && currentY < size.height) {
        double radius = 1.0 + random.nextDouble() * 1.5;

        // Draw shorter, more compact shape (not a long tail)
        final Rect glowRect = Rect.fromCenter(
            center: Offset(startX, currentY - radius),
            width: radius * 2.5,
            height: radius * 5.0 // Shorter tail
            );
        final Rect coreRect = Rect.fromCenter(
            center: Offset(startX, currentY),
            width: radius * 1.5,
            height: radius * 2.5 // Shorter core
            );

        canvas.drawOval(glowRect, glowPaint);
        canvas.drawOval(coreRect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FallingSparklesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
