#!/pro/bin/perl

use 5.18.2;
use warnings;

$| = 1;
binmode STDOUT, ":encoding(utf-8)";

my $v;
my %t;
my %seen;
foreach my $i (1, 2) {
    open my $th, "-|", "time.pl";
    binmode $th, ":encoding(utf-8)";
    while (<$th>) {
        if (m/^([^ ]+[ ]+[^ ]+)[ ]+(?:\**[ ]+)?[0-9]/) {
            print $seen{$1}++ ? "." : $_;
            next;
            }
        # print;
        m/^This is/ and $v //= $_;
        my ($s, $t) = m/^(.+?)\s+([0-9][.0-9]+)$/ or next;
        push @{$t{$s =~ s/(?:\s+|\xa0|\x{00a0})+/ /gr}}, $t;
        }
    }

say "";
print $v =~ s/^This is //r =~ s/ built on / - /r;
foreach my $t (sort { $t{$a}[0] <=> $t{$b}[0] } keys %t) {
    my @t = sort { $a <=> $b } @{$t{$t}};
    printf "%-18s %s\n", $t, join " - " => map { sprintf "%6.3f", $_ } @t[0,-1];
    }
