#!/usr/bin/Rscript
csv <- read.csv ("/dev/stdin", header=FALSE)
# TODO: make this actually count the fields instead of this fudge.
print (nrow (csv) * ncol (csv))
