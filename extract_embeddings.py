"""extract_embeddings.py
ResNet-18 이미지 임베딩을 추출해 numpy로 저장합니다.

사용법 예:
  & '.\.venv\Scripts\python.exe' extract_embeddings.py --csv rest_recreation_600_labeled.csv --out image_features.npy

스크립트 동작:
 - CSV에서 이미지 경로 컬럼을 자동으로 찾습니다 (이름에 'img' 또는 'image' 포함 여부).
 - 이미지 로드, 리사이즈, 정규화, ResNet-18 backbone으로 512-D 임베딩 추출
 - 임베딩과 대응 인덱스, 파일명을 출력/저장
"""

import argparse
import os
import sys
from pathlib import Path
import numpy as np
from PIL import Image

import torch
import torchvision.transforms as T
from torchvision import models
import pandas as pd


def find_image_column(df):
    for col in df.columns:
        if 'image' in col.lower() or 'img' in col.lower() or 'file' in col.lower():
            return col
    return None


def build_model(device='cpu'):
    model = models.resnet18(pretrained=True)
    # remove classifier
    modules = list(model.children())[:-1]
    backbone = torch.nn.Sequential(*modules)
    backbone.eval()
    backbone.to(device)
    return backbone


def image_to_tensor(image_path, size=224):
    img = Image.open(image_path).convert('RGB')
    transform = T.Compose([
        T.Resize((size, size)),
        T.ToTensor(),
        T.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
    ])
    return transform(img)


def main(args):
    csv_path = Path(args.csv)
    if not csv_path.exists():
        print('CSV not found:', csv_path)
        sys.exit(1)

    df = pd.read_csv(csv_path)
    img_col = find_image_column(df)
    if img_col is None:
        print('이미지 경로 컬럼을 찾지 못했습니다. CSV 열 목록:', df.columns.tolist())
        sys.exit(1)

    device = 'cuda' if torch.cuda.is_available() and not args.force_cpu else 'cpu'
    model = build_model(device=device)

    features = []
    files = []

    for idx, row in df.iterrows():
        img_path = row[img_col]
        if not os.path.isabs(img_path):
            # 시도: static/images 상대 경로
            candidate = Path(img_path)
            if not candidate.exists():
                candidate = Path('static') / 'images' / Path(img_path).name
            img_path = str(candidate)

        try:
            tensor = image_to_tensor(img_path)
        except Exception as e:
            print(f'이미지 로드 실패: {img_path} ({e})')
            features.append(np.zeros((512,), dtype=np.float32))
            files.append(img_path)
            continue

        with torch.no_grad():
            x = tensor.unsqueeze(0).to(device)
            out = model(x)  # shape: (1, 512, 1, 1)
            out = out.squeeze().cpu().numpy()
            if out.ndim > 1:
                out = out.reshape(-1)
        features.append(out.astype(np.float32))
        files.append(img_path)

    features = np.stack(features, axis=0)
    np.save(args.out, features)
    # Save metadata
    meta = pd.DataFrame({'file': files})
    meta.to_csv(str(Path(args.out).with_suffix('.csv')), index=False)
    print('저장 완료:', args.out)
    print('메타 저장:', Path(args.out).with_suffix('.csv'))


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--csv', required=True, help='데이터 CSV 파일')
    parser.add_argument('--out', default='image_features.npy', help='저장할 numpy 파일')
    parser.add_argument('--force-cpu', action='store_true', help='강제로 CPU 사용')
    args = parser.parse_args()
    main(args)
