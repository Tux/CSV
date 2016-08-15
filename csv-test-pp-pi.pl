#!/usr/bin/perl

use strict;
use warnings;

use Text::CSV_PP;

my @rows;
my $csv = Text::CSV_PP->new ({ binary => 1, auto_diag => 1 } )
    or die "Cannot use CSV: ", Text::CSV->error_diag ();

my $sum = 0;
while (my $row = $csv->getline (*ARGV)) {
    $sum += scalar @$row;
    }
print "$sum\n";
