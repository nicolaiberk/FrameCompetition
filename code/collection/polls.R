## setup
library(tidyverse)
library(jsonlite)

## read data
polls_json <- fromJSON("https://www.politico.eu/wp-json/politico/v1/poll-of-polls/DE-parliament")



## clean
polls_tidy <- 
    polls_json$polls %>%
    flatten() %>%
    as_tibble() %>%
    pivot_longer(cols = -c(date, firm, date_from, sample_size), 
    names_to = "party",
    names_prefix = "parties.", 
    values_to = "value") %>%
    mutate(date = as.Date(date))

## plot
plt <- polls_tidy %>%
    ggplot(aes(x = date, y = value, color = party)) +
    geom_point(alpha = 0.025) +
    geom_smooth() +
    facet_wrap(~party) +
    scale_color_manual(values = 
                        c("lightblue", "yellow", "green",
                        "purple", "orange", "red", "blue")) +
    theme_minimal()

png("plots/polls.png", width = 10, height = 8, units = "in", res = 300)
plt
dev.off()

## save
polls_tidy %>% 
    write_csv("data/processed/polls.csv")
