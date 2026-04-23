# src/ima_engine.py
import pandas as pd
from geopy.distance import geodesic
import fairpyx
import pymcdm

def calculate_haversine_distance(lat1, lon1, lat2, lon2):
    return geodesic((lat1, lon1), (lat2, lon2)).km

def adaptive_ima(donation, charities):
    """
    Main IMA function - returns the best charity using Adaptive MCDM
    """
    candidates = []

    for charity in charities:
        distance = calculate_haversine_distance(
            donation['lat'], donation['lon'],
            charity['lat'], charity['lon']
        )

        # Strict 8-12 km geofence
        if not (8 <= distance <= 12):
            continue

        # Simple spoilage risk (will be replaced by ML later)
        spoilage_risk = 0.0
        if donation['expiry_hours'] < 3:
            spoilage_risk += 0.6
        spoilage_risk += distance * 0.04

        # Adaptive weights based on urgency
        if donation['expiry_hours'] <= 2:
            weights = [0.60, 0.10, 0.30]   # distance, fairness, spoilage
        elif donation['expiry_hours'] <= 6:
            weights = [0.40, 0.30, 0.30]
        else:
            weights = [0.20, 0.50, 0.30]

        # MCDM scores
        dist_score = 1 / (distance + 1)
        fair_score = 1 / (charity['received_today'] + 1)
        spoil_score = 1 - spoilage_risk

        final_score = (weights[0] * dist_score) + (weights[1] * fair_score) + (weights[2] * spoil_score)

        candidates.append({
            "charity_id": charity["id"],
            "charity_name": charity["name"],
            "distance_km": round(distance, 2),
            "spoilage_risk": round(spoilage_risk, 3),
            "final_score": round(final_score, 4),
            "reason": f"Expiry {donation['expiry_hours']}h → Adaptive priority on spoilage safety"
        })

    if not candidates:
        return None

    # Return best match
    best = max(candidates, key=lambda x: x["final_score"])
    return best