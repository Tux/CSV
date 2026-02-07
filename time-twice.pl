#!/pro/bin/perl

use 5.026001;
use warnings;

our $CMD = $0 =~ s{.*}{}r;
our $VERSION = "1.41 - 20260207";

$| = 1;
binmode STDOUT, ":encoding(utf-8)";

use Getopt::Long qw(:config bundling passthrough);
GetOptions (
    "s|silent!" => \my $opt_s,
    ) or die "usage: $CMD [--silent] [options to time.pl]\n";

{   my $hcsv = "/tmp/hello.csv";
    unless (-s $hcsv) {
        my $l = qq{hello,","," ",world,"!"\n};
        open my $fh, ">", $hcsv or die "$hcsv: $!\n";
        print $fh $l for 1.. 10_000;
        close $fh;
        $hcsv =~ s/\./20./;
        open    $fh, ">", $hcsv or die "$hcsv: $!\n";
        print $fh $l for 1..200_000;
        close $fh;
        }
    }

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

say "https://tux.nl/Talks/CSV6/speed4-20.html / https://tux.nl/Talks/CSV6/speed4.html https://tux.nl/Talks/CSV6/speed.log";
