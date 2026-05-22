# analysis_server.py
from flask import Flask, jsonify
import pandas as pd
import numpy as np
from datetime import datetime
import json

app = Flask(__name__)

# Sample data processing function
def process_sales_data(data):
    df = pd.DataFrame(data)

    # Basic statistics
    stats = {
        'total_sales': float(df['transaction_amount'].sum()),
        'average_sale': float(df['transaction_amount'].mean()),
        'total_transactions': len(df),
        'transaction_types': df['transaction_type'].value_counts().to_dict()
    }

    # Time-based analysis
    df['created_at'] = pd.to_datetime(df['created_at'])
    time_analysis = df.groupby(df['created_at'].dt.hour)['transaction_amount'].sum().to_dict()

    return {
        'stats': stats,
        'time_analysis': {str(k): float(v) for k, v in time_analysis.items()}
    }

@app.route('/analyze', methods=['POST'])
def analyze():
    try:
        data = request.get_json()
        results = process_sales_data(data)
        return jsonify(results)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)