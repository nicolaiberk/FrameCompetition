# ______________________________________________
# Media Framing and Party Competition
# Goal: Generate subsample of news corpus
# ______________________________________________
# Date:  Tue Nov 29 14:24:47 2022
# Author: Nicolai Berk
#  R version 4.1.1 (2021-08-10)
# ______________________________________________



fread("data/processed/media/news_merged.csv") %>% 
  sample_n(10000) %>% 
  fwrite("data/processed/media/news_merged_sample.csv")

