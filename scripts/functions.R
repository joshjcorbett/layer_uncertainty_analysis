circular_diff <- function(x, y){
  # calculates the circular difference (in degrees) between two orientations in range [0, 180)
  # output is a 2 column (absolute and signed) x 1 row dataframe
  # the first output value is the absolute difference, and the second value is the signed difference
  # positive values in signed error means that y is clockwise relative to x
  
  # first make sure both inputs are in range [0, 180)
  x <- x %% 180
  y <- y %% 180
  
  # get absolute (unsigned) error
  error1 <- abs(x - y)
  error2 <- abs( abs(x - y) - 180)
  abs_diff <- min(error1, error2)
  
  # get signed error
  sign <- sign(y - x)
  greater_than_90 <- sign(90 - abs(y - x)) # if the size of the error is greater than 90, then the error is in the opposite direction to the sign
  if (greater_than_90 == 0){greater_than_90 = 1} # for the rare case where the difference is exactly 90
  signed_diff <- abs_diff*sign*greater_than_90
  
  diff <- rbind(abs_diff, signed_diff)
  
  return(diff)
}

circular_sample_sd <- function(angles){
  # takes a vector of angles (in degrees) and returns the circular sd (in degrees)
  
  # first make sure inputs are in range [0, 180)
  angles <- angles %% 180
  
  # then convert to radians
  angles <- angles*2*pi/180
  
  n <- length(angles) # no. angles in the vector

  # get angular deviation using the circular statistics toolbox in R
  # angular deviation used for consistency with Van Bergen et al., 2015 and the matlab default
  if (n == 1) {s = 0
  print('WARNING: Only one angle found, check this is right.')
  } else {

  s = angular.deviation(angles)
  
  # want sample sd, rather than population sd - adjust accordingly
  s = s*n/(n-1) 
  
  # convert back to degrees
  s = s*180/(2*pi)
  }
  
  return(s)
}

closest_card <- function(ori) {
  # function finds which cardinal orientation is closest to the input orientation, where the cardinals are 0, 90, and 180 degrees.
  
  # note the cardinals
  cardinals <- c(0, 90, 180)
  
  # find the closest cardinal
  closest <- cardinals[which.min(abs(cardinals - ori))]
  
  return(closest)
}