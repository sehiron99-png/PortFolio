import os
from .recommender import (
    ClothingRecommender,
    detect_color_label_from_image,
    detect_clothing_category_from_image,
    normalize_color_label
)

__version__ = "1.1.0"
__all__ = [
    "ClothingRecommender",
    "detect_color_label_from_image",
    "detect_clothing_category_from_image",
    "normalize_color_label"
]
