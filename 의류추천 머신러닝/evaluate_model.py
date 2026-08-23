import sys
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")
import json
from recommender import ClothingRecommender

print("==================================================")
print("🧠 Rest & Recreation 색상 최우선 (Color 65%) AI 모델 연관 추천 코드 결과")
print("==================================================")

# 1. 모델 기동 (색상 최우선 65% 설정)
rec = ClothingRecommender('rest_recreation_600_labeled.csv', weight_mode='color_first')

# 2. 0번 상품(LIGHT LOGO TANK TOP - PINK) 연관 추천 계산
target_id = 0
target_item = rec.df.iloc[target_id]
print(f"\n📌 [기준 상품 #{target_id}]")
print(f"   - 상품명: {target_item['product_name']}")
print(f"   - 카테고리: {target_item['main_category']} ({target_item['sub_category']})")
print(f"   - 색상: {target_item['color_label']} | 핏: {target_item['fit_label']}\n")

# 3. 모델 코드로 계산된 유사도 상위 5개 결과
sim_results = rec.recommend_by_product_index(target_id, top_n=5)

print("🎯 [AI 추천 계산 코드 결과 (Top 5)]")
for i, item in enumerate(sim_results, 1):
    print(f"  {i}위. [{item['product_name']}]")
    print(f"       - 유사도 점수 (Similarity Score): {item['similarity_score']:.4f} ({(item['similarity_score']*100):.1f}%)")
    print(f"       - 카테고리: {item['main_category']} | 색상: {item['color_label']} | ID: #{item['item_id']}")
    print(f"       - 이미지 경로: {item['image_url']}")
    print("       --------------------------------------------------")

print("\n📊 [파이썬 딕셔너리 RAW JSON 데이터 출력 예시]")
print(json.dumps(sim_results[0], indent=2, ensure_ascii=False))
