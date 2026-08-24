import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/fitting_provider.dart';

class InquiryScreen extends StatefulWidget {
  const InquiryScreen({super.key});

  @override
  State<InquiryScreen> createState() => _InquiryScreenState();
}

class _InquiryScreenState extends State<InquiryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _emailController = TextEditingController();

  String _selectedCategory = '결제/환불';
  final List<String> _categories = ['결제/환불', '피팅 오류', '서비스 건의', '기타 문의'];

  bool _isSubmitting = false;
  bool _hasAttachment = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submitInquiry(FittingProvider provider) {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    // 1.2초 시뮬레이션 후 완료
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        // 실제 FittingProvider 상태에 문의내역 적립
        provider.addInquiry(
          _selectedCategory,
          _titleController.text.trim(),
          _contentController.text.trim(),
          _emailController.text.trim(),
        );

        setState(() {
          _isSubmitting = false;
          // 입력 폼 필드 초기화
          _titleController.clear();
          _contentController.clear();
          _emailController.clear();
          _hasAttachment = false;
        });
        
        // 상단 안내 배너 표출
        _showTopSuccessBanner(context, '1:1 문의가 성공적으로 접수되었습니다.');
        
        // 문의 내역 탭(인덱스 1)으로 이동하여 접수된 건 확인 유도
        _tabController.animateTo(1);
      }
    });
  }

  void _showTopSuccessBanner(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => _TopSuccessBannerWidget(message: message),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FittingProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.primary, size: 20),
          onPressed: () => provider.goBack(),
        ),
        title: const Text(
          '고객센터 1:1 문의',
          style: TextStyle(
            color: AppTheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary,
          unselectedLabelColor: Colors.grey[400],
          indicatorColor: AppTheme.primary,
          indicatorWeight: 2,
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
          tabs: [
            const Tab(text: '문의 접수'),
            Tab(text: '문의 내역 (${provider.inquiries.length})'),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              // 탭 1: 문의 접수 폼
              _buildInquiryForm(provider),

              // 탭 2: 문의 내역 리스트
              _buildInquiryHistory(provider),
            ],
          ),

          // 로딩 오버레이
          if (_isSubmitting)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  // 1:1 문의 입력 폼 빌드
  Widget _buildInquiryForm(FittingProvider provider) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 안내 문구
              const Text(
                '궁금하신 점이나 불편한 사항을 남겨주시면\n고객센터에서 확인 후 신속하게 답변해 드리겠습니다.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // 카테고리 선택
              const Text(
                '문의 유형',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _categories.map((category) {
                  final isSelected = _selectedCategory == category;
                  return ChoiceChip(
                    label: Text(
                      category,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.grey[700],
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      }
                    },
                    selectedColor: AppTheme.primary,
                    backgroundColor: Colors.grey[100],
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSelected ? AppTheme.primary : Colors.transparent,
                        width: 1,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // 답변받을 이메일 주소
              const Text(
                '답변받을 이메일 주소',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'example@email.com',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primary, width: 1.2),
                  ),
                  errorStyle: const TextStyle(fontSize: 11),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '답변을 수신할 이메일을 입력해 주세요.';
                  }
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(value)) {
                    return '올바른 이메일 주소 형식이 아닙니다.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // 문의 제목
              const Text(
                '문의 제목',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _titleController,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: '제목을 입력해 주세요.',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primary, width: 1.2),
                  ),
                  errorStyle: const TextStyle(fontSize: 11),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '문의 제목을 입력해 주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // 문의 내용
              const Text(
                '문의 내용',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _contentController,
                maxLines: 6,
                maxLength: 1000,
                style: const TextStyle(fontSize: 14, height: 1.5),
                decoration: InputDecoration(
                  hintText: '문의 내용을 상세히 기재해 주세요.\n(환불 신청 시 결제 일시 및 요금제를 기재해주시면 더욱 빠른 처리가 가능합니다.)',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13, height: 1.5),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primary, width: 1.2),
                  ),
                  errorStyle: const TextStyle(fontSize: 11),
                  counterStyle: TextStyle(color: Colors.grey[400], fontSize: 11),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '문의 내용을 입력해 주세요.';
                  }
                  if (value.trim().length < 10) {
                    return '내용은 최소 10자 이상 입력해 주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // 이미지 첨부 기능
              const Text(
                '이미지 첨부 (선택)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _hasAttachment = !_hasAttachment;
                  });
                },
                child: Container(
                  height: 110,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!, width: 1),
                  ),
                  child: _hasAttachment
                      ? Stack(
                          children: [
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image_outlined, color: Colors.grey[400], size: 28),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'error_screenshot.png (첨부됨)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.grey[300],
                                child: const Icon(Icons.close, size: 14, color: Colors.white),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, color: Colors.grey[400], size: 28),
                            const SizedBox(height: 8),
                            Text(
                              '결제 영수증 또는 스크린샷 추가',
                              style: TextStyle(color: Colors.grey[500], fontSize: 12),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 48),

              // 접수하기 버튼
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : () => _submitInquiry(provider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    '문의 접수하기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // 1:1 문의 내역 리스트 뷰 빌드
  Widget _buildInquiryHistory(FittingProvider provider) {
    final list = provider.inquiries;

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Colors.grey[350]),
            const SizedBox(height: 16),
            Text(
              '작성하신 1:1 문의 내역이 없습니다.',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final inquiry = list[index];
        final isAnswered = inquiry['status'] == '답변 완료';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!, width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x05000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              )
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              title: Row(
                children: [
                  // 문의 카테고리 뱃지
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      inquiry['category'] ?? '일반',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 접수일자
                  Text(
                    inquiry['date'] ?? '',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[400],
                    ),
                  ),
                  const Spacer(),
                  // 답변 상태 뱃지
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAnswered ? const Color(0xFFEAF5EA) : const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      inquiry['status'] ?? '접수 완료',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isAnswered ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  inquiry['title'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ),
              childrenPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(color: Color(0xFFEEEEEE), height: 1, thickness: 1),
                const SizedBox(height: 12),
                
                // 고객 문의 원문
                const Text(
                  '문의 내용',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                Text(
                  inquiry['content'] ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
                
                // 답변 대기중일 경우: 안내 메시지 박스
                if (!isAnswered) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBF0),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFE0A0), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.access_time_rounded, size: 15, color: Color(0xFFE6970A)),
                            SizedBox(width: 6),
                            Text(
                              '답변 처리 중',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE6970A),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          '문의 접수가 완료되었으며 현재 담당자가 내용을 확인 중입니다.\n통상적으로 영업일 기준 1~3일 이내에 답변이 등록됩니다.\n\n문의량이 많을 경우 최대 5~7 영업일 정도 소요될 수 있는 점 양해 부탁드립니다. 빠른 처리를 위해 최선을 다하겠습니다 🙏',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.65,
                            color: Color(0xFF7A5800),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // 답변 완료된 경우: 고객센터 답변 박스
                if (isAnswered && inquiry['answer'] != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!, width: 0.8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.support_agent_rounded, size: 16, color: AppTheme.accent),
                            SizedBox(width: 6),
                            Text(
                              '고객센터 답변',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          inquiry['answer'] ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// 1:1 문의 완료 알림 상단 토스트 배너 위젯
class _TopSuccessBannerWidget extends StatefulWidget {
  final String message;
  const _TopSuccessBannerWidget({required this.message});

  @override
  State<_TopSuccessBannerWidget> createState() => _TopSuccessBannerWidgetState();
}

class _TopSuccessBannerWidgetState extends State<_TopSuccessBannerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _slideAnimation = Tween<double>(begin: -100.0, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _animController.forward();
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        _animController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double safeAreaTop = MediaQuery.of(context).padding.top;
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Positioned(
          top: safeAreaTop + 16 + _slideAnimation.value,
          left: 20,
          right: 20,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF2E382A),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    offset: Offset(0, 4),
                    blurRadius: 10,
                  )
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
