
library(tidyverse)
library(dplyr)
library(data.table)

merged <- 
    fread("data/processed/media/full_ests.csv") %>%
    filter(reduced_topic_label != "Stock Market")

merged %>%
    dplyr::select(date_clean, paper, crime_label, ext_crime, `Association (reduced): Refugee Crime`, reduced_topic_label) %>%
    filter(date_clean <= "2018-12-31") %>%
    mutate(month_date = floor_date(date_clean, "quarter")) %>%
    group_by(month_date, paper) %>%
    summarise(
        crime_label = mean(crime_label, na.rm = TRUE),
        ext_crime = mean(ext_crime >= 5, na.rm = TRUE),
        `Association (reduced): Refugee Crime` = mean(`Association (reduced): Refugee Crime`, na.rm = TRUE),
        reduced_topic_label = mean(reduced_topic_label == "Refugee Crime", na.rm = TRUE),
        mig_sal = n()
    ) %>%
    select(-paper) %>%
    group_by(month_date) %>%
    summarise_all(mean) %>%
    mutate(
        across(!contains("month_date"), scale, )
    ) %>%
    ggplot(aes(x = month_date)) +
    geom_line(aes(y = crime_label, color = "Supervised", lty = "Supervised")) +
    geom_line(aes(y = reduced_topic_label, color = "Topic Model", lty = "Topic Model")) +
    geom_line(aes(y = `Association (reduced): Refugee Crime`, color = "Topic Association", lty = "Topic Association")) +
    geom_line(aes(y = ext_crime, color = "Dictionary", lty = "Dictionary")) +
    scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
    labs(
        color  = "Estimate", linetype = "Estimate", shape = "Estimate",
        x = "Date", y = "Normalized Score"
        ) +
    theme_minimal()

# save
ggsave("plots/crime_estimates.png", width = 10, height = 5)
ggsave("plots/crime_estimates_pres.png", width = 8, height = 5)

# correlation matrix
library(GGally)
ggcorr(
    merged %>%
        dplyr::select(contains("crime") | contains("Krim"), paper, date_clean, reduced_topic_label) %>%
        mutate(id_var = 1:nrow(merged)) %>%
        filter(date_clean <= "2018-12-31") %>%
        group_by(id_var) %>%
        summarise(
            Dictionary = mean(ext_crime >= 5, na.rm = TRUE),
            Topic_Classfication = mean(reduced_topic_label == "Refugee Crime", na.rm = TRUE),
            Topic_Association = mean(`Association (reduced): Refugee Crime`, na.rm = TRUE),
            Supervised = mean(crime_label, na.rm = TRUE)
            ) %>%
            select(Dictionary, Topic_Classfication, Topic_Association, Supervised),
    label = TRUE,
    label_size = 5, label_round = 2)

ggsave("plots/crime_est_cor_doclevel.png", width = 5, height = 5)

ggcorr(
    merged %>%
        dplyr::select(contains("crime") | contains("Krim"), paper, date_clean, reduced_topic_label) %>%
        mutate(month_date = floor_date(date_clean, "month")) %>%
        filter(date_clean <= "2018-12-31") %>%
        group_by(month_date, paper) %>%
        summarise(
            Dictionary = mean(ext_crime >= 5, na.rm = TRUE),
            Topic_Classfication = mean(reduced_topic_label == "Refugee Crime", na.rm = TRUE),
            Topic_Association = mean(`Association (reduced): Refugee Crime`, na.rm = TRUE),
            Supervised = mean(crime_label, na.rm = TRUE)
            ) %>%
        group_by(month_date) %>%
        summarise(
            Dictionary = mean(Dictionary, na.rm = TRUE),
            Topic_Classfication = mean(Topic_Classfication, na.rm = TRUE),
            Topic_Association = mean(Topic_Association, na.rm = TRUE),
            Supervised = mean(Supervised, na.rm = TRUE)
            ) %>%
            select(Dictionary, Topic_Classfication, Topic_Association, Supervised),
    label = TRUE,
    label_size = 5, label_round = 2)

ggsave("plots/crime_est_cor_monthly.png", width = 5, height = 5)
