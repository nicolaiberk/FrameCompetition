# ______________________________________________
# FrameCompetition
# Goal: Create set of manifestos
# Procedure: Get data, generatae dataset, save
# ______________________________________________
# Date:  Tue Nov 29 15:34:54 2022
# Author: Nicolai Berk
#  R version 4.1.1 (2021-08-10)
# ______________________________________________

# parameters ####
whitelist <- ls()


# Get data ####
mp_setapikey("data/raw/manifestos/manifesto_apikey.txt")

my_corpus <- mp_corpus(countryname == "Germany" & 
                         edate < as.Date("2014-01-01") & 
                         edate > as.Date("2013-01-01"))

#
mpds <- mp_maindataset(); clean_list <- c(clean_list, "mpds")

# generatae dataset ####
corpus <- data.frame(doc_id = NULL, text = NULL)

for (doc in names(my_corpus)){
  
  text <- content(my_corpus[[doc]])
  partycode <- meta(my_corpus[[doc]])$party
  partyname <- mpds[mpds$party == partycode, "partyabbrev"] %>% unique() %>% .[[1]]
  
  corpus <- 
    
    rbind(
      corpus,
      data.frame(
        doc_id = partyname,
        text = text
      )
    )
}

# save ####
fwrite(corpus, "data/raw/manifestos/manifestos.csv")

# clean up ####
rm(ls()[!ls() %in% whitelist])

