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
my Str @line = ("", Str, "0\n", "", "\0\0\n0");

my $csv = Text::CSV.new (eol => "\n",
    :binary, :auto_diag, :blank_is_undef, :escape-null, :meta);

ok ($csv.combine (@line), "combine [ ... ]");
is ($csv.string, qq{,,"0\n",,""0"0\n0"\n}, "string");

my $fh = open "__41test.csv", :w or die "$!";

for @pat -> $pat {
    ok ($csv.print ($fh, $pat), "print %exp{$pat}");
    }

$csv.always_quote (True);

ok ($csv.print ($fh, @line), "print [ ... ]");

close $fh;

$fh = open "__41test.csv", :r or die $!;

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

my Str @got = $csv.getline ($fh).map (~*);
is (@got.perl, @line.perl, "read [ ... ]");

close $fh;

unlink "__41test.csv";

$csv = Text::CSV.new (
    eol            => "\n",
    auto_diag      => True,
    blank_is_undef => True,
    quote_null     => False,
    meta           => True,
    );

ok ($csv.combine (@line), "combine [ ... ]");
is ($csv.string, qq{,,"0\n",,"\0\0\n0"\n}, "string");

$fh = open "__41test.csv", :w or die $!;

for @pat -> $pat {
    ok ($csv.print ($fh, $pat), "print %exp{$pat}");
    }

$csv.always_quote (True);

ok ($csv.print ($fh, @line), "print [ ... ]");

close $fh;

$fh = open "__41test.csv", :r or die $!;

for @pat -> $pat {
    my @row = $csv.getline ($fh);
    ok (@row.elems, "getline %exp{$pat}");
    is (@row[0].text, $pat, "data %exp{$pat}");
    }

@got = $csv.getline ($fh).map (~*);
is (@got.perl, @line.perl, "read [ ... ]");

close $fh;

unlink "__41test.csv";

done-testing;
