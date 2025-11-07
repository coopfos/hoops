library(dplyr)
library(broom)

pts <- bs_avg5 %>% 
  select(game_id, date, pid, Player, team_code, mp, pts, pts_avg5) %>% 
  mutate(pts_diff = pts - pts_avg5)

pts_pairs <- pts %>% 
  inner_join(pts, by = c('game_id', 'team_code'), suffix = c('.x', '.y'))

pts_pairs_filt <- pts_pairs %>% 
  filter(!(is.na(pts_diff.x)) &
           !(is.na(pts_diff.y)))

pts_pairs_filt <- pts_pairs_filt %>% 
  filter(pid.x != pid.y)

pair_r2 <- pts_pairs_filt %>%
  group_by(pid.x, pid.y) %>%
  summarise(
    n = n(),
    r2 = summary(lm(pts_diff.y ~ pts_diff.x))$r.squared,
    .groups = "drop"
  )

pair_corr <- pts_pairs_filt %>%
  group_by(pid.x, pid.y) %>%
  summarise(
    n = n(),
    corr = cor(pts_diff.x, pts_diff.y, use = "pairwise.complete.obs"),
    r2 = corr^2,
    .groups = "drop"
  )

pair_corr