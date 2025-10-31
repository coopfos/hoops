library(dplyr)
library(tidyr)
library(stringr)
library(purrr)

qcols <- grep("^q[1-4]_p[1-6]$", names(bs_pres), value = TRUE)

oncourt <- bs_pres %>%
  pivot_longer(all_of(qcols),
               names_to = c("quarter","part"),
               names_pattern = "q(\\d)_p(\\d)",
               values_to = "on") %>%
  filter(on == 1) %>%
  mutate(quarter = as.integer(quarter),
         part    = as.integer(part))

candidate_stats <- c("pts","trb","orb","drb","ast","stl","blk","tov","fg","fga","fg_pct","x3p","x3pa","ft","fta","pf")
stat_cols <- intersect(candidate_stats, names(oncourt))

base_cols <- c("game_id","pid","team_code","quarter","part")
oncourt_small <- oncourt %>%
  select(any_of(c("game_id","pid","team_code","quarter","part", stat_cols))) %>%
  mutate(across(all_of(stat_cols), readr::parse_number))

pairs <- oncourt_small %>%
  inner_join(oncourt_small,
             by = c("game_id","quarter","part"),
             suffix = c(".x",".y")) %>%
  filter(pid.x != pid.y) %>%
  mutate(relation = if_else(team_code.x == team_code.y, "teammate", "opponent"))

corr_same_stat <- map_dfr(stat_cols, function(s) {
  x <- pairs[[paste0(s,".x")]]
  y <- pairs[[paste0(s,".y")]]
  tibble(
    stat = s,
    n    = sum(!is.na(x) & !is.na(y)),
    r_teammate = suppressWarnings(cor(x[pairs$relation=="teammate"],
                                      y[pairs$relation=="teammate"],
                                      use = "pairwise.complete.obs")),
    r_opponent = suppressWarnings(cor(x[pairs$relation=="opponent"],
                                      y[pairs$relation=="opponent"],
                                      use = "pairwise.complete.obs"))
  )
}) %>%
  arrange(desc(pmax(abs(r_teammate), abs(r_opponent), na.rm = TRUE)))

bs <- read.csv('/users/coop/desktop/hoops/rolled_basic.csv')

numeric_stats <- c("pts","trb","orb","drb","ast","stl","blk","tov",
                   "fg","fga","fg_pct","fg_3","fga_3","fg_3_pct",
                   "ft","fta","ft_pct","plus_minus")

stat_cols <- intersect(numeric_stats, names(df))

players <- read.csv('/users/coop/desktop/hoops/players.csv')

bs <- players %>% 
  select(pid, Player) %>% 
  right_join(bs, by = c('Player' = 'player'))

bs <- bs %>%
  mutate(across(all_of(stat_cols), readr::parse_number))

# teammate pairs within same team across games
pairs <- bs %>%
  inner_join(bs, by = c('game_id', "team_code"), suffix = c('.x', '.y')) %>%
  filter(pid.x != pid.y)

pairs <- pairs %>% 
  filter(!(mp.y == "Did Not Play") |
           !(mp.x == "Did Not Play"))

# function: player-level correlation per stat
player_pair_corr <- function(stat = "pts") {
  sx <- paste0(stat, ".x"); sy <- paste0(stat, ".y")
  pairs %>%
    filter(!is.na(.data[[sx]]), !is.na(.data[[sy]])) %>%
    mutate(
      xnum = suppressWarnings(as.numeric(.data[[sx]])),
      ynum = suppressWarnings(as.numeric(.data[[sy]]))
    ) %>%
    group_by(pid.x, pid.y) %>%
    summarise(r = suppressWarnings(cor(xnum, ynum, use = "pairwise.complete.obs")),
              n = n(),
              .groups = "drop") %>%
    arrange(desc(abs(r)))
}



# Example: top teammate comovements
top_pts  <- player_pair_corr("pts")
top_ast  <- player_pair_corr("ast")  %>% head(20)
top_trb  <- player_pair_corr("trb")  %>% head(20)
