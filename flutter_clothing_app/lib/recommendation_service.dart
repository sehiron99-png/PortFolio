import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ClothingItem {
  final int itemId;
  final String productName;
  final String mainCategory;
  final String subCategory;
  final String fitLabel;
  final String lengthLabel;
  final String colorLabel;
  final String productUrl;
  final String imageUrl;
  final double? similarityScore;

  ClothingItem({
    required this.itemId,
    required this.productName,
    required this.mainCategory,
    required this.subCategory,
    required this.fitLabel,
    required this.lengthLabel,
    required this.colorLabel,
    required this.productUrl,
    required this.imageUrl,
    this.similarityScore,
  });

  factory ClothingItem.fromJson(Map<String, dynamic> json, [int defaultId = 0]) {
    String rawImgUrl = json['image_url'] ?? '';
    if (rawImgUrl.startsWith('/')) {
      rawImgUrl = '${RecommendationService.baseUrl}$rawImgUrl';
    }

    return ClothingItem(
      itemId: json['item_id'] ?? json['id'] ?? defaultId,
      productName: json['product_name'] ?? '상품명 없음',
      mainCategory: json['main_category'] ?? '',
      subCategory: json['sub_category'] ?? '',
      fitLabel: json['fit_label'] ?? '일반핏',
      lengthLabel: json['length_label'] ?? '기본',
      colorLabel: json['color_label'] ?? '기타',
      productUrl: json['product_url'] ?? '',
      imageUrl: rawImgUrl,
      similarityScore: json['similarity_score'] != null
          ? (json['similarity_score'] as num).toDouble()
          : null,
    );
  }
}

class RecommendationService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8105';
    }
    return 'http://10.0.2.2:8105';
  }

  // 1. 필터 옵션 가져오기 (카테고리, 핏, 색상 등)
  static Future<Map<String, List<String>>> fetchFilterOptions() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/meta/filters'));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return {
          'sub_categories': List<String>.from(data['sub_categories']),
          'fits': List<String>.from(data['fits']),
          'lengths': List<String>.from(data['lengths']),
          'colors': List<String>.from(data['colors'] ?? []),
        };
      }
    } catch (e) {
      debugPrint("Error fetching filters: $e");
    }
    return {'sub_categories': [], 'fits': [], 'lengths': [], 'colors': []};
  }

  // 2. 사용자 취향 (색상 포함) 맞춤 추천 받아오기
  static Future<List<ClothingItem>> fetchUserPreferenceRecommendations({
    String? category,
    String? fit,
    String? length,
    String? color,
    int? topN,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/recommend/user-preference'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'category': category,
          'fit': fit,
          'length': length,
          'color': color,
          'top_n': topN,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final List recs = data['recommendations'];
        return recs.asMap().entries.map((entry) {
          return ClothingItem.fromJson(entry.value, entry.key);
        }).toList();
      }
    } catch (e) {
      debugPrint("Error fetching preference recommendations: $e");
    }
    return [];
  }

  // 3. 연관 상품 추천 받아오기
  static Future<List<ClothingItem>> fetchSimilarItems(int itemId, {int topN = 5}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/recommend/item/$itemId?top_n=$topN'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final List recs = data['recommendations'];
        return recs.asMap().entries.map((entry) {
          return ClothingItem.fromJson(entry.value, entry.key);
        }).toList();
      }
    } catch (e) {
      debugPrint("Error fetching similar items: $e");
    }
    return [];
  }
}
