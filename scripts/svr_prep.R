# Written by Joshua Corbett based on van Bergen et al. (2015) and the original MATLAB analysis scripts written by Ruben van Bergen
# data processing per individual
# output is a tibble with all relevant values

sub <- Sys.getenv("sub")

library(tidyverse)
library(here)
source(file = here('scripts/functions.R'))
library(circular)

reported_loc <- paste0(here('data'), '/behaviour/sub-', sub, '/sub-', sub, '_reported.csv')
reported <- read_csv(reported_loc, col_names=FALSE) %>% select(reported = X1)

svr_loc <- paste0(here('data'), '/svr/sub-', sub)

sup <- list.files(svr_loc, pattern = 'sup', full.names=TRUE) %>%
  lapply(read_csv, col_names=FALSE) %>%
  bind_rows %>%
  select(ori = X1, est = X2)

mid <- list.files(svr_loc, pattern = 'mid', full.names=TRUE) %>%
  lapply(read_csv, col_names=FALSE) %>%
  bind_rows %>%
  select(ori = X1, est = X2)

deep <- list.files(svr_loc, pattern = 'deep', full.names=TRUE) %>%
  lapply(read_csv, col_names=FALSE) %>%
  bind_rows %>%
  select(ori = X1, est = X2)

# first grab the oris from one of the decoding outputs
oris <- sup[,1]

# create a subject id vector the same length as the no. trials
sub_vec <- rep(sub, length(oris))

# combine reported and presented oris into a single tibble
df <- tibble(cbind(sub=sub_vec, oris, reported))

# calculate absolute (be_a) and signed (be_s) behavioural errors
# for signed error, positive values mean that reported is clockwise relative to y
df_error <- df %>% rowwise() %>%
  mutate(be_a = circular_diff(ori, reported)[1],
         be_s = circular_diff(ori, reported)[2]) %>%
  ungroup()

# get the (circular) sd of behavioural errors in degrees
error_sd <- circular_sample_sd(df_error$be_s)
# calculate highest acceptable (absolute) behavioural error for the participant
b_cut <- mean(df_error$be_a) + 3*(error_sd)

# calculate decoding error for each layer
dec_sup <- sup %>% rowwise() %>% mutate(de_s = circular_diff(ori, est)[1]) %>% ungroup() %>% select(est_s = est, de_s)
dec_mid <- mid %>% rowwise() %>% mutate(de_m = circular_diff(ori, est)[1]) %>% ungroup() %>% select(est_m = est, de_m)
dec_deep <- deep %>% rowwise() %>% mutate(de_d = circular_diff(ori, est)[1]) %>% ungroup() %>% select(est_d = est, de_d)

df_dec <- cbind(df_error, dec_sup, dec_mid, dec_deep)

# trials where absolute behavioural error is greater than 3 sds shouldn't be included in any analysis, so make the variables of interest NA for these trials
df_dec$est_s[df_dec$be_a > b_cut] = NA
df_dec$est_m[df_dec$be_a > b_cut] = NA
df_dec$est_d[df_dec$be_a > b_cut] = NA

output_file=paste0(here('data/svr_processed'), '/sub-', sub, '_svr-processed.rds')
saveRDS(df_dec, output_file)