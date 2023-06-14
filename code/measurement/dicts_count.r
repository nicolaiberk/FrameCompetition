#%% setup

library(tidyverse)
library(dplyr)
library(data.table)

# load migration content
mig_artcls <-
    fread("data/raw/media/bert_crime_clean.csv", header = TRUE) %>% 
    as_tibble() %>%
    dplyr::select(-V1)

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

## load valence table
topic_table <-
    fread("data/processed/media/topic_table.csv") %>%
    mutate(topic_label = label) %>%
    select(topic_label, valence)

## annotate valence
top_artcls <-
    top_artcls %>%
    right_join(topic_table, by = "topic_label") %>%
    mutate(
        monthdate =
            lubridate::floor_date(
                as.Date(
                    date_clean,
                    origin = "1970-01-01"),
                "quarter"),
        valence =
            factor(
                valence,
                levels = c("--", "-", "", "+", "++"), 
                ordered = T),
            )

## load topic data
top_artcls <-
    fread("data/processed/media/docs_topics_sims.csv", header = TRUE) %>%
    as_tibble()

## merge
merged <-
    mig_artcls %>%
    right_join(top_artcls, by = c("url", "date_clean"))


## save
fwrite(merged, "data/processed/media/full_ests.csv")
