import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/fitting_provider.dart';
import '../widgets/top_alert.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;

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
        title: const Text('설정',
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 12),
            child: Text('디스플레이',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey)),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildSwitchTile(
                  title: '다크 모드',
                  value: _isDarkMode,
                  onChanged: (val) {
                    setState(() => _isDarkMode = val);
                    TopAlert.show(context, '다크 모드 기능은 준비 중입니다.');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 12),
            child: Text('앱 알림',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey)),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildSwitchTile(
                  title: '알림 허용',
                  subtitle: '앱에서 보내는 푸시 알림을 받습니다',
                  value: provider.masterNotice,
                  onChanged: (val) => provider.setNotices(master: val),
                ),
                const Divider(height: 1, indent: 20, endIndent: 20),
                _buildSwitchTile(
                  title: '피팅 완료 알림',
                  value: provider.fittingNotice,
                  onChanged: (val) => provider.setNotices(fitting: val),
                ),
                _buildSwitchTile(
                  title: '결제 및 구독 알림',
                  value: provider.billingNotice,
                  onChanged: (val) => provider.setNotices(billing: val),
                ),
                _buildSwitchTile(
                  title: '이벤트 및 마케팅 알림',
                  value: provider.marketingNotice,
                  onChanged: (val) => provider.setNotices(marketing: val),
                ),
                _buildSwitchTile(
                  title: '야간 알림 수신 (21시~08시)',
                  value: provider.nightNotice,
                  onChanged: (val) => provider.setNotices(night: val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildActionTile(
                  title: '로그아웃',
                  titleColor: Colors.redAccent,
                  onTap: () {
                    _showLogoutDialog(context);
                  },
                ),
                const Divider(height: 1, indent: 20, endIndent: 20),
                 _buildActionTile(
                  title: '회원 탈퇴',
                  titleColor: Colors.grey[400],
                  fontSize: 13,
                  onTap: () {
                    _showWithdrawDialog(context);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
     ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ]
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            activeColor: AppTheme.fittingAccent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    String? trailingText,
    Color? titleColor,
    double fontSize = 16,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                color: titleColor ?? Colors.black87,
              ),
            ),
            if (trailingText != null)
              Text(
                trailingText,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              )
            else if (onTap != null)
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('로그아웃',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
        content: const Text('정말 로그아웃 하겠습니까?', textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          const SizedBox(width: 16),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              final provider =
                  Provider.of<FittingProvider>(context, listen: false);
              provider.goBack(); // go back from settings
              provider.logout(); // trigger logout logic if available in provider
              TopAlert.show(context, '로그아웃 되었습니다.');
            },
            child: const Text('로그아웃',
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('회원 탈퇴',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
        content: const Text('정말 탈퇴 하겠습니까?', textAlign: TextAlign.center),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          const SizedBox(width: 16),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              final provider =
                  Provider.of<FittingProvider>(context, listen: false);
              provider.goBack();
              provider.logout();
              TopAlert.show(context, '회원 탈퇴 처리가 완료되었습니다.');
            },
            child: const Text('탈퇴하기',
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
