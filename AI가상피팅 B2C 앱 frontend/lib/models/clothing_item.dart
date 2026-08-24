class ClothingItem {
  final String id;
  final String category; // '상의' | '하의' | '아우터' | '신발' | '가방'
  final String imageUrl; // 로컬 경로 또는 데모용 Unsplash URL
  final String name;
  final String price;

  ClothingItem({
    required this.id,
    required this.category,
    required this.imageUrl,
    required this.name,
    required this.price,
  });

  // Map 변환 (DB 저장용)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'image_url': imageUrl,
      'name': name,
      'price': price,
    };
  }

  // Map에서 객체 생성 (DB 로드용)
  factory ClothingItem.fromMap(Map<String, dynamic> map) {
    return ClothingItem(
      id: map['id'] as String,
      category: map['category'] as String,
      imageUrl: map['image_url'] as String,
      name: map['name'] as String,
      price: map['price'] as String,
    );
  }
}
