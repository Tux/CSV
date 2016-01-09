#!/pro/bin/perl

use 5.18.2;
use warnings;

use Time::HiRes qw( gettimeofday tv_interval );

$| = 1;

# cpupower frequency-set -g performance

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
    [ 6, "test-t"      ],
    [ 6, "csv-parser"  ],
    [ 0, "csv-ruby19"  ],
    [ 1, "csv-ruby20"  ],
    [ 2, "csv-python2" ],
    [ 3, "csv-python3" ],
    );
my %lang = (
    0 => [ "rb", "ruby1.9", ],
    1 => [ "rb", "ruby2.0", ],
    2 => [ "py", "python2", ],
    3 => [ "py", "python3", ],
    5 => [ "pl", "perl",    ],
    6 => [ "pl", "perl6",   ],
    );
my (%start, $exe, $ext);
foreach my $v (keys %lang) {
    ($ext, $exe) = @{$lang{$v}};
    my $t = 0;
    for (1 .. 5) {
        my $t0 = [ gettimeofday ];
        open my $th, "-|", "$exe -e 1 2>&1 >/dev/null";
        close $th;
        $t += tv_interval ($t0);
        }
    $start{$exe} = $t / 5;
    }

my $pat = shift // ".";

for (@test) {
    my ($v, $script) = @$_;
    $script =~ $pat or next;
    ($ext, $exe) = @{$lang{$v}};
    my $run = $exe;

    printf "%-11s ", $script;

    $v >= 5 and $run .= " -Ilib";

    #say "$v / $ext / $exe\t/ $run"; next;
    my ($i, $t0) = (0);
    open my $ph, "|-", "$run $script.$ext 2>&1 >/dev/null";
    print   $ph "\n";
    close   $ph;

    $t0 = [ gettimeofday ];
    open my $th, "-|", "$run $script.$ext 2>&1 </tmp/hello.csv";
    while (<$th>) {
        m/^(\d+)$/ and $i = $1;
        }
    my $elapsed = tv_interval ($t0);
    printf "%s %6d %9.3f %9.3f\n", $i eq 50000 ? "   " : "***", $i,
        $elapsed, $elapsed - $start{$exe};
    }
