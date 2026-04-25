# Test script to verify IMA with your actual data
import requests
import json

# Your actual data from Firestore
donation = {
    "id": "test_donation",
    "lat": 6.85,
    "lon": 79.86,
    "food_type": "Cooked Meals",
    "quantity_kg": 5,
    "expiry_hours": 2,  # This should trigger 0.6 spoilage risk
    "cold_required": False,
    "timestamp": "2026-04-25T10:09:10"
}

charity = {
    "id": "test_charity",
    "name": "Volunteer Sri Lanka",
    "lat": 6.9319,
    "lon": 79.8478,
    "received_today": 0,
    "has_cold_storage": True,
    "capacity_remaining": 20
}

# Test single match
print("Testing IMA with your data...")
print(f"Donation: {donation}")
print(f"Charity: {charity}")
print()

# Calculate distance manually
from geopy.distance import geodesic
distance = geodesic((6.85, 79.86), (6.9319, 79.8478)).km
print(f"Distance: {distance:.2f} km")
print(f"Within 8-12km geofence? {8 <= distance <= 12}")
print()

# Call backend
try:
    response = requests.post('http://localhost:5000/ima', json={
        'donation': donation,
        'charities': [charity]
    })
    
    if response.status_code == 200:
        result = response.json()
        print("Backend Response:")
        print(json.dumps(result, indent=2))
        
        if result:
            print(f"\nSpoilage Risk: {result.get('spoilage_risk', 'N/A')}")
            print(f"Expected: ~0.6 (from expiry < 3h) + {distance * 0.04:.3f} (from distance) = {0.6 + distance * 0.04:.3f}")
        else:
            print("\nNo match returned - charity outside geofence!")
    else:
        print(f"Error: {response.status_code}")
        print(response.text)
except Exception as e:
    print(f"Error connecting to backend: {e}")
    print("Make sure backend is running: python app.py")
