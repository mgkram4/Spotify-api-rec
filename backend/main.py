import os

import numpy as np
from dotenv import load_dotenv
from flask import Flask, jsonify, request
from flask_cors import CORS
from sklearn import svm

app = Flask(__name__)
CORS(app)
load_dotenv()

# Model data
moodKey = ["Happy", "Sad", "Angry", "Excited", "Scary", "Violent", "Silly"]
settingKey = ["Car", "Home", "Party", "Vacation", "Walk", "Run", "Workout"]

song_data = [
    [8, 3, 4, 1, 2000, 1],
    [8, 2, 2, 1, 2010, 6],
    [7, 0, 5, 0, 1930, 0],
    [6, 0, 3, 0, 2015, 2],
    [5, 0, 1, 0, 2018, 2],
    [2, 1, 10, 0, 1800, 0],
    [9, 3, 4, 1, 1990, 1]
]

song_title = {
    1: "Rap",
    2: "Trap",
    3: "Jazz",
    4: "Pop",
    5: "EDM",
    6: "Classical",
    7: "Rock"
}

attribute_names = ["Tempo", "Mood", "Length", "Explicit", "Age", "Setting"]

# Initialize and train model
model = svm.SVC()
model.fit(song_data, list(song_title.keys()))

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({"status": "healthy", "message": "Service is running"}), 200

@app.route('/api/recommend', methods=['POST'])
def get_recommendation():
    try:
        data = request.get_json()
        
        # Validate input data
        required_fields = ["tempo", "mood", "length", "explicit", "age", "setting"]
        for field in required_fields:
            if field not in data:
                return jsonify({
                    "error": f"Missing required field: {field}"
                }), 400
        
        # Create input array for model
        inputs = [
            int(data["tempo"]),
            int(data["mood"]),
            int(data["length"]),
            int(data["explicit"]),
            int(data["age"]),
            int(data["setting"])
        ]
        
        # Get prediction
        suggested_genre_id = model.predict([inputs])[0]
        suggested_genre = song_title[suggested_genre_id]
        
        # Return recommendation
        return jsonify({
            "success": True,
            "recommendation": {
                "genre": suggested_genre,
                "genre_id": int(suggested_genre_id),
                "inputs": {
                    "tempo": inputs[0],
                    "mood": inputs[1],
                    "length": inputs[2],
                    "explicit": inputs[3],
                    "age": inputs[4],
                    "setting": inputs[5]
                }
            }
        }), 200
        
    except ValueError as e:
        return jsonify({
            "error": "Invalid input values. All fields must be numeric.",
            "details": str(e)
        }), 400
    except Exception as e:
        return jsonify({
            "error": "An error occurred while processing your request.",
            "details": str(e)
        }), 500

@app.route('/api/options', methods=['GET'])
def get_options():
    """Return the available options for mood and setting"""
    return jsonify({
        "moods": moodKey,
        "settings": settingKey,
        "attributes": {
            "tempo": {
                "min": 1,
                "max": 10,
                "description": "Rate the tempo from 1 (very slow) to 10 (very fast)"
            },
            "mood": {
                "options": moodKey,
                "description": "Select your current mood"
            },
            "length": {
                "min": 1,
                "max": 10,
                "description": "Preferred song length from 1 (short) to 10 (long)"
            },
            "explicit": {
                "options": [0, 1],
                "description": "Allow explicit content (0 for no, 1 for yes)"
            },
            "age": {
                "min": 1800,
                "max": 2024,
                "description": "Preferred music era (year)"
            },
            "setting": {
                "options": settingKey,
                "description": "Where will you be listening?"
            }
        }
    }), 200

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(host='0.0.0.0', port=port, debug=True)