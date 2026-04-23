# src/generator.py
import pandas as pd
import numpy as np
from datetime import datetime

def generate_synthetic_data(n_donations=200, n_charities=15):
    np.random.seed(42)
    
    # Charities
    charities = []
    for i in range(n_charities):
        charities.append({
            "id": f"CH{i+1:03d}",
            "name": f"Charity {i+1}",
            "lat": 6.9271 + np.random.uniform(-0.05, 0.05),
            "lon": 79.8612 + np.random.uniform(-0.08, 0.08),
            "received_today": np.random.randint(0, 25),
            "has_cold_storage": np.random.choice([True, False], p=[0.6, 0.4]),
            "capacity_remaining": np.random.randint(10, 100)
        })
    
    # Donations
    donations = []
    for i in range(n_donations):
        expiry = np.random.uniform(0.5, 8.0)
        donations.append({
            "id": f"D{i+1:04d}",
            "lat": 6.9271 + np.random.uniform(-0.08, 0.08),
            "lon": 79.8612 + np.random.uniform(-0.12, 0.12),
            "food_type": np.random.choice(["Rice & Curry", "String Hoppers", "Fruits", "Bread", "Meals"]),
            "quantity_kg": round(np.random.uniform(2, 25), 1),
            "expiry_hours": round(expiry, 2),
            "cold_required": np.random.choice([True, False], p=[0.3, 0.7]),
            "timestamp": datetime.now().isoformat()
        })
    
    pd.DataFrame(charities).to_csv("data/charities.csv", index=False)
    pd.DataFrame(donations).to_csv("data/donations.csv", index=False)
    
    print(f"✅ Generated {n_donations} donations and {n_charities} charities")
    return donations, charities