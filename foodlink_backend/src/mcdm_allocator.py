# src/mcdm_allocator.py
import pymcdm
from geopy.distance import geodesic
from .predict_risk import predict_spoilage_risk

def adaptive_mcdm_allocator(donation, charities):
    candidates = []
    
    for ch in charities:
        dist = geodesic((donation['lat'], donation['lon']), (ch['lat'], ch['lon'])).km
        if not (8 <= dist <= 12):
            continue
            
        risk = predict_spoilage_risk(donation['expiry_hours'], dist, donation['quantity_kg'])
        
        # Adaptive weights
        if donation['expiry_hours'] <= 2:
            weights = [0.60, 0.10, 0.30]   # distance, fairness, spoilage
        elif donation['expiry_hours'] <= 6:
            weights = [0.40, 0.30, 0.30]
        else:
            weights = [0.20, 0.50, 0.30]
        
        score = (weights[0] * (1/(dist+1))) + \
                (weights[1] * (1/(ch['received_today']+1))) + \
                (weights[2] * (1-risk))
        
        candidates.append({
            "charity_id": ch["id"],
            "charity_name": ch["name"],
            "distance_km": round(dist, 2),
            "spoilage_risk": risk,
            "final_score": round(score, 4),
            "reason": f"Adaptive MCDM - Expiry {donation['expiry_hours']}h"
        })
    
    return max(candidates, key=lambda x: x["final_score"]) if candidates else None