#%%
import pandas as pd
import numpy as np
import seaborn as sns
from top2vec import Top2Vec
from pprint import pprint
import random
random.seed(42)

## load manifestos
migmps = pd.read_csv("data/raw/manifestos/manifestos1317_mig.csv")

#%% generate embeddings
## load top2vec model
model = Top2Vec.load("models/t2v/migration_mindocs300")

## add party documents to generate embeddings
model.add_documents(migmps["text"].tolist())

#%% save new vectors
nrows = model.document_vectors.shape[0]
party_vecs = model.document_vectors[nrows-len(migmps.text):nrows]

## merge with meta data
party_vecs = pd.DataFrame(party_vecs)
party_vecs = pd.concat([migmps, party_vecs], axis=1)

## save party vectors (sentence embeddings)
party_vecs.to_csv("data/processed/embeddings/parties_sentences.csv", index=False)

#%% average party vectors
vars = [i for i in range(300)]
vars.append("party")
party_vecs = party_vecs[vars].groupby("party").mean().reset_index()

## save party vectors (average of sentence embeddings)
party_vecs.to_csv("data/processed/embeddings/parties.csv", index=False)

#%% estimate similarity to doc vecs

## load doc vecs
doc_vecs = pd.read_csv("data/processed/embeddings/documents.csv")

## estimate cosin sim to reduced topics
from scipy.spatial import distance
cos_sim = 1 - distance.cdist(doc_vecs, party_vecs.drop("party", axis = 1), 'cosine')

#%%
## merge with meta data
cos_sim = pd.DataFrame(cos_sim)
cos_sim.columns = party_vecs["party"].tolist()

## load meta data
meta = pd.read_csv("data/processed/media/docs_topics_sims.csv")
meta = meta[['paper', 'title', 'url', 'crime', 'crime_label', 'crime_prob',
                'label_prob', 'dpa', 'date_clean', 'topic_id', 'reduced_topic_id',
                'topic_label', 'reduced_topic_label']]
## merge
meta = pd.concat([meta, cos_sim], axis=1)

## save
meta.to_csv("data/processed/media/docs_party_sims.csv", index=False)

#%% visualise party similarity across time
meta[['date_clean', '90/Greens', 'AfD', 
     'CDU/CSU', 'FDP', 'LINKE', 'SPD']
     ].groupby(pd.PeriodIndex(meta['date_clean'], freq="M")).mean().plot()


#%% visualise party and topic vecs in 2D

## load reduced topic vectors
top_vecs = pd.read_csv("data/processed/embeddings/reduced_topics.csv")

## label topics
import json
f = open('data/processed/reduced_topic_labels.json', 'r')
top_vecs['label'] = json.load(f).keys()
f.close()


## string var names
party_vecs['label'] = party_vecs['party']
party_vecs.columns = [str(i) for i in party_vecs.columns]

## merge party and topic vecs
vecs = pd.concat([party_vecs.drop('party', axis = 1), top_vecs], 
                 axis=0, ignore_index=True
                 ).reset_index(drop=True)

## dimensionality reduction
from sklearn.decomposition import PCA
pca = PCA(n_components=2).fit(vecs.drop('label', axis = 1))
vec_red = pca.transform(vecs.drop('label', axis = 1))
vec_red = pd.DataFrame(vec_red, columns = ['C1', 'C2'])
vec_red['label'] = vecs['label']
vec_red['party'] = np.concatenate([np.repeat(True, 6), np.repeat(False, vec_red.shape[0]-6)])

## plot
import matplotlib.pyplot as plt
plt.figure(figsize=(8,5))
sns.scatterplot(x="C1", y="C2", data=vec_red, hue = 'party', style = 'party')
for line in range(0,vec_red.shape[0]):
    plt.text(vec_red.C1[line], 
            vec_red.C2[line], 
            vec_red.label[line])
plt.show()


# %%

polls = pd.read_csv("data/raw/polls/polls.csv")

## aggregate monthly polls
polls = polls.pivot(columns='party', values='value',
     ).groupby(pd.PeriodIndex(polls['date'], freq="M")
     ).mean().reset_index()

## aggregate monthl similarity
meta = meta[['date_clean', '90/Greens', 'AfD', 
             'CDU/CSU', 'FDP', 'LINKE', 'SPD']
             ].groupby(pd.PeriodIndex(meta['date_clean'], 
                                      freq="M")).mean().reset_index()


## determine equal size
polls = polls[polls['date'] <= meta['date_clean'].max()]
polls = polls[polls['date'] >= meta['date_clean'].min()]


## correlation

# AfD
merged = pd.merge(polls, meta, left_on='date', right_on='date_clean')
print(merged[['AfD_x',   'AfD_y'  ]].corr()) # weakly negative
print(merged[['FDP_x',   'FDP_y'  ]].corr()) # weakly negative
print(merged[['SPD_x',   'SPD_y'  ]].corr()) # weakly positive
print(merged[['Union',   'CDU/CSU']].corr()) # zero
print(merged[['LINKE_x', 'LINKE_y']].corr()) # moderate negative
print(merged[['GRUENE', '90/Greens']].corr()) # very weak negative

## dis is not de way

# %%
