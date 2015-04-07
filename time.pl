#!/pro/bin/perl

use 5.18.2;
use warnings;

use Time::HiRes qw( gettimeofday tv_interval );

unlink "test-x.pl"; END { unlink "test-x.pl" }
open my $th, "<", "test-t.pl" or die "test-t.pl: $!\n";
open my $xh, ">", "test-x.pl" or die "test-x.pl: $!\n";
while (<$th>) {
    s/^ ?(?=\s*.opt_v)/#/;
    print $xh $_;
    }
close $th;
close $xh;

open  my $fh, "<", "/tmp/hello.csv";
1 while <$fh>;
close    $fh;

my @test = (
    [ 5, "csv-easy-xs" ],
    [ 5, "csv-easy-pp" ],
    [ 5, "csv-xsbc"    ],
    [ 5, "csv-test-xs" ],
    [ 5, "csv-test-pp" ],
    [ 5, "csv-pegex"   ],
    [ 6, "csv"         ],
    [ 6, "csv-ip5xs"   ],
    [ 6, "csv-ip5xsio" ],
    [ 6, "csv-ip5pp"   ],
    [ 6, "csv_gram"    ],
    [ 6, "test"        ],
    [ 6, "test-x"      ],
    );
my %perl = (
    5 => "perl",
    6 => "perl6",
    );
my %start;
foreach my $v (keys %perl) {
    my $t = 0;
    for (1 .. 5) {
        my $t0 = [ gettimeofday ];
        open my $th, "-|", "$perl{$v} -e 1 2>&1 >/dev/null";
        close $th;
        $t += tv_interval ($t0);
        }
    $start{$v} = $t / 5;
    }

for (@test) {
    my ($v, $script) = @$_;
    open my $ph, "|-", "$perl{$v} -Ilib $script.pl 2>&1 >/dev/null";
    print   $ph "\n";
    close   $ph;

    printf "%-11s ", $_->[1];
    my $t0 = [ gettimeofday ];
    open my $th, "-|", "$perl{$v} -Ilib $script.pl 2>&1 </tmp/hello.csv";
    my $i = 0;
    while (<$th>) {
        m/^(\d+)$/ and $i = $1;
        }
    my $elapsed = tv_interval ($t0);
    close $th;
    printf "%s %6d %9.3f %9.3f\n", $i eq 50000 ? "   " : "***", $i,
        $elapsed, $elapsed - $start{$v};
    }
