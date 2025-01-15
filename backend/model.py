from sklearn import svm


class MusicRecommender:
    def __init__(self):
        self.mood_key = ["Happy", "Sad", "Angry", "Excited", "Scary", "Violent", "Silly"]
        self.setting_key = ["Car", "Home", "Party", "Vacation", "Walk", "Run", "Workout"]
        
        self.song_data = [
            [8, 3, 4, 1, 2000, 1],
            [8, 2, 2, 1, 2010, 6],
            [7, 0, 5, 0, 1930, 0],
            [6, 0, 3, 0, 2015, 2],
            [5, 0, 1, 0, 2018, 2],
            [2, 1, 10, 0, 1800, 0],
            [9, 3, 4, 1, 1990, 1]
        ]

        self.song_title = {
            1: "Rap",
            2: "Trap",
            3: "Jazz",
            4: "Pop",
            5: "EDM",
            6: "Classical",
            7: "Rock"
        }

        self.attribute_names = ["Tempo", "Mood", "Length", "Explicit", "Age", "Setting"]
        self.model = self._train_model()

    def _train_model(self):
        model = svm.SVC()
        model.fit(self.song_data, list(self.song_title.keys()))
        return model

    def predict(self, inputs):
        genre_id = self.model.predict([inputs])[0]
        return {
            "genre": self.song_title[genre_id],
            "genre_id": int(genre_id)
        }

    def get_options(self):
        return {
            "moods": self.mood_key,
            "settings": self.setting_key,
            "attributes": {
                "tempo": {
                    "min": 1,
                    "max": 10,
                    "description": "Rate the tempo from 1 (very slow) to 10 (very fast)"
                },
                "mood": {
                    "options": self.mood_key,
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
                    "options": self.setting_key,
                    "description": "Where will you be listening?"
                }
            }
        }