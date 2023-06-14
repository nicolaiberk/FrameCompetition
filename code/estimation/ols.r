# ols model frames vs salience
library(dplyr)
library(tidyverse)
library(data.table)
library(here)

## parameters
first_difference <- TRUE
outlier_removal <- TRUE

if (first_difference){
    merged <- 
        merged %>%
        ungroup() %>%
        mutate(
            across(AfD:lag_neg_tot, ~ .x - lag(.x))
        )

}

merged <- 
    merged %>%
    mutate(across(AfD:lag_neg_tot, ~ scale(.x), .names = "{.col}_scaled"))




## ols
m_sal_lin <-
    lm(LINKE  ~ lag_mig_sal, data = merged %>%
        filter(if_all(c(LINKE_scaled, lag_mig_sal_scaled), ~ ((.x < 3 & .x > -3) | !outlier_removal))))
        # keep IF(NOT(OUTLIER) OR NOT(REMOVAL))
m_sal_gru <- 
    lm(GRUENE ~ lag_mig_sal, data = merged  %>%
        filter(if_all(c(GRUENE_scaled, lag_mig_sal_scaled), ~ ((.x < 3 & .x > -3) | !outlier_removal))))
m_sal_spd <- lm(SPD    ~ lag_mig_sal, data = merged %>%
                filter(if_all(c(SPD_scaled, lag_mig_sal_scaled), ~  ((.x < 3 & .x > -3) | !outlier_removal))))
m_sal_fdp <- lm(FDP    ~ lag_mig_sal, data = merged %>% 
                filter(if_all(c(FDP_scaled, lag_mig_sal_scaled), ~  ((.x < 3 & .x > -3) | !outlier_removal))))
m_sal_cdu <- lm(Union  ~ lag_mig_sal, data = merged %>% 
                filter(if_all(c(Union_scaled, lag_mig_sal_scaled), ~  ((.x < 3 & .x > -3) | !outlier_removal))))
m_sal_afd <- lm(AfD    ~ lag_mig_sal, data = merged %>% 
                filter(if_all(c(AfD_scaled, lag_mig_sal_scaled), ~  ((.x < 3 & .x > -3) | !outlier_removal))))

ms <-
    # modelsummary::modelsummary(
        list(
            "LINKE" = m_sal_lin, 
            "GRUENE" = m_sal_gru, 
            "SPD" = m_sal_spd, 
            "FDP" = m_sal_fdp, 
            "UNION" = m_sal_cdu, 
            "AFD" = m_sal_afd)
    #     stars = T, 
    #     coef_map = list("(Intercept)" = "(Intercept)", "lag_mig_sal" = "Migration Salience (Lag)"),
    #     gof_map = c("nobs", "r.squared")
    # )

save(
    ms,
    file = here(
            paste0(
                "models/ols/salience_", 
                ifelse(first_difference, "delta_", ""),
                ifelse(outlier_removal, "outrem", ""),
                ".RData"
                )
            )
    )

## valence fine
m_fra_lin <- lm(LINKE  ~ lag_vpositive + lag_positive + lag_negative + lag_vnegative, 
            data = merged %>% 
            filter(if_all(c(LINKE_scaled, lag_vpositive_scaled, lag_positive_scaled, lag_negative_scaled, lag_vnegative_scaled), ~  ((.x < 3 & .x > -3) | !outlier_removal))))
m_fra_gru <- lm(GRUENE ~ lag_vpositive + lag_positive + lag_negative + lag_vnegative, 
            data = merged %>%
            filter(if_all(c(GRUENE_scaled, lag_vpositive_scaled, lag_positive_scaled, lag_negative_scaled, lag_vnegative_scaled), ~  ((.x < 3 & .x > -3) | !outlier_removal))))
m_fra_spd <- lm(SPD    ~ lag_vpositive + lag_positive + lag_negative + lag_vnegative, 
            data = merged %>%
            filter(if_all(c(SPD_scaled, lag_vpositive_scaled, lag_positive_scaled, lag_negative_scaled, lag_vnegative_scaled), ~  ((.x < 3 & .x > -3) | !outlier_removal))))
m_fra_fdp <- lm(FDP    ~ lag_vpositive + lag_positive + lag_negative + lag_vnegative, 
            data = merged %>%
            filter(if_all(c(FDP_scaled, lag_vpositive_scaled, lag_positive_scaled, lag_negative_scaled, lag_vnegative_scaled), ~  ((.x < 3 & .x > -3) | !outlier_removal))))
m_fra_cdu <- lm(Union  ~ lag_vpositive + lag_positive + lag_negative + lag_vnegative, 
            data = merged %>%
            filter(if_all(c(Union_scaled, lag_vpositive_scaled, lag_positive_scaled, lag_negative_scaled, lag_vnegative_scaled), ~  ((.x < 3 & .x > -3) | !outlier_removal))))
m_fra_afd <- lm(AfD    ~ lag_vpositive + lag_positive + lag_negative + lag_vnegative, 
            data = merged %>%
            filter(if_all(c(AfD_scaled, lag_vpositive_scaled, lag_positive_scaled, lag_negative_scaled, lag_vnegative_scaled), ~  ((.x < 3 & .x > -3) | !outlier_removal))))

ms <- 
    list(
        "LINKE" = m_fra_lin, 
        "GRUENE" = m_fra_gru, 
        "SPD" = m_fra_spd, 
        "FDP" = m_fra_fdp, 
        "UNION" = m_fra_cdu, 
        "AFD" = m_fra_afd)

save(
    ms,
    file = here(
            paste0(
                "models/ols/valence_fine_", 
                ifelse(first_difference, "delta_", ""),
                ifelse(outlier_removal, "outrem", ""),
                ".RData"
                )
            )
    )


## valence coarse
m_fra_lin <- lm(LINKE  ~ lag_pos_tot + lag_neg_tot,
            data = merged %>% 
            filter(if_all(c(LINKE_scaled, lag_vpositive_scaled, lag_positive_scaled, lag_negative_scaled, lag_vnegative_scaled), ~  ((.x < 3 & .x > -3) | !outlier_removal))))
m_fra_gru <- lm(GRUENE ~ lag_pos_tot + lag_neg_tot, 
            data = merged %>%
            filter(if_all(c(GRUENE_scaled, lag_vpositive_scaled, lag_positive_scaled, lag_negative_scaled, lag_vnegative_scaled), ~  ((.x < 3 & .x > -3) | !outlier_removal))))
m_fra_spd <- lm(SPD    ~ lag_pos_tot + lag_neg_tot, 
            data = merged %>%
            filter(if_all(c(SPD_scaled, lag_vpositive_scaled, lag_positive_scaled, lag_negative_scaled, lag_vnegative_scaled), ~  ((.x < 3 & .x > -3) | !outlier_removal))))
m_fra_fdp <- lm(FDP    ~ lag_pos_tot + lag_neg_tot, 
            data = merged %>%
            filter(if_all(c(FDP_scaled, lag_vpositive_scaled, lag_positive_scaled, lag_negative_scaled, lag_vnegative_scaled), ~  ((.x < 3 & .x > -3) | !outlier_removal))))
m_fra_cdu <- lm(Union  ~ lag_pos_tot + lag_neg_tot, 
            data = merged %>%
            filter(if_all(c(Union_scaled, lag_vpositive_scaled, lag_positive_scaled, lag_negative_scaled, lag_vnegative_scaled), ~  ((.x < 3 & .x > -3) | !outlier_removal))))
m_fra_afd <- lm(AfD    ~ lag_pos_tot + lag_neg_tot, 
            data = merged %>%
            filter(if_all(c(AfD_scaled, lag_vpositive_scaled, lag_positive_scaled, lag_negative_scaled, lag_vnegative_scaled), ~  ((.x < 3 & .x > -3) | !outlier_removal))))


ms <- 
    list(
        "LINKE" = m_fra_lin,
        "GRUENE" = m_fra_gru, 
        "SPD" = m_fra_spd, 
        "FDP" = m_fra_fdp, 
        "UNION" = m_fra_cdu, 
        "AFD" = m_fra_afd)

save(
    ms,
    file = here(
            paste0(
                "models/ols/valence_coarse_",
                ifelse(first_difference, "delta_", ""),
                ifelse(outlier_removal, "outrem", ""),
                ".RData"
                )
            )
    )

