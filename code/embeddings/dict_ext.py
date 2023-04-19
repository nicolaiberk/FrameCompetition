#%% embedding extension for dictionaries

import os
import pandas as pd
import numpy as np
import gensim

# load model
model = gensim.models.Word2Vec.load("data/raw/embeddings/np_embs/np_emb")

#%%

## return most similar terms for each term
for d in os.listdir("data/raw/dicts"):
    print("Processing", d, "...")
    dict = pd.read_csv(f'data/raw/dicts/{d}', sep=', ')
    sim_terms = pd.DataFrame(columns=['term', 'sim_term', 'sim_score'])
    for w in dict:
        if w not in model.wv.index_to_key:
            continue
        for we in model.wv.most_similar(w):
            if we[1] > 0.8:
                sim_terms = pd.concat([sim_terms, pd.DataFrame.from_dict({'term': [w], 'sim_term': [we[0]], 'sim_score': [we[1]]})], ignore_index=True)
    dict = [t for t in dict]
    dict.extend(sim_terms.sim_term.unique())
    with open("data/processed/dicts/ext_" + d, "w", encoding = "UTF-8") as f:
        for s in set(dict):
            f.write(s + ", ")