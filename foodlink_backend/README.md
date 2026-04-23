# FoodLink Backend - Intelligent Matching Engine

## Setup
1. Activate venv: `venv\Scripts\activate`
2. Install: `pip install -r requirements.txt`
3. Run generator: `python -c "from src.generator import generate_synthetic_data; generate_synthetic_data()"`
4. Train model: `python -c "from src.train_model import train_spoilage_model; train_spoilage_model()"`
5. Run evaluation: `python -c "from src.evaluate import evaluate_all_methods; evaluate_all_methods()"`

This backend implements Adaptive MCDM + ML spoilage prediction as per the project proposal.