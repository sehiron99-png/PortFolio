import os
import csv
from recommender import ClothingRecommender, map_main_to_binary
import pandas as pd

CSV = 'rest_recreation_600_labeled.csv'
NPY = 'image_features_aug.npy'
IMAGE_DIR = 'static/images'
TOP_N = 5
OUT_CSV = 'evaluation_part_recs.csv'

r = ClothingRecommender(CSV, npy_path=NPY, image_dir=IMAGE_DIR)
df = r.df

# find image column in CSV
img_col = None
for col in df.columns:
    if 'image' in col.lower() or 'img' in col.lower() or 'file' in col.lower():
        img_col = col
        break
if img_col is None:
    img_col = 'image_url'

rows = []
correct_pred = 0
pred_count = 0
rec_match_counts = []
rec_total_counts = []

for idx in range(len(df)):
    row = df.iloc[idx]
    true_part = map_main_to_binary(row['main_category'])

    # resolve image path from CSV value if present, else fallback to static/images/item_{idx}.jpg
    raw_path = str(row.get(img_col, '') if img_col in df.columns else '')
    cand = raw_path.replace('\\', '/').lstrip('/')
    if cand == '' or not os.path.exists(cand):
        cand = os.path.join(IMAGE_DIR, f'item_{idx}.jpg')
    if not os.path.exists(cand):
        # skip items without image
        continue

    pred_part, conf = r.predict_part_from_image(cand)
    if pred_part is not None:
        pred_count += 1
        if pred_part == true_part:
            correct_pred += 1

    # recommendation top-N
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
        'item_id': row.get('item_id', ''),
        'true_main': row.get('main_category', ''),
        'true_part': true_part,
        'image_path': cand,
        'pred_part': pred_part if pred_part is not None else '',
        'pred_conf': conf,
        'topN_matches': match,
        'topN_total': total
    })

# metrics
part_acc = (correct_pred / pred_count) if pred_count else 0.0
avg_rec_match_rate = (sum(rec_match_counts) / sum(rec_total_counts)) if rec_total_counts else 0.0
avg_rec_match_count = (sum(rec_match_counts) / len(rec_match_counts)) if rec_match_counts else 0.0

print('Evaluated items with images:', len(rows))
print('Part prediction count:', pred_count)
print('Part prediction accuracy (exact):', round(part_acc, 4))
print(f'Avg Top-{TOP_N} match rate (fraction of recs matching part):', round(avg_rec_match_rate, 4))
print(f'Avg Top-{TOP_N} matches per query:', round(avg_rec_match_count, 4))

# save detail
pd.DataFrame(rows).to_csv(OUT_CSV, index=False)
print('Saved detailed results to', OUT_CSV)
