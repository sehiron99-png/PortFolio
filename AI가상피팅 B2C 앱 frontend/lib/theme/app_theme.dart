import 'package:flutter/material.dart';

class AppTheme {
  // 가을 느낌 (카키 톤 통일) 메인 테마 색상 정의
  static const Color primary = Color(0xFF3E4A3D); // 다크 카키 (Dark Khaki)
  static const Color accent = Color(0xFF8B9D83); // 연한 녹색 카키
  static const Color fittingAccent =
      Color(0xFF8B9D83); // AI 피팅 및 카메라 전용
  static const Color secondary = Color(0xFFEFECE5); // 부드러운 베이지 (Light Beige)
  static const Color background = Color(0xFFFCFBF9); // 따뜻한 흰색 (Warm White)
  static const Color scaffoldBackground = Color(0xFFE6E2D8); // 은은한 카키빛 배경
  static const Color border = Color(0x1A000000);

  // 카테고리별 테두리 및 텍스트 색상 정보 (통일된 디자인)
  static const Map<String, CategoryColor> categoryColors = {
    '상의': CategoryColor(
        bg: Color(0xFFF8F9FA),
        text: Color(0xFF212529),
        border: Color(0xFFCED4DA)),
    '하의': CategoryColor(
        bg: Color(0xFFF8F9FA),
        text: Color(0xFF212529),
        border: Color(0xFFCED4DA)),
    '아우터': CategoryColor(
        bg: Color(0xFFF8F9FA),
        text: Color(0xFF212529),
        border: Color(0xFFCED4DA)),
    '신발': CategoryColor(
        bg: Color(0xFFF8F9FA),
        text: Color(0xFF212529),
        border: Color(0xFFCED4DA)),
    '가방': CategoryColor(
        bg: Color(0xFFF8F9FA),
        text: Color(0xFF212529),
        border: Color(0xFFCED4DA)),
  };

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primary,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: accent,
        surface: background,
      ),
      scaffoldBackgroundColor: background,
      fontFamily: 'NotoSansKR',
      useMaterial3: true,
    );
  }
}

class CategoryColor {
  final Color bg;
  final Color text;
  final Color border;

  const CategoryColor({
    required this.bg,
    required this.text,
    required this.border,
  });
}
