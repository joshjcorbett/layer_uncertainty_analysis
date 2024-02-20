# Written by Joshua Corbett based on van Bergen et al. (2015) and the original MATLAB analysis scripts written by Ruben van Bergen
# data processing per individual:
# output is a list with the following components, which is saved as a .rds file:
#   df_full - full data frame with all behaviour, decoder, and bin information for that participant.
#   d2c_bin - bin statistics based on distance to nearest cardinal orientation. Statistics include:
#       a) behavioural bias
#       b) behavioural variability (after bias correction)
#       c) uncertainty estimates for each layer
#       d) decoding error for each layer
#   sup_bin/mid_bin/deep_bin - bin statistics based on uncertainty estimates for superficial, middle, and deep layers, respectively. Statistics include:
#       a) decoding error
#       b) behavioural bias

sub <- Sys.getenv("sub")

# create list that will eventually save everything for the participant
final <- list()

library(tidyverse)
library(here)
source(file = here('scripts/functions.R'))
library(circular)

reported_loc <- paste0(here('data'), '/behaviour/sub-', sub, '/sub-', sub, '_reported.csv')
decoding_loc <- paste0(here('data'), '/decoding/sub-', sub)

reported <- read_csv(reported_loc, col_names=FALSE) %>% select(reported = X1)

sup <- list.files(decoding_loc, pattern = 'sup', full.names=TRUE) %>%
  lapply(read_csv, col_names=FALSE) %>%
  bind_rows %>%
  select(ori = X1, est = X2, unc = X3)

mid <- list.files(decoding_loc, pattern = 'mid', full.names=TRUE) %>%
  lapply(read_csv, col_names=FALSE) %>%
  bind_rows %>%
  select(ori = X1, est = X2, unc = X3)

deep <- list.files(decoding_loc, pattern = 'deep', full.names=TRUE) %>%
  lapply(read_csv, col_names=FALSE) %>%
  bind_rows %>%
  select(ori = X1, est = X2, unc = X3)

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

# create empty vector of corrected behavioural errors
be_c <- rep(NA, length(oris)) # any trials where error was greater than 3 SD was ignored

# fit first polynomial: trials with oris in range [0,90) and behavioural errors less than 3 SDs above the mean
mod1 <- lm(be_s[ori < 90 & be_a < b_cut] ~ poly(ori[ori < 90 & be_a < b_cut], 4), data=df_error)
# second polynomial with oris in range [90, 180)
mod2 <- lm(be_s[ori >= 90 & be_a < b_cut] ~ poly(ori[ori >= 90 & be_a < b_cut], 4), data=df_error)

# corrected values as the residuals of the model
be_c[df_error$ori < 90 & df_error$be_a < b_cut] <- residuals(mod1)
be_c[df_error$ori >= 90 & df_error$be_a < b_cut] <- residuals(mod2)

# add back as a column to our dataframe
df_corr <- cbind(df_error, be_c)

# note the nearest cardinal and calculate the distance to that cardinal
df_d2c <- df_corr %>%
  mutate(c_card = sapply(ori, closest_card)) %>% # c_card = closest cardinal orientation
  mutate(d2c = abs(ori - c_card)) # d2c = distance to closest cardinal orientation

# calculate bias (behavioural error in the direction opposite to the nearest cardinal)
df_bias <- df_d2c %>%
  mutate(bias = (be_s)*sign(ori - c_card)) # multiple by 'sign' to account for the fact that the nearest cardinal could be either clockwise or anticlockwise

# calculate decoding error for each layer
dec_sup <- sup %>% rowwise() %>% mutate(de_s = circular_diff(ori, est)[1]) %>% ungroup() %>% select(est_s = est, unc_s = unc, de_s)
dec_mid <- mid %>% rowwise() %>% mutate(de_m = circular_diff(ori, est)[1]) %>% ungroup() %>% select(est_m = est, unc_m = unc, de_m)
dec_deep <- deep %>% rowwise() %>% mutate(de_d = circular_diff(ori, est)[1]) %>% ungroup() %>% select(est_d = est, unc_d = unc, de_d)

df_dec <- cbind(df_bias, dec_sup, dec_mid, dec_deep)

# trials where absolute behavioural error is greater than 3 sds shouldn't be included in any analysis, so make the variables of interest NA for these trials
df_dec$unc_s[df_dec$be_a > b_cut] = NA
df_dec$unc_m[df_dec$be_a > b_cut] = NA
df_dec$unc_d[df_dec$be_a > b_cut] = NA
df_dec$est_s[df_dec$be_a > b_cut] = NA
df_dec$est_m[df_dec$be_a > b_cut] = NA
df_dec$est_d[df_dec$be_a > b_cut] = NA
df_dec$d2c[df_dec$be_a > b_cut] = NA

# create bins for distance to cardinal and uncertainty (for each layer)
# 'ntile' command 'Creates groups where the groups each have as close to the same number of members as possible.'
df_bin <- df_dec %>%
  mutate(d2c_bin = ntile(d2c, 4), # binning based on distance to nearest cardinal orientation
         unc_s_bin = ntile(unc_s, 4), # binning based on uncertainty for each layer
         unc_m_bin = ntile(unc_m, 4),
         unc_d_bin = ntile(unc_d, 4))

final$df_full <- df_bin

# paste("mean of sup decoding", mean(df_bin$de_s))
# paste("mean of mid decoding", mean(df_bin$de_m))
# paste("mean of deep decoding", mean(df_bin$de_d))

sub_bin_vec <- rep(sub, 4)

unc_s_bins <- df_bin %>%
  filter(!is.na(unc_s_bin)) %>%
  group_by(unc_s_bin) %>%
  summarise(mean_unc = mean(unc_s),
            de = mean(de_s), # mean decoding error for each bin
            bias = mean(bias), # mean bias for each bin
            b_var = circular_sample_sd(be_c), # behavioural variability for each bin
            de_var = circular_sample_sd(de_s)) %>% # circ stdev of decoding errors per bin
  ungroup()

final$sup_bin <- cbind(sub=sub_bin_vec, unc_s_bins)

unc_m_bins <- df_bin %>%
  filter(!is.na(unc_m_bin)) %>%
  group_by(unc_m_bin) %>%
  summarise(mean_unc = mean(unc_m),
            de = mean(de_m), # mean decoding error for each bin
            bias = mean(bias), # mean bias for each bin
            b_var = circular_sample_sd(be_c), # behavioural variability for each bin
            de_var = circular_sample_sd(de_m)) %>% # circ stdev of decoding errors per bin
  ungroup()

final$mid_bin <- cbind(sub=sub_bin_vec, unc_m_bins)

unc_d_bins <- df_bin %>%
  filter(!is.na(unc_d_bin)) %>%
  group_by(unc_d_bin) %>%
  summarise(mean_unc = mean(unc_d),
            de = mean(de_d), # mean decoding error for each bin
            bias = mean(bias), # mean bias for each bin
            b_var = circular_sample_sd(be_c), # behavioural variability for each bin
            de_var = circular_sample_sd(de_d)) %>% # circ stdev of decoding errors per bin
  ungroup()

final$deep_bin <- cbind(sub=sub_bin_vec, unc_d_bins)

d2c_bins <- df_bin %>%
  filter(!is.na(unc_s_bin)) %>%
  group_by(d2c_bin) %>%
  summarise(mean_unc_s = mean(unc_s, na.rm=TRUE),
            mean_unc_m = mean(unc_m, na.rm=TRUE),
            mean_unc_d = mean(unc_d, na.rm=TRUE),
            mean_d2c = mean(d2c, na.rm=TRUE),
            mean_bias = mean(bias, na.rm=TRUE),
            b_var = circular_sample_sd(be_c)) %>%
  ungroup()

final$d2c_bin <- cbind(sub=sub_bin_vec, d2c_bins)

output_file=paste0(here('data/processed'), '/sub-', sub, '_processed.rds')
saveRDS(final, output_file)