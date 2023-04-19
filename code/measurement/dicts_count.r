#%% setup

library(tidyverse)
library(dplyr)
library(data.table)

# load migration content
mig_artcls <-
    fread("data/raw/media/bert_crime_clean.csv", header = TRUE) %>% 
    as_tibble() %>%
    select(!V1)

# count terms

for (d in list.files("data/processed/dicts")) {
    
    print(d)

    # load dict
    dict <-
        read.csv(paste0("data/processed/dicts/", d)) %>%
        colnames() %>%
        str_replace_all('\\.', ' ')

    # count terms
    mig_artcls[str_replace(d, '.txt', '')] <-
        mig_artcls$text %>%
        tolower()  %>%
        map(\(x) str_count(x, dict)) %>%
        map(\(x) sum(x)) %>%
        as_vector()


    }

## load topic data
top_artcls <-
    fread("data/processed/media/docs_topics_sims.csv", header = TRUE) %>%
    as_tibble()

## merge
merged <-
    cbind(
        mig_artcls %>%
            select(contains("ext_")),
        top_artcls)

## save
fwrite(merged, "data/processed/media/full_ests.csv")
