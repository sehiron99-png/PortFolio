`clip_zero_shot_test.py/` : OpenAI의 CLIP 모델을 활용해 별도의 추가 학습 없이 텍스트-이미지 간 유사도 기반의 Zero-shot 의류 분류 및 추천 성능을 테스트하는 모듈


`evaluate_model.py/` : 단일 머신러닝/딥러닝 모델의 기본 추천 및 분류 성능 평가 스크립트

`evaluate_full.py/` : 전체 파이프라인에 대한 종합적인 성능 평가를 수행

`evaluate_compare.py/` : ResNet, CLIP 등 서로 다른 모델/알고리즘 간 성능 비교 평가 데이터를 출력

`rest_recreation_cloth_01.py/` : 추천 모델의 API 서버를 구축하거나, 특정 스타일/조건에 맞춰 의류 코디를 재조합 및 추천하는 추론 모듈


`test_custom_clothing.ipynb/` : 입력한 커스텀 의류 이미지에 대한 파이프라인 테스트

`test_custom_clothing_29cm.ipynb/` : 29cm 등 특정 쇼핑몰/플랫폼의 실제 의류 데이터셋을 적용하여 머신러닝 추천 결과를 테스트

`extract_embeddings.py/` : 의류 이미지 데이터셋으로부터 시각적 특징을 추출하여 저장하거나 벡터 DB/배열 형태로 변환하는 전처리 모듈

`resnet_clustering.py/` " ResNet 백본 네트워크를 활용해 의류 이미지의 특징을 추출하고, 군집화를 수행하여 스타일이나 범주별 그룹을 생성하는 스크립트

`train_part_classifier.py/` : 의류의 세부 부위를 분류하기 위해 분류기 모델을 학습시키는 파이프라인 스크립트

`tune_part_classifier.py/` : 학습된 분류기 모델의 하이퍼파라미터 튜닝 또는 파인튜닝을 진행하여 정확도를 개선하는 스크립트

