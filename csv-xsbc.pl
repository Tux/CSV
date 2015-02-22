#!/usr/bin/perl

use strict;
use warnings;

use Text::CSV_XS;

my @rows;
my $csv = Text::CSV_XS->new ({ binary => 1, auto_diag => 1 } )
    or die "Cannot use CSV: ", Text::CSV->error_diag ();

my $row = $csv->getline (*ARGV);
my @row = @$row;
my $n   = scalar @row;
my $sum = $n;
$csv->bind_columns (\(@row));
while ($csv->getline (*ARGV)) {
    $sum += $n;
    }
print "$sum\n";
