library(tidyverse)
library(dplyr)

## load data
var_results <- read.csv("data/processed/estimation/var_results.csv")

## topics
merged <- data.table::fread("data/processed/media/merged.csv")
merged %>%
    dplyr::select(`AfD Topic`:`Young Refugees`) %>%
    summarise_all(sum) %>%
    t() -> topic_dist

row.names(topic_dist)[order(topic_dist, decreasing = T)] -> top_topics

top_topics <- c(top_topics, "AfD Topic")

## plot
var_results %>%
    filter(topic_metric == "association",
           aggregation == "yw",
           topic %in% top_topics,
           is.na(controls)) %>%
    ggplot(aes(y = topic,
               x = point_party_dv, 
               xmin = lower_party_dv,
               xmax = upper_party_dv,
               color = (lower_party_dv > 0 | upper_party_dv < 0))) +
    geom_vline(xintercept = 0) +
    geom_pointrange() +
    theme_minimal() +
    theme(legend.position = "none") +
    facet_grid(~party, scales = "free_x") +
    ggtitle("Framing Effects on Party Polling")

ggsave(filename = "plots/var_top_topics.svg", width = 15, height = 10)


## plot all estimates sorted by effect size per party
for (p in unique(var_results$party)){
    var_results %>%
        filter(topic_metric == "association",
               aggregation == "yw",
               is.na(controls),
               party == p) %>%
        ggplot(aes(x = reorder(topic, -point_party_dv),
                   y = point_party_dv, 
                   ymin = lower_party_dv,
                   ymax = upper_party_dv,
                   color = (lower_party_dv > 0 | upper_party_dv < 0))) +
        geom_hline(yintercept = 0) +
        geom_pointrange() +
        theme_minimal() +
        theme(
            legend.position = "none",
            axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1)
        ) +
        ggtitle(paste0(p, ": Framing Effects on Party Polling")) +
        labs(x = "Topic", y = "Effect Size")
    ggsave(filename = paste0("plots/var_", p, "_topics.png"), width = 15, height = 8)
}


## plot single vars
merged <- data.table::fread("data/processed/media/merged.csv")

parties <- 
    merged %>% 
    dplyr::select(AfD:Union) %>% 
    dplyr::select(-PIRATEN) %>%
    colnames()

rm(merged)

## run var for all party-topic combinations
source("code/functions/var_topic.r")

var_results <-
    expand.grid(

        ## inputs
        topic = top_topics,
        party = parties,

        stringsAsFactors = F
    )

aggregation <- "yw"
topic_metric <- "association"
controls <- NA
max_lag = 12


## needs to be effing long bc gdamn saving doesnt work
for (i in seq_len(nrow(var_results))) {

    print(paste(i, "/", nrow(var_results)))

    party <- var_results$party[i]
    topic <- var_results$topic[i]

    ## load data
    merged <- data.table::fread("data/processed/media/merged.csv")

    ## aggregate data
    merged_agg <-
        merged %>%
        mutate(
            yw = paste(year, week(date), sep = "-"),
            ym = paste(year, month(date), sep = "-"),
            yq = paste(year, quarter(date), sep = "-")
        ) %>%
        group_by(.data[[aggregation]]) %>%
        summarize(
            date = min(date),
            mig_sal = sum(mig_sal),
            crime_sv = sum(crime_label),
            across(contains("Assoc"), ~mean(.x, na.rm = T)),
            across(AfD:Union, ~mean(.x, na.rm = T)),
            across(`AfD Topic`:`Young Refugees`, ~sum(.x, na.rm = T))
        ) %>%
        mutate(
            year = year(date),
            week = week(date),
            wday = wday(date)
            )

    ## define topic metric
    topic_var <- ifelse(topic_metric == "association",
                    paste0("Association (reduced): ", topic),
                    topic)

    if (topic_metric == "share"){
        merged_agg[topic_var] <-
            merged_agg[topic_var] / merged_agg["mig_sal"]
    }

    ## filter missings
    merged_agg <-
        merged_agg[min((seq_len(nrow(merged_agg)))[!is.na(merged_agg[[party]])]):max((1:nrow(merged_agg))[!is.na(merged_agg[[party]])]),] # drop front and end missing values

    ## interpolate missing values
    merged_agg[party] <- zoo::na.approx(merged_agg[party])

    ## filter missings
    merged_agg <-
        merged_agg[min((seq_len(nrow(merged_agg)))[!is.na(merged_agg[[party]])]):max((1:nrow(merged_agg))[!is.na(merged_agg[[party]])]),] # drop front and end missing values

    ## interpolate missing values
    merged_agg[party] <- zoo::na.approx(merged_agg[party])

    ## define control variables
    if (!is.na(controls)) {
        if (controls == "ywd") {
            control_vars  <- c("year", "week", "wday")
            control_merged_agg <- merged_agg[, c(control_vars)]
        } else {
            stop(paste("Unknown control variables:", controls, "."))
        }
    }else{
        control_merged_agg <- as.null()
    }

    # define arguments for var
    args <-
    list(
        y = merged_agg[, c(party, topic_var)],
        exogen = control_merged_agg,
        lag.max = max_lag)


    ## run var
    m <- do.call(vars::VAR, args)
    ifun <- vars::irf(m, cum = T)

    ## return results

    # define topic varname
    topic_irf <- str_replace_all(topic_var, "[\\d\\(\\)\\:\\s\\,\\-\\']", ".")

    ## plot irf to png

        ## party - topic
        p <- ggplot(data = NULL,
                aes(x = 1:nrow(ifun$irf[[party]]),
                   y = ifun$irf[[party]][, topic_irf],
                   ymin = ifun$Lower[[party]][, topic_irf],
                   ymax = ifun$Upper[[party]][, topic_irf])) +
                   geom_pointrange(col = "red") +
                   geom_hline(yintercept = 0, col = "black") +
                   theme_minimal() +
                   labs(x = "Lag", y = "IRF") +
                   ggtitle(paste0(party, " ~ ", topic))
        png(str_c("plots/var/", party, "_", topic, "_irf.png"))
        print(p)
        dev.off()

        ## topic - party
        p <- ggplot(data = NULL,
                aes(x = seq_len(nrow(ifun$irf[[topic_irf]])), 
                   y = ifun$irf[[topic_irf]][, party],
                   ymin = ifun$Lower[[topic_irf]][, party],
                   ymax = ifun$Upper[[topic_irf]][, party])) +
                   geom_pointrange(col = "red") +
                   geom_hline(yintercept = 0, col = "black") +
                   theme_minimal() +
                   labs(x = "Lag", y = "IRF") +
                   ggtitle(paste0(topic, " ~ ", party))
        png(str_c("plots/var/", topic, "_", party, "_irf.png"))
        print(p)
        dev.off()
}


# check afd migration ~ coverage ####
## load data
merged <- data.table::fread("data/processed/media/merged.csv")
party <- "AfD"

## aggregate data
merged_agg <-
    merged %>%
    mutate(
        yw = paste(year, week(date), sep = "-"),
        ym = paste(year, month(date), sep = "-"),
        yq = paste(year, quarter(date), sep = "-")
    ) %>%
    group_by(.data[["yw"]]) %>%
    summarize(
        date = min(date),
        mig_sal = sum(mig_sal),
        across(AfD, ~mean(.x, na.rm = T))
    )

## filter missings
merged_agg <-
    merged_agg[min((seq_len(nrow(merged_agg)))[!is.na(merged_agg[[party]])]):max((1:nrow(merged_agg))[!is.na(merged_agg[[party]])]),] # drop front and end missing values

## interpolate missing values
merged_agg[party] <- zoo::na.approx(merged_agg[party])

# define arguments for var
args <-
list(
    y = merged_agg[, c(party, "mig_sal")],
    lag.max = 12)


## run var
m <- do.call(vars::VAR, args)
ifun <- vars::irf(m, cum = T)

## plt

topic_irf <- "mig_sal"
## afd - mig_sal
p <- ggplot(data = NULL,
        aes(x = 1:nrow(ifun$irf[[party]]),
            y = ifun$irf[[party]][, topic_irf],
            ymin = ifun$Lower[[party]][, topic_irf],
            ymax = ifun$Upper[[party]][, topic_irf])) +
            geom_pointrange(col = "red") +
            geom_hline(yintercept = 0, col = "black") +
            theme_minimal() +
            labs(x = "Lag", y = "IRF") +
            ggtitle(paste0(party, " ~ ", topic_irf))
png(str_c("plots/var/", party, "_", topic_irf, "_irf.png"))
print(p)
dev.off()

## mig_sal - afd
p <- ggplot(data = NULL,
        aes(x = seq_len(nrow(ifun$irf[[topic_irf]])), 
            y = ifun$irf[[topic_irf]][, party],
            ymin = ifun$Lower[[topic_irf]][, party],
            ymax = ifun$Upper[[topic_irf]][, party])) +
            geom_pointrange(col = "red") +
            geom_hline(yintercept = 0, col = "black") +
            theme_minimal() +
            labs(x = "Lag", y = "IRF") +
            ggtitle(paste0(topic_irf, " ~ ", party))
png(str_c("plots/var/", topic_irf, "_", party, "_irf.png"))
print(p)
dev.off()
