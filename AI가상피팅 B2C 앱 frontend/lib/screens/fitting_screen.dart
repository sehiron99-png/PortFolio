import 'dart:io';
import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../providers/fitting_provider.dart';
import '../widgets/add_photo_popup.dart';
import '../widgets/clothing_image.dart';
import '../widgets/notification_icon.dart';

import 'subscription_screen.dart';

class FittingScreen extends StatefulWidget {
  const FittingScreen({super.key});

  @override
  State<FittingScreen> createState() => _FittingScreenState();
}

class _FittingScreenState extends State<FittingScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  static const String _defaultModelUrl =
      'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=400&h=600&fit=crop&auto=format';

  String? _lastUserPhotoPath; // 신규 등록 사진 감지용 변수 추가
  bool _isSearchMode = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String? _pressedCategory;
  bool _isHistoryPressed = false;
  bool _isSearchPressed = false;
  bool _showCategoryArrows = false;
  final ScrollController _categoryScrollController = ScrollController();
  Timer? _scrollTimer;
  bool _continuousScrollingActive = false;

  late AnimationController _shimmerController;

  // 기획전 배너 슬라이더 추가 변수
  late PageController _promoPageController;
  Timer? _promoTimer;
  int _promoCurrentPage = 0;

  final List<Map<String, String>> _promotions = [
    {
      'image': 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=600&h=900&fit=crop&auto=format',
      'badge': 'NEW SEASON',
      'title': '새로운 시즌을 깨우는 에센셜 컬렉션',
      'subtitle': '매일 입어도 질리지 않는 모던 룩',
    },
    {
      'image': 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600&h=900&fit=crop&auto=format',
      'badge': 'TIME SALE',
      'title': '썸머 시즌 오프 최대 70% 할인',
      'subtitle': '해변에서 빛날 바캉스룩 필수템',
    },
    {
      'image': 'https://images.unsplash.com/photo-1509319117193-57bab727e09d?w=600&h=900&fit=crop&auto=format',
      'badge': 'NEW ARRIVAL',
      'title': '가을을 준비하는 얼리버드 특가',
      'subtitle': '분위기 있는 가을 트렌치 코트 신상',
    },
    {
      'image': 'https://images.unsplash.com/photo-1487222477894-8943e31ef7b2?w=600&h=900&fit=crop&auto=format',
      'badge': 'BEST ITEM',
      'title': 'MD 강력 추천 미니멀 셋업 컬렉션',
      'subtitle': '단정하고 세련된 오피스룩의 정석',
    },
  ];

  void _startPromoAutoScroll() {
    _promoTimer = Timer.periodic(const Duration(milliseconds: 3500), (Timer timer) {
      if (_promoPageController.hasClients) {
        int nextPage = _promoCurrentPage + 1;
        if (nextPage >= _promotions.length) {
          nextPage = 0;
        }
        _promoPageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutQuart,
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
    _promoPageController = PageController(initialPage: 0);
    _startPromoAutoScroll();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _searchController.dispose();
    _categoryScrollController.dispose();
    _scrollTimer?.cancel();
    _promoTimer?.cancel();
    _promoPageController.dispose();
    super.dispose();
  }

  void _startContinuousScroll({required bool directionLeft}) {
    _scrollTimer?.cancel();
    _continuousScrollingActive = false;
    _scrollTimer = Timer(const Duration(milliseconds: 300), () {
      _continuousScrollingActive = true;
      _scrollTimer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
        if (!_categoryScrollController.hasClients) return;
        final double currentOffset = _categoryScrollController.offset;
        final double delta = directionLeft ? -10.0 : 10.0;
        final double targetOffset = (currentOffset + delta).clamp(
          0.0,
          _categoryScrollController.position.maxScrollExtent,
        );
        _categoryScrollController.jumpTo(targetOffset);
      });
    });
  }

  void _stopContinuousScroll() {
    _scrollTimer?.cancel();
    _scrollTimer = null;
  }

  // 가이드 항목 위젯 (사진 가져오기 다이얼로그용)
  // 사용자 본인 전신/반신의 사진 촬영/업로드
  Future<void> _uploadUserPhoto(FittingProvider provider) async {
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            width: 310,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '인물 사진 등록',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () {
                            Navigator.pop(context);
                            provider.setIsCameraForUserPhoto(true);
                            provider.setScreen('camera');
                          },
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: AppTheme.secondary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt,
                                color: AppTheme.primary, size: 28),
                          ),
                          const SizedBox(height: 8),
                          const Text('카메라 촬영',
                              style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          Navigator.of(context).pop(ImageSource.gallery),
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: AppTheme.secondary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.photo_library,
                                color: AppTheme.primary, size: 28),
                          ),
                          const SizedBox(height: 8),
                          const Text('갤러리 선택',
                              style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // 인물 촬영 가이드 버튼
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _showGuideDialog(context, provider);
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.help_outline, size: 14, color: AppTheme.accent),
                        SizedBox(width: 6),
                        Text(
                          '인물 촬영 가이드',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.accent,
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
      },
    );

    if (source == null) return;

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 600,
      );

      if (pickedFile == null) return;
      provider.setTempUserPhoto(pickedFile.path);
    } catch (e) {
      debugPrint('사용자 사진 업로드 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사진 등록하는데 실패했습니다.')),
      );
    }
  }

  // 사용자가 전신의 사진을 등록하지 않았을 경우 기본 모델 사진을 임시 파일로 다운로드하여 백엔드로 보냅니다.
  Future<void> _handleStartFitting(FittingProvider provider) async {
    if (provider.outfit.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('피팅할 옷을 먼저 골라주세요.')),
      );
      return;
    }

    // 토큰/구독 상태 검사 및 차감
    bool hasSubscriptionOrTokens = provider.isPremium ||
        provider.freeFittingCount > 0 ||
        provider.tokenCount > 0;

    if (!hasSubscriptionOrTokens) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('피팅을 진행할 무료 횟수와 토큰이 부족합니다. 결제 페이지로 이동합니다.')),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
      );
      return;
    }

    // 피팅 진행 예정 및 횟수 차감 (무료 피팅을 우선 차감)
    provider.useFittingCount();

    if (provider.userPhotoPath == null) {
      // 1. 로딩 인디케이터 스타트 표시합니다
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(AppTheme.accent)),
                  SizedBox(height: 16),
                  Text('기본 모델 이미지를 준비하는 중...',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      );

      // 2. 모델 이미지 다운로드 (웹에서는 직접 URL을 피팅에 바로 활용)
      try {
        if (kIsWeb) {
          Navigator.pop(context); // 로딩 닫기
          provider.setUserPhoto(_defaultModelUrl);
          await provider.startFitting();
        } else {
          Navigator.pop(context);
          throw Exception('모델 이미지 로드 실패');
        }
      } catch (e) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('모델 이미지를 불러오지 못했습니다. 본인 사진을 찍어 올려보세요.')),
        );
        return;
      }
    } else {
      await provider.startFitting();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FittingProvider>(context);

    // 임시 인물 사진이 지정되었을 때 구도 조정 및 격자 가이드 다이얼로그 노출
    if (provider.tempUserPhotoPath != null) {
      final tempPath = provider.tempUserPhotoPath!;
      // 무한 루프 방지를 위해 즉시 임시 상태를 null로 클리어합니다.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.setTempUserPhoto(null);
        _showPhotoAdjustmentDialog(context, tempPath, provider);
      });
    }

    final outfitList = provider.outfit.entries.toList();
    final categories = ['전체', '상의', '하의', '원피스', '아우터', '신발'];
    final categoryClothes = provider.clothes.where((c) {
      final categoryMatch = provider.selectedCategory == '전체' ||
          c.category == provider.selectedCategory;
      final searchMatch = _searchQuery.isEmpty ||
          c.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return categoryMatch && searchMatch;
    }).toList();

    // 예상 총액 계산
    int totalPrice = provider.outfit.values.fold(0, (sum, item) {
      final priceNum = int.tryParse(item.price.replaceAll(',', '')) ?? 0;
      return sum + priceNum;
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // 헤더
                Padding(
                  padding: const EdgeInsets.only(
                      left: 40.0, right: 40.0, top: 22.0, bottom: 22.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        '피팅룸',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () =>
                                _showFittingDetailsDialog(context, provider),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF8E7),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFE5A93C)
                                      .withValues(alpha: 0.4),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFE5A93C)
                                        .withValues(alpha: 0.08),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    size: 13,
                                    color: Color(0xFFD9901C),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    provider.isPremium
                                        ? '남은 피팅: ${provider.premiumFittingCount}회'
                                        : '남은 피팅: ${provider.freeFittingCount + provider.tokenCount}회',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFB27A1C),
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const NotificationIcon(),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(
                    color: Color(0xFFEEEEEE),
                    thickness: 1,
                    height: 1), // 헤드라인 밑 선
                Expanded(
                  child: Container(
                    color: AppTheme.background,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 160),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            color: Colors.white,
                            width: double.infinity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 모델 오버레이 피팅 뷰 영역
                                Padding(
                                  padding: const EdgeInsets.only(left: 40, right: 40, top: 12),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // 좌측: 인물 사진 영역 (가로폭 크게 확대)
                                      Expanded(
                                        flex: 5,
                                        child: GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onTap: () {
                                            if (provider.userPhotoPath == null) {
                                              _uploadUserPhoto(provider);
                                            } else {
                                              _showUserPhotoOptions(context, provider);
                                            }
                                          },
                                          child: AnimatedContainer(
                                            duration:
                                                const Duration(milliseconds: 300),
                                            height: 390,
                                            decoration: BoxDecoration(
                                            color:
                                                provider.userPhotoPath == null
                                                    ? AppTheme.background
                                                    : AppTheme.secondary,
                                            borderRadius:
                                                BorderRadius.circular(32),
                                            border: Border.all(
                                              color: AppTheme.accent.withValues(alpha: 0.28), // 옅고 은은한 파스텔 올리브 톤
                                              width: 1.2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: provider.userPhotoPath ==
                                                        null
                                                    ? AppTheme.accent
                                                        .withValues(alpha: 0.05)
                                                    : const Color(0x0A000000),
                                                blurRadius: 20,
                                                spreadRadius: 2,
                                                offset: const Offset(0, 8),
                                              )
                                            ],
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(30),
                                            child: Stack(
                                              children: [
                                                // 배경 이미지
                                                Positioned.fill(
                                                  child:
                                                      provider.userPhotoPath !=
                                                              null
                                                          ? (kIsWeb 
                                                              ? Image.network(
                                                                  provider.userPhotoPath!,
                                                                  fit: BoxFit.cover,
                                                                  alignment: Alignment.center,
                                                                )
                                                              : Image.file(
                                                                  File(provider
                                                                      .userPhotoPath!),
                                                                  fit: BoxFit.cover,
                                                                  alignment: Alignment.center,
                                                                ))
                                                          : Container(
                                                              decoration:
                                                                  BoxDecoration(
                                                                gradient:
                                                                    LinearGradient(
                                                                  begin: Alignment
                                                                      .topCenter,
                                                                  end: Alignment
                                                                      .bottomCenter,
                                                                  colors: [
                                                                    Colors
                                                                        .white,
                                                                    AppTheme
                                                                        .secondary
                                                                        .withValues(
                                                                            alpha:
                                                                                0.25),
                                                                  ],
                                                                ),
                                                              ),
                                                              child: Center(
                                                                child: Column(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  children: [
                                                                    TweenAnimationBuilder(
                                                                      duration: const Duration(
                                                                          milliseconds:
                                                                              1500),
                                                                      tween: Tween<
                                                                              double>(
                                                                          begin:
                                                                              0,
                                                                          end:
                                                                              1),
                                                                      builder: (context,
                                                                          double
                                                                              val,
                                                                          child) {
                                                                        return Transform
                                                                            .translate(
                                                                          offset: Offset(
                                                                              0,
                                                                              math.sin(val * math.pi * 2) * 4),
                                                                          child:
                                                                              child,
                                                                        );
                                                                      },
                                                                      child:
                                                                          Container(
                                                                        padding: const EdgeInsets
                                                                            .all(
                                                                            18),
                                                                        decoration: const BoxDecoration(
                                                                          color: Colors.transparent,
                                                                          shape: BoxShape.circle,
                                                                        ),
                                                                        child: const Icon(
                                                                          Icons
                                                                              .add_a_photo_outlined,
                                                                          color:
                                                                              AppTheme.accent,
                                                                          size:
                                                                              28,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                        height:
                                                                            16),
                                                                    const Text(
                                                                      '인물 사진 등록',
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                      style:
                                                                          TextStyle(
                                                                        fontSize:
                                                                            14,
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        color: AppTheme
                                                                            .primary,
                                                                        letterSpacing:
                                                                            -0.5,
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ),
                                                ),


                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      ),
                                      const SizedBox(width: 12),

                                      // 우측: 선택한 옷 리스트
                                      Expanded(
                                        flex: 3,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              height: 390,
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                color: AppTheme.background,
                                                borderRadius:
                                                    BorderRadius.circular(24),
                                                border: Border.all(
                                                    color: Colors.grey[350]!),
                                              ),
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 12),
                                              child: SingleChildScrollView(
                                                physics: const BouncingScrollPhysics(),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    // 1. 선택된 옷 목록 (있을 때만 노출)
                                                    if (provider.outfit.isNotEmpty) ...[
                                                      Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: outfitList.map((entry) {
                                                          final category = entry.key;
                                                          final item = entry.value;
                                                          return Container(
                                                            margin: const EdgeInsets.only(bottom: 8),
                                                            padding: const EdgeInsets.all(8),
                                                            decoration: BoxDecoration(
                                                              color: Colors.white,
                                                              borderRadius: BorderRadius.circular(16),
                                                              border: Border.all(color: Colors.grey[200]!),
                                                              boxShadow: const [
                                                                BoxShadow(
                                                                  color: Color(0x05000000),
                                                                  blurRadius: 4,
                                                                  offset: Offset(0, 1),
                                                                )
                                                              ],
                                                            ),
                                                            child: Row(
                                                              children: [
                                                                ClipRRect(
                                                                  borderRadius: BorderRadius.circular(10),
                                                                  child: SizedBox(
                                                                    width: 40,
                                                                    height: 40,
                                                                    child: ClothingImage(imageUrl: item.imageUrl),
                                                                  ),
                                                                ),
                                                                const SizedBox(width: 10),
                                                                Expanded(
                                                                  child: Column(
                                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                                    children: [
                                                                      Text(
                                                                        item.name,
                                                                        style: const TextStyle(
                                                                          fontSize: 12,
                                                                          fontWeight: FontWeight.bold,
                                                                          color: AppTheme.primary,
                                                                        ),
                                                                        maxLines: 1,
                                                                        overflow: TextOverflow.ellipsis,
                                                                      ),
                                                                      Text(
                                                                        category,
                                                                        style: const TextStyle(
                                                                            fontSize: 10,
                                                                            color: Colors.grey),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                                GestureDetector(
                                                                  onTap: () => provider.toggleOutfitItem(item),
                                                                  child: const Padding(
                                                                    padding: EdgeInsets.all(4),
                                                                    child: Icon(
                                                                        Icons.close_rounded,
                                                                        size: 16,
                                                                        color: Colors.grey),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                        }).toList(),
                                                      ),
                                                      const SizedBox(height: 16),
                                                    ],
                                                    // 2. 고정 플레이스홀더 안내 영역 (의류 아이콘 + 가이드 텍스트)
                                                    SizedBox(height: provider.outfit.isEmpty ? 95 : 15),
                                                    Icon(
                                                      Icons.checkroom_rounded,
                                                      color: Colors.grey[400],
                                                      size: 32,
                                                    ),
                                                    const SizedBox(height: 12),
                                                    const Text(
                                                      '아래에서 입어볼\n옷을 골라주세요!',
                                                      textAlign: TextAlign.center,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey,
                                                        fontWeight: FontWeight.w600,
                                                        height: 1.5,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 24),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),

                                const SizedBox(height: 8),

                                // 가로 카테고리 탭 리스트 (피팅룸 전용 미니 탭)
                                Stack(
                                  children: [
                                    SizedBox(
                                      height: 44,
                                      child: Listener(
                                        onPointerDown: (_) => setState(() => _showCategoryArrows = true),
                                        onPointerUp: (_) => setState(() => _showCategoryArrows = false),
                                        onPointerCancel: (_) => setState(() => _showCategoryArrows = false),
                                        child: ListView(
                                          controller: _categoryScrollController,
                                          scrollDirection: Axis.horizontal,
                                        physics:
                                            const AlwaysScrollableScrollPhysics(
                                                parent:
                                                    BouncingScrollPhysics()),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 40),
                                        children: [
                                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTapDown: (_) => setState(() => _isSearchPressed = true),
                              onTapCancel: () => setState(() => _isSearchPressed = false),
                              onTapUp: (_) async {
                                await Future.delayed(const Duration(milliseconds: 100));
                                if (mounted) setState(() => _isSearchPressed = false);
                              },
                              onTap: () {
                                setState(() {
                                  _isSearchMode = !_isSearchMode;
                                  if (!_isSearchMode) {
                                    _searchController.clear();
                                    _searchQuery = '';
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: _isSearchMode
                                      ? (_isSearchPressed ? const Color(0xFF6B7E64) : AppTheme.fittingAccent)
                                      : (_isSearchPressed ? Colors.grey[200] : Colors.white),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _isSearchMode
                                        ? Colors.transparent
                                        : Colors.grey[200]!,
                                    width: 1.0,
                                  ),
                                ),
                                child: Icon(
                                  Icons.search,
                                  size: 18,
                                  color: _isSearchMode
                                      ? Colors.white
                                      : Colors.grey[700],
                                ),
                              ),
                            ),
                          ),
                          ...categories
                              .map((cat) {
                            final isSelected = provider.selectedCategory == cat;
                            final hasItem = provider.outfit.containsKey(cat);
                            
                            final isPressed = _pressedCategory == cat;

                            final Color bgColor;
                            final Color textColor;
                            final Color borderColor;
                            final Color checkColor;

                            if (isSelected) {
                              bgColor = isPressed ? const Color(0xFF6B7E64) : const Color(0xFF8B9D83);
                              textColor = Colors.white;
                              borderColor = Colors.transparent;
                              checkColor = Colors.white;
                            } else {
                              bgColor = isPressed ? Colors.grey[200]! : Colors.white;
                              textColor = hasItem ? AppTheme.fittingAccent : Colors.grey[700]!;
                              borderColor = hasItem 
                                  ? AppTheme.fittingAccent.withValues(alpha: 0.4) 
                                  : Colors.grey[200]!;
                              checkColor = AppTheme.fittingAccent;
                            }

                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTapDown: (_) => setState(() => _pressedCategory = cat),
                                onTapCancel: () => setState(() => _pressedCategory = null),
                                onTapUp: (_) async {
                                  await Future.delayed(const Duration(milliseconds: 100));
                                  if (mounted) setState(() => _pressedCategory = null);
                                },
                                onTap: () => provider.setSelectedCategory(cat),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: borderColor,
                                      width: 1.0,
                                    ),
                                  ),
                                                                    child: Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (hasItem)
                                          Icon(
                                            Icons.check,
                                            size: 14,
                                            color: checkColor,
                                          ),
                                        if (hasItem)
                                          const SizedBox(width: 4),
                                        Text(
                                          cat,
                                          style: TextStyle(
                                            color: textColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                                         ],
                                       ),
                                     ),
                                     ),
                                    Positioned(
                                      left: 0,
                                      top: 0,
                                      bottom: 0,
                                      child: IgnorePointer(
                                        child: Container(
                                            width: 40,
                                            color: Colors.white),
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      bottom: 0,
                                      child: IgnorePointer(
                                        child: Container(
                                            width: 40,
                                            color: Colors.white),
                                      ),
                                    ),
                                    Positioned(
                                      left: 10,
                                      top: 0,
                                      bottom: 0,
                                      child: AnimatedOpacity(
                                        opacity: _showCategoryArrows ? 1.0 : 0.0,
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                        child: GestureDetector(
                                          onTapDown: (_) => _startContinuousScroll(directionLeft: true),
                                          onTapUp: (_) => _stopContinuousScroll(),
                                          onTapCancel: () => _stopContinuousScroll(),
                                          onTap: () {
                                            if (_continuousScrollingActive) return;
                                            if (_categoryScrollController.hasClients) {
                                              _categoryScrollController.animateTo(
                                                (_categoryScrollController.offset - 100.0).clamp(
                                                    0.0, _categoryScrollController.position.maxScrollExtent),
                                                duration: const Duration(milliseconds: 300),
                                                curve: Curves.easeInOut,
                                              );
                                            }
                                          },
                                          child: Center(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.9),
                                                shape: BoxShape.circle,
                                                boxShadow: const [
                                                  BoxShadow(
                                                      color: Colors.black12,
                                                      blurRadius: 4,
                                                      offset: Offset(0, 2)),
                                                ],
                                              ),
                                              padding: const EdgeInsets.all(4),
                                              child: const Icon(Icons.chevron_left,
                                                  size: 18, color: Colors.black54),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 10,
                                      top: 0,
                                      bottom: 0,
                                      child: AnimatedOpacity(
                                        opacity: _showCategoryArrows ? 1.0 : 0.0,
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                        child: GestureDetector(
                                          onTapDown: (_) => _startContinuousScroll(directionLeft: false),
                                          onTapUp: (_) => _stopContinuousScroll(),
                                          onTapCancel: () => _stopContinuousScroll(),
                                          onTap: () {
                                            if (_continuousScrollingActive) return;
                                            if (_categoryScrollController.hasClients) {
                                              _categoryScrollController.animateTo(
                                                (_categoryScrollController.offset + 100.0).clamp(
                                                    0.0, _categoryScrollController.position.maxScrollExtent),
                                                duration: const Duration(milliseconds: 300),
                                                curve: Curves.easeInOut,
                                              );
                                            }
                                          },
                                          child: Center(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.9),
                                                shape: BoxShape.circle,
                                                boxShadow: const [
                                                  BoxShadow(
                                                      color: Colors.black12,
                                                      blurRadius: 4,
                                                      offset: Offset(0, 2)),
                                                ],
                                              ),
                                              padding: const EdgeInsets.all(4),
                                              child: const Icon(Icons.chevron_right,
                                                  size: 18, color: Colors.black54),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // 검색바 (직접 추가하기 위에 표시)
                                if (_isSearchMode)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 40, right: 40, bottom: 12),
                                    child: SizedBox(
                                      height: 42,
                                      child: TextField(
                                        controller: _searchController,
                                        style: const TextStyle(fontSize: 14),
                                        decoration: InputDecoration(
                                          hintText: '옷 이름 검색...',
                                          hintStyle: TextStyle(
                                              color: Colors.grey[400],
                                              fontSize: 14),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: BorderSide(
                                              color: AppTheme.fittingAccent.withValues(alpha: 0.5),
                                              width: 1,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: BorderSide(
                                              color: Colors.grey[300]!,
                                              width: 1,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: const BorderSide(
                                              color: AppTheme.fittingAccent,
                                              width: 1.5,
                                            ),
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                          contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 0),
                                          prefixIcon: const Icon(Icons.search,
                                              color: Colors.grey, size: 20),
                                          suffixIcon: IconButton(
                                            icon: const Icon(Icons.cancel,
                                                size: 18, color: Colors.grey),
                                            onPressed: () {
                                              setState(() {
                                                _isSearchMode = false;
                                                _searchController.clear();
                                                _searchQuery = '';
                                              });
                                            },
                                          ),
                                        ),
                                        onChanged: (val) {
                                          setState(() => _searchQuery = val);
                                        },
                                      ),
                                    ),
                                  ),
                                // 직접 추가하기 버튼
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 40),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        provider.setShouldOpenGallery(true);
                                        provider.setScreen('camera');
                                      },
                                      icon: const Icon(Icons.add, color: AppTheme.accent, size: 20),
                                      label: const Text('직접 추가하기',
                                          style: TextStyle(
                                              color: AppTheme.accent,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        elevation: 0,
                                        side: const BorderSide(color: AppTheme.accent, width: 0.8),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // 구분선
                                Container(
                                  height: 8,
                                  color: AppTheme.background,
                                ),
                              ],
                            ),
                          ),
                          // 하단 영역 (아이템 리스트)
                          SizedBox(
                            width: double.infinity,
                            child: Column(
                              children: [


                                // 해당 카테고리 옷 가로 스크롤 카드 리스트
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 40),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      categoryClothes.isEmpty
                                          ? Container(
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                color: AppTheme.background,
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  const SizedBox(height: 24),
                                                  GestureDetector(
                                                    onTap: () => showClothesGuideDialog(context),
                                                    child: Column(
                                                      children: [
                                                        Icon(
                                                          Icons.photo_outlined,
                                                          size: 40,
                                                          color: AppTheme.accent.withValues(alpha: 0.5),
                                                        ),
                                                        const SizedBox(height: 12),
                                                        Text(
                                                          '아직 촬영한 옷이 없어요',
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            color: Colors.grey[500],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  GestureDetector(
                                                    onTap: () => showAddPhotoPopup(context, provider),
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius: BorderRadius.circular(12),
                                                        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
                                                      ),
                                                      child: Text(
                                                        '탭하여 촬영하러 가기',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: AppTheme.accent,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 24),
                                                ],
                                              ),
                                            )
                                          : GridView.builder(
                                              shrinkWrap: true,
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              padding: EdgeInsets.zero,
                                              gridDelegate:
                                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                                crossAxisCount: 3,
                                                mainAxisSpacing: 12,
                                                crossAxisSpacing: 12,
                                                childAspectRatio:
                                                    0.7, // 세로가로 공간 비율
                                              ),
                                              itemCount: categoryClothes.length,
                                              itemBuilder: (context, index) {
                                                final item =
                                                    categoryClothes[index];
                                                final isSelected = provider
                                                        .outfit[item.category]
                                                        ?.id ==
                                                    item.id;

                                                return GestureDetector(
                                                  onTap: () {
                                                    if (provider.userPhotoPath == null) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(
                                                          content: Text('가이드를 확인하기 위해 인물 사진을 먼저 등록해 주세요!'),
                                                          duration: Duration(seconds: 2),
                                                        ),
                                                      );
                                                      _uploadUserPhoto(provider);
                                                      return;
                                                    }
                                                    provider.toggleOutfitItem(item);
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              16),
                                                      border: Border.all(
                                                        color: isSelected
                                                            ? AppTheme.accent
                                                            : Colors
                                                                .transparent,
                                                        width: 2,
                                                      ),
                                                      boxShadow: const [
                                                        BoxShadow(
                                                          color:
                                                              Color(0x05000000),
                                                          blurRadius: 4,
                                                          offset: Offset(0, 1),
                                                        )
                                                      ],
                                                    ),
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              14),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Expanded(
                                                            child: Stack(
                                                              children: [
                                                                Positioned.fill(
                                                                  child: ClothingImage(
                                                                      imageUrl:
                                                                          item.imageUrl),
                                                                ),
                                                                if (isSelected)
                                                                  Positioned
                                                                      .fill(
                                                                    child:
                                                                        Container(
                                                                      color: AppTheme
                                                                          .accent
                                                                          .withValues(
                                                                              alpha: 0.15),
                                                                      child:
                                                                          const Center(
                                                                        child:
                                                                            CircleAvatar(
                                                                          backgroundColor:
                                                                              AppTheme.accent,
                                                                          radius:
                                                                              14,
                                                                          child: Icon(
                                                                              Icons.check,
                                                                              color: Colors.white,
                                                                              size: 14),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                              ],
                                                            ),
                                                          ),
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(8),
                                                            child: Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  item.name,
                                                                  style:
                                                                      const TextStyle(
                                                                    fontSize:
                                                                        10,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color: AppTheme
                                                                        .primary,
                                                                  ),
                                                                  maxLines: 1,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis,
                                                                ),
                                                                Text(
                                                                  '${item.price}원',
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize: 9,
                                                                    color: Colors
                                                                            .grey[
                                                                        500],
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
                                              },
                                            ),
                                    ],
                                  ),
                                ),
                                // 기획전 / 세일 정보 프로모션 배너 슬라이더
                                Container(
                                  height: 110,
                                  margin: const EdgeInsets.only(left: 40, right: 40, bottom: 20, top: 20),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: PageView.builder(
                                      controller: _promoPageController,
                                      onPageChanged: (int page) {
                                        setState(() {
                                          _promoCurrentPage = page;
                                        });
                                      },
                                      itemCount: _promotions.length,
                                      itemBuilder: (context, index) {
                                        final promo = _promotions[index];
                                        return Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            Image.network(
                                              promo['image']!,
                                              fit: BoxFit.cover,
                                              alignment: Alignment.center,
                                            ),
                                            Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.centerLeft,
                                                  end: Alignment.centerRight,
                                                  colors: [
                                                    Colors.black.withOpacity(0.65),
                                                    Colors.black.withOpacity(0.1),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(16.0),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                        decoration: BoxDecoration(
                                                          color: AppTheme.accent,
                                                          borderRadius: BorderRadius.circular(10),
                                                        ),
                                                        child: Text(
                                                          promo['badge']!,
                                                          style: const TextStyle(
                                                            fontSize: 9,
                                                            color: Colors.white,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    promo['title']!,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    promo['subtitle']!,
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.white.withOpacity(0.8),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      },
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
                ),
              ],
            ),


            // 하단 예상 총액 및 AI 피팅 버튼 바
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  border: Border(
                      top: BorderSide(color: Colors.grey[300]!, width: 1)),
                ),
                padding: const EdgeInsets.only(
                    top: 16, bottom: 12, left: 40, right: 40),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Container(
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppTheme.secondary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${totalPrice.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]},")}원',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 5,
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF7C8954), // 조금 더 진한 올리브 그린
                              Color(0xFF5A6B45), // 브랜드 올리브 카키
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            children: [
                              // 1. 왼쪽에서 오른쪽으로 슥 지나가는 대각선 광택 하이라이트 (Soft Diagonal Shimmer)
                              Positioned.fill(
                                child: AnimatedBuilder(
                                  animation: _shimmerController,
                                  builder: (context, child) {
                                    final value = _shimmerController.value;
                                    // begin과 end를 넓은 사선 방향으로 배치하여 대각선 느낌을 확실히 살리고, 수평으로 이동시킵니다.
                                    final beginX = -2.5 + (value * 5.0);
                                    final endX = -1.0 + (value * 5.0);
                                    return Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            const Color(0xFFFFF7C2).withValues(alpha: 0.0),
                                            const Color(0xFFFFF7C2).withValues(alpha: 0.05),
                                            const Color(0xFFFFF7C2).withValues(alpha: 0.16), // 따뜻하게 퍼지는 노란 광택선
                                            const Color(0xFFFFF7C2).withValues(alpha: 0.05),
                                            const Color(0xFFFFF7C2).withValues(alpha: 0.0),
                                          ],
                                          // 경계가 딱딱 끊어지지 않고 안개처럼 은은하게 블러처리되도록 stops를 넓게 분산
                                          stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                                          begin: Alignment(beginX, -1.2),
                                          end: Alignment(endX, 1.2),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              // 2. 상단 하프 글래스 효과 (유리 재질 반사)
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                height: 28,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.white.withValues(alpha: 0.22),
                                        Colors.white.withValues(alpha: 0.03),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),
                              ),

                              // 4. 실제 버튼 및 인터랙션 레이어
                              Positioned.fill(
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () => _handleStartFitting(provider),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.flash_on,
                                            size: 18, color: Colors.white),
                                        const SizedBox(width: 8),
                                        Text(
                                          provider.outfit.isNotEmpty
                                              ? 'AI 피팅 시작 (${provider.outfit.length})'
                                              : 'AI 피팅 시작',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
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

  void _showPhotoAdjustmentDialog(
      BuildContext context, String tempImagePath, FittingProvider provider) {
    double topGuideY = 120.0;
    double bottomGuideY = 360.0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 620),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 25,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. 헤더 영역
                    Padding(
                      padding: const EdgeInsets.only(top: 20, bottom: 12),
                      child: Column(
                        children: [
                          const Text(
                            '가이드라인 직접 조정',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '초록 가이드선을 손가락으로 드래그하여 신체에 맞춰보세요.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // 2. 이미지 영역 (움직이는 가이드라인 격자 오버레이 포함)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey[300]!, width: 1),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(19),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final maxH = constraints.maxHeight;
                                
                                return Stack(
                                  children: [
                                    // 배경: 사용자가 선택한 임시 사진
                                    Positioned.fill(
                                      child: kIsWeb
                                          ? Image.network(
                                              tempImagePath,
                                              fit: BoxFit.cover,
                                              alignment: Alignment.center,
                                            )
                                          : Image.file(
                                              File(tempImagePath),
                                              fit: BoxFit.cover,
                                              alignment: Alignment.center,
                                            ),
                                    ),
                                    
                                    // 고정 오버레이: 십자선 및 노치 데코
                                    Positioned.fill(
                                      child: IgnorePointer(
                                        child: Stack(
                                          children: [
                                            // 노치 데코
                                            Positioned(
                                              top: 10,
                                              left: 0,
                                              right: 0,
                                              child: Center(
                                                child: Container(
                                                  width: 60,
                                                  height: 12,
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.accent.withValues(alpha: 0.4),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            // 고정 십자선
                                            Center(
                                              child: Container(
                                                width: double.infinity,
                                                height: 1.0,
                                                color: AppTheme.accent.withValues(alpha: 0.2),
                                              ),
                                            ),
                                            Center(
                                              child: Container(
                                                width: 1.0,
                                                height: double.infinity,
                                                color: AppTheme.accent.withValues(alpha: 0.2),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // 3. 움직이는 상단 가이드라인 (드래그 가능)
                                    Positioned(
                                      top: topGuideY - 20,
                                      left: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.translucent,
                                        onVerticalDragUpdate: (details) {
                                          setState(() {
                                            topGuideY = (topGuideY + details.delta.dy)
                                                .clamp(10.0, bottomGuideY - 40.0);
                                          });
                                        },
                                        child: Container(
                                          height: 40,
                                          color: Colors.transparent,
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Container(
                                                height: 2.0,
                                                color: AppTheme.accent,
                                              ),
                                              Positioned(
                                                right: 16,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.accent,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Row(
                                                    children: const [
                                                      Icon(Icons.unfold_more_rounded, size: 10, color: Colors.white),
                                                      SizedBox(width: 2),
                                                      Text(
                                                        '머리/어깨',
                                                        style: TextStyle(fontSize: 8.5, color: Colors.white, fontWeight: FontWeight.bold),
                                                      )
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),

                                    // 4. 움직이는 하단 가이드라인 (드래그 가능)
                                    Positioned(
                                      top: bottomGuideY - 20,
                                      left: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.translucent,
                                        onVerticalDragUpdate: (details) {
                                          setState(() {
                                            bottomGuideY = (bottomGuideY + details.delta.dy)
                                                .clamp(topGuideY + 40.0, maxH - 20.0);
                                          });
                                        },
                                        child: Container(
                                          height: 40,
                                          color: Colors.transparent,
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Container(
                                                height: 2.0,
                                                color: AppTheme.accent,
                                              ),
                                              Positioned(
                                                right: 16,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.accent,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Row(
                                                    children: const [
                                                      Icon(Icons.unfold_more_rounded, size: 10, color: Colors.white),
                                                      SizedBox(width: 2),
                                                      Text(
                                                        '발끝 정렬',
                                                        style: TextStyle(fontSize: 8.5, color: Colors.white, fontWeight: FontWeight.bold),
                                                      )
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // 5. 하단 액션 버튼
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 50),
                                side: BorderSide(color: Colors.grey[300]!),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                '다시 선택하기',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                provider.setUserPhoto(tempImagePath);
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accent,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                '이 구도로 등록',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
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
            );
          },
        );
      },
    );
  }

  void _showGuideDialog(BuildContext context, FittingProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        '올바른 인물 촬영 예시',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/guide_user_fullbody.png',
                          width: 120,
                          height: 160,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 120,
                            height: 160,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: const Icon(Icons.portrait_rounded,
                                size: 44, color: AppTheme.accent),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildGuideTextLine('O', Colors.green, '입으려는 부위까지 나오는 사진'),
                            const SizedBox(height: 10),
                            _buildGuideTextLine('O', Colors.green, '단독으로 나오는 사진'),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Divider(color: Color(0xFFE0E0E0), thickness: 1),
                            ),
                            _buildGuideTextLine('X', Colors.red, '의류 방향과 다른 자세의 사진'),
                            const SizedBox(height: 10),
                            _buildGuideTextLine('X', Colors.red, '여러 사람과 찍힌 사진'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('확인했습니다',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGuideTextLine(String prefix, Color prefixColor, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          prefix,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: prefixColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                height: 1.3),
          ),
        ),
      ],
    );
  }

  void _showFittingDetailsDialog(
      BuildContext context, FittingProvider provider) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent, // 검은 배경 제거
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent, // 부모 다이얼로그 배경을 완벽하게 투명화하여 외부 여백 제거
          elevation: 0, // 다이얼로그 기본 그림자 제거
          insetPadding: EdgeInsets.zero, // 가로 정렬 한계 해제
          alignment: const Alignment(0.44, -0.84), // 왼쪽으로 좀더 확실히 이동
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          child: UnconstrainedBox( // Dialog 의 최소 가로폭 강제 제약을 해제하여 원하는 210폭이 강제 작동하게 조치
            child: Container(
              width: 210, // 이제 정확하게 가로 210 폭으로 축소되어 렌더링됨
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.accent.withValues(alpha: 0.2), // 연한 올리브 테두리 선
                width: 1.2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context, // 최상위 부모 컨텍스트 사용으로 팝업 중첩 제약 무력화
                          builder: (ctx) => Dialog(
                            backgroundColor: Colors.white,
                            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Container(
                              width: 300,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: AppTheme.accent.withValues(alpha: 0.2), // 연한 올리브 테두리 선 일치화
                                  width: 1.2,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: const [
                                      Icon(Icons.swap_vert_rounded,
                                          color: Color(0xFFB27A1C), size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        '피팅 차감 순서',
                                        style: TextStyle(
                                          fontSize: 20, // 헤더로 확 튀게 20으로 조절
                                          fontWeight: FontWeight.w900, // 더욱 진하게
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  _buildOrderRow(
                                      1,
                                      '프리미엄 구독',
                                      '프리미엄 횟수 우선 차감',
                                      Icons.workspace_premium_rounded,
                                      AppTheme.primary),
                                  const SizedBox(height: 12),
                                  _buildOrderRow(
                                      2,
                                      '보유 토큰',
                                      '충전 토큰 우선 차감',
                                      Icons.toll_rounded,
                                      const Color(0xFF7A6A45)),
                                  const SizedBox(height: 12),
                                  _buildOrderRow(
                                      3,
                                      '월 기본 무료',
                                      '월 기본 제공 횟수 차감',
                                      Icons.card_giftcard_rounded,
                                      AppTheme.accent),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      '여러 유형의 피팅 횟수를 보유 중일 경우\n위의 순서대로 자동으로 차감됩니다.',
                                      style: TextStyle(
                                        fontSize: 13.0,
                                        height: 1.6,
                                        fontWeight: FontWeight.w500, // 글자 두께를 차분하게 조절
                                        color: Color(0xFF78909C), // 연한 올리브 그레이 텍스트 색상 적용
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Align(
                                    alignment: Alignment.center, // 확인 버튼 가로 중앙 정렬
                                    child: TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 40, vertical: 10), // 가로 와이드 40 패딩
                                        backgroundColor: const Color(0xFF8E9B61), // 연한 녹색 버튼색
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: const Text(
                                        '확인',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      child: const Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFFB27A1C),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      '남은 피팅',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(
                    color: Color(0xFFECEFF1), // 연한 올리브그레이 톤의 얇은 구분선
                    thickness: 1,
                  ),
                ),
                _buildBalanceRow('보유 토큰', '${provider.tokenCount}회',
                    Icons.toll_rounded, const Color(0xFF7A6A45)),
                const SizedBox(height: 12),
                _buildBalanceRow('월 기본 무료', '${provider.freeFittingCount}회',
                    Icons.card_giftcard_rounded, AppTheme.accent),
                const SizedBox(height: 12),
                _buildBalanceRow(
                    '프리미엄',
                    provider.isPremium
                        ? '${provider.premiumFittingCount}회'
                        : '0회',
                    Icons.workspace_premium_rounded,
                    AppTheme.primary),
                const SizedBox(height: 18), // 프리미엄 글자와 확인 버튼 간격 넓힘
                Align(
                  alignment: Alignment.center, // 정중앙
                  child: TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 10), // 가로로 더 넓어진 확인창
                      backgroundColor: const Color(0xFF8E9B61), // 연한 녹색
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '확인',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),),
        );
      },
    );
  }

  Widget _buildOrderRow(
      int order, String title, String subtitle, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$order',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold, // 너무 과한 w900 -> 적절히 강조된 bold 로 톤다운
                color: Colors.black87, // 부드러운 흑색
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500, // 투박했던 bold -> 얇고 세련된 w500 굵기로 톤다운
                color: Colors.black54, // 부드럽고 가독성 좋은 진회색
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBalanceRow(
      String label, String value, IconData icon, Color iconColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildImageGuideCard({
    required String title,
    required Color titleColor,
    required List<Map<String, String>> items,
    bool isWarning = false,
  }) {
    final Color bgColor = isWarning ? Colors.redAccent : Colors.green;
    return Container(
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.05),
        border: Border.all(color: bgColor.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: titleColor)),
          const SizedBox(height: 14),
          SizedBox(
            height: 130,
            child: Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 80,
                          child: Column(
                            children: [
                              Expanded(
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    GestureDetector(
                                      onTap: () => _showZoomableImageDialog(
                                        context,
                                        AssetImage(item['image']!),
                                      ),
                                      child: Container(
                                        width: 80,
                                        height: double.infinity,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: Colors.grey[300]!),
                                          image: DecorationImage(
                                            image: AssetImage(item['image']!),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: -6,
                                      left: -6,
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          isWarning
                                              ? Icons.cancel
                                              : Icons.check_circle,
                                          color: isWarning
                                              ? Colors.redAccent
                                              : Colors.green,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                item['desc']!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  height: 1.3,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                              ),
                            ],
                          ),
                        ),
                        if (index != items.length - 1)
                          const SizedBox(width: 20),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showZoomableImageDialog(
      BuildContext context, ImageProvider imageProvider) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.9),
      pageBuilder: (context, anim1, anim2) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  clipBehavior: Clip.none,
                  child: Image(
                    image: imageProvider,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.pinch_rounded,
                            color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          '핀치 제스처로 확대/축소할 수 있습니다',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showUserPhotoOptions(BuildContext context, FittingProvider provider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: SizedBox(
            width: 130,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '인물 사진 관리',
                    textAlign: TextAlign.center,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 2),
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _showZoomableImageDialog(
                        context,
                        kIsWeb
                            ? NetworkImage(provider.userPhotoPath!) as ImageProvider
                            : FileImage(File(provider.userPhotoPath!)) as ImageProvider,
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      child: const Text(
                        '사진 보기',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      provider.setUserPhoto(null);
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      child: const Text(
                        '사진 삭제',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 2),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      child: const Text(
                        '취소',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
