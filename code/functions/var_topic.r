## estimate var model poll ~ topic
var_topic <-
    function(
        topic,
        party,
        controls = NA,
        max_lag = 12,
        topic_metric = "association",
        aggregation = "date") {

    ## load data
    merged <- data.table::fread("data/processed/media/merged.csv")

    ## aggregate data
    merged_agg <-
        merged %>%
        mutate(
            yw = floor_date(date, "week"),
            ym = floor_date(date, "month"),
            yq = floor_date(date, "quarter")
        ) %>%
        group_by(.data[[aggregation]]) %>%
        summarize(
            date = min(date),
            mig_sal = sum(mig_sal),
            crime_sv = sum(crime_label),
            across(contains("Assoc"), ~mean(.x, na.rm = T)),
            across(AfD:Union, ~mean(.x, na.rm = T)),
            across(`AfD Topic`:`Young Refugees`, ~sum(.x, na.rm = T)),
            across(`(ot) Abschiebung 1`:`(ot) Koalitionsstreit über Transitzonen`, ~sum(.x, na.rm = T)),
            across(ext_afd:ext_welfare, ~sum(.x, na.rm = T))
        ) %>%
        mutate(
            year = year(date),
            week = week(date),
            wday = wday(date)
            )

    ## rename columns
    colnames(merged_agg) <-
        str_replace(colnames(merged_agg), "\\(ot\\)", "ot")

    ## define topic metric
    # consider moving average for frame prevalence to deal with noisiness
    if(topic_metric == "association") {
        if (grepl(topic, pattern = "\\bot\\s")) {
            topic_var <- str_replace(topic, "\\bot", "ot\\:")
            topic_var <- paste0("Association ", topic_var)
        } else {
            topic_var <- paste0("Association (reduced): ", topic)
        }
    }else{
        # consider logging count
        topic_var <- topic
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

    ## define control variables
    if (!is.na(controls)) {
        control_merged_agg <- merged_agg[, controls]
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
    ifun <- vars::irf(m, cum = T, n.ahead = m$p, n.boot = 1000)

    ## return results

    # define topic varname
    topic_irf <- str_replace_all(topic_var, "[\\(\\)\\:\\s\\,\\-\\'\\&]", ".")

    # get estimate according to chosen lag
    point_iv_party <- ifun$irf[[party]][[nrow(ifun$irf[[party]]), topic_irf]]
    lower_iv_party <- ifun$Lower[[party]][[nrow(ifun$irf[[party]]), topic_irf]]
    upper_iv_party <- ifun$Upper[[party]][[nrow(ifun$irf[[party]]), topic_irf]]


    point_iv_topic <- ifun$irf[[topic_irf]][[nrow(ifun$irf[[topic_irf]]), party]]
    lower_iv_topic <- ifun$Lower[[topic_irf]][[nrow(ifun$irf[[topic_irf]]), party]]
    upper_iv_topic <- ifun$Upper[[topic_irf]][[nrow(ifun$irf[[topic_irf]]), party]]


    return(
        list(
            "topic ~ poll" =
                list(
                    "point" = point_iv_party,
                    "lower" = lower_iv_party,
                    "upper" = upper_iv_party
                ),
            "poll ~ topic" =
                list(
                    "point" = point_iv_topic,
                    "lower" = lower_iv_topic,
                    "upper" = upper_iv_topic
                )
        )
    )

}
