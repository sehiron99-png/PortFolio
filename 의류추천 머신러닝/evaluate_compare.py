import os
import pandas as pd
from recommender import ClothingRecommender, map_main_to_binary

configs = [
    {
        'name': 'original',
        'csv': 'rest_recreation_600_labeled.csv',
        'npy': 'image_features.npy',
        'out_csv': 'evaluation_original.csv'
    },
    {
        'name': 'augmented',
        'csv': 'rest_recreation_600_labeled_augmented.csv',
        'npy': 'image_features_aug.npy',
        'out_csv': 'evaluation_augmented.csv'
    }
]

TOP_N = 5
IMAGE_DIR = 'static/images'

results = []

for cfg in configs:
    print('Running evaluation for', cfg['name'])
    r = ClothingRecommender(cfg['csv'], npy_path=cfg['npy'], image_dir=IMAGE_DIR)
    df = r.df

    # find image column
    img_col = None
    for col in df.columns:
        if 'image' in col.lower() or 'img' in col.lower() or 'file' in col.lower():
            img_col = col
            break

    rows = []
    correct_pred = 0
    pred_count = 0
    rec_match_counts = []
    rec_total_counts = []

    for idx in range(len(df)):
        row = df.iloc[idx]
        true_part = map_main_to_binary(row.get('main_category', ''))

        raw_path = ''
        if img_col:
            raw_path = str(row.get(img_col, '') or '')
        cand = raw_path.replace('\\', '/').lstrip('/') if raw_path else ''
        if cand == '' or not os.path.exists(cand):
            # for augmented CSV the path may contain static/images_aug/
            alt = os.path.join('static', 'images_aug', f'item_{idx}_aug_0.jpg')
            cand2 = os.path.join(IMAGE_DIR, f'item_{idx}.jpg')
            if os.path.exists(cand):
                pass
            elif os.path.exists(alt):
                cand = alt
            elif os.path.exists(cand2):
                cand = cand2
            else:
                cand = ''
        if not cand or not os.path.exists(cand):
            continue

        pred_part, conf = r.predict_part_from_image(cand)
        if pred_part is not None:
            pred_count += 1
            if pred_part == true_part:
                correct_pred += 1

        recs = r.recommend_by_product_index(idx, top_n=TOP_N, same_category_only=False)
        match = 0
        total = 0
        for rec in recs:
            total += 1
            rec_part = map_main_to_binary(rec.get('main_category', ''))
            if rec_part == true_part:
                match += 1
        if total > 0:
            rec_match_counts.append(match)
            rec_total_counts.append(total)

        rows.append({
            'idx': idx,
            'true_part': true_part,
            'image_path': cand,
            'pred_part': pred_part if pred_part is not None else '',
            'pred_conf': conf,
            'topN_matches': match,
            'topN_total': total
        })

    part_acc = (correct_pred / pred_count) if pred_count else 0.0
    avg_rec_match_rate = (sum(rec_match_counts) / sum(rec_total_counts)) if rec_total_counts else 0.0
    avg_rec_match_count = (sum(rec_match_counts) / len(rec_match_counts)) if rec_match_counts else 0.0

    print(f"Dataset: {cfg['name']}")
    print(' Evaluated items with images:', len(rows))
    print(' Part prediction count:', pred_count)
    print(' Part prediction accuracy:', round(part_acc, 4))
    print(f' Avg Top-{TOP_N} match rate:', round(avg_rec_match_rate, 4))
    print(f' Avg Top-{TOP_N} matches per query:', round(avg_rec_match_count, 4))

    pd.DataFrame(rows).to_csv(cfg['out_csv'], index=False)
    print(' Saved detailed CSV to', cfg['out_csv'])

    results.append({
        'name': cfg['name'],
        'items': len(rows),
        'pred_count': pred_count,
        'part_acc': part_acc,
        'avg_rec_match_rate': avg_rec_match_rate,
        'avg_rec_match_count': avg_rec_match_count,
    })

print('\nSummary:')
for r in results:
    print(r)
