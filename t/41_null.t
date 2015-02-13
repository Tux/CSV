#!perl6

use v6;
use Slang::Tuxic;

use Text::CSV;
use Test;

my @pat = (
    "00", 
    "\00",
    "0\0",
    "\0\0",

    "0\n0",
    "\0\n0",
    "0\n\0",
    "\0\n\0",

    "\"0\n0",
    "\"\0\n0",
    "\"0\n\0",
    "\"\0\n\0",

    "\"0\n\"0",
    "\"\0\n\"0",
    "\"0\n\"\0",
    "\"\0\n\"\0",

    "0\n0",
    "\0\n0",
    "0\n\0",
    "\0\n\0",
    );
my %exp;
for @pat -> $pat {
    my $x = $pat;
    $x ~~ s:g/\0/\\0/;
    $x ~~ s:g/\n/\\n/;
    %exp{$pat} = $x;
    }
my @line = ("", Str, "0\n", "", "\0\0\n0");

my $csv = Text::CSV.new (
    eol                 => "\n",
    binary              => True,
    auto_diag           => True,
    blank_is_undef      => True,
    );

ok ($csv.combine (@line), "combine [ ... ]");
is ($csv.string, qq{,,"0\n",,""0"0\n0"\n}, "string");

my $fh = open "__41test.csv", :w or die "$!";

for @pat -> $pat {
    ok ($csv.print ($fh, $pat), "print %exp{$pat}");
    }

$csv.always_quote (True);

ok ($csv.print ($fh, @line), "print [ ... ]");

close $fh;

$fh = open "__41test.csv", :r, :!chomp or die $!;

for @pat -> $pat {
    my @row = $csv.getline ($fh);
    ok (@row.elems, "getline %exp{$pat}");
    my $err = $csv.error_diag;
    if ($err.error == 2027) {
        $fh.get;
        next;
        }
    is (@row[0].text, $pat, "data %exp{$pat}");
    }

=finish
is_deeply ($csv.getline ($fh), $line, "read [ ... ]");

close $fh;

unlink "__41test.csv";

$csv = Text::CSV.new (
    eol            => "\n",
    binary         => 1,
    auto_diag      => 1,
    blank_is_undef => 1,
    quote_null     => 0,
    );

ok ($csv.combine (@$line), "combine [ ... ]");
is ($csv.string, qq{,,"0\n",,"\0\0\n0"\n}, "string");

open $fh, ">", "__41test.csv" or die $!;
binmode $fh;

for @pat -> $pat {
    ok ($csv.print ($fh, [ $pat ]), "print %exp{$pat}");
    }

$csv.always_quote (1);

ok ($csv.print ($fh, $line), "print [ ... ]");

close $fh;

open $fh, "<", "__41test.csv" or die $!;
binmode $fh;

foreach my $pat (@pat) {
    ok (my $row = $csv.getline ($fh), "getline $exp{$pat}");
    is ($row.[0], $pat, "data $exp{$pat}");
    }

is_deeply ($csv.getline ($fh), $line, "read [ ... ]");

close $fh;

unlink "__41test.csv";
