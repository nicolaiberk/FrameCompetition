# ______________________________________________
# FrameCompetition
# Goal: Estimate Party Embeddings
# Procedure: get manifestos, embed, save
# ______________________________________________
# Date:  Tue Nov 29 14:53:44 2022
# Author: Nicolai Berk
#  R version 4.1.1 (2021-08-10)
# ______________________________________________


whitelist <- ls()

## load party manifestos on migration (2013)
partycom <- fread(here("data/media/migcov_sample.csv"), encoding = "UTF-8")

## load word embeddings trained on full set

emb <- read.word2vec("newsembeddings")


## generate document embeddings
doc2vec(w2v_model, party_com)

# embed ####
d2v_model <- doc2vec(
  read.word2vec("data/processed/embeddings/w2v_news.bin"),
  "data/raw/migration_manifestos/")

# save ####

# clean up
rm(ls()[!ls() %in% whitelist])