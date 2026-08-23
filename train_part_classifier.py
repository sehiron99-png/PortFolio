"""train_part_classifier.py
학습 스크립트: 임베딩(또는 이미지)과 라벨을 사용해 상/하(파츠) 분류기를 학습합니다.

동작 순서:
 - image_features.npy 또는 CSV에서 임베딩 로드
 - CSV에서 파트 라벨(열 이름에 'part' 또는 'main_category' 포함) 자동 검색
 - 라벨이 없으면 KMeans로 pseudo-label 생성
 - LogisticRegression으로 학습, 교차검증 결과 출력
 - 모델을 joblib로 저장

사용 예:
  & '.\.venv\Scripts\python.exe' train_part_classifier.py --features image_features.npy --csv rest_recreation_600_labeled.csv --out part_classifier.joblib
"""

import argparse
from pathlib import Path
import numpy as np
import pandas as pd
from sklearn.cluster import KMeans
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import cross_val_score, train_test_split
from sklearn.preprocessing import LabelEncoder
from sklearn.metrics import classification_report
import joblib


def find_label_column(df):
    for col in df.columns:
        if 'part' in col.lower() or 'main' in col.lower() or 'category' in col.lower():
            return col
    return None


def map_to_binary(label):
    s = str(label).lower()
    if '하의' in label or 'bottom' in s or 'bott' in s:
        return 'BOTTOM'
    if '상의' in label or 'top' in s or 'top)' in s:
        return 'TOP'
    return 'OTHER'


def main(args):
    features_path = Path(args.features)
    if not features_path.exists():
        print('features 파일이 없습니다:', features_path)
        return

    X = np.load(features_path)
    df = None
    if args.csv:
        df_path = Path(args.csv)
        if df_path.exists():
            df = pd.read_csv(df_path)

    if args.use_hist:
        hist_path = Path(args.color_features)
        if hist_path.exists():
            H = np.load(hist_path)
            if H.shape[0] == X.shape[0]:
                X = np.concatenate([X, H], axis=1)
                print('컬러 히스토그램 추가됨:', H.shape)
            else:
                print('color_features.npy 크기 불일치, 히스토그램 사용 안함:', H.shape)
        else:
            print('color_features.npy를 찾을 수 없습니다. 히스토그램을 사용하지 않습니다.')

    y = None
    if df is not None:
        label_col = find_label_column(df)
        if label_col:
            y = df[label_col].astype(str).values
            print('라벨 컬럼 사용:', label_col)

    if args.binary and y is not None:
        print('binary 매핑 적용 (TOP/BOTTOM/OTHER)')
        y = [map_to_binary(v) for v in y]

    if y is None:
        # pseudo-label via KMeans
        k = args.k
        print('라벨이 없어 KMeans로 pseudo-label 생성, k=', k)
        km = KMeans(n_clusters=k, random_state=42).fit(X)
        y = km.labels_.astype(str)
        # save pseudo labels
        meta = pd.DataFrame({'pseudo_label': y})
        meta.to_csv('pseudo_labels_parts.csv', index=False)
        print('pseudo_labels_parts.csv 저장됨')

    le = LabelEncoder()
    y_enc = le.fit_transform(y)

    clf = RandomForestClassifier(
        n_estimators=args.n_estimators,
        class_weight='balanced_subsample',
        random_state=42,
        n_jobs=-1
    )

    scores = cross_val_score(clf, X, y_enc, cv=5, scoring='f1_macro')
    print('5-fold F1_macro:', scores, 'mean:', scores.mean())

    clf.fit(X, y_enc)
    joblib.dump({'model': clf, 'le': le, 'use_hist': args.use_hist}, args.out)
    print('모델 저장:', args.out)

    # optional evaluation on holdout
    if args.test_size > 0:
        Xtr, Xte, ytr, yte = train_test_split(X, y_enc, test_size=args.test_size, random_state=42, stratify=y_enc)
        clf2 = RandomForestClassifier(
            n_estimators=args.n_estimators,
            class_weight='balanced_subsample',
            random_state=42,
            n_jobs=-1
        )
        clf2.fit(Xtr, ytr)
        yp = clf2.predict(Xte)
        print('Holdout classification report:')
        print(classification_report(yte, yp, target_names=le.classes_))


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--features', default='image_features.npy', help='임베딩 numpy 파일')
    parser.add_argument('--csv', help='원본 CSV 파일 (라벨 포함 시 사용)')
    parser.add_argument('--color-features', default='color_features.npy', help='색상 히스토그램 numpy 파일')
    parser.add_argument('--out', default='part_classifier.joblib', help='저장할 모델 파일')
    parser.add_argument('--n-estimators', type=int, default=200, help='RandomForest 트리 개수')
    parser.add_argument('--use-hist', action='store_true', help='컬러 히스토그램을 추가 특성으로 사용')
    parser.add_argument('--k', type=int, default=2, help='pseudo-label 생성시 KMeans k')
    parser.add_argument('--test-size', type=float, default=0.2, help='holdout 비율 (0이면 생략)')
    parser.add_argument('--binary', action='store_true', help='binary 매핑: TOP/BOTTOM/OTHER')
    args = parser.parse_args()
    main(args)
