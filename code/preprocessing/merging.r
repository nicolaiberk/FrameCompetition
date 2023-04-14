## run var models of polling and topics in migration coverage
library(tidyverse)
library(vars)
library(data.table)
library(zoo)

topics  <- fread("data/processed/media/docs_topics_sims.csv")
polls <- fread("data/raw/polls/polls.csv")

## generate topic dummies
topics_agg  <- 
    topics[,c("date_clean", "paper", "dpa", "crime_label", "crime_prob")] %>%
    cbind(fastDummies::dummy_cols(topics$reduced_topic_label)) %>%
    mutate(reduced_topic_label = `.data`)

## clean colnames
colnames(topics_agg) <- 
    colnames(topics_agg) %>%
    str_replace(".data_", "")

topics_agg <- 
    topics_agg %>%
    dplyr::select(!contains(".data"), -reduced_topic_label)

## add original topic labels
topics_agg <-
    topics_agg %>% 
    cbind(fastDummies::dummy_cols(topics$topic_label)) %>% 
    mutate(topic_label = `.data`)

## clean colnames
colnames(topics_agg) <- 
    colnames(topics_agg) %>%
    str_replace(".data_", "(ot) ")

topics_agg <- 
    topics_agg %>%
    dplyr::select(!contains(".data"), -topic_label)

## aggregate topics
topics_agg <- 
    topics_agg %>%
    group_by(date_clean, paper) %>%
    summarise(
        across(everything(), ~sum(.x)),
        mig_sal = n()) %>%
    dplyr::select(-paper) %>%
    group_by(date_clean) %>%
    summarise_all(sum)


## merge daily polls and topics
topics_agg <-
    topics %>%
    dplyr::select(c(paper, date_clean, contains("Association"))) %>%
    group_by(date_clean, paper) %>%
    summarise_all(mean) %>%
    dplyr::select(!paper) %>%
    group_by(date_clean) %>%
    summarise_all(mean) %>%
    dplyr::select(-date_clean) %>%
    cbind(topics_agg) %>%
    mutate(date = date_clean)

polls_agg <-
    polls %>%
    dplyr::select(c(date, party, value)) %>%
    group_by(date, party) %>%
    summarise_all(mean) %>%
    mutate(value = value/100) %>%
    pivot_wider(
        names_from = party,
        values_from = value
    )

merged <-
    merge(topics_agg, polls_agg, by = "date") %>%
    mutate(year = year(date),
           month = month(date),
           week = week(date),
           wday = lubridate::wday(date, label = T, week_start = 1),
           yw = paste(year(date), week(date), sep = "-"))

## save
merged %>%
    fwrite("data/processed/media/merged.csv")
