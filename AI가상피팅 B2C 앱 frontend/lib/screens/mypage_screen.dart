import 'package:flutter/material.dart';
import '../widgets/commercial_footer.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/fitting_provider.dart';
import '../widgets/notification_icon.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  String _nickname = '패셔니스타 유저';

  void _showEditNicknameDialog() {
    final TextEditingController controller =
        TextEditingController(text: _nickname);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title:
            const Text('닉네임 변경', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '새 닉네임을 입력하세요',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() {
                  _nickname = controller.text.trim();
                });
              }
              Navigator.pop(context);
              _showSnackBar(context, '닉네임이 변경되었습니다.');
            },
            child: const Text('저장',
                style: TextStyle(
                    color: AppTheme.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FittingProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 40.0, right: 40.0, top: 22.0, bottom: 22.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '마이페이지',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const NotificationIcon(),
                ],
              ),
            ),
            const Divider(
                color: Color(0xFFEEEEEE), thickness: 1, height: 1), // 헤드라인 밑 선
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40.0, vertical: 0.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
// 2. 프로필 정보 카드 (배경색 제거됨)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 16.0,
                                horizontal: 40.0), // 위아래 간격 줄임 (32 -> 16)
                            decoration: const BoxDecoration(
                              color: Colors.transparent,
                            ),
                            child: Column(
                              children: [
                                // 아바타 원형
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // 사용자 이름 및 수정 버튼
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _nickname,
                                      style: const TextStyle(
                                        color: AppTheme.primary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: _showEditNicknameDialog,
                                      child: Icon(
                                        Icons.edit,
                                        size: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                // 이메일
                                Text(
                                  'lumiere_user@example.com',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                        ],
                      ),
                    ),
                    const SizedBox(height: 8), // 프로필 아래 여백 약간
                    const Divider(
                        color: Color(0xFFEEEEEE),
                        thickness: 1,
                        height: 1), // 프로필과 카테고리 사이 구분선
                    // 3. 메뉴 리스트
                    Container(
                      color: AppTheme.background,
                      padding: const EdgeInsets.symmetric(vertical: 0.0),
                      child: Column(
                        children: [
                           _buildMenuItem(
                             context,
                             title: '좋아요한 옷장',
                             icon: Icons.favorite_border,
                             onTap: () => provider.setScreen('favorites'),
                             showBottomBorder: false,
                           ),
                          const Divider(color: Color(0xFFEEEEEE), thickness: 1, height: 1),
                          _buildMenuItem(
                            context,
                            title: '구독 플랜',
                            icon: Icons.card_membership,
                            onTap: () => provider.setScreen('subscription'),
                          ),
                          _buildMenuItem(
                            context,
                            title: '이벤트 및 혜택',
                            icon: Icons.card_giftcard,
                            onTap: () => provider.setScreen('event'),
                            showBottomBorder: false,
                          ),
                          const Divider(color: Color(0xFFEEEEEE), thickness: 1, height: 1),
                          _buildMenuItem(
                            context,
                            title: '공지사항',
                            icon: Icons.campaign_outlined,
                            onTap: () => provider.setScreen('notice'),
                          ),
                          _buildMenuItem(
                            context,
                            title: '고객센터',
                            icon: Icons.headset_mic_outlined,
                            onTap: () => provider.setScreen('support'),
                            showBottomBorder: false,
                          ),
                          const Divider(color: Color(0xFFEEEEEE), thickness: 1, height: 1),
                          _buildMenuItem(
                            context,
                            title: '설정',
                            icon: Icons.settings_outlined,
                            onTap: () => provider.setScreen('settings'),
                          ),
                          _buildMenuItem(
                            context,
                            title: '서비스 정보',
                            icon: Icons.info_outline,
                            onTap: () => provider.setScreen('about'),
                            showBottomBorder: false,
                          ),
                        ],
                      ),
                    ),
                    const Divider(
                        color: Color(0xFFEEEEEE),
                        thickness: 1,
                        height: 1), // 메뉴와 푸터 사이 구분선
                    const CommercialFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Color? textColor,
    bool showBottomBorder = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque, // 빈 공간 클릭도 인식되도록 설정
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: showBottomBorder
              ? Border(
                  bottom: BorderSide(
                    color: Colors.grey[100]!,
                    width: 1.0,
                  ),
                )
              : null,
        ),
        padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 40.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.grey[700],
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: textColor ?? Colors.grey[700],
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
