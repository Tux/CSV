#!/usr/bin/perl

use strict;
use warnings;

use Text::CSV::Easy_XS qw(csv_parse);

my $sum = 0;
while (my $line = <>) {
    my @row = csv_parse ($line);
    $sum += @row;
    }
print "$sum\n";
