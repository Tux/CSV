#!/pro/bin/perl

use 5.18.2;
use warnings;

sub usage {
    my $err = shift and select STDERR;
    say "usage: $0 [--verbose[=#]] [--irc]";
    exit $err;
    } # usage

use Time::HiRes qw( gettimeofday tv_interval );
use Getopt::Long qw(:config bundling);
my $opt_6 = 1;
GetOptions (
    "help|?"      => sub { usage (0); },
    "i|irc!"      => \my $opt_i,
    "p|perl6!"    =>    \$opt_6,
    "f|fast"      => sub { $opt_6 = 0; },
    "v|verbose:1" => \my $opt_v,
    ) or usage (1);

$| = 1;
$opt_v //= $opt_i ? 0 : 1;

# cpupower frequency-set -g performance

open  my $fh, "<", "/tmp/hello.csv";
1 while <$fh>;
close    $fh;

my %lang = (
    ##       ext     prog       args
     0 => [ ".rb",  "ruby1.9",         ],
     1 => [ ".rb",  "ruby2.0",         ],
     2 => [ ".py",  "python2",         ],
     3 => [ ".py",  "python3",         ],
     4 => [ ".php", "php",     "-nq"   ],
     5 => [ ".pl",  "perl",            ],
     6 => [ ".pl",  "perl6",   "-Ilib" ],
     7 => [ ".lua", "lua"              ],
     8 => [ ".go",  "go",      "run"   ],
     9 => [ "",     "java",    "-cp csvJava.jar:opencsv-2.3.jar csvJava" ],
    10 => [ "",     "c"                ],
    );
my @test = (
    # lang irc script
    [  5, 0, "csv-easy-xs" ],
    [  5, 0, "csv-easy-pp" ],
    [  5, 0, "csv-xsbc"    ],
    [  5, 0, "csv-test-xs" ],
    [  5, 0, "csv-test-pp" ],
    [  5, 0, "csv-pegex"   ],
    [  6, 0, "csv"         ],
    [  6, 1, "csv-ip5xs"   ],
    [  6, 0, "csv-ip5xsio" ],
    [  6, 0, "csv-ip5pp"   ],
    [  6, 0, "csv_gram"    ],
    [  6, 1, "test"        ],
    [  6, 1, "test-t"      ],
    [  6, 1, "csv-parser"  ],
    [ 10, 0, "csv-c"       ],
    [  7, 0, "csv-lua"     ],
    [  2, 0, "csv-python2" ],
    [  3, 0, "csv-python3" ],
    [  4, 0, "csv-php"     ],
    [  9, 0, "csvJava"     ],
    [  0, 0, "csv-ruby"    ],
    [  1, 0, "csv-ruby"    ],
    [  8, 0, "csv-go"      ],
    );
my %start;
foreach my $v (keys %lang) {
    my ($ext, $exe) = @{$lang{$v}};
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

my @irc;
for (@test) {
    my ($v, $irc, $script) = @$_;
    $script =~ m{$pat}i or  next;
    $opt_i && !$irc     and next;

    my ($ext, $exe, @arg) = @{$lang{$v}};

    $exe eq "perl6" && !$opt_6 and next;

    $opt_v and printf "%-8s ", $exe;
    my $s_script = sprintf "%-11s ", $script;
    print $s_script;

    $exe eq "c" and $exe = "";
    my $run = join " " => $exe, @arg;

    local *STDERR;
    open STDERR, ">", "/dev/null";

    $opt_v > 4 and say "$v / $ext / $exe\t/ $run";
    my $i = 0;
    open my $ph, "|-", "$run $script$ext >/dev/null";
    print   $ph "\n";
    close   $ph;

    my $cmd = "$run $script$ext </tmp/hello.csv";
    $opt_v > 2 and say $cmd;
    my $t0 = [ gettimeofday ];
    open my $th, "-|", $cmd;
    while (<$th>) {
        m/^(\d+)$/ and $i = $1;
        }
    my $elapsed = tv_interval ($t0);
    my $s = sprintf "%s %6d %9.3f %9.3f", $i eq 50000 ? "   " : "***", $i,
        $elapsed, $elapsed - $start{$exe};
    say $s;
    $opt_i and next;
    $irc and push @irc, "$s_script\t$s";
    }

say for @irc;
