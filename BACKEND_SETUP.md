# FoodLink Backend - Setup & Run Guide

This guide is for developers who cloned the project from GitHub and need to run the Python Flask backend.

---

## Prerequisites

- **Python 3.10+** installed
- **pip** (Python package manager)
- **Git** (already used to clone)

---

## Step-by-Step Setup

### Step 1: Navigate to Backend Directory

```bash
cd foodlink_backend
```

**Windows:**
```powershell
cd D:\Flutter\Foodlink\foodlink_backend
```

---

### Step 2: Create Virtual Environment (Recommended)

**Windows:**
```powershell
# Create virtual environment
python -m venv venv

# Activate virtual environment
venv\Scripts\activate

# You should see (venv) in your prompt
(venv) PS D:\Flutter\Foodlink\foodlink_backend>
```

**macOS/Linux:**
```bash
# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate

# You should see (venv) in your prompt
(venv) $ 
```

---

### Step 3: Install Dependencies

```bash
pip install -r requirements.txt
```

This installs:
- `flask` - Web framework
- `flask-cors` - Cross-origin resource sharing
- `pandas` - Data manipulation
- `numpy` - Numerical operations
- `scikit-learn` - Machine learning
- `geopy` - Geographical calculations
- `pymcdm` - Multi-criteria decision making
- `joblib` - Model serialization
- `matplotlib` - Plotting for reports
- `fairpyx` - Fairness algorithms

**Expected output:**
```
Collecting flask
  Downloading Flask-3.0.3-py3-none-any.whl (101 kB)
...
Successfully installed flask-3.0.3 flask-cors-5.0.0 ...
```

---

### Step 4: Verify Project Structure

Your `foodlink_backend` folder should look like this:

```
foodlink_backend/
├── app.py                  # Main Flask application
├── requirements.txt        # Python dependencies
├── src/
│   ├── ima_engine.py      # Core IMA algorithm
│   ├── mcdm_allocator.py  # MCDM scoring
│   ├── baselines.py       # Baseline algorithms
│   ├── evaluate.py        # Evaluation metrics
│   ├── generator.py       # Synthetic data generator
│   ├── train_model.py     # ML model training
│   └── spoilage_model.pkl # Pre-trained model
└── venv/                  # Virtual environment (created in Step 2)
```

---

### Step 5: Run the Backend

```bash
python app.py
```

**Expected output:**
```
 * Serving Flask app 'app'
 * Debug mode: on
 * Running on http://127.0.0.1:5000

Press CTRL+C to quit
```

---

### Step 6: Verify Backend is Running

Open browser or use curl to test:

```bash
# Health check
curl http://localhost:5000/health
```

**Expected response:**
```json
{
  "status": "healthy",
  "version": "1.0.0"
}
```

Or test in browser:
- Go to: `http://localhost:5000/health`

---

## Available API Endpoints

Once running, these endpoints are available:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Health check |
| `/ima` | POST | Single donation match |
| `/ima/batch` | POST | Batch matching for multiple donations |
| `/evaluate` | POST | Run evaluation metrics |
| `/train` | POST | Train ML model |
| `/report` | GET | Generate evaluation report |

### Test Example: Single Match

```bash
curl -X POST http://localhost:5000/ima \
  -H "Content-Type: application/json" \
  -d '{
    "donation": {
      "id": "D001",
      "lat": 6.8500,
      "lon": 79.8600,
      "food_type": "Rice & Curry",
      "quantity_kg": 10,
      "expiry_hours": 4
    },
    "charities": [
      {
        "id": "C001",
        "name": "Hope Shelter",
        "lat": 6.9319,
        "lon": 79.8478,
        "received_today": 2,
        "has_cold_storage": true,
        "capacity_remaining": 50
      }
    ]
  }'
```

---

## Configuration (Optional)

### Change Port

Edit `app.py` line:
```python
app.run(debug=True, port=5000)  # Change to your port
```

### Enable Debug Mode

Debug mode is enabled by default. To disable:
```python
app.run(debug=False, port=5000)
```

---

## Troubleshooting

### Issue: "ModuleNotFoundError: No module named 'flask'"

**Solution:** Virtual environment not activated or dependencies not installed.

```bash
# Make sure venv is activated
venv\Scripts\activate  # Windows
source venv/bin/activate  # macOS/Linux

# Reinstall dependencies
pip install -r requirements.txt
```

### Issue: "Port 5000 already in use"

**Solution:** Change the port in `app.py`:
```python
app.run(debug=True, port=5001)  # Use different port
```

Or kill the existing process:

**Windows:**
```powershell
# Find process using port 5000
netstat -ano | findstr :5000

# Kill the process (replace PID)
taskkill /PID <PID> /F
```

### Issue: "ImportError: cannot import name 'geodesic'"

**Solution:** Update geopy:
```bash
pip install --upgrade geopy
```

### Issue: CORS errors from Flutter app

**Solution:** CORS is already enabled in `app.py`. If issues persist:
```python
from flask_cors import CORS
CORS(app, resources={r"/*": {"origins": "*"}})  # Allow all origins
```

---

## Connect Flutter App to Backend

### 1. Find your computer's IP address

**Windows:**
```powershell
ipconfig
```
Look for `IPv4 Address` under your active network adapter (e.g., `192.168.1.100`)

**macOS/Linux:**
```bash
ifconfig
```

### 2. Update Flutter API Service

Edit `food_app/lib/services/ima_api_service.dart`:

```dart
// For Android emulator
static const String baseUrl = 'http://10.0.2.2:5000';

// For physical device (use your computer's IP)
static const String baseUrl = 'http://192.168.1.100:5000';

// For web
static const String baseUrl = 'http://localhost:5000';
```

### 3. Run Flutter App

```bash
cd food_app
flutter run
```

---

## Production Deployment (Optional)

### Using Gunicorn (Linux/Mac)

```bash
pip install gunicorn
gunicorn -w 4 -b 0.0.0.0:5000 app:app
```

### Using Waitress (Windows)

```bash
pip install waitress
waitress-serve --port=5000 app:app
```

---

## Quick Reference Commands

```bash
# Navigate to backend
cd foodlink_backend

# Activate virtual environment (Windows)
venv\Scripts\activate

# Activate virtual environment (macOS/Linux)
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run backend
python app.py

# Test health endpoint
curl http://localhost:5000/health

# Stop backend
Ctrl+C

# Deactivate virtual environment
deactivate
```

---

## Need Help?

If you encounter issues:
1. Check Python version: `python --version` (should be 3.10+)
2. Verify virtual environment is activated (see `(venv)` in prompt)
3. Reinstall dependencies: `pip install -r requirements.txt --force-reinstall`
4. Check firewall isn't blocking port 5000

---

*Last Updated: April 2026*
