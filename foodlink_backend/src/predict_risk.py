# src/predict_risk.py
import joblib

model = joblib.load("models/spoilage_model.pkl")

def predict_spoilage_risk(expiry_hours, distance_km, quantity_kg):
    features = [[expiry_hours, distance_km, quantity_kg]]
    prob = model.predict_proba(features)[0][1]  # probability of spoilage
    return round(float(prob), 3)