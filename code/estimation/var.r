# run var for all party-topic combinations

## setup
library(tidyverse)
library(vars)
source("code/functions/var_topic.r")
# source("code/functions/var_prep.r")

## load parties and topics
merged <- data.table::fread("data/processed/media/merged.csv")

parties <- 
    merged %>% 
    dplyr::select(AfD:Union) %>% 
    dplyr::select(-PIRATEN) %>%
    colnames()

topics <-
    merged %>% 
    dplyr::select(contains("Association")) %>% 
    dplyr::select(!contains("Stock Market")) %>%
    colnames() %>%
    str_replace("Association \\(reduced\\): ", "") %>%
    str_replace("Association ", "")

rm(merged)

## run var for all party-topic combinations
var_results <-
    expand.grid(

        ## inputs
        topic = topics,
        party = parties,
        controls = NA,
        aggregation = c("yw", "ym", "yq"),
        topic_metric = c("association", "share", "absolute"),
        
        ## outputs
        point_party_dv = NA,
        lower_party_dv = NA,
        upper_party_dv = NA,
        
        point_topic_dv = NA,
        lower_topic_dv = NA,
        upper_topic_dv = NA,

        stringsAsFactors = F
    ) %>%
    mutate(
        lag_max =
            case_when(
                aggregation == "yw" ~ 12,
                aggregation == "ym" ~ 12,
                aggregation == "yq" ~ 4,
                aggregation == "date" ~ 30
            )
    )

for (i in seq_len(nrow(var_results))) {

    print(paste(i, "/", nrow(var_results)))



    var_raw <-
        var_topic(
            party = var_results$party[i],
            topic = var_results$topic[i],
            aggregation = var_results$aggregation[i],
            topic_metric = var_results$topic_metric[i],
            controls = var_results$controls[i],
            max_lag = var_results$lag_max[i],
            plot_var = FALSE
        )

    var_results[i, c("point_party_dv", "lower_party_dv", "upper_party_dv")] <-
        var_raw$`poll ~ topic`

    var_results[i, c("point_topic_dv", "lower_topic_dv", "upper_topic_dv")] <-
        var_raw$`topic ~ poll`
}


## save results
write.csv(var_results, "data/processed/estimation/var_results.csv", row.names = F)