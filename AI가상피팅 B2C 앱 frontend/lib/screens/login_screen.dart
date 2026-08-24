import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/fitting_provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FittingProvider>(context, listen: false);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 웰컴 화면과 완벽히 동일한 배경 이미지 (전환 시 배경 유지 효과)
          Image.network(
            'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?q=80&w=2070&auto=format&fit=crop',
            fit: BoxFit.cover,
          ),
          // 웰컴 화면과 완벽히 동일한 어두운 반투명 오버레이
          Container(
            color: Colors.black.withOpacity(0.55),
          ),

          // 전경 컨텐츠 (로그인 버튼들)
          SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 2),

                  // 중앙 로고와 태양계 궤도 애니메이션
                  SizedBox(
                    height: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        const LogoOrbitAnimation(),
                        Text(
                          'Lumière',
                          style: GoogleFonts.greatVibes(
                            fontSize: 84,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.white.withValues(alpha: 0.6),
                                blurRadius: 16,
                                offset: const Offset(0, 0),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const Positioned(
                          bottom: -40, // Moved further down
                          child: SpinningDiamonds(),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 3),

                  // 1. 카카오 로그인 (둥근 버튼)
                  _buildRoundedSocialButton(
                    text: '카카오로 시작하기',
                    backgroundColor: const Color(0xFFFEE500),
                    textColor: Colors.black87,
                    iconWidget: const Icon(Icons.chat_bubble,
                        color: Colors.black87, size: 20),
                    onTap: () => provider.setScreen('login_loading'),
                  ),
                  const SizedBox(height: 12),

                  // 2. 네이버 로그인 (둥근 버튼)
                  _buildRoundedSocialButton(
                    text: '네이버로 시작하기',
                    backgroundColor: const Color(0xFF03C75A), // 네이버 고유 색상
                    textColor: Colors.white,
                    iconWidget: const Text(
                      'N',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Arial',
                      ),
                    ),
                    onTap: () => provider.setScreen('login_loading'),
                  ),
                  const SizedBox(height: 12),

                  // 3. 구글 로그인 (둥근 버튼)
                  _buildRoundedSocialButton(
                    text: '구글로 시작하기',
                    backgroundColor: Colors.white,
                    textColor: Colors.black87,
                    iconWidget: Image.network(
                      'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/480px-Google_%22G%22_logo.svg.png',
                      width: 20,
                      height: 20,
                      errorBuilder: (context, error, stackTrace) => const Text(
                        'G',
                        style: TextStyle(
                          color: Color(0xFF800080),
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Arial',
                        ),
                      ),
                    ),
                    onTap: () => provider.setScreen('login_loading'),
                  ),
                  const SizedBox(height: 12),

                  // 4. 이메일로 시작하기 (둥근 버튼)
                  _buildRoundedSocialButton(
                    text: '이메일로 시작하기',
                    backgroundColor: Colors.white.withOpacity(0.9),
                    textColor: Colors.black87,
                    iconWidget: const Icon(Icons.email_rounded,
                        color: Colors.black87, size: 20),
                    onTap: () => provider.setScreen('login_loading'),
                  ),

                  const SizedBox(height: 32),

                  // 이용약관 등 동의 텍스트
                  const Text(
                    '시작하기를 누름으로써 Lumiere Corp.의\n이용약관 및 개인정보처리방침에 동의합니다.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white54,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundedSocialButton({
    required String text,
    required Color backgroundColor,
    required Color textColor,
    required Widget iconWidget,
    required VoidCallback onTap,
    BoxBorder? border,
  }) {
    return BouncingSocialButton(
      text: text,
      backgroundColor: backgroundColor,
      textColor: textColor,
      iconWidget: iconWidget,
      onTap: onTap,
      border: border,
    );
  }
}

// 뽀잉(Bounce) 애니메이션이 적용된 커스텀 소셜 로그인 버튼
class BouncingSocialButton extends StatefulWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final Widget iconWidget;
  final VoidCallback onTap;
  final BoxBorder? border;

  const BouncingSocialButton({
    super.key,
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    required this.iconWidget,
    required this.onTap,
    this.border,
  });

  @override
  State<BouncingSocialButton> createState() => _BouncingSocialButtonState();
}

class _BouncingSocialButtonState extends State<BouncingSocialButton> {
  double _scale = 1.0;
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      // 버튼 가로 길이 축소를 위해 Center와 SizedBox 사용
      child: SizedBox(
        width: 280, // 가로 길이 축소
        child: MouseRegion(
          onEnter: (_) {
            setState(() {
              _isHovering = true;
              _scale = 1.05; // 마우스 오버 시 살짝 커짐
            });
          },
          onExit: (_) {
            setState(() {
              _isHovering = false;
              _scale = 1.0; // 마우스가 벗어나면 원상복구
            });
          },
          child: GestureDetector(
            onTapDown: (_) => setState(() => _scale = 0.92), // 누를 때는 뽀잉(작아짐)
            onTapUp: (_) {
              setState(() =>
                  _scale = _isHovering ? 1.05 : 1.0); // 손을 떼면 호버 상태에 따라 복구
              widget.onTap();
            },
            onTapCancel: () =>
                setState(() => _scale = _isHovering ? 1.05 : 1.0),
            child: AnimatedScale(
              scale: _scale,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutBack, // 커질 때 살짝 튕기는 뽀잉 느낌
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: BorderRadius.circular(30),
                  border: widget.border,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                          alpha: _isHovering ? 0.2 : 0.1), // 호버 시 그림자도 살짝 진해짐
                      blurRadius: _isHovering ? 12 : 8,
                      offset: Offset(0, _isHovering ? 6 : 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 24.0),
                        child: widget.iconWidget,
                      ),
                    ),
                    Center(
                      child: Text(
                        widget.text,
                        style: TextStyle(
                          color: widget.textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SpinningDiamonds extends StatefulWidget {
  final double size;
  final Color color;

  const SpinningDiamonds({
    super.key,
    this.size = 24.0, // Increased slightly from 16.0 to 24.0
    this.color = Colors.white,
  });

  @override
  State<SpinningDiamonds> createState() => _SpinningDiamondsState();
}

class _SpinningDiamondsState extends State<SpinningDiamonds>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000), // 6초마다 1바퀴 회전
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RotationTransition(
        turns: _controller,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
            painter: SparklePainter(color: widget.color),
          ),
        ),
      ),
    );
  }
}

class SparklePainter extends CustomPainter {
  final Color color;

  SparklePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final Paint shadowPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3); // Reduced blur

    final double cx = size.width / 2;
    final double cy = size.height / 2;

    // Size parameters
    final double R = size.width / 2; // Full radius
    final double gap = R * 0.04; // Very small gap, barely touching
    final double kiteR = R - gap; // Kite length
    final double r = kiteR * 0.28; // Kite width

    void drawKite(Canvas c, double angle) {
      c.save();
      c.translate(cx, cy);
      c.rotate(angle);

      // Shift up by gap to leave center empty
      c.translate(0, -gap);

      final Path path = Path();
      // Top tip of kite
      path.moveTo(0, -kiteR);
      // Right tip
      path.lineTo(r, -r);
      // Bottom tip
      path.lineTo(0, 0);
      // Left tip
      path.lineTo(-r, -r);
      path.close();

      c.drawPath(path, shadowPaint);
      c.drawPath(path, paint);

      c.restore();
    }

    drawKite(canvas, 0); // Top
    drawKite(canvas, math.pi / 2); // Right
    drawKite(canvas, math.pi); // Bottom
    drawKite(canvas, -math.pi / 2); // Left
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) =>
      oldDelegate != this;
}

class LogoOrbitAnimation extends StatefulWidget {
  const LogoOrbitAnimation({super.key});

  @override
  State<LogoOrbitAnimation> createState() => _LogoOrbitAnimationState();
}

class _LogoOrbitAnimationState extends State<LogoOrbitAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12), // 느리고 우아한 회전
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(320, 180),
          painter: OrbitPainter(animationValue: _controller.value),
        );
      },
    );
  }
}

class OrbitPainter extends CustomPainter {
  final double animationValue;

  OrbitPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final Paint orbitPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final Paint planetPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.save();
    canvas.translate(center.dx, center.dy);

    // Orbit 1
    canvas.save();
    canvas.rotate(math.pi / 12);
    canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 280, height: 100),
        orbitPaint);
    double angle1 = animationValue * 2 * math.pi;
    double px1 = 140 * math.cos(angle1);
    double py1 = 50 * math.sin(angle1);
    canvas.drawCircle(Offset(px1, py1), 3.0, planetPaint);
    canvas.restore();

    // Orbit 2
    canvas.save();
    canvas.rotate(-math.pi / 8);
    canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 240, height: 130),
        orbitPaint);
    double angle2 = (1.0 - animationValue) * 2 * math.pi * 1.5;
    double px2 = 120 * math.cos(angle2);
    double py2 = 65 * math.sin(angle2);
    canvas.drawCircle(Offset(px2, py2), 2.5, planetPaint);

    double px3 = 120 * math.cos(angle2 + math.pi);
    double py3 = 65 * math.sin(angle2 + math.pi);
    canvas.drawCircle(Offset(px3, py3), 1.5, planetPaint);
    canvas.restore();

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant OrbitPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
