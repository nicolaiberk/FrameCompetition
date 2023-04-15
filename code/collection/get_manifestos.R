# ______________________________________________
# FrameCompetition
# Goal: Create set of manifestos
# Procedure: Get data, generatae dataset, save
# ______________________________________________
# Date:  Tue Nov 29 15:34:54 2022
# Author: Nicolai Berk
#  R version 4.1.1 (2021-08-10)
# ______________________________________________

# setup
library(tidyverse)
library(dplyr)
library(manifestoR)
library(data.table)

# Get data 13 & 17 elections ####
mp_setapikey("data/raw/manifestos/manifesto_apikey.txt")

my_corpus <- mp_corpus(countryname == "Germany" &
                         edate < as.Date("2018-01-01") &
                         edate > as.Date("2013-01-01"))

mpds <- mp_maindataset()

# generatae migration corpus ####
corpus <- 
  data.frame(
    party = NULL,
    date = NULL,
    text = NULL, 
    code = NULL)

for (doc in names(my_corpus)){

  text <- content(my_corpus[[doc]])
  yr <- meta(my_corpus[[doc]])$date %>% 
        as.character() %>% 
        str_sub(1,4)
  mp_codes <- codes(my_corpus[[doc]])
  partycode <- meta(my_corpus[[doc]])$party
  partyname <- mpds[mpds$party == partycode, "partyabbrev"] %>% unique() %>% .[[1]]
  
  corpus <- 
    rbind(
      corpus,
      data.frame(
        party = partyname,
        date = yr,
        code = mp_codes,
        text = text
      )
    )
}

# save ####
fwrite(corpus, "data/raw/manifestos/manifestos1317.csv")

# mig texts only
mig_corpus <- corpus %>%
  filter(code %in% c("601.2", "602.2", "607.2", "608.2")) # immigration-related codes acc to CMP v5 only available for 2017

table(mig_corpus$party, mig_corpus$code, mig_corpus$date) # clearly separating positions

fwrite(mig_corpus, "data/raw/manifestos/manifestos1317_mig.csv")
