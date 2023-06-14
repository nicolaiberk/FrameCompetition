## label topics

import pandas as pd
import numpy as np
import seaborn as sns
from top2vec import Top2Vec
from pprint import pprint
import random
random.seed(42)
import json

import os
os.chdir("C://Users/nicol/Dropbox/PhD/Papers/FrameCompetition")

## load model
model = Top2Vec.load("models/t2v/migration_mindocs300")

## get topic number k
topic_nums = model.get_num_topics()

## print most similar documents and topic words
with open("data/processed/topic_docs.txt", "w", encoding="UTF-8") as f:
    for topic in range(topic_nums):
        documents, document_scores, document_ids = model.search_documents_by_topic(topic_num=topic, num_docs=5)
        f.write(f"Topic: {topic}")
        f.write(" ".join(model.topic_words[topic][:10]))
        for doc, score, doc_id in zip(documents, document_scores, document_ids):
            f.write("\\n")
            f.write("\\n")
            f.write(f"Document: {doc_id}, Score: {score}")
            f.write("\\n")
            f.write("-----------")
            f.write(doc)
            f.write("\\n")
            f.write("-----------")

## load topic ids from json
with open('data/processed/reduced_topic_ids.json', 'r') as f:
  reduced_ids = json.load(f)

## load topic labels from json
with open('data/processed/topic_labels.json', 'r') as f:
    topic_labels = json.load(f)

## load reduced topic labels from json
with open('data/processed/reduced_topic_labels.json', 'r') as f:
    reduced_labels = json.load(f)

## load document metadata
meta = pd.read_csv("data/raw/media/bert_crime_clean.csv", encoding="utf-8").drop('text', axis=1)

## merge topic ids

## add topic data
meta['topic_id'] = model.get_documents_topics(model.document_ids)[0]
meta['reduced_topic_id'] = meta['topic_id'].apply(lambda x: [i for i, j in reduced_ids.items() if x in j])
meta.reduced_topic_id = meta.reduced_topic_id.apply(lambda x: x[0])
meta['topic_label'] = [topic_labels[str(k)] for k in meta.topic_id]
meta['reduced_topic_label'] = meta['topic_id'].apply(lambda x: [i for i, j in reduced_labels.items() if x in j])
meta.reduced_topic_label = meta.reduced_topic_label.apply(lambda x: x[0])

## define topic overview, incl valence
topic_table = pd.DataFrame({"id": range(model.get_num_topics()), "words": [" ".join(f[:10]) for f in model.topic_words]})

topic_table["label"] = topic_table["id"].map(topic_labels)
topic_table["reduced_label"] = topic_table["id"].apply(lambda x: [i for i, j in reduced_labels.items() if x in j][0])
topic_table["topic_share"] = meta.topic_label.value_counts(normalize=True).values
topic_table["valence"] = [
    "", "", "", "+", "+", "-", "-", "++", "", "", 
    "-", "+", "", "", "", "", "+", "", "--", "-",
    "+", "-", "+", "-", "", "", "", "--", "+", "",
    "-", "++", "+", "", "-", "", "", "", "++", "--",
    "+", "", "", "", "", "+", "", "-", "", "-", "", "",
    "-", "+", "", "++", "", "", "", "++", "", ""
]

## write overview to csv
topic_table.sort_values(["topic_share"], ascending=False)[["label", "reduced_label", "valence", "topic_share", "words"]].to_csv("data/processed/media/topic_table.csv", index=False)

## add topic similarity to document data (takes a few minutes)
doc_top_sim = model.get_documents_topics(model.document_ids, num_topics=62)[1]
doc_top_sim = pd.DataFrame(doc_top_sim, columns=[f"Association (ot): {t}" for t in topic_labels.values()])

## merge topic similarities
meta = pd.concat([meta.drop("V1", axis = 1), doc_top_sim], axis=1)

## load topic vectors
rt_vectors = pd.read_csv("data/processed/embeddings/reduced_topics.csv")

## estimate cosin sim to reduced topics
from scipy.spatial import distance
cos_sim = 1 - distance.cdist(model.document_vectors, rt_vectors, 'cosine')
cos_sim = pd.DataFrame(cos_sim, columns=[f"Association (reduced): {t}" for t in reduced_labels.keys()])

## merge
meta = pd.concat([meta, pd.DataFrame(cos_sim)], axis=1)

## write to csv
meta.to_csv("data/processed/media/docs_topics_sims.csv", index=False)