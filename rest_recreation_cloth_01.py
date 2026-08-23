import requests
import time
import pandas as pd

# REST & RECREATION CSV 기준 10대 대표 색상 매핑 함수
def map_color_label(raw_color_text, product_name):
    text = (str(raw_color_text) + " " + str(product_name)).upper()
    
    if any(k in text for k in ['BLACK', '블랙', '검정']):
        return '블랙'
    if any(k in text for k in ['WHITE', '화이트', '흰색']):
        return '화이트'
    if any(k in text for k in ['GRAY', 'GREY', 'CHARCOAL', 'MELANGE', '그레이', '차콜', '멜란지', '회색']):
        return '그레이'
    if any(k in text for k in ['BLUE', 'SKY BLUE', 'MINT BLUE', 'DENIM', '블루', '소라', '스카이블루', '연청', '중청', '진청', '파랑']):
        return '블루'
    if any(k in text for k in ['BEIGE', 'CREAM', 'IVORY', 'YELLOW', '베이지', '크림', '아이보리', '노랑']):
        return '베이지/아이보리'
    if any(k in text for k in ['PINK', 'RED', 'BURGUNDY', 'WINE', '핑크', '레드', '빨강', '버건디']):
        return '핑크/레드'
    if any(k in text for k in ['NAVY', '네이비', '곤색']):
        return '네이비'
    if any(k in text for k in ['BROWN', '브라운', '갈색', '초코']):
        return '브라운'
    if any(k in text for k in ['KHAKI', '카키']):
        return '카키'
    if any(k in text for k in ['GREEN', 'MINT', '그린', '민트', '초록']):
        return '그린'
        
    return '기타/실버'

def scrape_29cm_exclusive_women(target_count=1000):
    products_data = []
    page = 1
    size = 50
    
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'application/json'
    }

    # 제외 대상 카테고리/상품 키워드
    exclude_keywords = ['홈웨어', '언더웨어', '파자마', '이지웨어', '속옷', '잠옷', '속바지', '라운지웨어', '브라', '팬티']

    print(f"29CM 여성의류 단독([EXCLUSIVE]) 상품 {target_count}개 수집을 시작합니다...\n")

    while len(products_data) < target_count:
        # 요청 URL 파라미터 (카테고리: 268100100, 정렬: RECOMMENDED)
        url = f"https://api.29cm.co.kr/api/v4/products?category_large_code=268100100&page={page}&size={size}&sort=RECOMMENDED"
        
        try:
            res = requests.get(url, headers=headers, timeout=10)
            if res.status_code != 200:
                print(f"페이지 {page} 호출 실패 (Status: {res.status_code}). 종료합니다.")
                break
                
            data = res.json()
            items = data.get('data', {}).get('list', [])
            
            if not items:
                print("더 이상 불러올 상품 데이터가 없습니다.")
                break

            for item in items:
                if len(products_data) >= target_count:
                    break

                item_no = item.get('item_no')
                name = item.get('item_name', 'N/A')
                brand_name = item.get('front_brand_name', '29CM')
                
                category = item.get('category_large_name', '여성의류')
                sub_category = item.get('category_medium_name', '일반')
                
                # 1. 홈웨어, 언더웨어 제외 검사
                cat_text = f"{category} {sub_category} {name}".lower()
                if any(ex in cat_text for ex in exclude_keywords):
                    continue

                # 2. [단독 / EXCLUSIVE] 여부 검사
                is_exclusive = item.get('is_exclusive', False) or '[단독]' in name or '단독' in name or 'EXCLUSIVE' in name.upper()
                if not is_exclusive:
                    continue  # 단독 상품이 아니면 건너뜀

                product_url = f"https://product.29cm.co.kr/catalog/{item_no}"

                # 3. 색상 추출 및 대표 색상 매핑
                raw_color = 'N/A'
                if '[' in name and ']' in name:
                    # 단독 태그 외의 색상 정보 추출
                    parts = name.split('[')
                    for p in parts[1:]:
                        clean_p = p.split(']')[0].strip()
                        if '단독' not in clean_p and 'EXCLUSIVE' not in clean_p.upper():
                            raw_color = clean_p
                            break
                elif '(' in name and ')' in name:
                    raw_color = name.split('(')[-1].split(')')[0].strip()

                color_label = map_color_label(raw_color, name)

                products_data.append({
                    'brand': brand_name,
                    'product_name': name,
                    'main_category': category,
                    'sub_category': sub_category,
                    'color_label': color_label,
                    'raw_color': raw_color,
                    'product_url': product_url
                })

            print(f"[페이지 {page}] 단독 조건 일치 수집 완료 | 현재 누적: {len(products_data)}개")
            page += 1
            time.sleep(0.3)

        except Exception as e:
            print(f"페이지 {page} 수집 중 오류: {e}")
            break

    # CSV 저장
    df = pd.DataFrame(products_data)
    filename = '29cm_exclusive_women_1000.csv'
    df.to_csv(filename, index=False, encoding='utf-8-sig')
    
    print(f"\n최종 완료! 총 {len(df)}개 데이터를 성공적으로 저장했습니다 -> '{filename}'")
    return df

if __name__ == "__main__":
    scrape_29cm_exclusive_women(target_count=1000)