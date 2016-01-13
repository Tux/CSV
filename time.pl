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
     9 => [ "",     "c"                ],
    10 => [ "",     "java7",   "-cp csv-java7.jar:opencsv-2.3.jar csvJava" ],
    11 => [ "",     "java8",   "-cp csv-java8.jar:opencsv-2.3.jar csvJava" ],
    12 => [ "",     "java9",   "-cp csv-java9.jar:opencsv-2.3.jar csvJava" ],
    13 => [ ".R",   "R",       "--slave -f" ],
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
    [  9, 0, "csv-c"       ],
    [  7, 0, "csv-lua"     ],
    [  2, 0, "csv-python2" ],
    [  3, 0, "csv-python3" ],
    [  4, 0, "csv-php"     ],
    [ 11, 0, "csv-java8"   ],
    [ 10, 0, "csv-java7"   ],
    [  0, 0, "csv-ruby"    ],
    [  1, 0, "csv-ruby"    ],
    [  8, 0, "csv-go"      ],
    [ 13, 0, "csv-R"       ],
    [ 12, 0, "csv-java9"   ],
    );

sub runfrom {
    my ($v, $script, $file) = @_;
    my ($ext, $exe, @arg) = @{$lang{$v}};

    $exe eq "c" and $exe = "";
    my $run = join " " => $exe, @arg;

    $opt_v > 4 and say "$v / $ext / $exe\t/ $run";
    my $i = 0;
    my $cmd = "$run $script$ext <$file";
    $opt_v > 2 and say $cmd;
    $file eq "empty.csv" and $cmd .= " 2>/dev/null";
    my $t0 = [ gettimeofday ];
    open my $th, "-|", $cmd;
    while (<$th>) {
        m/^(?:\[\d+\]\s+)?(\d+)$/ and $i = $1;
        }
    return (scalar tv_interval ($t0), $i);
    } # runfrom

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

    local *STDERR;
    open STDERR, ">", "/dev/null";

    open my $eh, ">", "empty.csv";
    print $eh  "\n";
    close $eh; END { unlink "empty.csv"; }

                    runfrom ($v, $script, "empty.csv");
                    runfrom ($v, $script, "empty.csv");
    my ($start)   = runfrom ($v, $script, "empty.csv");
    my ($run, $i) = runfrom ($v, $script, "/tmp/hello.csv");

    my $s = sprintf "%s %6d %9.3f %9.3f", $i eq 50000 ? "   " : "***", $i,
        $run, $run - $start;
    say $s;
    $opt_i and next;
    $irc and push @irc, "$s_script\t$s";
    }

say for @irc;
