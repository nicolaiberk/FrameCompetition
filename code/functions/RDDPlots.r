library(tidyverse)
library(dplyr)
library(rdrobust)

RDDPlots <- function(
    event_name, cutoff_date, topic_ass, topic_cls_label,
    sv, supervised, dict, plt_title
){


    ### polls
    polls <- 
        read.csv("data/processed/polls.csv") %>%
        pivot_wider(names_from = "party", values_from = "value", values_fn = mean) %>%
        mutate(
            date = as.Date(date),
            date_from = as.Date(date_from))

    ### media content
    media <- read.csv("data/processed/media/full_ests.csv") %>%
        mutate(date_clean = as.Date(date_clean))


    ## Cologne


    ### Topic: Refugee Crime
    media <- 
        media %>%
        mutate(topic_cls = reduced_topic_label == topic_cls_label)


    #### models
    m_topic_ass <- rdrobust(scale(media[, topic_ass]), as.numeric(media$date_clean - cutoff_date)) # topic association
    m_topic_cls <- rdrobust(scale(media[, "topic_cls"]), as.numeric(media$date_clean - cutoff_date)) # topic classification
    
    if (!isFALSE(dict)){
        m_dict <- rdrobust(media[, dict], as.numeric(media$date_clean - cutoff_date)) # dictionary count
    }

    if (sv){
        if (!exists("supervised")){
            stop("If `sv == TRUE`, need to specify `supervised`!")
        }
        
        m_sv <- rdrobust(
            scale(media[, supervised]),
            as.numeric(media$date_clean - cutoff_date)
            ) # supervised

    }

    ### Parties

    #### filter overlapping polls
    polls_sub <- 
        polls %>%
        filter(
            !(
                date > cutoff_date &
                date_from < cutoff_date
            )
        )

    #### models
    m_afd   <- rdrobust(polls_sub$AfD,    as.numeric(polls_sub$date - cutoff_date))
    m_union <- rdrobust(polls_sub$Union,  as.numeric(polls_sub$date - cutoff_date))
    m_spd   <- rdrobust(polls_sub$SPD,    as.numeric(polls_sub$date - cutoff_date))
    m_green <- rdrobust(polls_sub$GRUENE, as.numeric(polls_sub$date - cutoff_date))
    m_linke <- rdrobust(polls_sub$LINKE,  as.numeric(polls_sub$date - cutoff_date))
    m_fdp   <- rdrobust(polls_sub$FDP,    as.numeric(polls_sub$date - cutoff_date))


    ### generate datasets

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

    #### get media estimates
    model_vec <- c("m_topic_ass", "m_topic_cls")
    title_vec <-  c("Association", "Topic")

    
    if(!isFALSE(dict)){
        model_vec <- c(model_vec, "m_dict")
        title_vec <- c(title_vec, "Dictionary")
    }


    if(sv){
        model_vec <- c(model_vec, "m_sv")
        title_vec <- c(title_vec, "Supervised")
    }


    media_ests <- est_extract(model_vec, title_vec)

    #### get poll estimates
    model_vec  <- c("m_afd", "m_union", "m_spd", "m_green", "m_linke", "m_fdp")
    title_vec <- c("AfD", "Union", "SPD", "Greens", "Left", "FDP")

    poll_ests <- est_extract(model_vec, title_vec)

    ### Effectplots
    media_plot <- 
        media_ests %>%
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
                paste0("Effect of ", event_name, " on ", plt_title),
                "Robust RD on Different Measures"
                )

    poll_plot <- 
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
                paste0("Effect of ", event_name, " on Polling"),
                "Robust RD on PollOfPolls Data")
    

    return(
        list(
            "media_plot" = media_plot, 
            "polls_plot" = poll_plot,
            "media_ests" = media_ests,
            "polls_ests" = poll_ests
            )
        )

}

