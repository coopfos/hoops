library(dplyr)
library(lubridate)

setwd('/users/cooperfoster/desktop/hoops')

codes <- read.csv('team_codes.csv')
games_dirty <- read.csv('games_dirty.csv')

games_dirty$date1 <- as.Date(games_dirty$date, format = "%a %b %d %Y")

games <- games_dirty %>% 
  select(date1, visitor, home, ptsV, ptsH)

games <- codes %>% 
  right_join(games, by = c("team" = "visitor")) %>% 
  rename(visitor_code = code,
         visitor = team)
games <- codes %>% 
  right_join(games, by = c("team" = "home")) %>% 
  rename(home_code = code,
         home = team)

games <- games %>% 
  rename(date = date1)

games <- games %>%
  mutate(
    game_id = paste0(
      format(as.Date(date), "%Y%m%d"), # YYYYMMDD
      "0",
      home_code                      # team code
    )
  )

