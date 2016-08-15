#!/usr/bin/perl

use strict;
use warnings;

use Text::CSV::Easy_PP;

my $sum = 0;
while (my $line = <>) {
    my @row = Text::CSV::Easy_PP::csv_parse ($line);
    $sum += @row;
    }
print "$sum\n";
