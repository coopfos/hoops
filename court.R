shots <- read.csv('/Users/cooperfoster/Desktop/hoops/all_shots.csv')

shots_na <- shots %>% 
  filter(is.na(top) |
           is.na(left))

# --- 0) Packages
library(ggplot2); library(grid); library(png); library(dplyr)

# --- 1) Load court image and overlay a grid (adjust path)
img <- readPNG("/users/cooperfoster/desktop/hoops/court.png")   # same image your x,y are based on
W  <- dim(img)[2]; H <- dim(img)[1]        # image pixel size

# If your shot coords live in a 0..500 system, rescale grid to 500x500 for reading
target_max <- 500
sx <- target_max / W; sy <- target_max / H

ggplot() +
  annotation_raster(img, xmin=0, xmax=target_max, ymin=0, ymax=target_max*H/W) +
  geom_vline(xintercept = seq(0, target_max, by=25), linewidth=.15) +
  geom_hline(yintercept = seq(0, target_max, by=25), linewidth=.15) +
  coord_fixed(xlim=c(0,target_max), ylim=c(0,target_max*H/W), expand=FALSE) +
  labs(x="x (px)", y="y (px)")