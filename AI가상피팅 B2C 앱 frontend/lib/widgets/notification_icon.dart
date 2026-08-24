import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/fitting_provider.dart';
import '../theme/app_theme.dart';

class NotificationIcon extends StatefulWidget {
  final Color iconColor;
  final Color badgeColor;

  const NotificationIcon({
    super.key,
    this.iconColor = AppTheme.primary,
    this.badgeColor = const Color(0xFF6DA248),
  });

  @override
  State<NotificationIcon> createState() => _NotificationIconState();
}

class _NotificationIconState extends State<NotificationIcon> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapCancel: () => setState(() => _isPressed = false),
      onTapUp: (_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) setState(() => _isPressed = false);
      },
      onTap: () {
        Provider.of<FittingProvider>(context, listen: false)
            .setScreen('notification');
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: widget.iconColor == Colors.white
                    ? (Colors.white.withValues(alpha: _isPressed ? 0.45 : 0.2))
                    : (_isPressed ? Colors.grey[300] : Colors.grey[100]),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_outlined,
                color: widget.iconColor,
                size: 24,
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: widget.badgeColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.transparent, width: 0),
                ),
                child: const Center(
                  child: Text(
                    '2',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
