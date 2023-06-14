import pandas as pd
import numpy as np
from top2vec import Top2Vec


## set path
import os
os.chdir("C://Users/nicol/Dropbox/PhD/Papers/FrameCompetition")

## read model
model = Top2Vec.load("models/t2v/migration_mindocs300")

## write document vectors
pd.DataFrame(model.document_vectors).to_csv("data/processed/embeddings/documents.csv", index=False)