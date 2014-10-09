#!/pro/bin/perl

use 5.16.2;
use warnings;

use Pegex::CSV;

local $/;
my $sum = 0;
for (@{Pegex::CSV->load (<>)}) {
    $sum += scalar @$_;
    }
say $sum;
