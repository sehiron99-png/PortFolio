"""tune_part_classifier.py
Automated hyperparameter tuning for part classifier (TOP/BOTTOM/OTHER).
Usage:
  python tune_part_classifier.py --features image_features.npy --csv rest_recreation_600_labeled.csv --color-features color_features.npy --use-hist --out part_classifier_tuned.joblib

The script:
 - Loads embeddings and optional color histograms
 - Maps CSV main_category to TOP/BOTTOM/OTHER
 - Tries grid of RandomForest hyperparameters
 - Evaluates with stratified holdout and 5-fold CV (f1_macro)
 - Saves best model and CSV of results
"""

import argparse
import os
import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import LabelEncoder
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.metrics import classification_report, f1_score
import joblib


def map_to_binary(main_label):
    s = str(main_label)
    if '하의' in s or 'BOTTOM' in s or 'pants' in s.lower():
        return 'BOTTOM'
    if '상의' in s or 'TOP' in s or 'shirt' in s.lower() or 'top' in s.lower():
        return 'TOP'
    return 'OTHER'


def load_features(features_path, color_path=None, use_hist=False):
    X = np.load(features_path)
    if use_hist and color_path and os.path.exists(color_path):
        H = np.load(color_path)
        if H.shape[0] == X.shape[0]:
            X = np.concatenate([X, H], axis=1)
    return X


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--features', default='image_features.npy')
    parser.add_argument('--color-features', default='color_features.npy')
    parser.add_argument('--csv', default='rest_recreation_600_labeled.csv')
    parser.add_argument('--out', default='part_classifier_tuned.joblib')
    parser.add_argument('--use-hist', action='store_true')
    parser.add_argument('--test-size', type=float, default=0.2)
    args = parser.parse_args()

    print('Loading CSV labels...')
    df = pd.read_csv(args.csv, encoding='utf-8-sig')
    if 'main_category' not in df.columns:
        raise SystemExit('CSV missing main_category column')

    print('Loading features...')
    X = load_features(args.features, args.color_features, use_hist=args.use_hist)
    if X is None:
        raise SystemExit('Failed to load features')

    y_raw = df['main_category'].fillna('').astype(str).values
    y = np.array([map_to_binary(v) for v in y_raw])
    le = LabelEncoder()
    y_enc = le.fit_transform(y)

    # Holdout split
    Xtr, Xte, ytr, yte = train_test_split(X, y_enc, test_size=args.test_size, random_state=42, stratify=y_enc)

    param_grid = []
    for n in [50, 100, 200, 300]:
        for md in [None, 20, 40]:
            param_grid.append({'n_estimators': n, 'max_depth': md})

    results = []
    best_score = -1.0
    best_model = None
    best_params = None

    for p in param_grid:
        print(f"Training RF n={p['n_estimators']} max_depth={p['max_depth']}")
        clf = RandomForestClassifier(n_estimators=p['n_estimators'], max_depth=p['max_depth'], class_weight='balanced_subsample', random_state=42, n_jobs=-1)
        # 5-fold CV on training set
        try:
            cv_scores = cross_val_score(clf, Xtr, ytr, cv=5, scoring='f1_macro')
            mean_cv = float(np.mean(cv_scores))
        except Exception as e:
            print('CV failed:', e)
            mean_cv = -1.0

        # Fit and evaluate holdout
        try:
            clf.fit(Xtr, ytr)
            ypred = clf.predict(Xte)
            hold_f1 = float(f1_score(yte, ypred, average='macro'))
        except Exception as e:
            print('Fit/eval failed:', e)
            hold_f1 = -1.0

        results.append({'n_estimators': p['n_estimators'], 'max_depth': p['max_depth'], 'cv_f1_macro': mean_cv, 'holdout_f1_macro': hold_f1})

        if hold_f1 > best_score:
            best_score = hold_f1
            best_model = clf
            best_params = p

        print(f" -> CV f1_macro: {mean_cv:.4f} | Holdout f1_macro: {hold_f1:.4f}")

    df_res = pd.DataFrame(results)
    df_res.to_csv('tuning_results.csv', index=False)
    print('Saved tuning_results.csv')

    if best_model is not None:
        joblib.dump({'model': best_model, 'le': le, 'use_hist': args.use_hist, 'best_params': best_params}, args.out)
        print('Saved best model to', args.out, 'best_params=', best_params, 'best_holdout_f1=', best_score)
    else:
        print('No model trained successfully')


if __name__ == '__main__':
    main()
