# src/evaluate.py
import pandas as pd
from .generator import generate_synthetic_data
from .mcdm_allocator import adaptive_mcdm_allocator
from .baselines import nearest_baseline, fairness_baseline

def evaluate_all_methods():
    donations, charities = generate_synthetic_data(300, 12)
    
    results = {"nearest": [], "fairness": [], "adaptive": []}
    
    for donation in donations:
        # Nearest
        results["nearest"].append(nearest_baseline(donation, charities))
        # Fairness
        results["fairness"].append(fairness_baseline(donation, charities))
        # Adaptive IMA
        best = adaptive_mcdm_allocator(donation, charities)
        if best:
            results["adaptive"].append(best)
    
    print("✅ Evaluation completed for 3 methods")
    print("Waste Rate, Gini Coefficient, Std Dev, etc. will be calculated in full report")
    return results