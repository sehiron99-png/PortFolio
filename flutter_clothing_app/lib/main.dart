import 'package:flutter/material.dart';
import 'recommendation_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rest & Recreation 의류 추천',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F172A)),
        useMaterial3: true,
      ),
      home: const RecommendationHomeScreen(),
    );
  }
}

class RecommendationHomeScreen extends StatefulWidget {
  const RecommendationHomeScreen({super.key});

  @override
  State<RecommendationHomeScreen> createState() => _RecommendationHomeScreenState();
}

class _RecommendationHomeScreenState extends State<RecommendationHomeScreen> {
  String? selectedCategory;
  String? selectedFit;
  String? selectedLength;
  String? selectedColor;

  List<String> categories = [];
  List<String> fits = [];
  List<String> lengths = [];
  List<String> colors = [];

  List<ClothingItem> recommendedItems = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFiltersAndInitialData();
  }

  Future<void> _loadFiltersAndInitialData() async {
    setState(() => isLoading = true);
    final filters = await RecommendationService.fetchFilterOptions();
    setState(() {
      categories = filters['sub_categories'] ?? filters['main_categories'] ?? [];
      fits = filters['fits'] ?? [];
      lengths = filters['lengths'] ?? [];
      colors = filters['colors'] ?? [];
    });
    await _fetchRecommendations();
  }

  Future<void> _fetchRecommendations() async {
    setState(() => isLoading = true);
    final items = await RecommendationService.fetchUserPreferenceRecommendations(
      category: selectedCategory,
      fit: selectedFit,
      length: selectedLength,
      color: selectedColor,
    );
    setState(() {
      recommendedItems = items;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'REST & RECREATION Style & Color AI',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0F172A),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 메인 카테고리 & 핏 & 색상 필터 선택 섹션
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '💡 메인 카테고리, 핏 및 선호 색상 선택',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: '카테고리',
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                        initialValue: selectedCategory,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('전체')),
                          ...categories.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                        ],
                        onChanged: (val) {
                          setState(() => selectedCategory = val);
                          _fetchRecommendations();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: '핏(Fit)',
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                        initialValue: selectedFit,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('전체')),
                          ...fits.map((f) => DropdownMenuItem(value: f, child: Text(f))),
                        ],
                        onChanged: (val) {
                          setState(() => selectedFit = val);
                          _fetchRecommendations();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: '색상(Color)',
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(),
                        ),
                        initialValue: selectedColor,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('전체')),
                          ...colors.map((col) => DropdownMenuItem(value: col, child: Text(col))),
                        ],
                        onChanged: (val) {
                          setState(() => selectedColor = val);
                          _fetchRecommendations();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 목록 헤더
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '✨ 맞춤 추천 의류',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${recommendedItems.length}개 상품',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

          // 추천 상품 카드 리스트
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : recommendedItems.isEmpty
                    ? const Center(child: Text('추천 데이터가 없습니다.'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: recommendedItems.length,
                        itemBuilder: (context, index) {
                          final item = recommendedItems[index];
                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ItemDetailScreen(item: item),
                                ),
                              );
                            },
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 12.0),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        item.imageUrl,
                                        width: 75,
                                        height: 75,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            Container(
                                          width: 75,
                                          height: 75,
                                          color: Colors.grey.shade200,
                                          child: const Icon(Icons.checkroom, color: Colors.grey),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.productName,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 4,
                                            children: [
                                              _buildChip(
                                                item.mainCategory.isNotEmpty ? item.mainCategory : item.subCategory,
                                                Colors.blue.shade100,
                                                Colors.blue.shade900,
                                              ),
                                              _buildChip(item.fitLabel, Colors.purple.shade100, Colors.purple.shade900),
                                              _buildChip(item.colorLabel, Colors.amber.shade100, Colors.amber.shade900),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (item.similarityScore != null)
                                      Column(
                                        children: [
                                          const Icon(Icons.star, color: Colors.amber, size: 20),
                                          Text(
                                            '${(item.similarityScore! * 100).toInt()}%',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: Colors.amber,
                                            ),
                                          )
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color bgColor, Color textColor) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
      ),
    );
  }
}

// 📌 연관 추천 상품 클릭 시 타고타고 무한 네비게이션이 가능한 ItemDetailScreen
class ItemDetailScreen extends StatefulWidget {
  final ClothingItem item;
  const ItemDetailScreen({super.key, required this.item});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  List<ClothingItem> similarItems = [];
  bool isLoadingSimilar = true;

  @override
  void initState() {
    super.initState();
    _fetchSimilarItems();
  }

  Future<void> _fetchSimilarItems() async {
    final items = await RecommendationService.fetchSimilarItems(widget.item.itemId, topN: 6);
    setState(() {
      similarItems = items;
      isLoadingSimilar = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item.productName),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                widget.item.imageUrl,
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 250,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.checkroom, size: 80, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.item.productName,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                Chip(label: Text('카테고리: ${widget.item.mainCategory.isNotEmpty ? widget.item.mainCategory : widget.item.subCategory}')),
                Chip(label: Text('핏: ${widget.item.fitLabel}')),
                Chip(label: Text('색상: ${widget.item.colorLabel}')),
              ],
            ),
            const Divider(height: 32),

            const Text(
              '🔥 이 옷과 스타일 & 색상이 유사한 연관 추천',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            isLoadingSimilar
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    height: 175,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: similarItems.length,
                      itemBuilder: (context, index) {
                        final sItem = similarItems[index];
                        // 📌 핵심: 연관 추천 카드를 클릭하면 InkWell을 통해 해당 연관 상품의 ItemDetailScreen으로 끊임없이(타고타고) 이동!
                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ItemDetailScreen(item: sItem),
                              ),
                            );
                          },
                          child: Container(
                            width: 125,
                            margin: const EdgeInsets.only(right: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    sItem.imageUrl,
                                    width: 125,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: 125,
                                      height: 100,
                                      color: Colors.grey.shade300,
                                      child: const Icon(Icons.checkroom),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  sItem.productName,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${sItem.colorLabel} • ${sItem.fitLabel}',
                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
