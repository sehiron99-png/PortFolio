import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/fitting_provider.dart';
import '../theme/app_theme.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  String? _pressedNotificationId;
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': '1',
      'category': '서비스 알림',
      'iconColor': Colors.blue,
      'icon': Icons.check_circle_outline,
      'title': '피팅 완료',
      'message': '가상 피팅이 완료되었습니다. 옷장에서 확인해보세요!',
      'timeAgo': '방금 전',
      'isUnread': true,
      'route': 'fitting',
    },
    {
      'id': '2',
      'category': '결제/구독',
      'iconColor': Colors.orange,
      'icon': Icons.credit_card_outlined,
      'title': '플랜 결제 완료',
      'message': '프리미엄 플랜 결제가 성공적으로 완료되었습니다. (2026-07-08)',
      'timeAgo': '2시간 전',
      'isUnread': true,
      'route': 'subscription',
    },
    {
      'id': '3',
      'category': '이벤트',
      'iconColor': Colors.pink,
      'icon': Icons.local_offer_outlined,
      'title': '여름 시즌 맞이 특가 할인',
      'message': '인기 의류 최대 50% 할인 이벤트를 확인해 보세요.',
      'timeAgo': '1일 전',
      'isUnread': false,
      'route': 'event',
    },
  ];

  void _removeNotification(String id) {
    setState(() {
      _notifications.removeWhere((item) => item['id'] == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FittingProvider>(context);
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: AppTheme.primary, size: 20),
          onPressed: () => provider.goBack(),
        ),
        title: const Text('알림',
            style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        centerTitle: true,
      ),
      body: _notifications.isEmpty
          ? const Center(
              child:
                  Text('새로운 알림이 없습니다.', style: TextStyle(color: Colors.grey)))
          : ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              children: _notifications.map((item) {
                return _buildNotificationItem(
                  id: item['id'] as String,
                  category: item['category'] as String,
                  iconColor: item['iconColor'] as Color,
                  icon: item['icon'] as IconData,
                  title: item['title'] as String,
                  message: item['message'] as String,
                  timeAgo: item['timeAgo'] as String,
                  isUnread: item['isUnread'] as bool,
                  onTap: () {
                    Provider.of<FittingProvider>(context, listen: false)
                        .setScreen(item['route'] as String);
                  },
                );
              }).toList(),
            ),
    );
  }

  Widget _buildNotificationItem({
    required String id,
    required String category,
    required Color iconColor,
    required IconData icon,
    required String title,
    required String message,
    required String timeAgo,
    required bool isUnread,
    required VoidCallback onTap,
  }) {
    final isPressed = _pressedNotificationId == id;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressedNotificationId = id),
      onTapCancel: () => setState(() => _pressedNotificationId = null),
      onTapUp: (_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) setState(() => _pressedNotificationId = null);
      },
      onTap: onTap,
      child: AnimatedScale(
        scale: isPressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isPressed
                ? (isUnread ? const Color(0xFF4CA624).withValues(alpha: 0.15) : Colors.grey[100])
                : (isUnread ? const Color(0xFF4CA624).withValues(alpha: 0.05) : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: isUnread
                ? Border.all(color: const Color(0xFF4CA624).withValues(alpha: 0.3))
                : Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon,
                  color: isUnread ? const Color(0xFF4CA624) : Colors.grey[400], size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  category,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isUnread
                                        ? const Color(0xFF4CA624)
                                        : Colors.grey[500],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  timeAgo,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isUnread
                                        ? const Color(0xFF4CA624)
                                        : Colors.grey[400],
                                    fontWeight: isUnread
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isUnread
                                    ? Colors.black87
                                    : Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _removeNotification(id),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Icon(Icons.close,
                              size: 24, color: Colors.grey[400]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 13,
                      color: isUnread ? Colors.black54 : Colors.grey[500],
                      height: 1.4,
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
