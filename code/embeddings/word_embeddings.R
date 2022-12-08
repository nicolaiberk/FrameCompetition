# ______________________________________________
# Media Frames and Party Competition
# Goal: Estimate word embeddings
# Procedure: estimate embeddings, save
# ______________________________________________
# Date:  Tue Nov 29 14:11:58 2022
# Author: Nicolai Berk
#  R version 4.1.1 (2021-08-10)
# ______________________________________________


whitelist <- ls()

# estimate embeddings ####
w2v_model <- word2vec(
  fread(
    here(
      paste0("data/processed/media/news_merged",
             ifelse(sampling, "_sample", ""),
             ".csv")
      ), 
    encoding = "UTF-8")$text, 
  dim = 300, window = 5, iter = 20, 
  min_count = 100, threads = 6)

# save ####
word2vec::write.word2vec(w2v_model, 
                         paste0("data/processed/embeddings/w2v_news",
                                ifelse(sampling, "_sample", ""),
                                ".bin"))

emb <- as.matrix(w2v_model)

save(emb,
     file = paste0("data/processed/embeddings/w2v_news_vectors",
                   ifelse(sampling, "_sample", ""),
                   ".Rdata"))

rm(ls()[!ls() %in% whitelist])

