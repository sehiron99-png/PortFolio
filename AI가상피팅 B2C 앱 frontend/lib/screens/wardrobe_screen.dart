import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/fitting_provider.dart';
import '../widgets/clothing_image.dart';
import '../widgets/notification_icon.dart';

import '../widgets/add_photo_popup.dart';

class WardrobeScreen extends StatefulWidget {
  const WardrobeScreen({super.key});

  @override
  State<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends State<WardrobeScreen> {
  bool _isSelectMode = false;
  final Set<String> _selectedItemIds = {};

  bool _isSearchMode = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String? _pressedCategory;
  bool _isHistoryPressed = false;
  bool _isSearchPressed = false;
  bool _showCategoryArrows = false;
  final ScrollController _categoryScrollController = ScrollController();
  Timer? _scrollTimer;
  bool _continuousScrollingActive = false;

  @override
  void dispose() {
    _searchController.dispose();
    _categoryScrollController.dispose();
    _scrollTimer?.cancel();
    super.dispose();
  }

  void _startContinuousScroll({required bool directionLeft}) {
    _scrollTimer?.cancel();
    _continuousScrollingActive = false;
    _scrollTimer = Timer(const Duration(milliseconds: 300), () {
      _continuousScrollingActive = true;
      _scrollTimer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
        if (!_categoryScrollController.hasClients) return;
        final double currentOffset = _categoryScrollController.offset;
        final double delta = directionLeft ? -10.0 : 10.0;
        final double targetOffset = (currentOffset + delta).clamp(
          0.0,
          _categoryScrollController.position.maxScrollExtent,
        );
        _categoryScrollController.jumpTo(targetOffset);
      });
    });
  }

  void _stopContinuousScroll() {
    _scrollTimer?.cancel();
    _scrollTimer = null;
  }

  // 선택 모드 취소/종료
  void _exitSelectMode() {
    setState(() {
      _isSelectMode = false;
      _selectedItemIds.clear();
    });
  }

  void _showDeleteSelectedDialog(FittingProvider provider) {
    if (_selectedItemIds.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('선택 의류 삭제', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          '선택한 ${_selectedItemIds.length}벌의 옷을 정말 삭제하시겠습니까?\n삭제된 옷은 복구할 수 없습니다.',
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final idsToDelete = _selectedItemIds.toList();
              _exitSelectMode();
              await provider.deleteMultipleClothes(idsToDelete);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('선택한 의류가 삭제되었습니다.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  // 전체 선택/해제 토글
  void _toggleSelectAll(List<dynamic> currentItems) {
    if (currentItems.isEmpty) return;

    final currentIds = currentItems.map((item) => item.id as String).toSet();
    setState(() {
      if (_selectedItemIds.containsAll(currentIds)) {
        _selectedItemIds.removeAll(currentIds);
      } else {
        _selectedItemIds.addAll(currentIds);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FittingProvider>(context);
    final filteredClothes = provider.clothes.where((c) {
      bool categoryMatch = provider.selectedCategory == '전체' ||
          c.category == provider.selectedCategory;
      bool searchMatch = _searchQuery.isEmpty ||
          c.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return categoryMatch && searchMatch;
    }).toList();

    final currentIds = filteredClothes.map((item) => item.id).toSet();
    final isAllSelected =
        _selectedItemIds.containsAll(currentIds) && currentIds.isNotEmpty;

    return PopScope(
        canPop: !_isSelectMode,
        onPopInvoked: (didPop) {
          if (!didPop && _isSelectMode) {
            _exitSelectMode();
          }
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              children: [
                // 상단 바 (선택 모드 여부에 따라 레이아웃 변형)
                Padding(
                  padding: const EdgeInsets.only(left: 40.0, right: 40.0, top: 22.0, bottom: 22.0),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _isSelectMode
                        ? Row(
                            key: const ValueKey('select_mode_header'),
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // 좌측 상단: 전체 선택 / 전체 해제
                              TextButton(
                                onPressed: () =>
                                    _toggleSelectAll(filteredClothes),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  isAllSelected ? '전체 해제' : '전체 선택',
                                  style: const TextStyle(
                                      color: AppTheme.accent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                                ),
                              ),
                              // 중앙 선택 개수 표시
                              Text(
                                '선택됨 (${_selectedItemIds.length})',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              ),
                              // 우측 상단: 삭제 및 취소
                              Row(
                                children: [
                                  TextButton(
                                    onPressed: _selectedItemIds.isNotEmpty
                                        ? () =>
                                            _showDeleteSelectedDialog(provider)
                                        : null,
                                    child: Text(
                                      '삭제하기',
                                      style: TextStyle(
                                        color: _selectedItemIds.isNotEmpty
                                            ? Colors.red
                                            : Colors.grey[400],
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close,
                                        color: AppTheme.primary, size: 20),
                                    onPressed: _exitSelectMode,
                                  ),
                                ],
                              ),
                            ],
                          )
                        : Row(
                            key: const ValueKey('normal_header'),
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                '내 옷장',
                                style: TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              NotificationIcon(),
                            ],
                          ),
                  ),
                ),
                const Divider(
                    color: Color(0xFFEEEEEE), thickness: 1, height: 1),
                const SizedBox(height: 12),

                // 카테고리 탭 목록 (선택 모드 중에도 탭 이동 가능하도록 지원)
                Stack(
                  children: [
                    SizedBox(
                      height: 44,
                      child: Listener(
                        onPointerDown: (_) => setState(() => _showCategoryArrows = true),
                        onPointerUp: (_) => setState(() => _showCategoryArrows = false),
                        onPointerCancel: (_) => setState(() => _showCategoryArrows = false),
                        child: ListView(
                          controller: _categoryScrollController,
                          scrollDirection: Axis.horizontal,
                        physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics()),
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTapDown: (_) => setState(() => _isSearchPressed = true),
                              onTapCancel: () => setState(() => _isSearchPressed = false),
                              onTapUp: (_) async {
                                await Future.delayed(const Duration(milliseconds: 100));
                                if (mounted) setState(() => _isSearchPressed = false);
                              },
                              onTap: () {
                                setState(() {
                                  _isSearchMode = !_isSearchMode;
                                  if (!_isSearchMode) {
                                    _searchController.clear();
                                    _searchQuery = '';
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: _isSearchMode
                                      ? (_isSearchPressed ? const Color(0xFF6B7E64) : AppTheme.accent)
                                      : (_isSearchPressed ? Colors.grey[200] : Colors.white),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _isSearchMode
                                        ? Colors.transparent
                                        : Colors.grey[200]!,
                                    width: 1.0,
                                  ),
                                ),
                                child: Icon(
                                  Icons.search,
                                  size: 18,
                                  color: _isSearchMode
                                      ? Colors.white
                                      : Colors.grey[700],
                                ),
                              ),
                            ),
                          ),
                          ...['전체', '상의', '하의', '원피스', '아우터', '신발']
                              .map((cat) {
                            final isSelected = provider.selectedCategory == cat;
                            final hasItem = cat != '전체' && provider.outfit.containsKey(cat);
                            final count = cat == '전체'
                                ? provider.clothes.length
                                : provider.clothes
                                    .where((c) => c.category == cat)
                                    .length;
                            final isPressed = _pressedCategory == cat;

                            final Color bgColor;
                            final Color textColor;
                            final Color borderColor;
                            final Color checkColor;

                            if (isSelected) {
                              bgColor = isPressed ? const Color(0xFF6B7E64) : const Color(0xFF8B9D83);
                              textColor = Colors.white;
                              borderColor = Colors.transparent;
                              checkColor = Colors.white;
                            } else {
                              bgColor = isPressed ? Colors.grey[200]! : Colors.white;
                              textColor = hasItem ? AppTheme.accent : Colors.grey[700]!;
                              borderColor = hasItem 
                                  ? AppTheme.accent.withValues(alpha: 0.4) 
                                  : Colors.grey[200]!;
                              checkColor = AppTheme.accent;
                            }

                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTapDown: (_) => setState(() => _pressedCategory = cat),
                                onTapCancel: () => setState(() => _pressedCategory = null),
                                onTapUp: (_) async {
                                  await Future.delayed(const Duration(milliseconds: 100));
                                  if (mounted) setState(() => _pressedCategory = null);
                                },
                                onTap: () => provider.setSelectedCategory(cat),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: bgColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: borderColor,
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (hasItem)
                                          Icon(
                                            Icons.check,
                                            size: 14,
                                            color: checkColor,
                                          ),
                                        if (hasItem)
                                          const SizedBox(width: 4),
                                        Text(count > 0 ? '$cat ($count)' : cat, style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    ),
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: IgnorePointer(
                        child: Container(width: 40, color: Colors.white),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: IgnorePointer(
                        child: Container(width: 40, color: Colors.white),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      top: 0,
                      bottom: 0,
                      child: AnimatedOpacity(
                        opacity: _showCategoryArrows ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: GestureDetector(
                          onTapDown: (_) => _startContinuousScroll(directionLeft: true),
                          onTapUp: (_) => _stopContinuousScroll(),
                          onTapCancel: () => _stopContinuousScroll(),
                          onTap: () {
                            if (_continuousScrollingActive) return;
                            if (_categoryScrollController.hasClients) {
                              _categoryScrollController.animateTo(
                                (_categoryScrollController.offset - 100.0).clamp(
                                    0.0, _categoryScrollController.position.maxScrollExtent),
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                          child: Center(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                shape: BoxShape.circle,
                                boxShadow: const [
                                  BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(0, 2)),
                                ],
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(Icons.chevron_left,
                                  size: 18, color: Colors.black54),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 10,
                      top: 0,
                      bottom: 0,
                      child: AnimatedOpacity(
                        opacity: _showCategoryArrows ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: GestureDetector(
                          onTapDown: (_) => _startContinuousScroll(directionLeft: false),
                          onTapUp: (_) => _stopContinuousScroll(),
                          onTapCancel: () => _stopContinuousScroll(),
                          onTap: () {
                            if (_continuousScrollingActive) return;
                            if (_categoryScrollController.hasClients) {
                              _categoryScrollController.animateTo(
                                (_categoryScrollController.offset + 100.0).clamp(
                                    0.0, _categoryScrollController.position.maxScrollExtent),
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                          child: Center(
                            child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  shape: BoxShape.circle,
                                  boxShadow: const [
                                    BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 4,
                                        offset: Offset(0, 2)),
                                  ],
                                ),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(Icons.chevron_right,
                                    size: 18, color: Colors.black54),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                 // 검색바 (직접 추가하기 위에 표시)
                 if (_isSearchMode)
                   Padding(
                     padding: const EdgeInsets.only(left: 40, right: 40, bottom: 12),
                     child: SizedBox(
                       height: 42,
                       child: TextField(
                         controller: _searchController,
                         style: const TextStyle(fontSize: 14),
                         decoration: InputDecoration(
                           hintText: '옷 이름 검색...',
                           hintStyle: TextStyle(
                               color: Colors.grey[400],
                               fontSize: 14),
                           border: OutlineInputBorder(
                             borderRadius: BorderRadius.circular(12),
                             borderSide: BorderSide(
                               color: AppTheme.accent.withValues(alpha: 0.5),
                               width: 1,
                             ),
                           ),
                           enabledBorder: OutlineInputBorder(
                             borderRadius: BorderRadius.circular(12),
                             borderSide: BorderSide(
                               color: Colors.grey[300]!,
                               width: 1,
                             ),
                           ),
                           focusedBorder: OutlineInputBorder(
                             borderRadius: BorderRadius.circular(12),
                             borderSide: const BorderSide(
                               color: AppTheme.accent,
                               width: 1.5,
                             ),
                           ),
                           filled: true,
                           fillColor: Colors.white,
                           contentPadding: const EdgeInsets.symmetric(
                               horizontal: 16, vertical: 0),
                           prefixIcon: const Icon(Icons.search,
                               color: Colors.grey, size: 20),
                           suffixIcon: IconButton(
                             icon: const Icon(Icons.cancel,
                                 size: 18, color: Colors.grey),
                             onPressed: () {
                               setState(() {
                                 _isSearchMode = false;
                                 _searchController.clear();
                                 _searchQuery = '';
                               });
                             },
                           ),
                         ),
                         onChanged: (val) {
                           setState(() => _searchQuery = val);
                         },
                       ),
                     ),
                   ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        provider.setShouldOpenGallery(true);
                        provider.setScreen('camera');
                      },
                      icon:
                          const Icon(Icons.add, color: AppTheme.accent, size: 20),
                      label: const Text('직접 추가하기',
                          style: TextStyle(
                              color: AppTheme.accent,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        elevation: 0,
                        side: const BorderSide(color: AppTheme.accent, width: 0.8),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 옷장 아이템 그리드 뷰
                Expanded(
                  child: Container(
                    color: AppTheme.background,
                    child: filteredClothes.isEmpty
                        ? _buildEmptyState(context, provider)
                        : GridView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(
                                left: 40, right: 40, bottom: 90, top: 16),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 0.52,
                            ),
                            itemCount: filteredClothes.length,
                            itemBuilder: (context, index) {
                              final item = filteredClothes[index];
                              final isInOutfit =
                                  provider.outfit[item.category]?.id == item.id;
                              final isLiked =
                                  provider.likedItems.contains(item.id);
                              final isSelectedToDelete =
                                  _selectedItemIds.contains(item.id);

                              return GestureDetector(
                                onLongPress: () {
                                  if (!_isSelectMode) {
                                    setState(() {
                                      _isSelectMode = true;
                                      _selectedItemIds.add(item.id);
                                    });
                                  }
                                },
                                onTap: () {
                                  if (_isSelectMode) {
                                    setState(() {
                                      if (isSelectedToDelete) {
                                        _selectedItemIds.remove(item.id);
                                      } else {
                                        _selectedItemIds.add(item.id);
                                      }
                                    });
                                  } else {
                                    // 선택 모드가 아닐 때 탭 시 피팅룸 상태 토글
                                    provider.toggleOutfitItem(item);
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: _isSelectMode
                                        ? Border.all(
                                            color: isSelectedToDelete
                                                ? AppTheme.accent
                                                : Colors.transparent,
                                            width: 2,
                                          )
                                        : null,
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x08000000),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      )
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // 의류 사진 영역
                                        Expanded(
                                          child: Stack(
                                            children: [
                                              Positioned.fill(
                                                child: ClothingImage(
                                                    imageUrl: item.imageUrl),
                                              ),
                                              // 선택 모드 일때의 체크박스 표시
                                              if (_isSelectMode)
                                                Positioned(
                                                  top: 10,
                                                  left: 10,
                                                  child: Container(
                                                    width: 24,
                                                    height: 24,
                                                    decoration: BoxDecoration(
                                                      color: isSelectedToDelete
                                                          ? AppTheme.accent
                                                          : Colors.white
                                                              .withOpacity(0.8),
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color:
                                                            isSelectedToDelete
                                                                ? AppTheme
                                                                    .accent
                                                                : Colors
                                                                    .grey[400]!,
                                                        width: 2,
                                                      ),
                                                    ),
                                                    child: isSelectedToDelete
                                                        ? const Icon(
                                                            Icons.check,
                                                            color: Colors.white,
                                                            size: 14)
                                                        : null,
                                                  ),
                                                )
                                              else ...[
                                                // 좋아요 버튼 (선택 모드 아닐 때 노출)
                                                Positioned(
                                                  top: 10,
                                                  right: 10,
                                                  child: GestureDetector(
                                                    onTap: () =>
                                                        provider.toggleLikeItem(
                                                            item.id),
                                                    child: Container(
                                                      width: 32,
                                                      height: 32,
                                                      decoration: BoxDecoration(
                                                        color: Colors.white
                                                            .withOpacity(0.8),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: Icon(
                                                        isLiked
                                                            ? Icons.favorite
                                                            : Icons
                                                                .favorite_border,
                                                        color: isLiked
                                                            ? Colors.red
                                                            : Colors.grey[600],
                                                        size: 16,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                // 피팅 장착 선택 뱃지
                                                if (isInOutfit)
                                                  Positioned(
                                                    top: 10,
                                                    left: 10,
                                                    child: Container(
                                                      width: 24,
                                                      height: 24,
                                                      decoration:
                                                          const BoxDecoration(
                                                        color: AppTheme.accent,
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: const Icon(
                                                        Icons.check,
                                                        color: Colors.white,
                                                        size: 14,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        // 정보 영역
                                        Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.name,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.primary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                '${item.price}원',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              // 피팅룸에 추가/해제 버튼 (선택 모드가 아닐 때만 활성화)
                                              SizedBox(
                                                width: double.infinity,
                                                height: 28,
                                                child: AbsorbPointer(
                                                  absorbing: _isSelectMode,
                                                  child: ElevatedButton(
                                                    onPressed: () => provider
                                                        .toggleOutfitItem(item),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          isInOutfit
                                                              ? AppTheme.accent
                                                              : AppTheme
                                                                  .secondary,
                                                      foregroundColor:
                                                          isInOutfit
                                                              ? Colors.white
                                                              : Colors
                                                                  .grey[700],
                                                      elevation: 0,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                      ),
                                                      padding: EdgeInsets.zero,
                                                    ),
                                                    child: Text(
                                                      isInOutfit
                                                          ? '선택됨'
                                                          : '피팅룸 추가',
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
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
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  Widget _buildEmptyState(BuildContext context, FittingProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 120),
            GestureDetector(
              onTap: () => showClothesGuideDialog(context),
              child: Column(
                children: [
                  Icon(
                    Icons.photo_outlined,
                    size: 48,
                    color: AppTheme.accent.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '아직 촬영한 옷이 없어요',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => showAddPhotoPopup(context, provider),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '탭하여 촬영하러 가기',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }
}
