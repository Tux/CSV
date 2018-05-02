#!perl6

use v6;

use Text::CSV;
use Test;

my $csv = Text::CSV.new;

my $s = <1,"\x[10fffd]xE0""\x[336]",3>; #"
ok($csv.parse($s), "Parse");
