import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/fitting_provider.dart';

class NoticeScreen extends StatefulWidget {
  const NoticeScreen({super.key});

  @override
  State<NoticeScreen> createState() => _NoticeScreenState();
}

class _NoticeScreenState extends State<NoticeScreen> {
  final Set<int> _expandedIndices = {};

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FittingProvider>(context);

    final List<Map<String, String>> notices = [
      {
        'title': 'Lumiere 서비스 업데이트 안내 (v1.2.0)',
        'date': '2026.07.08',
        'content':
            '안녕하세요, Lumiere 팀입니다.\n\n앱 성능 개선 및 새로운 AI 피팅 모델이 적용된 v1.2.0 업데이트가 배포되었습니다. 항상 이용해주셔서 감사합니다.',
      },
      {
        'title': '새벽 서버 점검 안내 (7/10)',
        'date': '2026.07.05',
        'content':
            '안정적인 service 제공을 위해 아래와 같이 서버 점검이 진행될 예정입니다.\n\n- 일시: 2026.07.10 02:00 ~ 04:00 (2시간)\n- 내용: DB 안정화 작업\n\n해당 시간에는 서비스 이용이 제한되오니 양해 부탁드립니다.',
      },
      {
        'title': '여름 시즌 신규 의류 브랜드 입점 안내',
        'date': '2026.07.01',
        'content':
            '국내 인기 디자이너 브랜드 3곳이 추가 입점되었습니다.\n이제 더 다양한 스타일을 AI 가상 피팅으로 즐겨보세요!',
      },
      {
        'title': '카카오페이 결제 수단 추가 안내',
        'date': '2026.06.28',
        'content':
            '고객님들의 편의를 위해 결제 수단으로 카카오페이가 추가되었습니다.\n프리미엄 피팅 서비스를 더욱 간편하게 이용해 보세요.',
      },
      {
        'title': 'iOS 앱 크래시 문제 해결 안내',
        'date': '2026.06.25',
        'content':
            '일부 iOS 기기에서 피팅 결과 화면 진입 시 발생하던 튕김 현상을 해결하였습니다.\n앱스토어에서 최신 버전(v1.1.9)으로 업데이트 부탁드립니다.',
      },
      {
        'title': '개인정보 처리방침 개정 안내',
        'date': '2026.06.20',
        'content':
            '개인정보 처리방침이 일부 변경되어 안내해 드립니다.\n변경된 약관은 앱 내 [서비스 정보] 탭에서 확인하실 수 있습니다.',
      },
      {
        'title': '체형 분석 AI 모델 업그레이드 완료',
        'date': '2026.06.15',
        'content':
            '더욱 정교한 피팅 결과를 제공하기 위해 체형 분석 AI 모델의 대규모 업데이트를 진행했습니다.\n이제 옷의 주름과 핏이 더욱 자연스럽게 표현됩니다.',
      },
      {
        'title': '친구 초대 이벤트 당첨자 발표',
        'date': '2026.06.05',
        'content':
            '지난 달 진행된 "내 옷장 공유하기" 이벤트 당첨자가 발표되었습니다.\n당첨되신 50분께는 개별 푸시 알림 및 이메일로 안내해 드렸습니다.',
      },
      {
        'title': 'Lumiere 정식 출시 안내 (v1.0.0)',
        'date': '2026.05.01',
        'content':
            '안녕하세요! 혁신적인 AI 가상 피팅 앱 Lumiere가 드디어 정식 출시되었습니다.\n앞으로 많은 관심과 사랑 부탁드립니다.',
      },
      {
        'title': '베타 테스트 종료 및 데이터 이관 안내',
        'date': '2026.04.28',
        'content':
            '약 2달간 진행된 클로즈 베타 테스트가 종료되었습니다.\n베타 테스터 분들의 계정 정보는 정식 서비스로 안전하게 이관되었습니다.',
      },
    ];

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
        title: const Text('공지사항',
            style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        centerTitle: true,
      ),
      body: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        itemCount: notices.length,
        itemBuilder: (context, index) {
          final notice = notices[index];
          final isExpanded = _expandedIndices.contains(index);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isExpanded ? AppTheme.accent.withValues(alpha: 0.3) : Colors.grey[200]!,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedIndices.remove(index);
                    } else {
                      _expandedIndices.add(index);
                    }
                  });
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  notice['title']!,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              AnimatedRotation(
                                turns: isExpanded ? 0.5 : 0,
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            notice['date']!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isExpanded)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        color: Colors.grey[50],
                        child: Text(
                          notice['content']!,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
