import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/notification_icon.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Dummy Data
  final List<Map<String, dynamic>> _allHistoryData = [
    {
      'date': '2026.07.10',
      'time': '오후 2:30',
      'item': '클래식 린넨 셔츠',
      'category': '상의',
      'price': '39,000',
      'status': '피팅 완료',
      'progress': 100,
      'originalImage': 'https://picsum.photos/seed/shirt1/200/200',
      'resultImage': 'https://picsum.photos/seed/shirt1_result/400/600',
      'tags': ['상의'],
    },
    {
      'date': '2026.07.10',
      'time': '오전 11:15',
      'item': '썸머 와이드 슬랙스',
      'category': '하의',
      'price': '45,000',
      'status': '피팅 완료',
      'progress': 100,
      'originalImage': 'https://picsum.photos/seed/pants1/200/200',
      'resultImage': 'https://picsum.photos/seed/pants1_result/400/600',
      'tags': ['하의'],
    },
    {
      'date': '2026.07.09',
      'time': '오후 8:00',
      'item': '캐주얼 반팔 티셔츠',
      'category': '상의',
      'price': '19,900',
      'status': '피팅 완료',
      'progress': 100,
      'originalImage': 'https://picsum.photos/seed/tshirt1/200/200',
      'resultImage': 'https://picsum.photos/seed/tshirt1_result/400/600',
      'tags': ['상의'],
    },
    {
      'date': '2026.07.05',
      'time': '오후 1:45',
      'item': '빈티지 데님 자켓',
      'category': '아우터',
      'price': '79,000',
      'status': '피팅 완료',
      'progress': 100,
      'originalImage': 'https://picsum.photos/seed/jacket1/200/200',
      'resultImage': 'https://picsum.photos/seed/jacket1_result/400/600',
      'tags': ['아우터'],
    },
    {
      'date': '2026.06.20',
      'time': '오전 9:30',
      'item': '플리츠 롱 스커트',
      'category': '하의',
      'price': '52,000',
      'status': '피팅 완료',
      'progress': 100,
      'originalImage': 'https://picsum.photos/seed/skirt1/200/200',
      'resultImage': 'https://picsum.photos/seed/skirt1_result/400/600',
      'tags': ['하의'],
    },
    {
      'date': '2026.07.10',
      'time': '오후 5:20',
      'item': '섬머 니트 & 화이트 팬츠 세트',
      'category': '코디',
      'price': '89,000',
      'status': '피팅 완료',
      'progress': 100,
      'originalImage': 'https://picsum.photos/seed/codi1/200/200',
      'resultImage': 'https://picsum.photos/seed/codi1_result/400/600',
      'tags': ['코디'],
    },
  ];

  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  String _selectedDateFilter = '전체';
  final List<String> _dateFilters = ['전체', '오늘', '1주', '1개월'];

  String _selectedCategoryFilter = '전체';
  final List<String> _categoryFilters = [
    '전체',
    '코디',
    '상의',
    '하의',
    '아우터',
    '원피스'
  ];

  List<Map<String, dynamic>> get _filteredData {
    return _allHistoryData.where((item) {
      // 0. 완료 내역만 노출
      if (item['status'] != '피팅 완료') return false;

      // 1. 카테고리 필터
      if (_selectedCategoryFilter != '전체' &&
          item['category'] != _selectedCategoryFilter) {
        return false;
      }

      // 2. 검색어 필터
      if (_searchQuery.isNotEmpty) {
        if (!item['item']
            .toString()
            .toLowerCase()
            .contains(_searchQuery.toLowerCase())) {
          return false;
        }
      }

      // 3. 날짜 필터 로직 (더미 로직: 데모를 위해 오늘=2026.07.10 가정)
      if (_selectedDateFilter == '오늘' && item['date'] != '2026.07.10') {
        return false;
      }
      if (_selectedDateFilter == '1주') {
        if (item['date'] == '2026.06.20') return false;
      }

      return true;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {



    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header Padding Row
            Padding(
              padding: const EdgeInsets.only(left: 40.0, right: 40.0, top: 22.0, bottom: 22.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _isSearching
                        ? TextField(
                            controller: _searchController,
                            autofocus: true,
                            decoration: const InputDecoration(
                              hintText: '의류 이름 검색...',
                              border: InputBorder.none,
                              hintStyle: TextStyle(color: Colors.grey),
                            ),
                            style: const TextStyle(color: AppTheme.primary, fontSize: 20, fontWeight: FontWeight.bold),
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                          )
                        : const Text(
                            'AI 피팅 내역',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                  ),
                  Row(
                    children: [
                      // Search button
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isSearching = !_isSearching;
                            if (!_isSearching) {
                              _searchQuery = '';
                              _searchController.clear();
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _isSearching
                                ? AppTheme.accent.withValues(alpha: 0.1)
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isSearching ? Icons.close : Icons.search,
                            size: 20,
                            color: AppTheme.primary,
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
            const Divider(color: Color(0xFFEEEEEE), thickness: 1, height: 1), // 헤드라인 밑 선
            Expanded(
              child: Column(
                children: [
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 48,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: _dateFilters.map((filter) {
                                final isSelected = filter == _selectedDateFilter;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(filter),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(() => _selectedDateFilter = filter);
                                      }
                                    },
                                    selectedColor: AppTheme.primary,
                                    labelStyle: TextStyle(
                                      color: isSelected ? Colors.white : Colors.grey[700],
                                      fontSize: 13,
                                      fontWeight:
                                          isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    backgroundColor: Colors.grey[100],
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        side: const BorderSide(color: Colors.transparent)),
                                    showCheckmark: false,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 48,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: _categoryFilters.map((filter) {
                                final isSelected = filter == _selectedCategoryFilter;
                                final isCodi = filter == '코디';
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isCodi) ...[
                                          Icon(Icons.style,
                                              size: 14,
                                              color: isSelected
                                                  ? Colors.white
                                                  : AppTheme.accent),
                                          const SizedBox(width: 4),
                                        ],
                                        Text(filter),
                                      ],
                                    ),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(() => _selectedCategoryFilter = filter);
                                      }
                                    },
                                    selectedColor: AppTheme.accent,
                                    labelStyle: TextStyle(
                                      color: isSelected ? Colors.white : Colors.grey[700],
                                      fontSize: 13,
                                      fontWeight:
                                          isSelected ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    backgroundColor: Colors.grey[100],
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        side: const BorderSide(color: Colors.transparent)),
                                    showCheckmark: false,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          Expanded(
            child: _filteredData.isEmpty
                ? const Center(
                    child: Text('해당 조건의 피팅 내역이 없습니다.',
                        style: TextStyle(color: Colors.grey)))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 20),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _filteredData.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = _filteredData[index];
                      return Dismissible(
                        key: ValueKey(item['item'].toString() + item['time'].toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red[400],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.delete_outline, color: Colors.white, size: 28),
                              SizedBox(height: 4),
                              Text('삭제', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: const Text('내역 삭제', style: TextStyle(fontWeight: FontWeight.bold)),
                              content: Text('\'${item['item']}\' 피팅 내역을 삭제하시겠어요?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('삭제', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          ) ?? false;
                        },
                        onDismissed: (_) {
                          setState(() {
                            _allHistoryData.remove(item);
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('\'${item['item']}\' 내역이 삭제되었습니다.'),
                              backgroundColor: AppTheme.accent,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: _buildHistoryItem(context, item),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildHistoryItem(BuildContext context, Map<String, dynamic> item) {
    Color statusColor;
    String statusText;

    if (item['status'] == '피팅 완료') {
      statusColor = Colors.green;
      statusText = '피팅 완료';
    } else if (item['status'] == '피팅 진행중') {
      statusColor = Colors.orange;
      statusText = '피팅 진행중 (${item['progress']}%)';
    } else {
      statusColor = Colors.grey;
      statusText = '피팅 대기중 (${item['progress']}%)';
    }

    return GestureDetector(
      onTap: () {
        if (item['status'] == '피팅 완료') {
          _showDetailDialog(context, item);
        } else {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('피팅이 완료된 후 상세 정보를 확인할 수 있습니다.')));
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  item['originalImage'],
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 64,
                    height: 64,
                    color: AppTheme.fittingAccent.withValues(alpha: 0.1),
                    child: const Icon(Icons.checkroom_rounded,
                        color: AppTheme.fittingAccent, size: 32),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item['item'],
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (item.containsKey('tags') && item['tags'] != null) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        children: (item['tags'] as List<dynamic>)
                            .map((tag) => Text('#$tag',
                                style: const TextStyle(
                                    color: AppTheme.accent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)))
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      '${item['price']}원',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '${item['date']} · ${item['time']}',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 96, // 극단적인 하단 배치를 위해 높이를 96으로 상향 조절함
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (item['status'] == '피팅 완료')
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      )
                    else
                      SizedBox(
                        width: 65,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              statusText,
                              style: TextStyle(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: LinearProgressIndicator(
                                value: item['progress'] / 100.0,
                                backgroundColor: Colors.grey[200],
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(statusColor),
                                minHeight: 4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    GestureDetector(
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: const Text('내역 삭제', style: TextStyle(fontWeight: FontWeight.bold)),
                            content: Text('\'${item['item']}\' 피팅 내역을 삭제하시겠어요?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('삭제', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          setState(() {
                            _allHistoryData.remove(item);
                          });
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('\'${item['item']}\' 내역이 삭제되었습니다.'),
                                backgroundColor: AppTheme.accent,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '삭제',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 11,
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
      ),
    );
  }

  void _showDetailDialog(BuildContext context, Map<String, dynamic> item) {
    final List<Map<String, String>> recommendedItems;
    final category = item['category'] ?? '상의';
    if (category == '상의') {
      recommendedItems = [
        {'name': '베이직 피케 티셔츠', 'price': '24,000', 'image': 'https://picsum.photos/seed/rec_shirt1/150/150'},
        {'name': '오버핏 옥스포드 셔츠', 'price': '35,000', 'image': 'https://picsum.photos/seed/rec_shirt2/150/150'},
        {'name': '스트라이프 하프 니트', 'price': '28,000', 'image': 'https://picsum.photos/seed/rec_shirt3/150/150'},
      ];
    } else if (category == '하의' || category == '치마') {
      recommendedItems = [
        {'name': '테이퍼드 라이트 데님', 'price': '42,000', 'image': 'https://picsum.photos/seed/rec_pants1/150/150'},
        {'name': '이지 웨이스트 밴딩 팬츠', 'price': '29,000', 'image': 'https://picsum.photos/seed/rec_pants2/150/150'},
        {'name': '린넨 버뮤다 팬츠', 'price': '31,000', 'image': 'https://picsum.photos/seed/rec_pants3/150/150'},
      ];
    } else if (category == '아우터') {
      recommendedItems = [
        {'name': '경량 나일론 바람막이', 'price': '49,000', 'image': 'https://picsum.photos/seed/rec_out1/150/150'},
        {'name': '오버사이즈 워크 자켓', 'price': '68,000', 'image': 'https://picsum.photos/seed/rec_out2/150/150'},
        {'name': '코튼 트러커 데님자켓', 'price': '59,000', 'image': 'https://picsum.photos/seed/rec_out3/150/150'},
      ];
    } else {
      recommendedItems = [
        {'name': '플라워 패턴 쉬폰 원피스', 'price': '65,000', 'image': 'https://picsum.photos/seed/rec_ops1/150/150'},
        {'name': '캐주얼 린넨 셋업', 'price': '82,000', 'image': 'https://picsum.photos/seed/rec_ops2/150/150'},
        {'name': '코튼 브이넥 니트 조끼', 'price': '26,000', 'image': 'https://picsum.photos/seed/rec_ops3/150/150'},
      ];
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '피팅 상세 정보',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // 결과물 이미지
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        item['resultImage'],
                        width: double.infinity,
                        height: 320,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: double.infinity,
                          height: 320,
                          color: Colors.grey[200],
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_not_supported,
                                  size: 48, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('이미지를 불러올 수 없습니다',
                                  style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // 세부 정보 컨테이너 (등록 의류 정보로 변경됨)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item['category'],
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              Text(
                                item['date'],
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            item['item'],
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '등록가: ${item['price']}원',
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accent),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '함께 코디하기 좋은 유사 추천 의상',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 140,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: recommendedItems.length,
                        itemBuilder: (context, idx) {
                          final rec = recommendedItems[idx];
                          return GestureDetector(
                            onTap: () {
                              Navigator.pop(context); // Close dialog first
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${rec['name']} 상품 구매 페이지로 이동합니다.'),
                                  backgroundColor: AppTheme.primary,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            child: Container(
                              width: 90,
                              margin: const EdgeInsets.only(right: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      rec['image']!,
                                      width: 90,
                                      height: 90,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    rec['name']!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${rec['price']}원',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: TextButton.icon(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: const Text('내역 삭제', style: TextStyle(fontWeight: FontWeight.bold)),
                              content: Text('\'${item['item']}\' 피팅 내역을 삭제하시겠어요?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('삭제', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            if (context.mounted) {
                              Navigator.pop(context); // Close detail dialog
                              setState(() {
                                _allHistoryData.remove(item);
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('\'${item['item']}\' 내역이 삭제되었습니다.'),
                                  backgroundColor: AppTheme.accent,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          }
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.red[50],
                        ),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text(
                          '이 피팅 내역 삭제하기',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
