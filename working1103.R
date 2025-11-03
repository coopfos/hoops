library(dplyr)
library(slider)
library(lubridate)
library(data.table)

games <- read.csv('/users/cooperfoster/desktop/hoops/game_log.csv')

games$date <- mdy(games$date)

bs <- games %>% 
  select(game_id, date) %>% 
  right_join(bs, by = 'game_id')


setDT(bs)
bs[, date := as.IDate(date)]  # if not already Date

# choose stat columns that you want rolling means for
stat_cols <- intersect(c(
  "fg","fga","fg_3","fga_3",
  "ft","fta","orb","drb","trb",
  "ast","stl","blk","pts","plus_minus"
), names(bs))

# coerce to numeric (blank/NA/DNP strings become NA)
for (v in stat_cols) bs[, (v) := as.numeric(gsub("[^0-9\\.-]", "", get(v)))]

# flag appearances that count as "played"
# basketball-reference DNP/DND/Inactive/NWT/Suspended live in `mp`
dnp_tokens <- unique(vals)
bs[, played := grepl(":", mp) & !(mp %chin% dnp_tokens)]

# ---- 1) rolling 5 prior games among PLAYED rows only
played_dt <- bs[played == TRUE][order(pid, date)]

# compute lagged 5-game means per player (exclude current using shift)
for (v in stat_cols) {
  played_dt[, paste0(v,"_avg5") :=
              frollmean(shift(get(v), 1L), n = 5L, align = "right"),
            by = pid]
}

# keep only keys and the new averages to use as "anchors"
avg_cols <- paste0(stat_cols, "_avg5")
anchor <- played_dt[, c("pid","date", avg_cols), with = FALSE]
setkey(anchor, pid, date)

# ---- 2) as-of rolling join onto ALL rows
setkey(bs, pid, date)
# roll=Inf picks the most recent prior PLAYED game for each row’s date
avg_asof <- anchor[bs, on = .(pid, date), roll = Inf]

# ---- 3) attach averages back to the original table
# avg_asof contains bs columns (prefixed with i.) and the *_avg5 columns from anchor
# keep the original bs plus the *_avg5 fields
keep <- c(names(bs), avg_cols)
bs_avg5 <- avg_asof[, ..keep][order(pid, date)]

