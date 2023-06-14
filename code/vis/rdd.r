# rdd estimates for event effects on party share

library(tidyverse)
library(dplyr)
library(rdrobust)

## load RDD funciton
source("code/functions/RDDPlots.R")


## Cologne and Refugee Crime

plots <- RDDPlots(
    event_name = "NYE15 Cologne",
    cutoff_date = as.Date("2016-01-01"), # event, coverage starts later (might check difference between the two for identification of media effect)
    topic_ass = "Association..reduced...Refugee.Crime",
    topic_cls_label = "Refugee Crime",
    sv = T,
    supervised = "crime_label",
    dict = "ext_crime",
    plt_title = "Crime Framing"
)

plots["media_plot"]
ggsave(paste0("plots/RDD/MediaEffect_cologne.png"), height = 4, width = 6)

plots["polls_plot"]
ggsave(paste0("plots/RDD/PollEffect_cologne.png"), height = 4, width = 6)


## Cologne and Refugee Crime

plots <- RDDPlots(
    event_name = "Cologne Reporting",
    cutoff_date = as.Date("2016-01-04"), # event, coverage starts later (might check difference between the two for identification of media effect)
    topic_ass = "Association..reduced...Refugee.Crime",
    topic_cls_label = "Refugee Crime",
    sv = T,
    supervised = "crime_label",
    dict = "ext_crime",
    plt_title = "Crime Framing"
)

plots["media_plot"]
ggsave(paste0("plots/RDD/MediaEffect_cologne_rep.png"), height = 4, width = 6)

plots["polls_plot"]
ggsave(paste0("plots/RDD/PollEffect_cologne_rep.png"), height = 4, width = 6)



## Lampedusa and the Humanitarian Crisis in the Mediterranean
plots <- RDDPlots(
    event_name = "Lampedusa",
    cutoff_date = as.Date("2013-10-03"),
    topic_ass = "Association..reduced...Humanitarian.Crisis.Mediterranean",
    topic_cls_label = "Humanitarian Crisis Mediterranean",
    sv = F,
    dict = "ext_mediterraneancrisis",
    plt_title = "Mediterranean Crisis Framing"
)

plots["media_plot"]
ggsave(paste0("plots/RDD/MediaEffect_lampedusa_med.png"), height = 4, width = 6)


## Lampedusa and the Humanitarian Crisis in the Mediterranean
plots <- RDDPlots(
    event_name = "Lampedusa",
    cutoff_date = as.Date("2013-10-03"),
    topic_ass = "Association..reduced...Police.Action.Against.Human.Trafficking",
    topic_cls_label = "Police Action Against Human Trafficking",
    sv = F,
    dict = "ext_humantrafficking",
    plt_title = "Human Trafficking Framing"
)

plots["media_plot"]
ggsave(paste0("plots/RDD/MediaEffect_lampedusa_ht.png"), height = 4, width = 6)

plots["polls_plot"]
ggsave(paste0("plots/RDD/PollEffect_lampedusa.png"), height = 4, width = 6)


## Lübcke

plots <- RDDPlots(
    event_name = "Assassination Lübcke",
    cutoff_date = as.Date("2019-06-16"),
    topic_ass = "Association..reduced...Attacks.on.Refugee.Homes",
    topic_cls_label = "Attacks on Refugee Homes",
    sv = F,
    dict = "ext_attacks",
    plt_title = "Attack Framing"
)

plots["media_plot"]
ggsave(paste0("plots/RDD/MediaEffect_luebcke.png"), height = 4, width = 6) # null

plots["polls_plot"] # still greens
ggsave(paste0("plots/RDD/PollEffect_luebcke.png"), height = 4, width = 6)

## lübcke greens plot
polls <- 
    read.csv("data/processed/polls.csv") %>%
    pivot_wider(names_from = "party", values_from = "value", values_fn = mean) %>%
    mutate(
        date = as.Date(date),
        date_from = as.Date(date_from))

polls %>%
    mutate(post = date >= as.Date("2019-06-01")) %>%
    filter(date >= "2019-01-01" & date <= "2019-12-31") %>%
    ggplot(aes(x = date, y = GRUENE, group = post)) + 
    geom_point() +
    geom_smooth(method = "loess") +
    theme_minimal()
ggsave(paste0("plots/RDD/polls_greens_luebcke.png"), height = 4, width = 6)
## likely reason: EU Elections

## csu campaign against welfare migration (https://www.sueddeutsche.de/politik/wegen-bulgarien-und-rumaenien-csu-plant-offensive-gegen-armutsmigranten-1.1852159)

plots <- RDDPlots(
    event_name = "CSU Campaign Against Welfare Migration",
    cutoff_date = as.Date("2013-12-28"),
    topic_ass = "Association..reduced...Welfare.Migration",
    topic_cls_label = "Welfare Migration",
    sv = F,
    dict = "ext_welfare",
    plt_title = "Welfare Framing"
)

plots["media_plot"]
ggsave(paste0("plots/RDD/MediaEffect_csu_campaign.png"), height = 4, width = 6)

plots["polls_plot"] # fdp surprisingly wins - opposition!
ggsave(paste0("plots/RDD/PollEffect_csu_campaign.png"), height = 4, width = 6)


## Tragedy at Parndorf (https://de.wikipedia.org/wiki/Fl%C3%BCchtlingstrag%C3%B6die_bei_Parndorf)

plots <- RDDPlots(
    event_name = "Parndorf",
    cutoff_date = as.Date("2015-08-26"),
    topic_ass = "Association..reduced...Police.Action.Against.Human.Trafficking",
    topic_cls_label = "Police Action Against Human Trafficking",
    sv = F,
    dict = "ext_humantrafficking",
    plt_title = "Human Trafficking"
)

plots["media_plot"]
ggsave(paste0("plots/RDD/MediaEffect_parndorf_ht.png"), height = 4, width = 6)

plots["polls_plot"] # fdp surprisingly wins - opposition!
ggsave(paste0("plots/RDD/PollEffect_parndorf.png"), height = 4, width = 6)

plots <- RDDPlots(
    event_name = "Parndorf",
    cutoff_date = as.Date("2015-08-26"),
    topic_ass = "Association..reduced...Humanitarian.Crisis.Mediterranean",
    topic_cls_label = "Humanitarian Crisis Mediterranean",
    sv = F,
    dict = "ext_mediterraneancrisis",
    plt_title = "Humanitarian Crisis Mediterranean"
)

plots["media_plot"]
ggsave(paste0("plots/RDD/MediaEffect_parndorf_med.png"), height = 4, width = 6)


## Breitscheidtplatz Attentat
plots <- RDDPlots(
    event_name = "Breitscheidtplatz",
    cutoff_date = as.Date("2016-12-19"),
    topic_ass = "Association..reduced...Refugee.Crime",
    topic_cls_label = "Refugee Crime",
    sv = F,
    dict = "ext_crime",
    plt_title = "Refugee Crime"
)

plots["media_plot"]
ggsave(paste0("plots/RDD/MediaEffect_breitscheidt.png"), height = 4, width = 6)

plots["polls_plot"] # v bad for SPD and Left, very good for AfD, somewhat good for FDP - unclear who loses when
ggsave(paste0("plots/RDD/PollEffect_breitscheidt.png"), height = 4, width = 6)



## lübcke with EP election adjustment
library(rdrobust)
cutoff_date <- as.Date("2019-06-16")

### estimate rdd for ep date
plots <- RDDPlots(
    event_name = "EP Election 2021",
    cutoff_date = as.Date("2019-05-26"),
    topic_ass = "Association..reduced...Welfare.Migration",
    topic_cls_label = "Welfare Migration",
    sv = F,
    dict = "ext_welfare",
    plt_title = "Welfare Framing"
)

plots["poll_plot"]
ggsave(paste0("plots/RDD/PollEffect_ep.png"), height = 4, width = 6)

### generate residuals
ests <- plots$polls_ests

#### extract correction
afd_cor    <- ests[ests$DV == "AfD",    "Estimate"]
union_cor  <- ests[ests$DV == "Union",  "Estimate"]
spd_cor    <- ests[ests$DV == "SPD",    "Estimate"]
greens_cor <- ests[ests$DV == "Greens", "Estimate"]
left_cor   <- ests[ests$DV == "Left",   "Estimate"]
fdp_cor    <- ests[ests$DV == "FDP",    "Estimate"]

#### prep data
polls <- 
    read.csv("data/processed/polls.csv") %>%
    pivot_wider(names_from = "party", values_from = "value", values_fn = mean) %>%
    mutate(
        date = as.Date(date),
        date_from = as.Date(date_from))

polls <- 
    polls %>%
    filter(
        !(
            date > cutoff_date &
            date_from < cutoff_date
        )
    )

#### generate residuals
polls$post <- polls$date >= as.Date("2019-05-26") # ep date

polls$AfD[polls$post] <- polls$AfD[polls$post] - afd_cor
polls$Union[polls$post] <- polls$Union[polls$post] - union_cor
polls$SPD[polls$post] <- polls$SPD[polls$post] - spd_cor
polls$GRUENE[polls$post] <- polls$GRUENE[polls$post] - greens_cor
polls$LINKE[polls$post] <- polls$LINKE[polls$post] - left_cor
polls$FDP[polls$post] <- polls$FDP[polls$post] - fdp_cor

#### estimate new models
m_afd   <- rdrobust(polls$AfD,    as.numeric(polls$date - cutoff_date))
m_union <- rdrobust(polls$Union,  as.numeric(polls$date - cutoff_date))
m_spd   <- rdrobust(polls$SPD,    as.numeric(polls$date - cutoff_date))
m_green <- rdrobust(polls$GRUENE, as.numeric(polls$date - cutoff_date))
m_linke <- rdrobust(polls$LINKE,  as.numeric(polls$date - cutoff_date))
m_fdp   <- rdrobust(polls$FDP,    as.numeric(polls$date - cutoff_date))

#### plot effect estimates
est_extract <- function(
        model_vec, title_vec
    ){

        ests <- data.frame()
        for (i in seq(1, length(model_vec))){

            m  <-  get(model_vec[i])
            dv_title <- title_vec[i]

            point_est <- m$Estimate[,"tau.bc"]
            lower_est <- point_est - 1.96 * m$Estimate[,"se.rb"]
            upper_est <- point_est + 1.96 * m$Estimate[,"se.rb"]

            ests <- 
                ests %>%
                rbind(
                    data.frame(
                        "DV" = dv_title,
                        "Estimate" = point_est,
                        "Lower" = lower_est,
                        "Upper" = upper_est
                        )
                    )
        }
        return(
            ests %>%
            mutate(
                DV = factor(DV, levels = title_vec)
            )
        )
    }

#### get poll estimates
model_vec  <- c("m_afd", "m_union", "m_spd", "m_green", "m_linke", "m_fdp")
title_vec <- c("AfD", "Union", "SPD", "Greens", "Left", "FDP")

poll_ests <- est_extract(model_vec, title_vec)

### Effectplots
poll_ests %>%
    ggplot(
        aes(
            y = DV,
            x = Estimate,
            xmin = Lower,
            xmax = Upper
        )) +
        geom_vline(xintercept = 0, col = "gray") +
        geom_pointrange() +
        theme_minimal() +
        xlab("") + ylab("") +
        ggtitle(
            paste0("Corrected Effect of Lübcke Assassination on Polling"),
            "Robust RD on PollOfPolls Data")

ggsave(paste0("plots/RDD/PollEffect_luebcke_corrected.png"), height = 4, width = 6)


## Calais Jungle Dismantling 24.20.2016
plots <- RDDPlots(
    event_name = "Calais Jungle Evacuation",
    cutoff_date = as.Date("2016-10-24"),
    topic_ass = "Association..reduced...Humanitarian.Crisis.EU.Borders",
    topic_cls_label = "Humanitarian Crisis EU Borders",
    sv = F,
    dict = F,
    plt_title = "Humanitarian Crisis EU Borders"
)

plots["media_plot"]
ggsave(paste0("plots/RDD/MediaEffect_calais.png"), height = 4, width = 6)

plots["polls_plot"] # insig neg for afd, good for greens, spd, union
ggsave(paste0("plots/RDD/PollEffect_calais.png"), height = 4, width = 6)
