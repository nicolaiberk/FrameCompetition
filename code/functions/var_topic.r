## estimate var model poll ~ topic
var_topic <-
    function(
        topic,
        party,
        controls = NA,
        max_lag = 12,
        topic_metric = "association",
        aggregation = "ym",
        plot_var = FALSE) {

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
            across(`AfD Topic`:`Young Refugees`, ~sum(.x, na.rm = T)),
            across(`(ot) Abschiebung 1`:`(ot) Koalitionsstreit über Transitzonen`, ~sum(.x, na.rm = T))
        ) %>%
        mutate(
            year = year(date),
            week = week(date),
            wday = wday(date)
            )

    ## define topic metric
    if(topic_metric == "association") {
        if (grepl(topic, pattern = "\\(ot\\)")) {
            topic_var <- paste0("Association ", topic)
        } else {
            topic_var <- paste0("Association (reduced): ", topic)
        }
    }
                    

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
        lag.max = max_lag,
        type = "trend")
    
    ## run var
    m <- do.call(vars::VAR, args)
    ifun <- vars::irf(m, cum = T)

    ## return results

    # define topic varname
    topic_irf <- str_replace_all(topic_var, "[\\(\\)\\:\\s\\,\\-\\'\\&]", ".")

    # get estimate according to chosen lag
    point_dv_party <- ifun$irf[[party]][[min(m$p, nrow(ifun$irf[[party]])), topic_irf]]
    lower_dv_party <- ifun$Lower[[party]][[min(m$p, nrow(ifun$irf[[party]])), topic_irf]]
    upper_dv_party <- ifun$Upper[[party]][[min(m$p, nrow(ifun$irf[[party]])), topic_irf]]


    point_dv_topic <- ifun$irf[[topic_irf]][[min(m$p, nrow(ifun$irf[[topic_irf]])), party]]
    lower_dv_topic <- ifun$Lower[[topic_irf]][[min(m$p, nrow(ifun$irf[[topic_irf]])), party]]
    upper_dv_topic <- ifun$Upper[[topic_irf]][[min(m$p, nrow(ifun$irf[[topic_irf]])), party]]


    return(
        list(
            "poll ~ topic" =
                list(
                    "point" = point_dv_party,
                    "lower" = lower_dv_party,
                    "upper" = upper_dv_party
                ),
            "topic ~ poll" =
                list(
                    "point" = point_dv_topic,
                    "lower" = lower_dv_topic,
                    "upper" = upper_dv_topic
                )
        )
    )

}
