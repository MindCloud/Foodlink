# app.py
import utils.clients
import utils.http_session
import utils.transport
import utils.session
from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
from src.ima_engine import adaptive_ima
from src.generator import generate_synthetic_data
from src.evaluate import evaluate_all_methods
from src.train_model import train_spoilage_model
import matplotlib.pyplot as plt
import pandas as pd
import io
import base64

app = Flask(__name__)
CORS(app)  # Enable CORS for Flutter

@app.route('/ima', methods=['POST'])
def get_match():
    """Get IMA match for a single donation"""
    data = request.json
    result = adaptive_ima(data['donation'], data['charities'])
    return jsonify(result)

@app.route('/ima/batch', methods=['POST'])
def batch_match():
    """Get IMA matches for multiple donations"""
    data = request.json
    results = []
    for donation in data['donations']:
        match = adaptive_ima(donation, data['charities'])
        results.append({
            "donation_id": donation.get('id'),
            "match": match
        })
    return jsonify(results)

@app.route('/evaluate', methods=['GET'])
def evaluate():
    """Run evaluation and return metrics"""
    results = evaluate_all_methods()
    return jsonify(results)

@app.route('/train', methods=['POST'])
def train():
    """Train the spoilage prediction model"""
    model = train_spoilage_model()
    return jsonify({"status": "success", "message": "Model trained successfully"})

@app.route('/report', methods=['GET'])
def generate_report():
    """Generate evaluation report with graphs"""
    # Generate synthetic data for report
    donations, charities = generate_synthetic_data(300, 12)
    
    # Run evaluation
    results = evaluate_all_methods()
    
    # Create visualization
    fig, axes = plt.subplots(2, 2, figsize=(12, 10))
    
    # Plot 1: Distance distribution
    distances = [d['distance_km'] if 'distance_km' in d else 0 for d in results.get('adaptive', [])]
    axes[0, 0].hist(distances, bins=20, color='skyblue', edgecolor='black')
    axes[0, 0].set_title('Distance Distribution (Adaptive IMA)')
    axes[0, 0].set_xlabel('Distance (km)')
    axes[0, 0].set_ylabel('Frequency')
    
    # Plot 2: Spoilage risk distribution
    risks = [d['spoilage_risk'] if 'spoilage_risk' in d else 0 for d in results.get('adaptive', [])]
    axes[0, 1].hist(risks, bins=20, color='lightcoral', edgecolor='black')
    axes[0, 1].set_title('Spoilage Risk Distribution')
    axes[0, 1].set_xlabel('Risk Score')
    axes[0, 1].set_ylabel('Frequency')
    
    # Plot 3: Score comparison
    adaptive_scores = [d['final_score'] if 'final_score' in d else 0 for d in results.get('adaptive', [])]
    axes[1, 0].plot(adaptive_scores, marker='o', linestyle='-', color='green')
    axes[1, 0].set_title('Adaptive IMA Scores')
    axes[1, 0].set_xlabel('Donation Index')
    axes[1, 0].set_ylabel('Score')
    axes[1, 0].grid(True)
    
    # Plot 4: Method comparison bar chart
    methods = ['Nearest', 'Fairness', 'Adaptive']
    counts = [len(results.get('nearest', [])), len(results.get('fairness', [])), len(results.get('adaptive', []))]
    axes[1, 1].bar(methods, counts, color=['blue', 'orange', 'green'])
    axes[1, 1].set_title('Successful Matches by Method')
    axes[1, 1].set_ylabel('Count')
    
    plt.tight_layout()
    
    # Save to buffer
    img_buffer = io.BytesIO()
    plt.savefig(img_buffer, format='png', dpi=150)
    img_buffer.seek(0)
    img_base64 = base64.b64encode(img_buffer.getvalue()).decode()
    plt.close()
    
    # Generate summary table
    summary = {
        "total_donations": len(donations),
        "total_charities": len(charities),
        "adaptive_matches": len(results.get('adaptive', [])),
        "nearest_matches": len(results.get('nearest', [])),
        "fairness_matches": len(results.get('fairness', [])),
        "avg_distance": sum(distances) / len(distances) if distances else 0,
        "avg_spoilage_risk": sum(risks) / len(risks) if risks else 0,
        "graph": img_base64
    }
    
    return jsonify(summary)

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({"status": "healthy", "service": "FoodLink IMA Backend"})

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)