import argparse
import os
import sys
from .recommender import ClothingRecommender

def main():
    parser = argparse.ArgumentParser(
        description="Rest & Recreation AI Clothing Recommender CLI (v1.1.0)"
    )
    parser.add_argument(
        "--image", "-i", required=True, help="분석/추천할 의류 이미지 경로 (예: 옷02.png)"
    )
    parser.add_argument(
        "--csv", default="rest_recreation_600_labeled.csv", help="라벨 데이터셋 CSV 경로"
    )
    parser.add_argument(
        "--top-n", "-n", type=int, default=5, help="추천할 유사 상품 개수 (기본값: 5)"
    )

    args = parser.parse_args()

    if not os.path.exists(args.image):
        print(f"❌ 오류: 이미지 파일이 존재하지 않습니다: {args.image}")
        sys.exit(1)

    if not os.path.exists(args.csv):
        print(f"❌ 오류: 데이터셋 CSV 파일이 존재하지 않습니다: {args.csv}")
        sys.exit(1)

    print(f"🚀 AI 추천 엔진 로딩 중... ({args.csv})")
    rec = ClothingRecommender(csv_path=args.csv)

    print(f"\n📸 이미지 정밀 분석 중: {args.image}")
    res = rec.recommend_by_custom_image(args.image, top_n=args.top_n)

    det = res["detected"]
    print("=" * 65)
    print(f"📌 감지된 의류 정보:")
    print(f"  • 대분류: {det['main_category']}")
    print(f"  • 소분류: {det['sub_category']}")
    print(f"  • 감지 색상: {det['color']}")
    print("=" * 65)

    print(f"\n✨ 유사 스타일 추천 TOP {args.top_n}:")
    for r, item in enumerate(res["recommendations"], 1):
        print(
            f"  {r}. [{item['sub_category']:8s}] [{item['color_label']:10s}] "
            f"{item['product_name']} (종합 유사도: {item['similarity_score']:.3f})"
        )
    print("=" * 65)

if __name__ == "__main__":
    main()
