# ______________________________________________
# Media Frames and Party Competition
# Main Execution FIle
# ______________________________________________
# Date:  Tue Nov 29 14:06:58 2022
# Author: Nicolai Berk
#  R version 4.1.1 (2021-08-10)
# ______________________________________________

# Setup ####
library(tidyverse)
library(here)
library(data.table)
library(word2vec)

# parameters ####
sampling <- T

# cleaning ####
cat("Cleaning in progress...")

cat("\tClean and merge news corpus...")
source("code/preprocessing/preprocess_news.R")

cat("All cleaned up.\n\n")



# sampling ####
cat("Sampling...")
if(sampling){
  cat("\tSampling from news corpus...")
  source("code/preprocessing/news_sampling.R")
}
cat("Done sampling.\n\n")



# embeddings ####
cat("Estimating embeddings...")

cat("\tEstimating word2vec...")
source("code/embeddings/word_embeddings.R")

cat("\tEstimating doc2vec: party embeddings...")
source("code/embeddings/party_embeddings.R")

cat("\tEstimating doc2vec: ...")
source("code/embeddings/news_embeddings.R")

cat("Estimation of embeddings finished.\n\n")
