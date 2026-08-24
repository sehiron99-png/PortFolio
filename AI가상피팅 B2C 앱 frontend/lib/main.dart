import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/fitting_provider.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/login_loading_screen.dart';
import 'screens/qr_screen.dart';
import 'screens/home_screen.dart';
import 'screens/camera_screen.dart';
import 'widgets/add_photo_popup.dart';
import 'screens/wardrobe_screen.dart';
import 'screens/fitting_screen.dart';
import 'screens/result_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/mypage_screen.dart';
import 'screens/history_screen.dart';
import 'screens/subscription_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/event_screen.dart';
import 'screens/notice_screen.dart';
import 'screens/support_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/about_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/inquiry_screen.dart';
import 'dart:ui';

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FittingProvider()),
      ],
      child: const FittingApp(),
    ),
  );
}

class FittingApp extends StatelessWidget {
  const FittingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mirror - AI Fitting Room',
      theme: AppTheme.lightTheme,
      scrollBehavior: AppScrollBehavior(),
      debugShowCheckedModeBanner: false,
      home: const MainNavigator(),
    );
  }
}

class MainNavigator extends StatelessWidget {
  const MainNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    // FittingProvider 상태 구독
    final provider = Provider.of<FittingProvider>(context);
    final screen = provider.currentScreen;

    Widget currentScreenWidget;
    // 네비게이션 바가 없는 특수 전체 화면 분기
    if (screen == 'welcome') {
      currentScreenWidget = const WelcomeScreen();
    } else if (screen == 'login') {
      currentScreenWidget = const LoginScreen();
    } else if (screen == 'login_loading') {
      currentScreenWidget = const LoginLoadingScreen();
    } else if (screen == 'qr') {
      currentScreenWidget = const QrScreen();
    } else if (screen == 'camera') {
      // 웹에서 카메라 화면의 최대 너비만 제한하고 비율은 카메라 자체 비율을 따르도록 설정
      currentScreenWidget = Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: const CameraScreen(),
          ),
        ),
      );
    } else if (screen == 'result') {
      currentScreenWidget = const ResultScreen();
    } else {
      currentScreenWidget = const MainShell();
    }
    return PopScope(
      canPop: false, // 시스템 뒤로가기 기본 동작 방지
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final popped = provider.goBack();
        if (!popped) {
          // 뒤로갈 이력이 없다면(앱의 최상단 화면인 qr 등) 앱 종료
          await SystemNavigator.pop();
        }
      },
      child: currentScreenWidget,
    );
  }
}

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FittingProvider>(context);
    final screen = provider.currentScreen;
    final outfitCount = provider.outfit.length;

    // Determine the "base" screen if we are on a notification overlay
    String baseScreen = screen;
    final shellScreens = ['home', 'fitting', 'result', 'wardrobe', 'mypage', 'history'];
    if (!shellScreens.contains(screen)) {
      // 서브카테고리 화면일 때 히스토리에서 가장 가까운 셸 화면을 찾아 탭 하이라이트 결정
      baseScreen = provider.screenHistory.reversed
          .firstWhere((s) => shellScreens.contains(s), orElse: () => 'home');
    }

    int selectedIndex = 0;
    if (baseScreen == 'home' || baseScreen == 'fitting' || baseScreen == 'result') {
      selectedIndex = 0;
    } else if (baseScreen == 'history') {
      selectedIndex = 1;
    } else if (baseScreen == 'wardrobe') {
      selectedIndex = 2;
    } else if (baseScreen == 'mypage') {
      selectedIndex = 3;
    }

    final subCategories = [
      'favorites',
      'subscription',
      'edit_profile',
      'event',
      'notice',
      'support',
      'inquiry',
      'settings',
      'about',
      'notification'
    ];
    final isSubCategory = subCategories.contains(screen);
    final mypageSubCategories = [
      'favorites',
      'subscription',
      'edit_profile',
      'event',
      'notice',
      'support',
      'inquiry',
      'settings',
      'about'
    ];
    final isMypageSubCategory = mypageSubCategories.contains(screen);

    Widget? subCategoryWidget;
    if (screen == 'favorites')
      subCategoryWidget = const FavoritesScreen();
    else if (screen == 'subscription')
      subCategoryWidget = const SubscriptionScreen();
    else if (screen == 'edit_profile')
      subCategoryWidget = const EditProfileScreen();
    else if (screen == 'event')
      subCategoryWidget = const EventScreen();
    else if (screen == 'notice')
      subCategoryWidget = const NoticeScreen();
    else if (screen == 'support')
      subCategoryWidget = const SupportScreen();
    else if (screen == 'inquiry')
      subCategoryWidget = const InquiryScreen();
    else if (screen == 'settings')
      subCategoryWidget = const SettingsScreen();
    else if (screen == 'about')
      subCategoryWidget = const AboutScreen();
    else if (screen == 'notification')
      subCategoryWidget = const NotificationScreen();

    return Scaffold(
      // endDrawer removed
      // 현재 화면 본문 렌더링
      body: Stack(
        children: [
          IndexedStack(
            index: selectedIndex,
            children: const [
              FittingScreen(),
              HistoryScreen(),
              WardrobeScreen(),
              MyPageScreen(),
            ],
          ),
          if (isSubCategory && subCategoryWidget != null)
            Container(
              color: AppTheme.background,
              child: subCategoryWidget,
            ),
        ],
      ),

      // 플랫하고 세련된 하단 커스텀 5탭 네비게이션 바
      bottomNavigationBar: Container(
        height: 86 + MediaQuery.of(context).padding.bottom,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Colors.black.withOpacity(0.05),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 1. 피팅룸 (Fitting)
              _buildNavItem(
                icon: (selectedIndex == 0 && !isMypageSubCategory)
                    ? Icons.auto_awesome
                    : Icons.auto_awesome_outlined,
                label: '피팅룸',
                isActive: selectedIndex == 0 && !isMypageSubCategory,
                badgeCount: outfitCount,
                activeColor: AppTheme.fittingAccent,
                onTap: () => provider.setScreen('fitting'),
              ),
              // 2. AI 피팅내역 (History)
              _buildNavItem(
                icon: Icons.history,
                label: 'AI 피팅내역',
                isActive: selectedIndex == 1 && !isMypageSubCategory,
                onTap: () => provider.setScreen('history'),
              ),
              // 3. 카메라 (Center Floating Button)
              _buildCenterCameraItem(context, provider),
              // 4. 내 옷장 (Wardrobe)
              _buildNavItem(
                icon: (selectedIndex == 2 && !isMypageSubCategory)
                    ? Icons.shopping_bag
                    : Icons.shopping_bag_outlined,
                label: '내 옷장',
                isActive: selectedIndex == 2 && !isMypageSubCategory,
                onTap: () => provider.setScreen('wardrobe'),
              ),
              // 5. 마이페이지 (MyPage)
              _buildNavItem(
                icon: selectedIndex == 3 || isMypageSubCategory
                    ? Icons.person
                    : Icons.person_outlined,
                label: '마이페이지',
                isActive: selectedIndex == 3 || isMypageSubCategory,
                onTap: () => provider.setScreen('mypage'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    int badgeCount = 0,
    Color? activeColor,
  }) {
    final color =
        isActive ? (activeColor ?? AppTheme.accent) : Colors.grey[400];
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: activeColor ?? AppTheme.accent,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? (activeColor ?? AppTheme.accent)
                    : Colors.grey[500],
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      ),
      ),
    );
  }

  Widget _buildCenterCameraItem(
      BuildContext context, FittingProvider provider) {
    return Expanded(
      child: Center(
        child: GestureDetector(
          onTap: () {
        showAddPhotoPopup(context, provider);
      },
      child: Transform.translate(
        offset: const Offset(0, -8), // 바텀 바 위로 플로팅
        child: SizedBox(
          width: 68,
          height: 68,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF6B7A56), // 라이트 올리브 카키
                      Color(0xFF42542E), // 딥 올리브 카키
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5A6B45).withOpacity(0.45),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                    const BoxShadow(
                      color: Colors.white,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
        ),
      ),
      ),
      ),
    );
  }
}
