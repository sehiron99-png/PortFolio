import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/fitting_provider.dart';

class EventScreen extends StatefulWidget {
  const EventScreen({super.key});

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  final Set<int> _expandedIndices = {};

  late final List<Map<String, String>> _events;

  @override
  void initState() {
    super.initState();
    _events = List.generate(30, (index) {
      int itemNum = index + 1;
      return {
        'title': _generateTitle(itemNum),
        'date': _generateDate(itemNum),
        'content': _generateContent(itemNum),
        'imageUrl': 'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=600&fit=crop&auto=format',
      };
    });
  }

  String _generateTitle(int index) {
    List<String> titles = [
      '(광고) 이번 주말 한정! 전품목 10% 추가 할인',
      '🎉 이달의 세일 이벤트: 바캉스룩 특가전',
      '✨ 새로운 여름 시즌 컬렉션 1차 오픈',
      '🎁 첫 가입 감사 쿠폰 지급 안내',
      '📸 베스트 피팅 리뷰 이벤트',
      '💳 카드사 무이자 할부 혜택 안내',
      '👗 봄 시즌 마감 빅세일 (최대 70%)',
      '🤝 패션 크리에이터 제휴 프로그램 안내',
      '🚚 전 상품 무료배송 이벤트',
      '🔔 앱 리뷰 작성 시 1,000 포인트 즉시 지급',
    ];
    if (index <= 10) return titles[index - 1];
    return '🎁 혜택 모음집: 깜짝 할인 쿠폰 팩 #$index 발급 안내';
  }

  String _generateDate(int index) {
    DateTime now = DateTime.now();
    DateTime date = now.subtract(Duration(days: index * 2));
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  String _generateContent(int index) {
    if (index == 1)
      return '이번 주말 동안만 진행되는 깜짝 할인 이벤트!\n\n장바구니에 담아둔 상품들을 10% 더 저렴하게 만나보세요.\n결제 시 자동 적용됩니다.';
    if (index == 2)
      return '여름 휴가를 준비하는 당신을 위한 특별한 세일!\n\n최대 50% 할인된 가격으로 다양한 바캉스룩을 AI로 피팅해보고 구매하세요.';
    return '고객님을 위해 특별히 준비한 이벤트 혜택입니다.\n\n다양한 스타일링을 AI로 경험해 보시고 합리적인 가격에 득템하세요. 언제나 Lumiere를 이용해주셔서 감사합니다.';
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FittingProvider>(context);
    final selectedIdx = provider.selectedEventIndex;

    if (selectedIdx != null && selectedIdx >= 0 && selectedIdx < _events.length) {
      final event = _events[selectedIdx];
      return Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFAFAFA),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios,
                color: AppTheme.primary, size: 20),
            onPressed: () {
              provider.setSelectedEventIndex(null);
            },
          ),
          title: const Text('이벤트 상세 정보',
              style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  event['imageUrl']!,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '진행중 이벤트',
                  style: TextStyle(
                    color: AppTheme.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                event['title']!,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '기간: ${event['date']!}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              const SizedBox(height: 24),
              Text(
                event['content']!,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.7,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('공식 쇼핑몰(https://lumiere-fashion.co.kr/event/${selectedIdx})로 이동합니다.'),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.link_rounded, color: AppTheme.accent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '연관 쇼핑몰 바로가기',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Lumière 공식 쇼핑몰 이벤트 페이지로 이동',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.accent,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    provider.setSelectedEventIndex(null);
                    provider.setScreen('home');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('이벤트 참여 완료! 공식 쇼핑몰(https://lumiere-fashion.co.kr/event/${selectedIdx})로 이동합니다.'),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    '이벤트 참여 & 쇼핑몰 이동',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final int startIndex = (_currentPage - 1) * _itemsPerPage;
    final int endIndex = startIndex + _itemsPerPage;
    final List<Map<String, String>> currentEvents = _events.sublist(
        startIndex, endIndex > _events.length ? _events.length : endIndex);

    int totalPages = (_events.length / _itemsPerPage).ceil();

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
        title: const Text('이벤트 및 혜택',
            style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              itemCount: currentEvents.length,
              itemBuilder: (context, index) {
                final globalIndex = startIndex + index;
                final event = currentEvents[index];
                final isExpanded = _expandedIndices.contains(globalIndex);
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
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
                            _expandedIndices.remove(globalIndex);
                          } else {
                            _expandedIndices.add(globalIndex);
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
                                        event['title']!,
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
                                  event['date']!,
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event['content']!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      height: 1.6,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      event['imageUrl']!,
                                      width: double.infinity,
                                      height: 180,
                                      fit: BoxFit.cover,
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
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentPage > 1
                      ? () => setState(() => _currentPage--)
                      : null,
                  color: _currentPage > 1 ? Colors.black87 : Colors.grey[300],
                ),
                const SizedBox(width: 8),
                ...List.generate(totalPages, (index) {
                  int pageNum = index + 1;
                  bool isSelected = pageNum == _currentPage;
                  return GestureDetector(
                    onTap: () => setState(() => _currentPage = pageNum),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color:
                            isSelected ? AppTheme.primary : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$pageNum',
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : Colors.grey[600],
                          fontSize: 15,
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _currentPage < totalPages
                      ? () => setState(() => _currentPage++)
                      : null,
                  color: _currentPage < totalPages
                      ? Colors.black87
                      : Colors.grey[300],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
