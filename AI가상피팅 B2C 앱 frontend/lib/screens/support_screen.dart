import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/fitting_provider.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final Set<int> _expandedIndices = {};

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FittingProvider>(context);

    final List<Map<String, String>> faqs = [
      {
        'q': '피팅 결과가 부자연스럽게 나와요.',
        'a':
            '전신이 잘 보이는 밝은 곳에서 촬영한 사진을 사용하시면 AI가 옷을 더 자연스럽게 합성할 수 있습니다. 체형이 가려진 사진은 피해주세요.'
      },
      {
        'q': '구독 취소는 어떻게 하나요?',
        'a': '마이페이지 > 구독 플랜 메뉴에서 하단의 [구독 해지] 버튼을 눌러 언제든 해지하실 수 있습니다.'
      },
      {
        'q': '결제한 금액을 환불받고 싶어요.',
        'a': '결제 완료 후 7일 이내에 피팅 횟수를 전혀 사용하지 않으신 상태라면 1:1 문의를 통해 환불 신청이 가능합니다. 소진된 피팅 횟수 및 7일 경과 시에는 부분 환불이 불가한 점 양해 부탁드립니다.'
      },
      {
        'q': '구매한 충전형 토큰은 유효기간이 있나요?',
        'a': '충전형 토큰은 유효기간 없이 영구적으로 보관됩니다. 구독 해지 여부와 무관하게 언제든지 사용하고 싶으실 때 차감해 쓰실 수 있습니다.'
      },
      {
        'q': '피팅 횟수는 어떤 순서로 차감되나요?',
        'a': '여러 피팅 권한을 중복 보유하신 경우, 가장 합리적이고 유리한 방향인 [1순위: 프리미엄 구독 횟수] ➔ [2순위: 월 기본 무료 피팅 횟수] ➔ [3순위: 충전형 토큰] 순서로 차감됩니다.'
      },
      {
        'q': '옷 사진을 촬영할 때의 꿀팁이 있나요?',
        'a': '의류 촬영 시 바닥이나 평평한 테이블에 주름 없이 곧게 잘 펴두고, 직사광선을 피해 수직 90도 각도에서 전체가 선명하고 그늘 없이 나오게 찍어주시면 AI 모델 인식률과 합성 퀄리티가 대폭 향상됩니다.'
      },
      {
        'q': '사진은 안전하게 보관되나요?',
        'a': '고객님의 사진은 AI 피팅 기능 제공 목적으로만 연동되며, 서버에 영구 보관되지 않아 안심하고 이용하실 수 있습니다.'
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
        title: const Text('고객센터',
            style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 40, right: 40, top: 24, bottom: 16),
                  child: Text('자주 묻는 질문 (FAQ)',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: List.generate(faqs.length, (index) {
                      final faq = faqs[index];
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
                                  child: Row(
                                    children: [
                                      const Text(
                                        'Q',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          color: AppTheme.accent,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          faq['q']!,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
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
                                ),
                                if (isExpanded)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(18),
                                    color: Colors.grey[50],
                                    child: Text(
                                      faq['a']!,
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
                    }),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 40, right: 40, bottom: 32, top: 16),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () {
                  provider.setScreen('inquiry');
                },
                icon:
                    const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 20),
                label: const Text('1:1 문의하기',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
