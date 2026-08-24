import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/fitting_provider.dart';
import 'terms_screen.dart';
import 'privacy_screen.dart';
import 'license_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FittingProvider>(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: AppTheme.primary, size: 20),
          onPressed: () => provider.goBack(),
        ),
        title: const Text('서비스 정보',
            style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        centerTitle: true,
      ),
      body: Container(
        color: const Color(0xFFFAFAFA),
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/icon/app_icon.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 80,
                        height: 80,
                        color: AppTheme.primary,
                        child: const Center(
                          child: Text('L',
                              style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontStyle: FontStyle.italic)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Lumière',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary)),
                  const SizedBox(height: 8),
                  Text('버전 1.2.0',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            _buildInfoItem(context, '이용 약관'),
            _buildInfoItem(context, '개인정보 처리방침'),
            _buildInfoItem(context, '오픈소스 라이선스'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, String title) {
    return Column(
      children: [
        ListTile(
          title: Text(title, style: const TextStyle(fontSize: 16, color: Colors.black87)),
          trailing:
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          onTap: () {
            Widget targetScreen;
            if (title == '이용 약관') {
              targetScreen = const TermsScreen();
            } else if (title == '개인정보 처리방침') {
              targetScreen = const PrivacyScreen();
            } else {
              targetScreen = const LicenseScreen();
            }
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
                transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
              ),
            );
          },
        ),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
      ],
    );
  }
}
