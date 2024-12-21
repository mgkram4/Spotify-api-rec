import random

import numpy as np
from sklearn import svm

moodKey = ["Happy", "Sad", "Angry", "Excited", "Scary", "Violant", "Silly", ]
settingKey = ["Car", "Home", "Party", "Vacation", "Walk", "Run", "Workout"]

song_data = [
    [8, 3, 4, 1, 2000, 1 ],
    [8, 2, 2, 1 , 2010, 6],
    [7, 0, 5, 0, 1930, 0 ],
    [6, 0, 3, 0, 2015, 2],
    [5, 0, 1, 0, 2018, 2],
    [2, 1, 10, 0, 1800, 0 ],
    [9, 3, 4, 1, 1990, 1]
]

song_title = {
    1 :  "Rap",
    2: "Trap",
    3: "Jazz",
    4: "Pop",
    5: "EDM",
    6: "Classical",
    7: "Rock"
}
attribute_names = ["Tempo", "Mood", "Length","Explict" , "Age", "Setting"]

model = svm.SVC()
model.fit(song_data, list(song_title.keys()))

def ratingLop(model):
    inputs = [
        int(input(f" what is your rating for tempo")),
        int(input(f" what is your rating for Mood")),
        int(input(f" what is your rating for Length")),
        int(input(f" what is your rating for Explict")),
        int(input(f" what is your rating for Age")),
        int(input(f" what is your rating for Setting"))
    ]
    
    suggested_songs = model.predict([inputs])[0]
    return print(f" your fav genre is {song_title[suggested_songs]}")

ratingLop(model)