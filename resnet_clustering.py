"""
ResNet embedding clustering script.
- Loads `image_features.npy` (or extracts if missing via ClothingRecommender)
- Runs KMeans for a small range of k values and prints cluster sizes and top examples
- Optionally writes `pseudo_labels.csv` with cluster ids for downstream training
"""
import os
import sys
import numpy as np
import pandas as pd
from sklearn.cluster import KMeans

CSV = 'rest_recreation_600_labeled.csv'
N_CLUSTERS = [2, 3, 4]
OUT_PSEUDO = 'pseudo_labels.csv'

if not os.path.exists(CSV):
    print('CSV not found:', CSV)
    sys.exit(1)

df = pd.read_csv(CSV, encoding='utf-8-sig')

emb_path = 'image_features.npy'
embs = None
if os.path.exists(emb_path):
    try:
        embs = np.load(emb_path)
        print('Loaded embeddings:', embs.shape)
    except Exception as e:
        print('Failed to load embeddings:', e)

if embs is None or embs.shape[0] != len(df):
    print('Embeddings missing or shape mismatch. Attempting to extract via recommender._extract_image_features_auto()')
    try:
        from recommender import ClothingRecommender
        rec = ClothingRecommender(CSV)
        embs = rec._extract_image_features_auto()
        np.save(emb_path, embs)
        print('Extracted and saved embeddings:', embs.shape)
    except Exception as e:
        print('Failed to extract embeddings automatically:', e)
        sys.exit(2)

for k in N_CLUSTERS:
    print('\nKMeans k=%d' % k)
    km = KMeans(n_clusters=k, random_state=42, n_init='auto')
    km.fit(embs)
    labels = km.labels_
    counts = pd.Series(labels).value_counts().sort_index()
    print('Cluster sizes:')
    print(counts.to_string())

    # show top-3 nearest examples to each cluster center
    centers = km.cluster_centers_
    from sklearn.metrics.pairwise import cosine_similarity
    sims = cosine_similarity(embs, centers)
    for cid in range(k):
        top_idx = sims[:, cid].argsort()[::-1][:5]
        print('\nCluster', cid, 'top examples:')
        for i in top_idx[:5]:
            item = df.iloc[i]
            print(f"  idx={i} id={item.get('item_id')} name={item.get('product_name')[:60]} main={item.get('main_category')} sub={item.get('sub_category')}")

# choose k=2 pseudo-labels (simple bottom/top split)
print('\nWriting pseudo labels using k=2')
km2 = KMeans(n_clusters=2, random_state=42, n_init='auto')
km2.fit(embs)
pseudo = pd.DataFrame({'item_id': df.index, 'pseudo_cluster': km2.labels_})
try:
    pseudo.to_csv(OUT_PSEUDO, index=False, encoding='utf-8-sig')
    print('Saved', OUT_PSEUDO)
except Exception as e:
    print('Failed to save pseudo labels:', e)
