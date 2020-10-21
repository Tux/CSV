#!/pro/bin/perl

use 5.18.2;
use warnings;

$| = 1;
binmode STDOUT, ":encoding(utf-8)";

use Getopt::Long qw(:config bundling passthrough);
GetOptions (
    "s|silent!" => \my $opt_s,
    ) or die "usage: $0 [--silent] [options to time.pl]\n";

my (@v, %t, %seen);
foreach my $i (1, 2) {
    print "\r";
    open my $th, "-|", "time.pl", @ARGV;
    binmode $th, ":encoding(utf-8)";
    while (<$th>) {
        if (m/^([^ ]+[ ]+[^ ]+)[ ]+(?:\**[ ]+)?[0-9]/) {
            print $seen{$1}++ || $opt_s ? "." : $_;
            next;
            }
        # print;
        if (m/^(?:This is|Welcome to)\s.*\s(v\d+[-.\w]+?)\.?$/) {
            $v[0] //= "Rakudo $1";
            next;
            }
        if (m/^Implementing\s.*(v\d\S+?)\.?$/) {
            $v[1] //= " ($1)";
            next;
            }
        if (m/^Built on (\w+)\s+version\s+(\S+?)\.?$/) {
            $v[2] //= " on $1 $2";
            next;
            }
        my ($s, $t) = m/^(.+?)\s+([0-9][.0-9]+)$/ or next;
        push @{$t{$s =~ s/(?:\s+|\xa0|\x{00a0})+/ /gr}}, $t;
        }
    }

say "";
say join "" => grep { length } @v;
foreach my $t (sort { $t{$a}[0] <=> $t{$b}[0] } keys %t) {
    my @t = sort { $a <=> $b } @{$t{$t}};
    printf "%-18s %s\n", $t, join " - " => map { sprintf "%6.3f", $_ } @t[0,-1];
    }
