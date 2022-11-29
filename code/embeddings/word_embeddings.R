# ______________________________________________
# Media Frames and Party Competition
# Goal: Estimate word embeddings
# Procedure: estimate embeddings, save
# ______________________________________________
# Date:  Tue Nov 29 14:11:58 2022
# Author: Nicolai Berk
#  R version 4.1.1 (2021-08-10)
# ______________________________________________


# estimate embeddings ####
w2v_model <- word2vec(paste0("data/processed/media/news_merged",
                             ifelse(sampling, "_sample", ""),
                             ".csv"), 
                      dim = 300, window = 5, iter = 20, 
                      min_count = 100, threads = 6)

# save ####
word2vec::write.word2vec(w2v_model, 
                         "data/processed/embeddings/w2v_news.bin")
