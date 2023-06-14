## estimate topic model

import pandas as pd
import numpy as np
from top2vec import Top2Vec
import random
random.seed(42)

## define parameters
umap_args = {'n_neighbors': 30, # when replicating, consider setting this to 15 (check umap website), as currently no outliers are removed
             'n_components': 5,
             'metric': 'cosine',
             "random_state": 42}

hdbscan_args = {'min_cluster_size': 300,
                'min_samples':5,
                'metric': 'euclidean',
                'cluster_selection_method': 'eom'}

## load data
documents = pd.read_csv("data/raw/media/bert_crime_clean.csv", encoding="utf-8")["text"].to_list()

## define model
model = Top2Vec(documents= documents, 
                # speed='deep-learn', 
                workers=7, 
                min_count = 100, 
                # embedding_model='distiluse-base-multilingual-cased', 
                umap_args = umap_args, 
                hdbscan_args = hdbscan_args)

model.save("models/t2v/migration_mindocs300")