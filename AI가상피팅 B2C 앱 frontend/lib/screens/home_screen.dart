import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui'; // For ImageFilter (Glassmorphism)
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/fitting_provider.dart';

import '../widgets/notification_icon.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late PageController _pageController;
  Timer? _timer;
  int _currentPage = 0; // 화면 하단 인디케이터용 (0 ~ length-1)
  int _realPage = 0;
  bool _isQrPressed = false; // 실제 PageView 인덱스 (무한 스크롤용)
  late ScrollController _scrollController;
  double _scrollOffset = 0.0;

  final List<Map<String, String>> _promotions = [
    {
      'image':
          'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=600&h=900&fit=crop&auto=format',
      'badge': 'NEW SEASON',
      'title': '새로운 시즌을 깨우는\n에센셜 컬렉션',
      'subtitle': '매일 입어도 질리지 않는 모던 룩',
    },
    {
      'image':
          'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600&h=900&fit=crop&auto=format',
      'badge': 'TIME SALE',
      'title': '썸머 시즌 오프\n최대 70% 할인',
      'subtitle': '해변에서 빛날 바캉스룩 필수템',
    },
    {
      'image':
          'https://images.unsplash.com/photo-1509319117193-57bab727e09d?w=600&h=900&fit=crop&auto=format',
      'badge': 'NEW ARRIVAL',
      'title': '가을을 준비하는\n얼리버드 특가',
      'subtitle': '분위기 있는 가을 트렌치 코트 신상',
    },
    {
      'image':
          'https://images.unsplash.com/photo-1487222477894-8943e31ef7b2?w=600&h=900&fit=crop&auto=format',
      'badge': 'BEST ITEM',
      'title': 'MD 강력 추천\n미니멀 셋업 컬렉션',
      'subtitle': '단정하고 세련된 오피스룩의 정석',
    },
    {
      'image':
          'https://images.unsplash.com/photo-1445205170230-053b83016050?w=600&h=900&fit=crop&auto=format',
      'badge': 'WINTER PREVIEW',
      'title': '한 발 앞서 만나는\n윈터 아우터',
      'subtitle': '포근함과 스타일을 동시에 잡으세요',
    },
    {
      'image':
          'https://images.unsplash.com/photo-1525507119028-ed4c629a60a3?w=600&h=900&fit=crop&auto=format',
      'badge': 'CASUAL WEEK',
      'title': '편안함에 스타일을 더하다\n위켄드 룩',
      'subtitle': '꾸민 듯 안 꾸민 듯 자연스러운 무드',
    },
  ];

  @override
  void initState() {
    super.initState();
    _realPage = _promotions.length * 1000;
    _currentPage = 0;
    _pageController = PageController(initialPage: _realPage);
    _scrollController = ScrollController()..addListener(() {
      if (mounted) {
        setState(() {
          _scrollOffset = _scrollController.offset;
        });
      }
    });
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(milliseconds: 3500), (Timer timer) {
      if (_pageController.hasClients) {
        // 무한 스크롤이므로 그냥 다음 페이지로 넘기기만 하면 됨
        _pageController.nextPage(
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOutQuart,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  double get _categoryOpacity {
    if (_scrollOffset <= 20) return 0.0;
    if (_scrollOffset >= 140) return 1.0;
    return (_scrollOffset - 20) / 120.0;
  }

  double get _categoryTranslationY {
    if (_scrollOffset >= 140) return 0.0;
    return (1.0 - _categoryOpacity) * 40.0;
  }

  // 상단 페이드: 화면 절반 높이를 스크롤로 넘어가면 점점 투명화 (80px 구간에 걸쳐)
  double _topFadeStop(double screenHeight) {
    final half = screenHeight * 0.5;
    if (_scrollOffset <= half) return 1.0; // 완전 불투명
    final excess = _scrollOffset - half;
    return (1.0 - (excess / 80.0)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FittingProvider>(context);
    final paddingTop = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Full Screen Photo Background (PageView)
          Positioned.fill(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.trackpad
                },
              ),
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() {
                    _realPage = page;
                    _currentPage = page % _promotions.length;
                  });
                },
                itemBuilder: (context, index) {
                  final int listIndex = index % _promotions.length;
                  final promo = _promotions[listIndex];

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      promo['image']!.startsWith('http')
                          ? Image.network(
                              promo['image']!,
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                            )
                          : Image.asset(
                              promo['image']!,
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                            ),
                      Container(color: Colors.black.withValues(alpha: 0.15)),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.6),
                              Colors.black.withValues(alpha: 0.2),
                              Colors.black.withValues(alpha: 0.6),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // 2. Scrollable Foreground Content
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragUpdate: (details) {
                _pageController.jumpTo(_pageController.offset - details.delta.dx);
              },
              onHorizontalDragEnd: (details) {
                final double width = MediaQuery.of(context).size.width;
                final int targetPage = (_pageController.offset / width).round().toInt();
                _pageController.animateToPage(
                  targetPage,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                );
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenH = constraints.maxHeight;
                  return ShaderMask(
                    shaderCallback: (Rect bounds) {
                      // 상단: 화면 절반 스크롤 시 서서히 투명
                      final double topAlpha = _topFadeStop(screenH);
                      // 하단: 항상 하단 25% 구간을 투명하게
                      return LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: topAlpha),
                          Colors.white,
                          Colors.white,
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.15, 0.75, 1.0],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.dstIn,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Spacer to reveal the background image + Floating Event Text
                  SizedBox(height: paddingTop + 100),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 700),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          transitionBuilder: (Widget child, Animation<double> animation) {
                            return FadeTransition(opacity: animation, child: child);
                          },
                          layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                            return Stack(
                              alignment: Alignment.centerLeft,
                              children: <Widget>[
                                ...previousChildren,
                                if (currentChild != null) currentChild,
                              ],
                            );
                          },
                          child: Column(
                            key: ValueKey<int>(_currentPage),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _promotions[_currentPage]['badge']!,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.0),
                                ),
                              ),
                              const SizedBox(height: 16),
                              GestureDetector(
                                onTap: () {
                                  provider.setSelectedEventIndex(_currentPage);
                                  provider.setScreen('event');
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _promotions[_currentPage]['title']!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.w900,
                                        height: 1.3,
                                        letterSpacing: -0.5,
                                        shadows: [
                                          Shadow(color: Colors.black54, blurRadius: 15, offset: Offset(0, 2)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      _promotions[_currentPage]['subtitle']!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        shadows: [
                                          Shadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 1)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              BouncyEventButton(
                                onTap: () {
                                  provider.setSelectedEventIndex(_currentPage);
                                  provider.setScreen('event');
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Carousel Indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: List.generate(
                            _promotions.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 4,
                              width: _currentPage == index ? 24 : 8,
                              decoration: BoxDecoration(
                                color: _currentPage == index ? Colors.white : Colors.white.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 100), // 스크롤 없이도 AI 피팅 내역 카드가 하단에 노출되도록 간격 좁힘
                  
                  // Menu Cards Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      children: [
                        BouncyGlassCard(
                          title: 'AI 피팅 내역',
                          subtitle: '피팅 결과 확인',
                          icon: Icons.history,
                          onTap: () => provider.setScreen('history'),
                          isLarge: true,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: BouncyGlassCard(
                                title: '내 옷장',
                                subtitle: '등록된 옷 관리',
                                icon: Icons.checkroom_rounded,
                                onTap: () => provider.setScreen('wardrobe'),
                                isLarge: false,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: BouncyGlassCard(
                                title: 'AI 피팅',
                                subtitle: '내 옷 입혀보기',
                                icon: Icons.auto_awesome,
                                onTap: () => provider.setScreen('fitting'),
                                isLarge: false,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Related recommendations box (enclosed in a premium glass box)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
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
                                    '피팅 내역 기반 추천 코디',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => provider.setScreen('fitting'),
                                    child: const Text(
                                      '더보기',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '최근 피팅하신 옷과 함께 코디하기 좋은 추천 의류입니다.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 178,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: _getRecommendedProducts().length,
                                  itemBuilder: (context, index) {
                                    final item = _getRecommendedProducts()[index];
                                    return GestureDetector(
                                      onTap: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Lumière 쇼핑몰에서 \'${item['name']}\' 상품 구매 페이지로 이동합니다.'),
                                            backgroundColor: AppTheme.primary,
                                          ),
                                        );
                                      },
                                      child: Container(
                                        width: 130,
                                        margin: const EdgeInsets.only(right: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.1),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Stack(
                                              children: [
                                                ClipRRect(
                                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                                  child: Image.network(
                                                    item['imageUrl']!,
                                                    height: 120,
                                                    width: 130,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                                Positioned(
                                                  top: 8,
                                                  left: 8,
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFF4CA624),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      item['match']!,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 9,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(8),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item['name']!,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    item['price']!,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: AppTheme.accent,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          );
                },
              ),
          ),
          ),

          // 3. Fixed Header (Floats above ScrollView)
          Positioned(
            top: paddingTop + 16.0,
            left: 40.0,
            right: 40.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Lumière',
                  style: GoogleFonts.greatVibes(
                    fontSize: 34,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    shadows: const [
                      Shadow(
                          color: Colors.black45,
                          blurRadius: 10,
                          offset: Offset(0, 1))
                    ],
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTapDown: (_) => setState(() => _isQrPressed = true),
                      onTapCancel: () => setState(() => _isQrPressed = false),
                      onTapUp: (_) async {
                        await Future.delayed(const Duration(milliseconds: 100));
                        if (mounted) setState(() => _isQrPressed = false);
                      },
                      onTap: () => provider.setScreen('qr'),
                      child: AnimatedScale(
                        scale: _isQrPressed ? 0.88 : 1.0,
                        duration: const Duration(milliseconds: 100),
                        curve: Curves.easeOut,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: _isQrPressed ? 0.45 : 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.qr_code_scanner,
                              color: Colors.white, size: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const NotificationIcon(iconColor: Colors.white),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Recommended products helper
  List<Map<String, String>> _getRecommendedProducts() {
    return [
      {
        'name': '스탠다드 리넨 블레이저',
        'imageUrl': 'https://images.unsplash.com/photo-1591047139829-d91aecb6caea?w=400&fit=crop&q=80',
        'price': '₩ 89,000',
        'match': '98% 매치',
      },
      {
        'name': '이지 실루엣 드레스 와이드 슬랙스',
        'imageUrl': 'https://images.unsplash.com/photo-1624378439575-d8705ad7ae80?w=400&fit=crop&q=80',
        'price': '₩ 49,000',
        'match': '96% 매치',
      },
      {
        'name': '데일리 오버핏 카라 반팔 셔츠',
        'imageUrl': 'https://images.unsplash.com/photo-1596755094514-f87e34085b2c?w=400&fit=crop&q=80',
        'price': '₩ 34,900',
        'match': '95% 매치',
      },
      {
        'name': '내추럴 코튼 버뮤다 팬츠',
        'imageUrl': 'https://images.unsplash.com/photo-1591195853828-11db59a44f6b?w=400&fit=crop&q=80',
        'price': '₩ 39,900',
        'match': '92% 매치',
      },
      {
        'name': '베이직 포멀 가죽 로퍼',
        'imageUrl': 'https://images.unsplash.com/photo-1533867617858-e7b97e060509?w=400&fit=crop&q=80',
        'price': '₩ 119,000',
        'match': '90% 매치',
      },
    ];
  }
}

class BouncyEventButton extends StatefulWidget {
  final VoidCallback onTap;

  const BouncyEventButton({required this.onTap, super.key});

  @override
  State<BouncyEventButton> createState() => _BouncyEventButtonState();
}

class _BouncyEventButtonState extends State<BouncyEventButton> {
  bool _isPressed = false;
  bool _isHovered = false;

  void _handleTapDown(TapDownDetails details) =>
      setState(() => _isPressed = true);

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    Future.delayed(const Duration(milliseconds: 150), widget.onTap);
  }

  void _handleTapCancel() => setState(() => _isPressed = false);



  @override
  Widget build(BuildContext context) {
    double targetScale = _isPressed ? 0.90 : (_isHovered ? 1.05 : 1.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: AnimatedScale(
          scale: targetScale,
          duration: const Duration(milliseconds: 200),
          curve: _isPressed ? Curves.easeOutQuad : Curves.elasticOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _isHovered
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.9),
                  width: _isHovered ? 1.5 : 1.0),
              boxShadow: [
                BoxShadow(
                    color:
                        Colors.black.withValues(alpha: _isHovered ? 0.2 : 0.12),
                    blurRadius: _isHovered ? 8 : 4,
                    offset: Offset(0, _isHovered ? 4 : 2))
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  '이벤트 자세히 보기',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward, color: Colors.white, size: 13),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BouncyGlassCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool isLarge;

  const BouncyGlassCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.isLarge,
    super.key,
  });

  @override
  State<BouncyGlassCard> createState() => _BouncyGlassCardState();
}

class _BouncyGlassCardState extends State<BouncyGlassCard> {
  bool _isPressed = false;
  bool _isHovered = false;

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    Future.delayed(const Duration(milliseconds: 150), widget.onTap);
  }

  void _handleTapCancel() {
    setState(() {
      _isPressed = false;
    });
  }



  @override
  Widget build(BuildContext context) {
    double targetScale = _isPressed ? 0.92 : (_isHovered ? 1.03 : 1.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: AnimatedScale(
          scale: targetScale,
          duration: const Duration(milliseconds: 200),
          curve: _isPressed ? Curves.easeOutQuad : Curves.elasticOut,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: widget.isLarge
                    ? Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              widget.icon,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  widget.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.subtitle,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              widget.icon,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.7),
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
