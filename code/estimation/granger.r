# Granger causality checks with weekly saleince, frame attention, and voting

library(tidyverse)
library(dplyr)
library(lmtest)

## load data
media <- 
    data.table::fread("data/processed/media/merged.csv") %>%
    select(
        date_clean, AfD:Union, mig_sal,
        `AfD Topic`, `Attacks on Refugee Homes`, `Coalition Conflict`, `Deportation`,
        `Humanitarian Crisis Mediterranean`, `Labor Market`, 
        `Police Action Against Human Trafficking`, `Refugee Crime`,
        `Schengen Border Control`, `Syrian Civil War`,
        `Welfare Migration`)

media_vars <- 
    media %>%
    select(-date_clean, -AfD, -SPD, -GRUENE, -FDP, -Union, -PIRATEN, -LINKE) %>%
    colnames()

party_vars <- 
    media %>%
    select(AfD:Union, -PIRATEN) %>%
    colnames()

## daily data granger test
ests <- 
    expand.grid(
        party = party_vars,
        var = media_vars,
        granger_p = NA,
        reverse_p = NA
    )

for (party in party_vars){
    for (var in media_vars){
        ests[ests$party == party &
                ests$var == var, "granger_p"] <- grangertest(media[[var]], media[[party]], order = 7)[2, "Pr(>F)"]
        ests[ests$party == party &
                ests$var == var, "reverse_p"] <- grangertest(media[[party]], media[[var]], order = 7)[2, "Pr(>F)"]
    }
}

## save table
write_csv(ests, "data/processed/media/granger_daily.csv")

ests %>%
    mutate(
        granger_p = granger_p < 0.05,
        reverse_p = reverse_p < 0.05) %>%
    filter(granger_p | reverse_p) %>%
    arrange(-granger_p, -reverse_p)

## aggregate to weekly
media <-
    media %>%
    mutate(yw = lubridate::floor_date(date_clean, "week")) %>%
    group_by(yw) %>%
    summarise(
        across(AfD:Union, mean),
        across(mig_sal:`Welfare Migration`, mean),
    )

## granger causality checks
ests <- 
    expand.grid(
        party = party_vars,
        var = media_vars,
        granger_p = NA,
        reverse_p = NA
    )

for (party in party_vars){
    for (var in media_vars){
        ests[ests$party == party &
                ests$var == var, "granger_p"] <- grangertest(media[[var]], media[[party]], order = 7)[2, "Pr(>F)"]
        ests[ests$party == party &
                ests$var == var, "reverse_p"] <- grangertest(media[[party]], media[[var]], order = 7)[2, "Pr(>F)"]
    }
}

## save table
write_csv(ests, "data/processed/media/granger_weekly.csv")

ests %>%
    mutate(
        granger_p = granger_p < 0.05,
        reverse_p = reverse_p < 0.05) %>%
    filter(granger_p | reverse_p) %>%
    arrange(-granger_p, -reverse_p)
