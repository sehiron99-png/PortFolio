"""
CLIP zero-shot test script.
- Tries to use Hugging Face `transformers` CLIPModel/Processor.
- Loads several sample images from the CSV dataset and prints predicted probs for labels '상의' and '하의'.
"""
import os
import sys
from PIL import Image

CSV = 'rest_recreation_600_labeled.csv'
LABELS = ['상의', '하의']
NUM_PER_CLASS = 6

try:
    from transformers import CLIPProcessor, CLIPModel
except Exception as e:
    print('ERROR: transformers CLIP not available. Install with: pip install transformers torch pillow')
    sys.exit(2)

import torch

if not os.path.exists(CSV):
    print('CSV not found:', CSV)
    sys.exit(1)

import pandas as pd

df = pd.read_csv(CSV, encoding='utf-8-sig')

# find sample image paths for each main category
samples = []
for label in ['상의 (TOP)', '하의 (BOTTOM)']:
    rows = df[df['main_category'] == label]
    for _, r in rows.head(NUM_PER_CLASS).iterrows():
        img_path = r.get('image_url') or r.get('product_url')
        # dataset stores relative path like /static/images/item_0.jpg
        if img_path and img_path.startswith('/'):
            p = img_path.lstrip('/')
        else:
            p = img_path
        if p and os.path.exists(p):
            samples.append((label, p))
        else:
            # try static/images/item_{id}.jpg
            candidate = os.path.join('static', 'images', f"item_{int(r['item_id'])}.jpg")
            if os.path.exists(candidate):
                samples.append((label, candidate))

if not samples:
    print('No sample images found in static/images. Please ensure images exist.')
    sys.exit(1)

print('Using samples:')
for lbl, p in samples:
    print(' -', lbl, p)

model_name = 'openai/clip-vit-base-patch32'
print('Loading CLIP model', model_name)
model = CLIPModel.from_pretrained(model_name)
processor = CLIPProcessor.from_pretrained(model_name)

# prepare text embeddings
text_inputs = processor(text=LABELS, return_tensors='pt', padding=True)
with torch.no_grad():
    text_out = model.get_text_features(**text_inputs)
    # model API may return a tensor or a BaseModelOutput-like object
    if hasattr(text_out, 'last_hidden_state') and not torch.is_tensor(text_out):
        # try pooler_output then first token
        if hasattr(text_out, 'pooler_output') and text_out.pooler_output is not None:
            text_emb = text_out.pooler_output
        else:
            text_emb = text_out.last_hidden_state[:, 0, :]
    else:
        text_emb = text_out
    # normalize
    text_emb = text_emb / (text_emb.norm(p=2, dim=-1, keepdim=True) + 1e-12)

for lbl, img_path in samples:
    img = Image.open(img_path).convert('RGB')
    inputs = processor(images=img, return_tensors='pt')
    with torch.no_grad():
        img_out = model.get_image_features(**inputs)
        if hasattr(img_out, 'last_hidden_state') and not torch.is_tensor(img_out):
            if hasattr(img_out, 'pooler_output') and img_out.pooler_output is not None:
                img_emb = img_out.pooler_output
            else:
                img_emb = img_out.last_hidden_state[:, 0, :]
        else:
            img_emb = img_out
        img_emb = img_emb / (img_emb.norm(p=2, dim=-1, keepdim=True) + 1e-12)
        sims = (img_emb @ text_emb.T).squeeze(0)
        probs = torch.softmax(sims, dim=0).cpu().numpy()
    best_idx = int(probs.argmax())
    print(f"\nImage: {img_path} (gold={lbl})")
    for i, lab in enumerate(LABELS):
        print(f"  {lab}: {probs[i]:.3f}")
    print('  predicted:', LABELS[best_idx])

    # accumulate results
    try:
        import pandas as _pd
        if 'results' not in globals():
            results = []
        results.append({'gold': lbl, 'image': img_path, 'top_prob': float(probs[0]), 'bottom_prob': float(probs[1]), 'predicted': LABELS[best_idx]})
    except Exception:
        pass

# save CSV if possible
try:
    import pandas as pd
    if 'results' in globals() and results:
        pd.DataFrame(results).to_csv('clip_predictions_samples.csv', index=False, encoding='utf-8-sig')
        print('\nSaved predictions to clip_predictions_samples.csv')
except Exception:
    pass
