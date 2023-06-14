library(tidyverse)
library(dplyr)

## load data
var_results <- read.csv("data/processed/estimation/var_results_weekly.csv")

## topics
top_topics <- 
    c(
        "Refugee Arrival", "Arrival in Munich", 
        "Attacks on Refugee Homes", "Schengen Border Control", 
        "Refugee Crime", "Deportation", 
        "Police Action Against Human Trafficking", 
        "Labor Market", "Humanitarian Crisis Mediterranean", 
        "Syrian Civil War", "Welfare Migration", "AfD Topic"
        )
dict_topics <- 
    c(
        "ext_arrival", "ext_attacks", 
        "ext_borders", "ext_crime", "ext_deportation", 
        "ext_humantrafficking", "ext_labormarket", 
        "ext_mediterraneancrisis", "ext_welfare", "ext_afd"
    )




## plot topic estimates
var_results$controls[is.na(var_results$controls)] <- "None"
var_results$controls[var_results$controls == "mig_sal"] <- "Salience"
var_results$controls <- factor(var_results$controls, levels = c("None", "Salience"))

var_results %>%
    filter(aggregation == "yw",
           topic %in% top_topics) %>%
    ggplot(aes(y = topic,
               x = point_topic_iv,
               xmin = lower_topic_iv,
               xmax = upper_topic_iv,
               color = (lower_topic_iv > 0 | upper_topic_iv < 0),
               shape = controls)) +
    geom_vline(xintercept = 0) +
    geom_pointrange(position = position_dodge(width = 0.5)) +
    theme_minimal() +
    theme(legend.position = "bottom") +
    labs(colour = "p < .05", shape = "Controls") +
    facet_grid(~party) +
    ggtitle("Framing")

ggsave(filename = "plots/var/top_topics_weekly.png", width = 10, height = 6)

## plot dict estimates
## plot
var_results %>%
    filter(aggregation == "yw",
           topic %in% dict_topics) %>%
    mutate(topic = str_replace(topic, "ext_", "")) %>%
    mutate(topic = toupper(topic)) %>%
    ggplot(aes(y = topic,
               x = point_topic_iv,
               xmin = lower_topic_iv,
               xmax = upper_topic_iv,
               color = (lower_topic_iv > 0 | upper_topic_iv < 0),
               shape = controls)) +
    geom_vline(xintercept = 0) +
    geom_pointrange(position = position_dodge(width = 0.5)) +
    theme_minimal() +
    theme(legend.position = "bottom") +
    labs(colour = "p < .05", shape = "Controls") +
    facet_grid(~party) +
    ggtitle("Framing (Dictionary)")

ggsave(filename = "plots/var/top_dicts_weekly.png", width = 10, height = 6)




## plot all estimates sorted by effect size per party
for (p in unique(var_results$party)){
    var_results %>%
        filter(topic_metric == "share",
               aggregation == "yw",
               party == p) %>%
        ggplot(aes(x = reorder(topic, -point_topic_iv),
                   y = point_topic_iv, 
                   ymin = lower_topic_iv,
                   ymax = upper_topic_iv,
                   color = (lower_topic_iv > 0 | upper_topic_iv < 0),
                   shape = controls)) +
        geom_hline(yintercept = 0) +
        geom_pointrange(position = position_dodge(width = 0.5)) +
        theme_minimal() +
        theme(
            legend.position = "right",
            axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1)
        ) +
        labs(colour = "p < .05", shape = "Controls") +
        ggtitle(paste0(p, ": Framing")) +
        labs(x = "Topic", y = "Effect Size")
    ggsave(filename = paste0("plots/var/", p, "_topics_weekly.png"), width = 15, height = 8)
}

for (p in unique(var_results$party)){
    var_results %>%
        filter(topic_metric == "share",
               aggregation == "date",
               party == p) %>%
        ggplot(aes(x = reorder(topic, -point_party_iv),
                   y = point_party_iv, 
                   ymin = lower_party_iv,
                   ymax = upper_party_iv,
                   color = (lower_party_iv > 0 | upper_party_iv < 0),
                   shape = controls)) +
        geom_hline(yintercept = 0) +
        geom_pointrange(position = position_dodge(width = 0.5)) +
        theme_minimal() +
        theme(
            legend.position = "right",
            axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1)
        ) +
        labs(colour = "p < .05", shape = "Controls") +
        ggtitle(paste0(p, ": Framing (DV)")) +
        labs(x = "Topic", y = "Effect Size")
    ggsave(filename = paste0("plots/var/", p, "_topics_dv_weekly.png"), width = 15, height = 8)
}

# descriptives/salience 

## load data
merged <- data.table::fread("data/processed/media/merged.csv")

## aggregate data
merged_agg <-
    merged %>%
    group_by(yw) %>%
    summarize(
        date = min(date),
        crime_sv = sum(crime_label),
        mig_sal_raw = sum(mig_sal),
        across(AfD:Union, ~mean(.x, na.rm = T)),
        across(`Association (reduced): Episodic Framing`:`Association (reduced): Swiss Immigration Debate`, ~sum(.x, na.rm = T)),
        across(`AfD Topic`:`Young Refugees`, ~sum(.x, na.rm = T)),
        across(`(ot) Abschiebung 1`:`(ot) Koalitionsstreit über Transitzonen`, ~sum(.x, na.rm = T)),
        across(ext_afd:ext_welfare, ~sum(.x, na.rm = T))
    )

## plot influence of salience - replace with relative salience at some point
VarByParty <- function(
    dta,
    topic,
    partynames = c("AfD", "FDP", "GRUENE", "LINKE", "Union", "SPD"),
    topic_title = "Salience") {

    ests <- data.frame()

    for (p in partynames){

        ## filter missings
        dta_tmp <-
            dta[min((seq_len(nrow(dta)))[!is.na(dta[[p]])]):max((1:nrow(dta))[!is.na(dta[[p]])]),] # drop front and end missing values

        ## interpolate missing values
        dta_tmp[p] <- zoo::na.approx(dta_tmp[p])

        ## filter missings
        dta_tmp <-
            dta_tmp[min((seq_len(nrow(dta_tmp)))[!is.na(dta_tmp[[topic]])]):max((1:nrow(dta_tmp))[!is.na(dta_tmp[[topic]])]),] # drop front and end missing values

        ## interpolate missing values
        dta_tmp[topic] <- zoo::na.approx(dta_tmp[topic])

        ## estimate var
        m <- vars::VAR(dta_tmp[, c(p, topic)], lag.max = 14, type = "trend")
        ifun <- vars::irf(m, cum = T, n.ahead = m$p, n.boot = 1000)

        topic_irf <- str_replace_all(topic, "[\\(\\)\\:\\s\\,\\-\\'\\&]", ".")

        # get estimate according to chosen lag
        ests <- 
            rbind(
                ests,
                data.frame(
                    "party" = p,
                    "topic" = topic,
                    "point_iv_party" = ifun$irf[[p]][[nrow(ifun$irf[[p]]), topic_irf]],
                    "lower_iv_party" = ifun$Lower[[p]][[nrow(ifun$irf[[p]]), topic_irf]],
                    "upper_iv_party" = ifun$Upper[[p]][[nrow(ifun$irf[[p]]), topic_irf]],
                    "point_iv_topic" = ifun$irf[[topic_irf]][[nrow(ifun$irf[[topic_irf]]), p]],
                    "lower_iv_topic" = ifun$Lower[[topic_irf]][[nrow(ifun$irf[[topic_irf]]), p]],
                    "upper_iv_topic" = ifun$Upper[[topic_irf]][[nrow(ifun$irf[[topic_irf]]), p]]
                )
            )
        }

    plt <- ests %>%
        ggplot(
            aes(
                y = party,
                x = point_iv_party,
                xmin = lower_iv_party,
                xmax = upper_iv_party
                )
            ) +
            geom_vline(xintercept = 0) +
            geom_pointrange() +
            theme_minimal() +
            ggtitle(paste0("Effect of ", topic_title, " on Party Support"))

    return(plt)

    }

## run var with salience
VarByParty(merged_agg, "mig_sal_raw", topic_title = "Salience")
ggsave(filename = "plots/var/salience_weekly.png", width = 8, height = 6)

## descriptives with ggplot - move to own file
merged_agg <- 
    merged_agg %>%
    mutate(across(`AfD Topic`:`Young Refugees`, ~.x/mig_sal_raw))

p1  <- 
    ggplot(merged_agg, aes(x = date, y = `Refugee Crime`)) + 
    geom_line() + 
    labs(x = "Date", y = "Prevalence", title = "Refugee Crime") + 
    theme_minimal()


p2  <- 
    ggplot(merged_agg, aes(x = date, y = `Welfare Migration`)) +
    geom_line() +
    labs(x = "Date", y = "Prevalence", title = "Welfare Migration") +
    theme_minimal()

p3 <-  
    ggplot(merged_agg, aes(x = date, y = `Deportation`)) +
    geom_line() +
    labs(x = "Date", y = "Prevalence", title = "Deportation") +
    theme_minimal()

p4 <- 
    ggplot(merged_agg, aes(x = date, y = `Police Action Against Human Trafficking`)) +
    geom_line() +
    labs(x = "Date", y = "Prevalence", title = "Human Trafficking") +
    theme_minimal()

p5 <- 
    ggplot(merged_agg, aes(x = date, y = `Schengen Border Control`)) +
    geom_line() +
    labs(x = "Date", y = "Prevalence", title = "Border Control") +
    theme_minimal()

p6 <-
    ggplot(merged_agg, aes(x = date, y = `Labor Market`)) +
    geom_line() +
    labs(x = "Date", y = "Prevalence", title = "Labor Market") +
    theme_minimal()

p7 <- 
    ggplot(merged_agg, aes(x = date, y = `Humanitarian Crisis Mediterranean`)) +
    geom_line() +
    labs(x = "Date", y = "Prevalence", title = "Humanitarian Crisis Mediterranean") +
    theme_minimal()

p8 <- 
    ggplot(merged_agg, aes(x = date, y = `Attacks on Refugee Homes`)) +
    geom_line() +
    labs(x = "Date", y = "Prevalence", title = "Attacks on Refugee Homes") +
    theme_minimal()


ggpubr::ggarrange(p1, p2, p3, p4, p5, p6, p7, p8, ncol = 4, nrow = 2)
ggsave("plots/descriptives/topics_weekly.png", width = 10, height = 6)
