library(tidyverse)
library(dplyr)

## load data
var_results <- read.csv("data/processed/estimation/var_results.csv")

## topics
top_topics <- 
    c(
        "AfD Topic", "Refugee Arrival", "Arrival in Munich", 
        "Attacks on Refugee Homes", "Schengen Border Control", 
        "Refugee Crime", "Deportation", 
        "Police Action Against Human Trafficking", 
        "Labor Market", "Humanitarian Crisis Mediterranean", 
        "Syrian Civil War", "Welfare Migration"
        )
dict_topics <- 
    c(
        "ext_afd", "ext_arrival", "ext_attacks", 
        "ext_borders", "ext_crime", "ext_deportation", 
        "ext_humantrafficking", "ext_labormarket", 
        "ext_mediterraneancrisis", "ext_welfare"
    )

## plot topic estimates
var_results %>%
    filter(aggregation == "ym",
           topic %in% top_topics) %>%
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

## plot dict estimates
## plot
var_results %>%
    filter(aggregation == "ym",
           topic %in% dict_topics) %>%
    mutate(topic = str_replace(topic, "ext_", "")) %>%
    mutate(topic = toupper(topic)) %>%
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

ggsave(filename = "plots/var_top_dicts.svg", width = 15, height = 10)




## plot all estimates sorted by effect size per party
for (p in unique(var_results$party)){
    var_results %>%
        filter(topic_metric == "association",
               aggregation == "ym",
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



