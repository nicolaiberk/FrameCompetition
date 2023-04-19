

## estimate frame prevalence in party dicts

#%% setup

import numpy as np
import pandas as pd
import nltk
nltk.download('stopwords')
from nltk.corpus import stopwords
from nltk.stem.snowball import SnowballStemmer
from sklearn.feature_extraction.text import CountVectorizer
import spacy

stemmer = SnowballStemmer('german')
nlp = spacy.load("de_core_news_sm")

sws = stopwords.words('german')
sws.extend(['und', 'die', 'wir', 'ein', 'in', 'der', 'zu', 'ist', 'den', 'eine', 'fur', 'sich', 'nicht', 'uns', 'nach', 'das', 'mit', 'auch', 'von', 'sie', "über", "ab", "schon", "muss", "bereits", "dafür", "deshalb", "dabei", "jahr", "jahre", "jahren", "teil"])
print(sws)


#%% assess most prevalent uni, bi and trigrams in cmp codes

### load party manifestos
migmps = pd.read_csv("data/raw/manifestos/manifestos1317_mig.csv")

### pro migration

#### restrict to nouns and adjectives
migmps['text_r'] = ''
for row in range(migmps.shape[0]):
    doc = nlp(migmps.text[row])
    pos = [(w.text, w.pos_) for w in doc]
    postxt = ''
    for tp in pos:
        if tp[1] == 'NOUN':
            postxt = postxt + tp[0] + ' '
    migmps.loc[row, "text_r"] = postxt

#### stem
migmps['stems'] = migmps.text_r.apply(lambda x: stemmer.stem(x))

#### generate dfm
vec_mig_con = CountVectorizer(min_df=3, ngram_range=(1,3))
vec_mig_pro = CountVectorizer(min_df=3, ngram_range=(1,3))

dfm_con = vec_mig_con.fit_transform(migmps.text_r[(migmps.code == 601.2) | (migmps.code == 608.2)])
dfm_pro = vec_mig_pro.fit_transform(migmps.text_r[(migmps.code == 602.2) | (migmps.code == 607.2)])


#%% most important terms for each category

## convert dfm to pd.DataFrame
termfreq_mig_con = pd.DataFrame(dfm_con.toarray(), columns=vec_mig_con.get_feature_names_out()).sum()
termfreq_mig_pro = pd.DataFrame(dfm_pro.toarray(), columns=vec_mig_pro.get_feature_names_out()).sum()

# ## remove stop words
# for sw in sws:
#     if sw in termfreq_mig_pro.index:
#         termfreq_mig_pro = termfreq_mig_pro[termfreq_mig_pro.index != sw]
#     if sw in termfreq_mig_con.index:
#         termfreq_mig_con = termfreq_mig_con[termfreq_mig_con.index != sw]


## remove indiscriminate terms
for t in termfreq_mig_pro:
    if t in termfreq_mig_con.index:
        termfreq_mig_pro = termfreq_mig_pro[termfreq_mig_pro.index != t]

for t in termfreq_mig_con:
    if t in termfreq_mig_pro.index:
        termfreq_mig_con = termfreq_mig_con[termfreq_mig_con.index != t]

#%% print most common pro
termfreq_mig_pro.sort_values(ascending=False).plot(kind = 'bar', figsize=(20,10))

#%% print most common con
termfreq_mig_con.sort_values(ascending=False).plot(kind = 'bar', figsize=(20,10))
