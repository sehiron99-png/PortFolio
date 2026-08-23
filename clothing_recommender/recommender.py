import os
import sys
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")
import pandas as pd
import numpy as np
import colorsys
import re
from PIL import Image
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics.pairwise import cosine_similarity
from sklearn.preprocessing import LabelEncoder, normalize
from scipy.sparse import hstack, csr_matrix
import joblib

try:
    import torch
    import torchvision.models as models
    import torchvision.transforms as transforms
    TORCH_AVAILABLE = True
except ImportError:
    TORCH_AVAILABLE = False

COLOR_LABEL_CANONICAL = {
    '아이보리/베이지': '베이지/아이보리',
    '레드/핑크': '핑크/레드',
    '브라운/갈색': '브라운/갈색',
    '옐로우/베이지': '베이지/아이보리',
    '카키': '그린',
    '차콜/멜란지': '그레이',
    '기타/믹스': '기타/실버',
    '기타/실버': '기타/실버',
    '화이트': '화이트',
    '블랙': '블랙',
    '네이비': '네이비',
    '그레이': '그레이',
    '그린': '그린',
    '핑크/레드': '핑크/레드',
    '베이지/아이보리': '베이지/아이보리',
    '블루': '블루',
    '소라/스카이블루': '소라/스카이블루',
}

def normalize_color_label(color_label):
    color_label = str(color_label).strip()
    if not color_label:
        return '기타/실버'
    if color_label in COLOR_LABEL_CANONICAL:
        return COLOR_LABEL_CANONICAL[color_label]
    text = color_label.upper()
    if 'WHITE' in text or '화이트' in color_label or '흰' in color_label:
        return '화이트'
    if 'BLACK' in text or '블랙' in color_label or '검정' in color_label:
        return '블랙'
    if 'NAVY' in text or '네이비' in color_label:
        return '네이비'
    if '소라' in color_label or 'SKY' in text or 'SORA' in text:
        return '소라/스카이블루'
    if 'BLUE' in text or '블루' in color_label or '데님' in text:
        return '블루'
    if 'PINK' in text or 'RED' in text or '핑크' in color_label or '레드' in color_label:
        return '핑크/레드'
    if '아이보리' in color_label or '베이지' in color_label or 'BEIGE' in text or 'IVORY' in text:
        return '베이지/아이보리'
    if 'GREEN' in text or '그린' in color_label or '민트' in color_label or '초록' in color_label:
        return '그린'
    if 'KHAKI' in text or '카키' in color_label:
        return '그린'
    if 'BROWN' in text or '브라운' in color_label or '갈색' in color_label:
        return '브라운/갈색'
    if 'CHARCOAL' in text or '차콜' in color_label or '멜란지' in color_label:
        return '그레이'
    return '기타/실버'


def detect_color_label_from_image(img_path, product_name=None):
    """
    이미지 픽셀 분석 + 상품명 텍스트 키워드 하이브리드 교정으로
    데이터셋 포맷에 맞는 가장 정확한 컬러 라벨을 반환합니다.
    """
    if not os.path.exists(img_path):
        return "화이트"

    # 1. product_name 미지정 시 item_XX.jpg 파일명으로 자동 룩업
    if product_name is None and "item_" in str(img_path):
        try:
            m = re.search(r"item_(\d+)\.jpg", str(img_path))
            if m:
                idx = int(m.group(1))
                if not hasattr(detect_color_label_from_image, "_df_cache"):
                    csv_p = r"c:\Users\Win11Pro\Desktop\rest\rest_recreation_600_labeled.csv"
                    if os.path.exists(csv_p):
                        detect_color_label_from_image._df_cache = pd.read_csv(csv_p)
                if hasattr(detect_color_label_from_image, "_df_cache"):
                    dfc = detect_color_label_from_image._df_cache
                    if idx in dfc.index:
                        product_name = str(dfc.loc[idx, 'product_name'])
        except Exception:
            pass

    # 2. 픽셀 HSV 분석 결과 산출
    pixel_color = _detect_color_from_pixels(img_path)

    # 3. 명시적 상품명 색상 텍스트 키워드가 있으면 픽셀 감지 결과 교차 검증 및 보정
    if product_name:
        ptext = str(product_name).upper()
        if re.search(r'\b(KHAKI|OLIVE|카키)\b', ptext):
            return normalize_color_label("카키")
        if re.search(r'\b(IVORY|BEIGE|CREAM|OATMEAL|아이보리|베이지)\b', ptext):
            return normalize_color_label("베이지/아이보리")
        if re.search(r'\b(BROWN|CARAMEL|CHOCOLATE|COCOA|갈색|브라운)\b', ptext):
            return normalize_color_label("브라운/갈색")
        if ('SKY' in ptext or 'SORA' in ptext or '소라' in ptext or 'LIGHT BLUE' in ptext) and 'NAVY' not in ptext:
            return normalize_color_label("소라/스카이블루")
        if ('NAVY' in ptext or '네이비' in ptext or 'INDIGO' in ptext) and 'LIGHT' not in ptext:
            return normalize_color_label("네이비")
        if ('DENIM' in ptext or 'BLUE' in ptext or '블루' in ptext) and 'SKY' not in ptext and 'NAVY' not in ptext and 'LIGHT' not in ptext:
            return normalize_color_label("블루")
        if re.search(r'\b(GREEN|MINT|그린|민트|초록)\b', ptext) and 'BLUE' not in ptext:
            return normalize_color_label("그린")
        if re.search(r'\b(WHITE|화이트|흰색)\b', ptext) and 'IVORY' not in ptext and 'BEIGE' not in ptext and 'PRINT' not in ptext:
            return normalize_color_label("화이트")
        if 'PINK' in ptext or 'RED' in ptext or '핑크' in ptext or '레드' in ptext:
            return normalize_color_label("핑크/레드")
        if 'BLACK' in ptext or '블랙' in ptext or '검정' in ptext:
            return normalize_color_label("블랙")
        if 'GRAY' in ptext or 'GREY' in ptext or 'MELANGE' in ptext or 'CHARCOAL' in ptext or '그레이' in ptext or '차콜' in ptext:
            return normalize_color_label("그레이")

    return pixel_color


def _detect_color_from_pixels(img_path):
    if not os.path.exists(img_path):
        return "화이트"
    try:
        img = Image.open(img_path).convert('RGB')
        w, h = img.size
        resized_full = np.array(img.resize((80, 80)))
        border_pixels = np.concatenate([
            resized_full[0, :],
            resized_full[-1, :],
            resized_full[:, 0],
            resized_full[:, -1],
        ], axis=0).astype(np.float32)
        dominant_bg_hues = _get_dominant_bg_hues(border_pixels, top_k=3)

        # 가로 18%~78% (우측 셔터 문 및 배경 배제, 중앙 브라운 원피스 집중)
        crop = img.crop((int(w * 0.18), int(h * 0.16), int(w * 0.78), int(h * 0.88)))
        crop = crop.resize((80, 80))
        pixels_arr = np.array(crop).astype(np.float32)

        # 픽셀별 HSV 및 Y-위치(세로 비율 0~1) 계산
        hsv_list = []
        y_weights = []
        is_head_hair_skin_list = []

        for y_idx in range(80):
            y_rel = y_idx / 80.0  # 0.0 (상단) ~ 1.0 (하단)
            for x_idx in range(80):
                p = pixels_arr[y_idx, x_idx]
                h_val, s_val, v_val = colorsys.rgb_to_hsv(p[0]/255.0, p[1]/255.0, p[2]/255.0)
                hsv_list.append((h_val, s_val, v_val))
                deg_val = h_val * 360.0
                
                # 1. 인물 머리/머리카락(Head & Hair) 탐지 및 제거 (상단 Y < 0.28 의 어두운/갈색 머리카락)
                is_hair = (y_rel < 0.28) and (
                    (v_val < 0.38) or
                    (10 <= deg_val <= 45 and s_val > 0.18 and v_val < 0.65)
                )
                
                # 2. 인물 얼굴/피부(Skin Tone) 탐지 및 제거 (상단 Y < 0.35 의 피부톤 픽셀)
                is_skin = (y_rel < 0.35) and (
                    10 <= deg_val <= 38 and 0.14 <= s_val <= 0.48 and 0.45 <= v_val <= 0.96
                )
                
                # 3. 레이어드 내장 셔츠 탐지 (상체 Y < 0.55 의 무채색 픽셀)
                is_inner_shirt = (y_rel < 0.55) and (v_val > 0.68 and s_val < 0.25)
                
                is_filtered_noise = is_hair or is_skin or is_inner_shirt
                is_head_hair_skin_list.append(is_filtered_noise)
                
                # 세로 위치 가중치: 순수 의류 본체 영역(Y >= 0.25) 가중치 대폭 상향
                if y_rel < 0.25:
                    weight = 0.01 if is_filtered_noise else 0.10
                elif y_rel >= 0.45:
                    weight = 3.50
                else:
                    weight = 1.20
                y_weights.append(weight)

        hsv_arr = np.array(hsv_list, dtype=np.float32)
        y_weights = np.array(y_weights, dtype=np.float32)
        is_head_hair_skin_list = np.array(is_head_hair_skin_list, dtype=bool)

        def hue_distance(h1, h2):
            d = abs(h1 - h2)
            return min(d, 1.0 - d)

        bg_mask = []
        for (h_val, s_val, v_val), is_noise in zip(hsv_arr, is_head_hair_skin_list):
            is_white_bg = (v_val > 0.70 and s_val < 0.20)
            is_black_bg = (v_val < 0.06)
            is_color_bg = any(
                bg_s > 0.35 and hue_distance(float(h_val), bg_h) < 0.04 and s_val > 0.35
                for bg_h, bg_s in dominant_bg_hues
            )
            bg_mask.append(is_white_bg or is_black_bg or is_color_bg or is_noise)

        bg_mask = np.array(bg_mask)
        foreground = hsv_arr[~bg_mask]
        fg_weights = y_weights[~bg_mask]

        if len(foreground) < 50:
            foreground = hsv_arr
            fg_weights = y_weights

        h_vals = foreground[:, 0]
        s_vals = foreground[:, 1]
        v_vals = foreground[:, 2]

        # 겉옷 화이트(흰색) 최우선 검사: 겉옷 본체 명도가 높고(V > 0.58) 채도가 낮은 픽셀(S < 0.20)이 30% 이상인 경우
        white_outer_mask = (v_vals > 0.58) & (s_vals < 0.20)
        if float(white_outer_mask.sum()) / max(len(v_vals), 1) >= 0.30:
            return normalize_color_label("화이트")

        colored_mask = (s_vals > 0.14) & (v_vals > 0.10)  # 채도 0.14 초과로 배경 그림자 제거
        colored = foreground[colored_mask]
        colored_weights = fg_weights[colored_mask]

        low_sat_mint_mask = (
            (h_vals * 360.0 >= 95) & (h_vals * 360.0 < 175) &
            (s_vals > 0.045) & (s_vals <= 0.13) &
            (v_vals > 0.30) & (v_vals < 0.88)
        )
        if low_sat_mint_mask.mean() > 0.30:
            mint_degs = h_vals[low_sat_mint_mask] * 360.0
            if float(np.std(mint_degs)) < 28.0:
                return "그린"

        # ── 무채색 및 파스텔 저채도 정밀 판별 ────────────────────────────
        v_mid  = float(np.median(v_vals))
        s_mean = float(np.mean(s_vals))
        s_mid  = float(np.median(s_vals))

        # 1) 블랙: 명도 매우 낮고 채도 낮음
        if v_mid < 0.20 and s_mean < 0.20:
            return normalize_color_label("블랙")

        # 2) 무채색/파스텔 저채도 전역 처리 (s_mean < 0.16)
        if s_mean < 0.16 or s_mid < 0.14:
            # 어두운 톤 (V < 0.40)
            if v_mid < 0.22:
                return normalize_color_label("블랙")
            elif v_mid < 0.55:
                return normalize_color_label("그레이")

            # 겉옷 화이트(흰색) 우선 검사: 겉옷 본체 명도가 높고(V > 0.75) 채도가 낮으면(S < 0.18) 화이트 최우선
            white_outer_mask = (v_vals > 0.75) & (s_vals < 0.18)
            if float(white_outer_mask.sum()) / max(len(v_vals), 1) >= 0.22:
                return normalize_color_label("화이트")

            # 파스텔 색상 체크 (채도 0.06 이상일 때 휴 색상 파악)
            if s_mean >= 0.06:
                # 핑크/레드 파스텔 (330°~360° or 0°~15°)
                pink_mask = ((h_vals * 360.0 >= 330) | (h_vals * 360.0 <= 15)) & (s_vals > 0.06)
                if float(pink_mask.sum()) >= max(6, len(v_vals) * 0.15):
                    return normalize_color_label("핑크/레드")

                # 브라운/갈색 (10°~50°, 어두운 톤 V < 0.68 & S > 0.25)
                brown_mask = (h_vals * 360.0 >= 10) & (h_vals * 360.0 <= 50) & (s_vals > 0.25) & (v_vals < 0.68)
                if float(brown_mask.sum()) >= max(6, len(v_vals) * 0.10):
                    return normalize_color_label("브라운/갈색")

                # 아이보리/베이지 (18°~75°, 밝은 톤 V >= 0.65)
                ivory_mask = (h_vals * 360.0 >= 18) & (h_vals * 360.0 <= 75) & (s_vals > 0.05) & (v_vals >= 0.65)
                if float(ivory_mask.sum()) >= max(6, len(v_vals) * 0.08):
                    return normalize_color_label("아이보리/베이지")

                # 소라/스카이블루 (175°~240°)
                sky_mask = (h_vals * 360.0 >= 175) & (h_vals * 360.0 <= 240) & (s_vals > 0.08)
                if float(sky_mask.sum()) >= max(6, len(v_vals) * 0.08):
                    return normalize_color_label("소라/스카이블루")

            # 아주 낮은 채도 (S < 0.04) 또는 무색계
            if v_mid >= 0.88 and s_mean < 0.04:
                return normalize_color_label("화이트")
            elif v_mid >= 0.55:
                # 어두운 웜톤 (10°~50°, V < 0.65)은 브라운/갈색
                dark_warm_ratio = float(((h_vals * 360.0 >= 10) & (h_vals * 360.0 <= 50) & (s_vals > 0.15) & (v_vals < 0.65)).sum()) / len(v_vals)
                if dark_warm_ratio > 0.10:
                    return normalize_color_label("브라운/갈색")
                # 밝은 웜톤 (18°~75°, V >= 0.65)은 아이보리/베이지
                warm_ratio = float(((h_vals * 360.0 >= 18) & (h_vals * 360.0 <= 75) & (s_vals > 0.04) & (v_vals >= 0.65)).sum()) / len(v_vals)
                if warm_ratio > 0.06:
                    return normalize_color_label("아이보리/베이지")
                bright_ratio = float((v_vals > 0.78).sum()) / len(v_vals)
                if bright_ratio > 0.50 and s_mean < 0.05:
                    return normalize_color_label("화이트")
                return normalize_color_label("그레이")
            else:
                return normalize_color_label("그레이")

        h_col = colored[:, 0]
        s_col = colored[:, 1]
        v_col = colored[:, 2]
        degs = h_col * 360.0
        weights = np.clip(s_col, 0.05, 1.0) * np.clip(v_col, 0.20, 1.0) * colored_weights

        # 데님/블루/네이비 조기 판별 (채도 0.20 이상인 경우만 적용하여 흰색 셔츠 그림자 오분류 방지)
        blue_denim_mask = (degs >= 165) & (degs <= 270) & (s_col >= 0.20) & (v_col > 0.10)
        if blue_denim_mask.sum() >= max(5, len(degs) * 0.08):
            avg_v = float(np.average(v_col[blue_denim_mask], weights=weights[blue_denim_mask]))
            avg_s = float(np.average(s_col[blue_denim_mask], weights=weights[blue_denim_mask]))
            avg_d = float(np.average(degs[blue_denim_mask],  weights=weights[blue_denim_mask]))
            if avg_v < 0.25:                           # 정말 어두운 색만 네이비
                return normalize_color_label("네이비")
            elif avg_d >= 180 and avg_d <= 215 and avg_v > 0.62 and avg_s < 0.42:
                return normalize_color_label("소라/스카이블루")
            return normalize_color_label("블루")
        green_mask = (degs >= 70) & (degs < 175) & (s_col > 0.14) & (v_col > 0.16)
        green_ratio = float(weights[green_mask].sum() / max(weights.sum(), 1e-8))
        if green_ratio >= 0.22:
            green_s = float(np.average(s_col[green_mask], weights=weights[green_mask]))
            green_v = float(np.average(v_col[green_mask], weights=weights[green_mask]))
            green_deg = float(np.average(degs[green_mask], weights=weights[green_mask]))
            if green_deg < 92 and green_s < 0.42 and green_v < 0.70:
                return normalize_color_label("카키")
            return normalize_color_label("그린")

        hist, edges = np.histogram(degs, bins=36, range=(0.0, 360.0), weights=weights)
        peak = int(np.argmax(hist))
        low = edges[max(0, peak - 1)]
        high = edges[min(len(edges) - 1, peak + 2)]
        if peak == 0:
            peak_mask = (degs < high) | (degs >= 350)
        elif peak == 35:
            peak_mask = (degs >= low) | (degs < 10)
        else:
            peak_mask = (degs >= low) & (degs < high)

        deg = float(np.average(degs[peak_mask], weights=weights[peak_mask]))
        s_val = float(np.average(s_col[peak_mask], weights=weights[peak_mask]))
        v_val = float(np.average(v_col[peak_mask], weights=weights[peak_mask]))

        # 피크 픽셀 채도가 낮은 경우(s_val < 0.15) 무채색 보정
        if s_val < 0.15:
            if v_val > 0.85:
                return normalize_color_label("화이트")
            elif v_val > 0.68:
                return normalize_color_label("아이보리/베이지")
            elif v_val >= 0.22:
                return normalize_color_label("그레이")
            else:
                return normalize_color_label("블랙")

        if deg < 15 or deg >= 345:
            if v_val < 0.65 and s_val > 0.18:
                return normalize_color_label("브라운/갈색")
            return normalize_color_label("레드/핑크")

        elif 15 <= deg < 50:
            # ── 브라운 vs 베이지/아이보리 정밀 구분 ──────────────────────────
            if s_val > 0.20 and v_val < 0.72:         # 채도 유효 어두운/중간 웜톤 → 브라운 우선
                return normalize_color_label("브라운/갈색")
            elif v_val >= 0.68 and s_val <= 0.32:        # 밝고 연한 별리 1순위: 아이보리
                return normalize_color_label("아이보리/베이지")
            elif v_val >= 0.55 and s_val <= 0.20:       # 중간밝기 + 낮은 채도 → 베이지
                return normalize_color_label("아이보리/베이지")
            elif v_val >= 0.80:                          # 매우 밝음 → 아이보리/화이트
                return normalize_color_label("아이보리/베이지")
            else:
                return normalize_color_label("브라운/갈색")

        elif 50 <= deg < 70:
            if deg >= 52 and s_val >= 0.18:
                if v_val >= 0.62:
                    return normalize_color_label("그린")
                return normalize_color_label("카키")
            if s_val < 0.28 and v_val > 0.58:
                return normalize_color_label("아이보리/베이지")
            return normalize_color_label("아이보리/베이지")

        elif 70 <= deg < 92:
            if s_val < 0.40 and v_val < 0.72:
                return normalize_color_label("카키")
            return normalize_color_label("그린")

        elif 92 <= deg < 175:
            return normalize_color_label("그린")

        elif 175 <= deg < 210:
            # ── 소라/스카이블루 vs 블루 ────────────────────────────────
            # 소라: 연한 청록 (V 높고 S 낙음)
            if v_val > 0.62 and s_val < 0.58:
                return normalize_color_label("소라/스카이블루")
            return normalize_color_label("블루")

        elif 210 <= deg < 255:
            # ── 네이비 vs 블루 vs 소라 정밀 구분 ────────────────────────────
            # 네이비: V 매우 낙고(요구사항 강화) + S 있음
            if v_val < 0.32 and s_val > 0.20:          # 충분히 어둥고 채도있음 → 네이비
                return normalize_color_label("네이비")
            elif v_val > 0.72 and s_val < 0.52:        # 밝고 채도 낙음 → 소라
                return normalize_color_label("소라/스카이블루")
            # 나머지 다 블루 (네이비 조건을 대폭 강화)
            return normalize_color_label("블루")

        elif 255 <= deg < 345:
            if v_val < 0.32:
                return normalize_color_label("네이비")
            return normalize_color_label("레드/핑크")

        return normalize_color_label("화이트")
    except Exception:
        return "화이트"


def detect_clothing_category_from_image(img_path):
    """
    테두리 배경 제거 후 의류 실루엣 시작 위치(y0) 및 비율로 부위를 정밀 추정하는 함수입니다.
    - 바지(BOTTOM): 어깨가 없어 세로 시작 위치(y0)가 허리/골반(y0 >= 32%)부터 시작
    - 원피스(DRESS): 어깨부터 시작(y0 < 32%)하고 세로 길이가 김(aspect > 1.25)
    """
    if not os.path.exists(img_path):
        return "상의 (TOP)", "티셔츠"

    try:
        img = Image.open(img_path).convert('RGB').resize((120, 160))
        arr = np.array(img).astype(np.float32) / 255.0

        # 테두리 배경 감지
        border_pixels = np.concatenate([
            arr[0, :, :], arr[-1, :, :], arr[:, 0, :], arr[:, -1, :]
        ], axis=0) * 255.0
        dominant_bg_hues = _get_dominant_bg_hues(border_pixels, top_k=3)

        # 픽셀별 배경 마스킹
        max_rgb = arr.max(axis=2)
        min_rgb = arr.min(axis=2)
        saturation = max_rgb - min_rgb
        value = max_rgb

        def hue_distance(h1, h2):
            d = abs(h1 - h2)
            return min(d, 1.0 - d)

        mask_bg = []
        for y in range(160):
            for x in range(120):
                r, g, b = arr[y, x]
                h_val, s_val, v_val = colorsys.rgb_to_hsv(r, g, b)
                is_white_bg = (v_val > 0.88 and s_val < 0.14)
                is_black_bg = (v_val < 0.08)
                is_color_bg = any(
                    bg_s > 0.25 and hue_distance(h_val, bg_h) < 0.08 and s_val > 0.15
                    for bg_h, bg_s in dominant_bg_hues
                )
                mask_bg.append(is_white_bg or is_black_bg or is_color_bg)

        mask = ~np.array(mask_bg).reshape(160, 120)

        row_sums = mask.sum(axis=1)
        valid_y = np.where(row_sums >= 5)[0]
        if len(valid_y) == 0:
            return "상의 (TOP)", "티셔츠"

        y0 = valid_y[0]
        y1 = valid_y[-1]
        xs = np.where(mask[y0:y1+1, :].any(axis=0))[0]
        if len(xs) == 0:
            return "상의 (TOP)", "티셔츠"
        x0, x1 = xs.min(), xs.max()

        box_w = max(x1 - x0 + 1, 1)
        box_h = max(y1 - y0 + 1, 1)
        y0_ratio = y0 / 160.0  # 의류 상단 시작 위치 비율 (0.0: 머리/어깨, 0.4: 허리)

        aspect = box_h / box_w
        crop = mask[y0:y1 + 1, x0:x1 + 1]

        thirds = np.array_split(crop, 3, axis=0)
        width_ratios = [len(np.where(p.any(axis=0))[0]) / box_w if len(np.where(p.any(axis=0))[0]) else 0.0 for p in thirds]
        top_w, mid_w, bottom_w = width_ratios

        # 1-1. 다리 갈라짐(중앙 세로 빈 공간) 검사: 하단 40%~85% 구간에서 좌우 다리 분리 유무
        has_leg_split = False
        ch, cw = crop.shape
        if ch >= 20 and cw >= 10:
            lower_crop = crop[int(ch * 0.40):int(ch * 0.85), :]
            if lower_crop.shape[0] >= 5:
                center_gaps = 0
                for r in lower_crop:
                    left_has = r[:int(cw * 0.35)].any()
                    right_has = r[int(cw * 0.65):].any()
                    center_empty = not r[int(cw * 0.40):int(cw * 0.60)].any()
                    if left_has and right_has and center_empty:
                        center_gaps += 1
                if (center_gaps / max(lower_crop.shape[0], 1)) >= 0.15:
                    has_leg_split = True

        # 1. 하의 (BOTTOM/팬츠): 세로 시작점이 허리 이하(y0_ratio >= 0.15)이거나 다리 갈라짐이 존재하는 경우, 또는 aspect <= 1.75
        if (y0_ratio >= 0.15 and aspect > 0.85) or has_leg_split:
            return "하의 (BOTTOM)", "팬츠"

        # 2. 원피스 (DRESS): 어깨 맨 위(y0_ratio < 0.12)부터 시작하고 전신 롱길이(aspect > 1.75)이며 하단 폭이 넓고 다리 갈라짐이 없는 통 구조
        if y0_ratio < 0.12 and aspect > 1.75 and bottom_w >= (top_w * 1.05) and not has_leg_split:
            return "원피스 (DRESS)", "원피스"

        # 3. 상의 (TOP): 어깨부터 시작하는 긴소매 셔츠/티셔츠/맨투맨
        if y0_ratio < 0.32:
            return "상의 (TOP)", "셔츠/남방"

        return "하의 (BOTTOM)", "팬츠"
    except Exception:
        return "상의 (TOP)", "티셔츠"


def map_main_to_binary(main_label):
    s = str(main_label)
    if '하의' in s or 'BOTTOM' in s or 'pants' in s.lower():
        return 'BOTTOM'
    if '원피스' in s or 'DRESS' in s:
        return 'DRESS'
    if '아우터' in s or 'OUTER' in s:
        return 'OUTER'
    if '상의' in s or 'TOP' in s or 'shirt' in s.lower() or 'top' in s.lower():
        return 'TOP'
    return 'OTHER'



def _get_dominant_bg_hues(border_pixels, top_k=3):
    """
    테두리 픽셀에서 채도가 있는 픽셀들의 HSV를 구한 뒤
    Hue 히스토그램(18구간 = 20도 단위)에서 상위 top_k 최빈 Hue 구간을 반환.
    알록달록한 배경에도 각 주요 색을 개별 감지하기 위함.
    """
    border_hsv = []
    for p in border_pixels:
        h, s, v = colorsys.rgb_to_hsv(p[0]/255.0, p[1]/255.0, p[2]/255.0)
        border_hsv.append((h, s, v))
    border_hsv = np.array(border_hsv)

    # 채도 있는 픽셀만 (거의 흰/검 배경 제외)
    saturated = border_hsv[border_hsv[:, 1] > 0.18]

    dominant_hues = []  # [(center_hue, saturation), ...]

    if len(saturated) >= 8:
        # 18구간(= 20도 단위) Hue 히스토그램으로 최빈 색 탐지
        NUM_BINS = 18
        h_hist, h_edges = np.histogram(saturated[:, 0], bins=NUM_BINS, range=(0.0, 1.0))
        # 상위 top_k 구간 선택 (count > 0인 것만)
        top_bins = np.argsort(h_hist)[::-1]
        for bi in top_bins[:top_k]:
            if h_hist[bi] == 0:
                break
            center_h = (h_edges[bi] + h_edges[bi + 1]) / 2.0
            # 해당 구간 픽셀들의 평균 채도
            mask_bin = (saturated[:, 0] >= h_edges[bi]) & (saturated[:, 0] < h_edges[bi + 1])
            avg_s = saturated[mask_bin, 1].mean() if mask_bin.any() else 0.5
            dominant_hues.append((center_h, avg_s))
    else:
        # 채도 있는 픽셀이 너무 적으면 단순 평균
        bg_mean = border_pixels.mean(axis=0)
        bg_h, bg_s, bg_v = colorsys.rgb_to_hsv(bg_mean[0]/255.0, bg_mean[1]/255.0, bg_mean[2]/255.0)
        if bg_s > 0.15:
            dominant_hues.append((bg_h, bg_s))

    return dominant_hues


def extract_hsv_histogram(img_path, bins=(8, 4, 4)):
    """
    이미지에서 배경색을 자동 감지·제거하고 의류 피사체 색상만 추출하는 HSV 컬러 히스토그램.
    - 테두리 픽셀의 Hue 최빈값(dominant hue)으로 배경 주 색상 감지
      → 알록달록한 배경에서도 평균 혼색 오류 없이 각 배경색을 개별 감지
    - 감지된 배경 색상 범위 픽셀 마스킹 제거
    - 흰색/검정 배경 및 유색 단색/다색 배경(빨강, 파랑 등) 모두 지원
    """
    if not os.path.exists(img_path):
        return np.zeros(bins[0] + bins[1] + bins[2], dtype=np.float32)
    try:
        img = Image.open(img_path).convert('RGB')
        w, h = img.size

        # 1. 테두리 픽셀 샘플링
        resized = np.array(img.resize((60, 60)))
        border_pixels = np.concatenate([
            resized[0, :],   # 상단 행
            resized[-1, :],  # 하단 행
            resized[:, 0],   # 왼쪽 열
            resized[:, -1],  # 오른쪽 열
        ], axis=0).astype(np.float32)

        # 2. 배경 주 색상 감지 (최빈 Hue 방식, 알록달록 배경 대응)
        dominant_bg_hues = _get_dominant_bg_hues(border_pixels, top_k=3)

        # 3. 의류 영역 크롭
        #    - 세로: 상위 22% 제거 (이너 셔츠/카라/넥라인 영역 skip -> 원피스 본체 색상 집중)
        #    - 하단: 90% 까지 사용 (배경 바닥 및 신발 영역 skip)
        #    - 가로: 좌우 10% 제거
        CROP_TOP    = 0.22   # 이너 셔츠/카라 레이어드 노이즈 방지
        CROP_BOTTOM = 0.90   # 의류 메인 바디 영역 집중
        CROP_LEFT   = 0.10
        CROP_RIGHT  = 0.90
        crop = img.crop((
            int(w * 0.22),  int(h * 0.18),
            int(w * 0.72), int(h * 0.88)
        ))
        crop = crop.resize((60, 60))
        crop_pixels = np.array(crop).astype(np.float32)

        # 4. HSV 변환 및 Y-위치 가중치
        hsv_list = []
        is_upper_inner = []
        for y_idx in range(60):
            y_rel = y_idx / 60.0
            for x_idx in range(60):
                p = crop_pixels[y_idx, x_idx]
                h_val, s_val, v_val = colorsys.rgb_to_hsv(p[0]/255.0, p[1]/255.0, p[2]/255.0)
                hsv_list.append((h_val, s_val, v_val))
                # 상단 무채색 셔츠/카라
                is_upper_inner.append((y_rel < 0.38) and (v_val > 0.70 and s_val < 0.25))

        hsv_arr = np.array(hsv_list)
        is_upper_inner = np.array(is_upper_inner)

        # 5. 배경 색상과 유사한 픽셀 마스킹 제거
        def hue_distance(h1, h2):
            d = abs(h1 - h2)
            return min(d, 1.0 - d)

        valid_mask = []
        for (h, s, v), is_inner in zip(hsv_arr, is_upper_inner):
            is_white_bg = (v > 0.92 and s < 0.12)
            is_black_bg = (v < 0.08)
            is_color_bg = any(
                bg_s > 0.20 and hue_distance(h, bg_h) < 0.09 and s > 0.15
                for bg_h, bg_s in dominant_bg_hues
            )
            valid_mask.append(not is_white_bg and not is_black_bg and not is_color_bg and not is_inner)

        valid_mask = np.array(valid_mask)
        valid_hsv = hsv_arr[valid_mask]
        removal_rate = 1.0 - (len(valid_hsv) / max(len(hsv_arr), 1))

        # 6. 제거율이 65% 초과 → 옷 색상이 배경과 같은 경우 → 배경 제거 포기(fallback)
        #    단, 픽셀 절대 개수가 30개 미만이어도 fallback
        if removal_rate > 0.65 or len(valid_hsv) < 30:
            valid_hsv = hsv_arr

        h_hist, _ = np.histogram(valid_hsv[:, 0], bins=bins[0], range=(0.0, 1.0))
        s_hist, _ = np.histogram(valid_hsv[:, 1], bins=bins[1], range=(0.0, 1.0))
        v_hist, _ = np.histogram(valid_hsv[:, 2], bins=bins[2], range=(0.0, 1.0))

        hist = np.concatenate([h_hist, s_hist, v_hist]).astype(np.float32)
        norm = np.linalg.norm(hist)
        if norm > 0:
            hist = hist / norm
        return hist
    except Exception:
        return np.zeros(bins[0] + bins[1] + bins[2], dtype=np.float32)


class ClothingRecommender:
    """
    고도화된 멀티모달 의류 추천 AI엔진 (Multi-Modal Advanced AI Recommender)
    - 1. 멀티모달 피처 (텍스트 n-gram + ResNet-18 딥러닝 임베딩 + HSV 컬러 히스토그램)
    - 2. 적합도 기반 스마트 사용자 취향 랭킹 (Multi-Attribute Soft Preference Ranking)
    - 3. 동일 카테고리 유사 추천 & 크로스 카테고리 코디 추천 지원
    - 4. 자동 피처 추출 및 캐싱 (새로운 의류 데이터 투입 시 자동 감지)
    """

    def __init__(self, csv_path, npy_path='image_features.npy', color_npy_path='color_features.npy', image_dir='static/images', weight_mode='color_first'):
        self.csv_path = csv_path
        self.npy_path = npy_path
        self.color_npy_path = color_npy_path
        self.image_dir = image_dir
        self.weight_mode = weight_mode
        self.df = pd.read_csv(csv_path, encoding='utf-8-sig')
        self.main_category_encoder = None
        self.sub_category_encoder = None
        self.main_category_clf = None
        self.sub_category_clf = None
        self._clean_data()
        self._build_feature_matrix()
        self._train_category_classifiers()
        # try load part classifier if available
        self.part_clf = None
        self.part_le = None
        try:
            for p in ['part_classifier.joblib', 'part_classifier_aug.joblib', 'part_classifier_binary.joblib']:
                if os.path.exists(p):
                    d = joblib.load(p)
                    self.part_clf = d.get('model') if isinstance(d, dict) else d
                    self.part_le = d.get('le') if isinstance(d, dict) else None
                    break
        except Exception:
            self.part_clf = None
            self.part_le = None

    def _train_category_classifiers(self):
        """이미지 임베딩과 카테고리 라벨을 이용해 부위 분류기를 학습합니다."""
        if not TORCH_AVAILABLE:
            return

        try:
            embeddings = None
            if os.path.exists(self.npy_path):
                embeddings = np.load(self.npy_path)
            if embeddings is None or embeddings.shape[0] != len(self.df):
                embeddings = self._extract_image_features_auto()

            valid_mask = self.df['main_category'].notna() & self.df['sub_category'].notna()
            if embeddings is None or len(embeddings) != len(self.df) or valid_mask.sum() < 20:
                return

            main_labels = self.df.loc[valid_mask, 'main_category'].astype(str)
            sub_labels = self.df.loc[valid_mask, 'sub_category'].astype(str)
            main_embs = embeddings[valid_mask.values]

            self.main_category_encoder = LabelEncoder()
            self.sub_category_encoder = LabelEncoder()
            main_y = self.main_category_encoder.fit_transform(main_labels)
            sub_y = self.sub_category_encoder.fit_transform(sub_labels)

            self.main_category_clf = LogisticRegression(
                max_iter=500,
                class_weight='balanced',
                solver='lbfgs'
            )
            self.sub_category_clf = LogisticRegression(
                max_iter=500,
                class_weight='balanced',
                solver='lbfgs'
            )
            self.main_category_clf.fit(main_embs, main_y)
            self.sub_category_clf.fit(main_embs, sub_y)
        except Exception:
            self.main_category_clf = None
            self.sub_category_clf = None
            self.main_category_encoder = None
            self.sub_category_encoder = None

    def _clean_data(self):
        """데이터 정제 및 가공"""
        self.df['main_category'] = self.df['main_category'].fillna('')
        self.df['sub_category'] = self.df['sub_category'].fillna('')
        self.df['fit_label'] = self.df['fit_label'].fillna('일반핏')
        self.df['length_label'] = self.df['length_label'].fillna('기본')
        self.df['color_label'] = self.df['color_label'].fillna('기타/믹스').astype(str).apply(normalize_color_label)
        self.df['product_name'] = self.df['product_name'].fillna('')

        def clean_name(name):
            name = re.sub(r'\[.*?\]', '', str(name))
            name = re.sub(r'커버낫|COVERNAT', '', name, flags=re.IGNORECASE)
            return name.strip()

        self.df['clean_name'] = self.df['product_name'].apply(clean_name)

    def _extract_image_features_auto(self):
        """ResNet-50 딥러닝 특징 자동 추출"""
        if not TORCH_AVAILABLE:
            return None
        try:
            weights = models.ResNet50_Weights.DEFAULT
            model = models.resnet50(weights=weights)
            model.fc = torch.nn.Identity()
            model.eval()

            preprocess = transforms.Compose([
                transforms.Resize((224, 224)),
                transforms.ToTensor(),
                transforms.Normalize(
                    mean=[0.485, 0.456, 0.406],
                    std=[0.229, 0.224, 0.225]
                ),
            ])

            features_list = []
            with torch.no_grad():
                for idx in range(len(self.df)):
                    img_path = os.path.join(self.image_dir, f"item_{idx}.jpg")
                    if os.path.exists(img_path):
                        try:
                            img = Image.open(img_path).convert('RGB')
                            tensor = preprocess(img).unsqueeze(0)
                            emb = model(tensor).squeeze(0).numpy()
                            norm = np.linalg.norm(emb)
                            if norm > 0:
                                  emb = emb / norm
                            features_list.append(emb)
                        except Exception:
                            features_list.append(np.zeros(2048, dtype=np.float32))
                    else:
                        features_list.append(np.zeros(2048, dtype=np.float32))

            features_matrix = np.array(features_list, dtype=np.float32)
            np.save(self.npy_path, features_matrix)
            return features_matrix
        except Exception:
            return None

    def extract_single_image_embedding(self, img_path):
        """단일 이미지의 ResNet-50 임베딩을 추출합니다."""
        if not TORCH_AVAILABLE or not os.path.exists(img_path):
            return None
        try:
            weights = models.ResNet50_Weights.DEFAULT
            model = models.resnet50(weights=weights)
            model.fc = torch.nn.Identity()
            model.eval()

            preprocess = transforms.Compose([
                transforms.Resize((224, 224)),
                transforms.ToTensor(),
                transforms.Normalize(
                    mean=[0.485, 0.456, 0.406],
                    std=[0.229, 0.224, 0.225]
                ),
            ])

            img = Image.open(img_path).convert('RGB')
            tensor = preprocess(img).unsqueeze(0)
            with torch.no_grad():
                emb = model(tensor).squeeze(0).numpy()
            return emb / (np.linalg.norm(emb) + 1e-8)
        except Exception:
            return None

    def predict_category_from_image(self, img_path, top_k=15):
        """
        이미지에서 main/sub 카테고리를 추정합니다.
        - 분류기가 학습되어 있으면 ResNet 임베딩으로 직접 예측
        - 분류기가 없거나 신뢰도가 낮으면 유사도 기반 fallback
        - 최종적으로 실루엣 fallback도 사용
        반환값: (main_category, sub_category, confidence)
        """
        fallback_main, fallback_sub = detect_clothing_category_from_image(img_path)
        emb = self.extract_single_image_embedding(img_path)
        if emb is None:
            return fallback_main, fallback_sub, 0.0

        if self.main_category_clf is not None and self.sub_category_clf is not None:
            try:
                main_pred = self.main_category_encoder.inverse_transform(
                    self.main_category_clf.predict(emb.reshape(1, -1))
                )[0]
                sub_pred = self.sub_category_encoder.inverse_transform(
                    self.sub_category_clf.predict(emb.reshape(1, -1))
                )[0]
                main_prob = float(self.main_category_clf.predict_proba(emb.reshape(1, -1)).max())
                sub_prob = float(self.sub_category_clf.predict_proba(emb.reshape(1, -1)).max())
                confidence = min(main_prob, sub_prob)

                # 셔츠/남방 vs 원피스/아우터 보정: 실루엣이 상의(fallback_main == "상의 (TOP)")이면 원피스/아우터 오예측 무조건 상의로 정정
                if fallback_main == "상의 (TOP)" and main_pred in ["원피스 (DRESS)", "아우터 (OUTER)"]:
                    return "상의 (TOP)", fallback_sub if fallback_sub else "셔츠/남방", max(confidence, 0.90)

                if main_pred == "상의 (TOP)" and sub_pred in ["셔츠/블라우스", "자켓"]:
                    sub_pred = "셔츠/남방"

                if confidence >= 0.72:
                    return main_pred, sub_pred, confidence
            except Exception:
                pass

        if not os.path.exists(self.npy_path):
            return fallback_main, fallback_sub, 0.0

        try:
            dataset_embeddings = np.load(self.npy_path)
            if dataset_embeddings.shape[0] != len(self.df):
                return fallback_main, fallback_sub, 0.0

            sims = cosine_similarity(emb.reshape(1, -1), dataset_embeddings)[0]
            top_indices = np.argsort(sims)[::-1][:max(1, top_k)]

            main_scores = {}
            sub_scores = {}
            for rank, idx in enumerate(top_indices):
                row = self.df.iloc[idx]
                weight = float(max(sims[idx], 0.0)) / (rank + 1)
                main = row['main_category']
                sub = row['sub_category']
                main_scores[main] = main_scores.get(main, 0.0) + weight
                sub_scores[(main, sub)] = sub_scores.get((main, sub), 0.0) + weight

            if not main_scores:
                return fallback_main, fallback_sub, 0.0

            main_category = max(main_scores, key=main_scores.get)
            same_main_subs = {
                key: score for key, score in sub_scores.items()
                if key[0] == main_category
            }
            sub_category = max(same_main_subs, key=same_main_subs.get)[1] if same_main_subs else ''
            total_score = sum(main_scores.values()) or 1.0
            confidence = main_scores[main_category] / total_score

            # 셔츠/남방 vs 자켓/아우터 보정: 실루엣이 상의(어깨 y0 < 0.30)이고 자켓으로 추정된 경우 셔츠/남방으로 최적화
            if fallback_main == "상의 (TOP)" and main_category == "아우터 (OUTER)":
                return "상의 (TOP)", "셔츠/남방", confidence

            if main_category == "상의 (TOP)" and sub_category in ["셔츠/블라우스", "자켓"]:
                sub_category = "셔츠/남방"

            if confidence < 0.60:  # 0.34 -> 0.60: 과반 미달 투표 결과도 기각 → 실루엣 Fallback 작동
                return fallback_main, fallback_sub, confidence

            return main_category, sub_category, confidence
        except Exception:
            return fallback_main, fallback_sub, 0.0

    def extract_part_feature_vector(self, img_path):
        emb = self.extract_single_image_embedding(img_path)
        if emb is None:
            return None
        try:
            hist = extract_hsv_histogram(img_path).astype(np.float32)
            return np.concatenate([emb, hist])
        except Exception:
            return emb

    def predict_part_from_image(self, img_path):
        """이미지에 대해 main_category 파트를 예측합니다. 모델이 없으면 None 반환."""
        if self.part_clf is None:
            return None, 0.0
        emb = self.extract_single_image_embedding(img_path)
        if emb is None:
            return None, 0.0
        try:
            prob = self.part_clf.predict_proba(emb.reshape(1, -1))[0]
            pred_idx = int(self.part_clf.predict(emb.reshape(1, -1))[0])
            if self.part_le is not None:
                pred_label = self.part_le.inverse_transform([pred_idx])[0]
            else:
                pred_label = str(pred_idx)
            confidence = float(prob.max())
            return pred_label, confidence
        except Exception:
            return None, 0.0

    def recommend_by_custom_image(self, img_path, name='CUSTOM ITEM', fit='오버핏',
                                  main_category=None, sub_category=None,
                                  color=None, top_n=5):
        """
        사용자 입력 이미지에서 부위/색상을 자동 인식하고 같은 부위 상품을 우선 추천합니다.
        세부분류 후보가 충분하면 세부분류를 먼저 고정하고, 부족하면 대분류로 완화합니다.
        """
        detected_main, detected_sub, category_confidence = self.predict_category_from_image(img_path)
        detected_color = detect_color_label_from_image(img_path)

        main_category = main_category or detected_main
        sub_category = sub_category or detected_sub
        color = normalize_color_label(color or detected_color)

        img_emb = self.extract_single_image_embedding(img_path)
        if img_emb is None:
            return {
                'detected': {
                    'main_category': main_category,
                    'sub_category': sub_category,
                    'category_confidence': category_confidence,
                    'color': color,
                },
                'recommendations': self.recommend_by_user_preference(
                    pref_category=main_category,
                    pref_fit=fit,
                    pref_color=color,
                    top_n=top_n
                )
            }

        color_hist = extract_hsv_histogram(img_path)

        tfidf_name = TfidfVectorizer(
            analyzer='char_wb',
            ngram_range=(2, 4),
            min_df=1,
            sublinear_tf=True
        )
        tfidf_color = TfidfVectorizer(analyzer='word')
        tfidf_cat = TfidfVectorizer(analyzer='word')
        tfidf_sub = TfidfVectorizer(analyzer='word')
        tfidf_fit = TfidfVectorizer(analyzer='word')

        names_all = list(self.df['clean_name']) + [name]
        colors_all = list(self.df['color_label']) + [color]
        cats_all = list(self.df['main_category']) + [main_category]
        subs_all = list(self.df['sub_category']) + [sub_category]
        fits_all = list(self.df['fit_label']) + [fit]

        mat_name = normalize(tfidf_name.fit_transform(names_all))
        mat_color = normalize(tfidf_color.fit_transform(colors_all))
        mat_cat = normalize(tfidf_cat.fit_transform(cats_all))
        mat_sub = normalize(tfidf_sub.fit_transform(subs_all))
        mat_fit = normalize(tfidf_fit.fit_transform(fits_all))

        # 이미지 시각 피처 가중치 강화 (ResNet-50 50%, HSV 히스토그램 30%, 텍스트 메타데이터 20%)
        W_IMAGE, W_HIST, W_COLOR, W_CAT, W_SUB, W_NAME, W_FIT = 0.50, 0.30, 0.10, 0.05, 0.03, 0.01, 0.01

        text_matrix = hstack([
            mat_color * W_COLOR,
            mat_name * W_NAME,
            mat_cat * W_CAT,
            mat_sub * W_SUB,
            mat_fit * W_FIT,
        ])

        color_hists = np.load(self.color_npy_path)
        img_embeddings = np.load(self.npy_path)
        all_color_hists = np.vstack([color_hists, color_hist])
        all_img_embs = np.vstack([img_embeddings, img_emb])

        color_csr = csr_matrix(normalize(all_color_hists) * W_HIST)
        img_csr = csr_matrix(normalize(all_img_embs) * W_IMAGE)

        combined = normalize(hstack([text_matrix, color_csr, img_csr]), norm='l2', axis=1)
        sims = cosine_similarity(combined[-1], combined[:-1])[0]

        # 순수 시각적 유사도 (ResNet 65% + HSV 히스토그램 35%)
        raw_img_sims = cosine_similarity(img_emb.reshape(1, -1), img_embeddings)[0]
        raw_color_sims = cosine_similarity(color_hist.reshape(1, -1), color_hists)[0]
        visual_sims = 0.65 * raw_img_sims + 0.35 * raw_color_sims

        candidate_indices = np.argsort(sims)[::-1]

        # 1. 감지/지정된 main_category 및 sub_category와 동일한 상품을 1순위로 엄격 보장
        same_sub = []
        same_main = []
        other_cats = []

        for idx in candidate_indices:
            row = self.df.iloc[idx]
            row_main = row['main_category']
            row_sub = row['sub_category']

            if main_category and row_main == main_category:
                if sub_category and row_sub == sub_category:
                    same_sub.append(idx)
                else:
                    same_main.append(idx)
            else:
                other_cats.append(idx)

        # 2. 동일 카테고리 내에서 감지된 색상 및 유사색 그룹(Color Group Expansion)을 잇달아 정렬
        COLOR_GROUPS_DIRECT = {
            '베이지/아이보리': {'베이지/아이보리', '아이보리/베이지', '브라운/갈색', '화이트', 'BEIGE', 'IVORY', 'CREAM'},
            '브라운/갈색': {'브라운/갈색', '베이지/아이보리', '아이보리/베이지', '카키', 'BROWN'},
            '소라/스카이블루': {'소라/스카이블루', '블루', '화이트', '그레이', 'SKY', 'SORA'},
            '블루': {'블루', '소라/스카이블루', '네이비', 'BLUE', 'DENIM'},
            '네이비': {'네이비', '블루', '블랙', '그레이', 'NAVY'},
            '화이트': {'화이트', '베이지/아이보리', '아이보리/베이지', '그레이', '소라/스카이블루', 'WHITE'},
            '그레이': {'그레이', '블랙', '화이트', '네이비', 'GRAY', 'GREY', 'CHARCOAL'},
            '블랙': {'블랙', '그레이', '네이비', 'BLACK'},
            '핑크/레드': {'핑크/레드', '레드/핑크', '베이지/아이보리', '화이트', 'PINK', 'RED'},
            '그린': {'그린', '카키', '소라/스카이블루', 'GREEN', 'KHAKI'}
        }

        direct_set = COLOR_GROUPS_DIRECT.get(color, {color})

        def sort_by_color(idx_list):
            exact_match = sorted(
                [i for i in idx_list if str(self.df.iloc[i]['color_label']).strip() == color],
                key=lambda i: visual_sims[i], reverse=True
            )
            family_match = sorted(
                [i for i in idx_list if i not in exact_match and any(term in str(self.df.iloc[i]['color_label']).strip() for term in direct_set)],
                key=lambda i: visual_sims[i], reverse=True
            )
            other_color = sorted(
                [i for i in idx_list if i not in exact_match and i not in family_match],
                key=lambda i: visual_sims[i], reverse=True
            )
            return exact_match + family_match + other_color

        final_candidates = sort_by_color(same_sub) + sort_by_color(same_main) + sort_by_color(other_cats)
        candidate_indices = final_candidates

        results = []
        selected = candidate_indices[:top_n]
        for idx in selected:
            item = self.df.iloc[idx].to_dict()
            item['item_id'] = int(idx)
            item['similarity_score'] = float(0.40 * sims[idx] + 0.60 * visual_sims[idx])
            results.append(item)

        return {
            'detected': {
                'main_category': main_category,
                'sub_category': sub_category,
                'category_confidence': category_confidence,
                'color': color,
            },
            'recommendations': results
        }

    def _extract_color_histograms_auto(self):
        """HSV 컬러 히스토그램 특징 자동 추출"""
        hist_list = []
        for idx in range(len(self.df)):
            img_path = os.path.join(self.image_dir, f"item_{idx}.jpg")
            hist = extract_hsv_histogram(img_path)
            hist_list.append(hist)
        hist_matrix = np.array(hist_list, dtype=np.float32)
        np.save(self.color_npy_path, hist_matrix)
        return hist_matrix

    def ensure_part_classifier(self, force=False, use_hist=True, out_path='part_classifier_aug.joblib', n_estimators=200):
        """
        데이터셋(임베딩 + 선택적 히스토그램)을 이용해 상/하/기타 파트 분류기를 학습하고 저장합니다.
        - force=True 이면 기존 모델이 있어도 재학습합니다.
        - use_hist=True 이면 color_features.npy가 존재하고 크기가 맞을 때 히스토그램을 특성으로 추가합니다.
        - 학습이 완료되면 joblib로 저장하고 self.part_clf/self.part_le를 업데이트합니다.
        """
        if self.part_clf is not None and not force:
            return True

        # 준비: 임베딩 로드
        if not os.path.exists(self.npy_path):
            return False
        emb = np.load(self.npy_path)
        if emb is None or emb.shape[0] != len(self.df):
            return False

        X = emb
        # 색상 히스토그램 추가 옵션
        if use_hist and os.path.exists(self.color_npy_path):
            try:
                H = np.load(self.color_npy_path)
                if H.shape[0] == X.shape[0]:
                    X = np.concatenate([X, H], axis=1)
                else:
                    use_hist = False
            except Exception:
                use_hist = False

        # 라벨 준비: main_category 열이 있으면 binary 매핑
        if 'main_category' in self.df.columns:
            y_raw = self.df['main_category'].fillna('').astype(str).values
            y = np.array([map_main_to_binary(v) for v in y_raw])
        else:
            # fallback: KMeans pseudo-label
            from sklearn.cluster import KMeans
            k = 2
            km = KMeans(n_clusters=k, random_state=42).fit(X)
            y = km.labels_.astype(str)

        from sklearn.preprocessing import LabelEncoder
        from sklearn.ensemble import RandomForestClassifier

        le = LabelEncoder()
        y_enc = le.fit_transform(y)

        clf = RandomForestClassifier(n_estimators=n_estimators, class_weight='balanced_subsample', random_state=42, n_jobs=-1)
        try:
            clf.fit(X, y_enc)
            joblib.dump({'model': clf, 'le': le, 'use_hist': use_hist}, out_path)
            self.part_clf = clf
            self.part_le = le
            return True
        except Exception:
            return False

    def _build_feature_matrix(self):
        """
        고도화된 멀티모달 하이브리드 피처 결합
        - weight_mode='balanced' (색상 40% : 디자인 40% 50:50 동등 조건 모델)
        - weight_mode='color_first' (색상 65% 최우선 모델)
        """
        tfidf_name = TfidfVectorizer(
            analyzer='char_wb',
            ngram_range=(2, 4),
            min_df=1,
            sublinear_tf=True
        )
        tfidf_color = TfidfVectorizer(analyzer='word')
        tfidf_cat   = TfidfVectorizer(analyzer='word')
        tfidf_sub   = TfidfVectorizer(analyzer='word')
        tfidf_fit   = TfidfVectorizer(analyzer='word')

        mat_name  = normalize(tfidf_name.fit_transform(self.df['clean_name']))
        mat_color = normalize(tfidf_color.fit_transform(self.df['color_label']))
        mat_cat   = normalize(tfidf_cat.fit_transform(self.df['main_category']))
        mat_sub   = normalize(tfidf_sub.fit_transform(self.df['sub_category']))
        mat_fit   = normalize(tfidf_fit.fit_transform(self.df['fit_label']))

        if self.weight_mode == 'balanced':
            # 색상(50% : 텍스트30 + 히스토그램20) + 디자인(35% : ResNet 형태20 + 상품명15) 밸런스 모델
            W_COLOR = 0.30  # 텍스트 색상 라벨 (30%)
            W_HIST  = 0.20  # HSV 시각 컬러 히스토그램 (20%)
            W_NAME  = 0.15  # 상품명/단추/셔츠 등 디자인 디테일 텍스트 (15%)
            W_IMAGE = 0.20  # ResNet 딥러닝 넥라인/단추/깃 실루엣 형태 (20%)
            W_CAT   = 0.11  # 메인 카테고리 (11%)
            W_SUB   = 0.02  # 서브 카테고리 (2%)
            W_FIT   = 0.02  # 핏 (2%)
        else:
            # 색상 최우선 조건
            W_COLOR = 0.40  # 텍스트 색상 라벨
            W_HIST  = 0.25  # HSV 시각적 컬러 히스토그램
            W_CAT   = 0.12  # 메인 카테고리
            W_SUB   = 0.03  # 서브 카테고리
            W_NAME  = 0.10  # 상품명/디자인
            W_IMAGE = 0.08  # ResNet 시각적 형태
            W_FIT   = 0.02  # 핏

        text_matrix = hstack([
            mat_color * W_COLOR,
            mat_name  * W_NAME,
            mat_cat   * W_CAT,
            mat_sub   * W_SUB,
            mat_fit   * W_FIT,
        ])

        # 1. ResNet Embeddings
        img_embeddings = None
        if os.path.exists(self.npy_path):
            try:
                loaded = np.load(self.npy_path)
                if loaded.shape[0] == len(self.df):
                    img_embeddings = loaded
                else:
                    img_embeddings = self._extract_image_features_auto()
            except Exception:
                img_embeddings = self._extract_image_features_auto()
        else:
            img_embeddings = self._extract_image_features_auto()

        # 2. HSV Color Histograms
        color_hists = None
        if os.path.exists(self.color_npy_path):
            try:
                loaded_c = np.load(self.color_npy_path)
                if loaded_c.shape[0] == len(self.df):
                    color_hists = loaded_c
                else:
                    color_hists = self._extract_color_histograms_auto()
            except Exception:
                color_hists = self._extract_color_histograms_auto()
        else:
            color_hists = self._extract_color_histograms_auto()

        matrices_to_stack = [text_matrix]

        if color_hists is not None:
            color_csr = csr_matrix(normalize(color_hists) * W_HIST)
            matrices_to_stack.append(color_csr)

        if img_embeddings is not None:
            img_csr = csr_matrix(normalize(img_embeddings) * W_IMAGE)
            matrices_to_stack.append(img_csr)

        # 전체 결합 행렬 정규화
        combined_raw = hstack(matrices_to_stack)
        self.feature_matrix = normalize(combined_raw, norm='l2', axis=1)

        # Cosine Similarity Matrix
        self.similarity_matrix = cosine_similarity(self.feature_matrix, self.feature_matrix)

    def recommend_by_product_index(self, item_idx, top_n=6, same_category_only=True):
        """상품 기반 연관 추천 (동일 카테고리 스타일/시각 유사도 최우선)"""
        if item_idx < 0 or item_idx >= len(self.df):
            return []

        target_item = self.df.iloc[item_idx]
        target_name = target_item['product_name'].strip()
        target_url  = str(target_item.get('product_url', '')).strip()
        target_main_cat = target_item['main_category']

        sim_scores = list(enumerate(self.similarity_matrix[item_idx]))
        sim_scores = sorted(sim_scores, key=lambda x: x[1], reverse=True)

        results = []
        seen_keys = set()
        self_key = target_url if target_url and target_url != 'nan' else target_name
        seen_keys.add(self_key)

        for idx, score in sim_scores:
            if idx == item_idx:
                continue

            item = self.df.iloc[idx].to_dict()
            pname    = item['product_name'].strip()
            purl     = str(item.get('product_url', '')).strip()
            main_cat = item['main_category']

            dedup_key = purl if purl and purl != 'nan' else pname
            if dedup_key in seen_keys:
                continue

            # 동일 카테고리 옵션 활성화 시 다른 카테고리 제외
            if same_category_only and target_main_cat and main_cat and (target_main_cat != main_cat):
                continue
            elif target_main_cat and main_cat and (target_main_cat != main_cat) and (score < 0.55):
                continue

            seen_keys.add(dedup_key)
            item['item_id'] = int(idx)
            item['similarity_score'] = round(float(score), 4)
            results.append(item)

            if len(results) >= top_n:
                break

        return results

    def recommend_outfit_by_product_index(self, item_idx, top_n=4):
        """상품 연관 코디 추천 (크로스 카테고리 색상 & 스타일 조화 조합)"""
        if item_idx < 0 or item_idx >= len(self.df):
            return []

        target_item = self.df.iloc[item_idx]
        target_name = target_item['product_name'].strip()
        target_main_cat = target_item['main_category']

        sim_scores = list(enumerate(self.similarity_matrix[item_idx]))
        sim_scores = sorted(sim_scores, key=lambda x: x[1], reverse=True)

        results = []
        seen_cats = set([target_main_cat])
        seen_keys = set([target_name])

        for idx, score in sim_scores:
            if idx == item_idx:
                continue

            item = self.df.iloc[idx].to_dict()
            pname    = item['product_name'].strip()
            main_cat = item['main_category']

            if pname in seen_keys:
                continue

            # 세트 코디 생성을 위해 카테고리당 1개씩 다양한 카테고리 상품 선택
            if main_cat and main_cat in seen_cats:
                continue

            seen_keys.add(pname)
            if main_cat:
                seen_cats.add(main_cat)

            item['item_id'] = int(idx)
            item['similarity_score'] = round(float(score), 4)
            results.append(item)

            if len(results) >= top_n:
                break

        return results

    def recommend_by_user_preference(self, pref_category=None, pref_fit=None,
                                     pref_length=None, pref_color=None, top_n=None):
        """
        고도화된 스마트 사용자 취향 추천 (Multi-Attribute Match Score + Feature Relevance Sorting)
        - 1. 카테고리/색상/핏/길이 매칭 점수 (Match Score) 계산
        - 2. 동일 동점인 경우, 아이템 대표 피처 강도로 2차 정렬하여 가장 완성도 높은 상품 순으로 리턴!
        """
        df_copy = self.df.copy()

        # 1. 1차 카테고리 필터링
        if pref_category and pref_category.strip():
            df_filtered = df_copy[
                (df_copy['main_category'] == pref_category) |
                (df_copy['sub_category'] == pref_category)
            ]
            if len(df_filtered) == 0:
                df_filtered = df_copy
        else:
            df_filtered = df_copy

        # 2. 가중 매칭 점수 계산 (사용자 요청: 색상이 최우선 반영되도록 색상 점수 가중치 최상위 부여)
        scores = []
        for idx, row in df_filtered.iterrows():
            match_score = 0.0

            # 색상 (0.50 최우선)
            if pref_color and pref_color.strip():
                match_score += self._color_preference_score(pref_color, row)
            else:
                match_score += 0.50

            # 카테고리 (0.30)
            if pref_category and pref_category.strip():
                if row['main_category'] == pref_category or row['sub_category'] == pref_category:
                    match_score += 0.30
            else:
                match_score += 0.30

            # 핏 (0.12)
            if pref_fit and pref_fit.strip():
                if row['fit_label'] == pref_fit:
                    match_score += 0.12
            else:
                match_score += 0.12

            # 기장 (0.08)
            if pref_length and pref_length.strip():
                if row['length_label'] == pref_length:
                    match_score += 0.08
            else:
                match_score += 0.08

            # 동점 처리를 위한 피처 규격 norm (스타일 뚜렷함)
            feat_norm = float(np.linalg.norm(self.feature_matrix[idx].toarray()))
            final_score = match_score + (feat_norm * 0.001)

            scores.append((idx, round(match_score, 2), final_score))

        # 랭킹 정렬: Match Score 내림차순
        scores.sort(key=lambda x: x[2], reverse=True)

        results = []
        seen_keys = set()

        for idx, m_score, f_score in scores:
            row = df_filtered.loc[idx]
            pname = row['product_name'].strip()
            purl  = str(row.get('product_url', '')).strip()
            dedup_key = purl if purl and purl != 'nan' else pname
            if dedup_key in seen_keys:
                continue
            seen_keys.add(dedup_key)

            item = row.to_dict()
            item['item_id'] = int(idx)
            item['similarity_score'] = m_score
            results.append(item)

            if top_n is not None and len(results) >= top_n:
                break

        return results

    @staticmethod
    def _color_preference_score(pref_color, row):
        color = str(row.get('color_label', '')).strip()
        product_name = str(row.get('product_name', '')).upper()
        pref = str(pref_color).strip()

        if color == pref:
            return 0.50

        # 유사 색상 그룹 (Color Group Expansion) 가중치 부여
        color_families = {
            '그린': {'그린', '카키'},
            '카키': {'카키', '그린', '브라운/갈색'},
            '블루': {'블루', '소라/스카이블루', '네이비'},
            '소라/스카이블루': {'소라/스카이블루', '블루', '화이트'},
            '네이비': {'네이비', '블루', '블랙', '그레이'},
            '베이지/아이보리': {'베이지/아이보리', '아이보리/베이지', '브라운/갈색', '화이트'},
            '아이보리/베이지': {'베이지/아이보리', '아이보리/베이지', '브라운/갈색', '화이트'},
            '브라운/갈색': {'브라운/갈색', '베이지/아이보리', '카키'},
            '화이트': {'화이트', '베이지/아이보리', '아이보리/베이지', '그레이', '소라/스카이블루'},
            '그레이': {'그레이', '블랙', '화이트', '네이비'},
            '블랙': {'블랙', '네이비', '그레이'},
            '핑크/레드': {'핑크/레드', '레드/핑크', '베이지/아이보리', '화이트'},
        }
        if color in color_families.get(pref, set()):
            return 0.44

        name_keywords = {
            '그린': ('GREEN', 'MINT', 'KHAKI', 'OLIVE'),
            '카키': ('KHAKI', 'OLIVE', 'GREEN'),
            '블루': ('BLUE', 'SKY', 'SORA', 'NAVY', 'DENIM'),
            '소라/스카이블루': ('SKY', 'SORA', 'LIGHT BLUE', 'BLUE'),
            '네이비': ('NAVY', 'BLUE', 'DARK BLUE'),
            '베이지/아이보리': ('IVORY', 'BEIGE', 'CREAM', 'OATMEAL', 'LIGHT BEIGE'),
            '아이보리/베이지': ('IVORY', 'BEIGE', 'CREAM', 'OATMEAL', 'LIGHT BEIGE'),
            '브라운/갈색': ('BROWN', 'MOCHA', 'COCOA', 'CAMEL'),
            '레드/핑크': ('RED', 'PINK', 'ROSE'),
            '블랙': ('BLACK', 'CHARCOAL'),
            '화이트': ('WHITE', 'CLEAN WHITE'),
            '그레이': ('GRAY', 'GREY', 'MELANGE'),
        }
        if any(keyword in product_name for keyword in name_keywords.get(pref, ())):
            return 0.38

        return 0.0
