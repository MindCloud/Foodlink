# src/baselines.py
from geopy.distance import geodesic

def nearest_baseline(donation, charities):
    best = min(charities, key=lambda c: geodesic((donation['lat'], donation['lon']), (c['lat'], c['lon'])).km)
    return {"charity_name": best["name"], "method": "Nearest"}

def fairness_baseline(donation, charities):
    best = min(charities, key=lambda c: c['received_today'])
    return {"charity_name": best["name"], "method": "Fairness-only"}