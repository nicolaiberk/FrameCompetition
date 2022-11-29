# ______________________________________________
# Media Frames and Party Competition
# Goal: Clean news coverage data
# Procedure: load, clean, write
# ______________________________________________
# Date:  Tue Nov 29 12:16:17 2022
# Author: Nicolai Berk
#  R version 4.1.1 (2021-08-10)
# ______________________________________________


for (corpus in list.files(here("data/raw/media/newspapers"))){
  
  # load ####
  if (str_detect(corpus, "bild")){
    
    dta <- 
      fread(here(paste0(here("data/raw/media/newspapers/", corpus)))) %>% 
      mutate(date_clean = as.Date(date),
             paper = "bild") %>%  # clean
      select(date_clean, text, paper)
    
    # write
    
  }else if (str_detect(corpus, "faz")){
    
    dta <- 
      fread(here(paste0(here("data/raw/media/newspapers/", corpus)))) %>% 
      mutate(date_clean = as.Date(date, origin = "1970-01-01"),
             paper = "faz") %>%  # clean
      select(date_clean, text, paper)
    
  }else if (str_detect(corpus, "spon")){
    
    dta <- 
      fread(here(paste0(here("data/raw/media/newspapers/", corpus)))) %>% 
      mutate(date_clean = as.Date(date, format = "%d.%m.%Y"),
             paper = "spon") %>%  # clean
      select(date_clean, text, paper)
    
  }else if (str_detect(corpus, "sz")){
    
    dta <- 
      fread(here(paste0(here("data/raw/media/newspapers/", corpus)))) %>% 
      filter(!is.na(date)) %>% 
      mutate(date_clean = as.Date(date, origin = "1970-01-01"),
             paper = "sz") %>%  # clean
      select(date_clean, text, paper)
    
  }else if (str_detect(corpus, "taz")){
    
    dta <- 
      fread(here(paste0(here("data/raw/media/newspapers/", corpus)))) %>% 
      mutate(date_clean = as.Date(date, origin = "1970-01-01"),
             paper = "taz") %>%  # clean
      select(date_clean, text, paper)
    
  }else if (str_detect(corpus, "welt")){
    
    dta <- 
      fread(here(paste0(here("data/raw/media/newspapers/", corpus)))) %>% 
      mutate(date_clean = as.Date(date, origin = "1970-01-01"),
             paper = "welt") %>%  # clean
      select(date_clean, text, paper)
    
  }
  
  if(file.exists("data/processed/media/news_merged.csv")){
    
    fwrite(dta, 
           file = "data/processed/media/news_merged.csv", 
           append = T, 
           showProgress = T)
    
  }else{
    
    fwrite(dta,
           file = "data/processed/media/news_merged.csv")
    
  }
  
}
