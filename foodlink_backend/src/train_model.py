# src/train_model.py
import pandas as pd
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report
import joblib
import os

def train_spoilage_model():
    # Load synthetic data
    df = pd.read_csv("data/donations.csv")
    
    # Create features and target
    df['distance_km'] = np.random.uniform(4, 15, len(df))  # simulated
    df['spoilage'] = ((df['expiry_hours'] < df['distance_km'] * 0.8) | 
                      (df['cold_required'] == True)).astype(int)
    
    X = df[['expiry_hours', 'distance_km', 'quantity_kg']]
    y = df['spoilage']
    
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
    
    model = RandomForestClassifier(n_estimators=100, random_state=42)
    model.fit(X_train, y_train)
    
    # Save model
    os.makedirs("models", exist_ok=True)
    joblib.dump(model, "models/spoilage_model.pkl")
    
    print("✅ Model trained. Accuracy:", accuracy_score(y_test, model.predict(X_test)))
    return model