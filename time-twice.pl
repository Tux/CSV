#!/pro/bin/perl

use 5.18.2;
use warnings;

$| = 1;

my $v;
my %t;
my %seen;
foreach my $i (1, 2) {
    open my $th, "-|", "time.pl";
    while (<$th>) {
        if (m/^(\S+\s+\S+)\s+(?:\**\s+)?\d/) {
            print $seen{$1}++ ? "." : $_;
            next;
            }
        # print;
        m/^This is/ and $v //= $_;
        m/^(\S+)\s+(\d[.\d]+)$/ or next;
        push @{$t{$1}}, $2;
        }
    }

say "";
print $v;
foreach my $t (qw( csv-ip5xs test test-t csv-parser )) {
    my @t = sort { $a <=> $b } @{$t{$t}};
    printf "%-15s %s\n", $t, join " - " => map { sprintf "%6.3f", $_ } @t[0,-1];
    }
