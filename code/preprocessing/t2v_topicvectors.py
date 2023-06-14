## generate topic vectors
import pandas as pd
import numpy as np
from top2vec import Top2Vec
import json

## set path
import os
os.chdir("C://Users/nicol/Dropbox/PhD/Papers/FrameCompetition")

## load t2v model
model = Top2Vec.load("models/t2v/migration_mindocs300")

## load topic ids from json
with open('data/processed/reduced_topic_ids.json', 'r') as f:
    reduced_ids = json.load(f)


## generate reduced topic vectors
rt_vectors = pd.DataFrame()
for rt in reduced_ids.keys():
    ots = reduced_ids[rt] # get original topic ids
    ot_vectors = model.topic_vectors[ots] # get original topic vectors
    rt_vector = np.mean(ot_vectors, axis=0) # calculate reduced topic vector
    rt_vectors = pd.concat([rt_vectors, pd.DataFrame(rt_vector).T], axis=0) # add to dataframe

rt_vectors.to_csv("data/processed/embeddings/reduced_topics.csv", index=False)