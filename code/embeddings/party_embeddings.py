#%%
import pandas as pd
import numpy as np
import seaborn as sns
from top2vec import Top2Vec
from pprint import pprint
import random
random.seed(42)

## load manifestos
migmps = pd.read_csv("../../data/raw/manifestos/manifestos1317_mig.csv")

#%% generate embeddings
## load top2vec model
model = Top2Vec.load("../../models/t2v/migration_mindocs300")

## add party documents to generate embeddings
model.add_documents(migmps["text"].tolist())

#%% save new vectors
nrows = model.document_vectors.shape[0]
party_vecs = model.document_vectors[nrows-len(migmps.text):nrows]

## merge with meta data
party_vecs = pd.DataFrame(party_vecs)
party_vecs = pd.concat([migmps, party_vecs], axis=1)

## save party vectors (sentence embeddings)
party_vecs.to_csv("../../data/processed/embeddings/parties_sentences.csv", index=False)

#%% average party vectors
vars = [i for i in range(300)]
vars.append("party")
party_vecs = party_vecs[vars].groupby("party").mean().reset_index()

## save party vectors (average of sentence embeddings)
party_vecs.to_csv("../../data/processed/embeddings/parties.csv", index=False)

#%% estimate similarity to doc vecs

## load doc vecs
doc_vecs = pd.read_csv("../../data/processed/embeddings/documents.csv")

## estimate cosin sim to reduced topics
from scipy.spatial import distance
cos_sim = 1 - distance.cdist(doc_vecs, party_vecs.drop("party", axis = 1), 'cosine')

#%%
## merge with meta data
cos_sim = pd.DataFrame(cos_sim)
cos_sim.columns = party_vecs["party"].tolist()

## load meta data
meta = pd.read_csv("../../data/processed/media/docs_topics_sims.csv")
meta = meta[['paper', 'title', 'url', 'crime', 'crime_label', 'crime_prob',
                'label_prob', 'dpa', 'date_clean', 'topic_id', 'reduced_topic_id',
                'topic_label', 'reduced_topic_label']]
## merge
meta = pd.concat([meta, cos_sim], axis=1)

## save
meta.to_csv("../../data/processed/media/docs_party_sims.csv", index=False)

#%% visualise party similarity across time
meta[['date_clean', '90/Greens', 'AfD', 
     'CDU/CSU', 'FDP', 'LINKE', 'SPD']
     ].groupby(pd.PeriodIndex(meta['date_clean'], freq="M")).mean().plot()


#%% visualise party and topic vecs in 2D

## load reduced topic vectors
top_vecs = pd.read_csv("../../data/processed/embeddings/reduced_topics.csv")

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

polls = pd.read_csv("../../data/raw/polls/polls.csv")

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

## plot topics vs party document sample

## load party vectors
party_vecs = pd.read_csv("../../data/processed/embeddings/parties_sentences.csv"
                         ).sample(100).drop(['date', 'code', 'text'], axis = 1)

## load topic vectors
top_vecs = pd.read_csv("../../data/processed/embeddings/reduced_topics.csv")
top_vecs["party"] = ""

# %%

## merge party and topic vecs
vecs = pd.concat([party_vecs, top_vecs], axis = 0, ignore_index = True)

## reduce dimensionality
vec_red = PCA(n_components=2).fit_transform(vecs.drop('party', axis = 1))
vec_red = pd.DataFrame(vec_red, columns = ['C1', 'C2'])
vec_red = pd.concat([vec_red, vecs['party']], axis = 1)

plt.figure(figsize=(8,5))
sns.scatterplot(x="C1", y="C2", data=vec_red, hue = 'party', style = 'party')
for line in range(0,vec_red.shape[0]):
    plt.text(vec_red.C1[line], 
            vec_red.C2[line], 
            vec_red.party[line])
plt.show()


# %%

## estimate party embedings from entire manifesto content on immigration (should be fine, limit is 10k tokens: https://github.com/RaRe-Technologies/gensim/issues/2880)

## load manifestos
migmps = pd.read_csv("../../data/raw/manifestos/manifestos1317_mig.csv")

## concatenate manifesto texts
migmps_con = migmps.drop(['date', 'code'], axis = 1).groupby('party').agg(lambda x: ' '.join(x))

## learn embeddings
### load top2vec model
model = Top2Vec.load("models/t2v/migration_mindocs300")

### add party documents to generate embeddings
model.add_documents(migmps["text"].tolist())
nrows = model.document_vectors.shape[0]
party_vecs = pd.DataFrame(model.document_vectors[nrows-len(migmps_con.text):nrows])
party_vecs.columns = [str(l) for l in party_vecs.columns]
party_vecs['party'] = migmps_con.index


#%%

## plot vectors in 2D

## merge party and topic vecs
top_vecs['party'] = " "
vecs = pd.concat([party_vecs, top_vecs], axis = 0, ignore_index = True)

## reduce dimensionality
vec_red = PCA(n_components=2).fit_transform(vecs.drop('party', axis = 1))
vec_red = pd.DataFrame(vec_red, columns = ['C1', 'C2'])
vec_red = pd.concat([vec_red, vecs['party']], axis = 1)

plt.figure(figsize=(8,5))
sns.scatterplot(x="C1", y="C2", data=vec_red, hue = 'party', style = 'party')
for line in range(0,vec_red.shape[0]):
    plt.text(vec_red.C1[line], 
            vec_red.C2[line], 
            vec_red.party[line])
plt.show()

# still odd similarity of afd position, but probably better

#%% 

## plot doc similarity over time


## load doc vecs
doc_vecs = pd.read_csv("../../data/processed/embeddings/documents.csv")

## estimate cosin sim to reduced topics
from scipy.spatial import distance
cos_sim = 1 - distance.cdist(doc_vecs, party_vecs.drop("party", axis = 1), 'cosine')

## merge with meta data
cos_sim = pd.DataFrame(cos_sim)
cos_sim.columns = party_vecs["party"].tolist()

## load meta data
meta = pd.read_csv("../../data/processed/media/docs_topics_sims.csv")
meta = meta[['paper', 'title', 'url', 'crime', 'crime_label', 'crime_prob',
                'label_prob', 'dpa', 'date_clean', 'topic_id', 'reduced_topic_id',
                'topic_label', 'reduced_topic_label']]
## merge
meta = pd.concat([meta, cos_sim], axis=1)

#%% visualise party similarity across time
meta[['date_clean', '90/Greens', 'AfD', 
     'CDU/CSU', 'FDP', 'LINKE', 'SPD']
     ].groupby(pd.PeriodIndex(meta['date_clean'], freq="")).mean().plot()

# seasonaltiy certainly gone

#%% correlate with polls

polls = pd.read_csv("../../data/raw/polls/polls.csv")

## aggregate monthly polls
polls = polls.pivot(columns='party', values='value',
     ).groupby(pd.PeriodIndex(polls['date'], freq="Q")
     ).mean().reset_index()

## aggregate monthl similarity
meta = meta[['date_clean', '90/Greens', 'AfD', 
             'CDU/CSU', 'FDP', 'LINKE', 'SPD']
             ].groupby(pd.PeriodIndex(meta['date_clean'], 
                                      freq="Q")).mean().reset_index()


## determine equal size
polls = polls[polls['date'] <= meta['date_clean'].max()]
polls = polls[polls['date'] >= meta['date_clean'].min()]

#%%

## correlation

# AfD
merged = pd.merge(polls, meta, left_on='date', right_on='date_clean')
merged['date'] = merged.date.dt.to_timestamp()
print(merged[['AfD_x',   'AfD_y'  ]].corr()) # moderately negative
print(merged[['FDP_x',   'FDP_y'  ]].corr()) # zero
print(merged[['SPD_x',   'SPD_y'  ]].corr()) # positive
print(merged[['Union',   'CDU/CSU']].corr()) # strongly positive
print(merged[['LINKE_x', 'LINKE_y']].corr()) # moderately positive
print(merged[['GRUENE', '90/Greens']].corr()) # moderately negative

#%%

sns.lineplot(data = merged, x = 'date', y = 'AfD_x', color = 'r')
ax2 = plt.twinx()
sns.lineplot(data = merged, x = 'date', y = 'AfD_y', ax = ax2)
plt.show()

# 2018 bump might be 

#%%

sns.lineplot(data = merged, x = 'date', y = 'Union', color = 'r')
ax2 = plt.twinx()
sns.lineplot(data = merged, x = 'date', y = 'CDU/CSU', ax = ax2) 
plt.show()
# correlated

#%%

sns.lineplot(data = merged, x = 'date', y = 'SPD_x', color = 'r')
ax2 = plt.twinx()
sns.lineplot(data = merged, x = 'date', y = 'SPD_y', ax = ax2) 
plt.show()
# also correlated

#%% 

sns.lineplot(data = merged, x = 'date', y = 'GRUENE', color = 'r')
ax2 = plt.twinx()
sns.lineplot(data = merged, x = 'date', y = '90/Greens', ax = ax2) 
plt.show()

#%% 

sns.lineplot(data = merged, x = 'date', y = 'FDP_x', color = 'r')
ax2 = plt.twinx()
sns.lineplot(data = merged, x = 'date', y = 'FDP_y', ax = ax2) 
plt.show()

#%% 

sns.lineplot(data = merged, x = 'date', y = 'LINKE_x', color = 'r')
ax2 = plt.twinx()
sns.lineplot(data = merged, x = 'date', y = 'LINKE_y', ax = ax2) 
plt.show()
# strikingly similar

#%% generate cmp code embeddings

## load manifestos
migmps = pd.read_csv("../../data/raw/manifestos/manifestos1317_mig.csv")

## concatenate manifesto texts
migmps_con = migmps.drop(['date', 'party'], axis = 1).groupby('code').agg(lambda x: ' '.join(x))

## learn embeddings
### load top2vec model
model = Top2Vec.load("models/t2v/migration_mindocs300")

### add party documents to generate embeddings
model.add_documents(migmps["text"].tolist())
nrows = model.document_vectors.shape[0]
code_vecs = pd.DataFrame(model.document_vectors[nrows-len(migmps_con.text):nrows])
code_vecs.columns = [str(l) for l in code_vecs.columns]
code_vecs['code'] = migmps_con.index

#%%


## plot vectors in 2D

## merge party and topic vecs
# top_vecs = top_vecs.drop('party', axis = 1)
top_vecs['code'] = " "
vecs = pd.concat([code_vecs, top_vecs], axis = 0, ignore_index = True)

## reduce dimensionality
vec_red = PCA(n_components=2).fit_transform(vecs.drop('code', axis = 1))
vec_red = pd.DataFrame(vec_red, columns = ['C1', 'C2'])
vec_red = pd.concat([vec_red, vecs['code']], axis = 1)

plt.figure(figsize=(8,5))
sns.scatterplot(x="C1", y="C2", data=vec_red, hue = 'code', style = 'code')
for line in range(0,vec_red.shape[0]):
    plt.text(vec_red.C1[line], 
            vec_red.C2[line], 
            vec_red.code[line])
plt.show()

#%% 

## cos similarity

## load doc vecs
doc_vecs = pd.read_csv("../../data/processed/embeddings/documents.csv")

## estimate cosin sim to reduced topics
from scipy.spatial import distance
cos_sim = 1 - distance.cdist(doc_vecs, code_vecs.drop("code", axis = 1), 'cosine')

## merge with meta data
cos_sim = pd.DataFrame(cos_sim)
cos_sim.columns = [str(c) for c in code_vecs["code"].tolist()]

## load meta data
meta = pd.read_csv("../../data/processed/media/docs_topics_sims.csv")
meta = meta[['paper', 'title', 'url', 'crime', 'crime_label', 'crime_prob',
                'label_prob', 'dpa', 'date_clean', 'topic_id', 'reduced_topic_id',
                'topic_label', 'reduced_topic_label']]
## merge
meta = pd.concat([meta, cos_sim], axis=1)



#%%

## crime vs crime_prob vs cos_sims

#%% visualise party similarity across time
meta_agg = meta[['date_clean', 'paper', 'crime_label', 'crime_prob', '601.2', '602.2']
     ].groupby(['date_clean', 'paper']).mean()

meta_agg['date'] = pd.to_datetime(meta.index.get_level_values(0))


#%% 
## scale documents on pro-con axis

## define difference between pro and con

diff_mig = code_vecs.drop('code', axis = 1)[code_vecs.code == 602.2].to_numpy() - code_vecs.drop('code', axis = 1)[code_vecs.code == 601.2].to_numpy()
diff_int = code_vecs.drop('code', axis = 1)[code_vecs.code == 607.2].to_numpy() - code_vecs.drop('code', axis = 1)[code_vecs.code == 608.2].to_numpy()

## generate pro-con axis with dot product
meta['cmp_mig'] = np.dot(doc_vecs, diff_mig.T)
meta['cmp_int'] = np.dot(doc_vecs, diff_int.T)

#%%

meta[['date_clean', 'cmp_mig']].groupby(
    pd.PeriodIndex(meta['date_clean'], freq="Q")).mean().plot()

meta[['date_clean', 'cmp_int']].groupby(
    pd.PeriodIndex(meta['date_clean'], freq="Q")).mean().plot()


#%% show party positions

party_vecs['cmp_mig'] = np.dot(party_vecs.drop('party', axis = 1), diff_mig.T)
party_vecs['cmp_int'] = np.dot(party_vecs.drop(['party', 'cmp_mig'], axis = 1), diff_int.T)

#%%
sns.scatterplot(x="cmp_mig", y="cmp_int", data=party_vecs, hue = 'party', style = 'party')

#%%
## reduce dimensionality
party_vecs.index = range(6)
vec_red = PCA(n_components=2).fit_transform(party_vecs.drop(['party', 'cmp_mig', 'cmp_int'], axis = 1))
vec_red = pd.DataFrame(vec_red)
vec_red = pd.concat([vec_red, party_vecs['party']], axis = 1, ignore_index = True)
vec_red.columns = columns = ['C1', 'C2', 'party']

plt.figure(figsize=(8,5))
sns.scatterplot(x="C1", y="C2", data=vec_red, hue = 'party', style = 'party')
for line in range(0,vec_red.shape[0]):
    plt.text(vec_red.C1[line], 
            vec_red.C2[line], 
            vec_red.party[line])
plt.show()


#%%
## dimensionality reduction based on marpor

vec_red = PCA(n_components=2).fit_transform(pd.crosstab(migmps.party, migmps.code))
vec_red = pd.DataFrame(vec_red)
vec_red = pd.concat([vec_red, party_vecs['party']], axis = 1, ignore_index = True)
vec_red.columns = columns = ['C1', 'C2', 'party']

plt.figure(figsize=(8,5))
sns.scatterplot(x="C1", y="C2", data=vec_red, hue = 'party', style = 'party')
for line in range(0,vec_red.shape[0]):
    plt.text(vec_red.C1[line], 
            vec_red.C2[line], 
            vec_red.party[line])
plt.show()

# certainly makes more sense

#%% use self-trained word2vec embeddings

## load word2vec model


## generate document vectors

## define difference

## define scale

