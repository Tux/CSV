#!perl6

use v6;
use Slang::Tuxic;

use Test;
use Text::CSV;

ok (my $csv = Text::CSV.new (:quote-empty, :blank-is-undef, :meta), "new");

my $tfn = "_22_print.csv";

my $args = q{1,foo,"a b",,3,""};
my @args = ("1", "foo", "a b", Str, "3", ""); # "1" instead of 1 for is-deeply

my $fh = open $tfn, :w;
ok ($csv.eol ("\r"), "EOL is CR for writing");
ok ($csv.print ($fh, 1, "foo", "a b", Str, 3, ""), "combine (list)");
ok ($csv.print ($fh,   @args),                     "combine (array)");
ok ($csv.print ($fh,  |@args),                     "combine (flattened array)");
ok ($csv.print ($fh,  [@args]),                    "combine (anon array)");
ok ($csv.print ($fh, \(@args)),                    "combine (array ref)");
$fh.close;

$fh = open $tfn, :r;
is-deeply ([$csv.getline ($fh).map (~*)], @args, "getline") for ^5;
$fh.close;

unlink $tfn;

done;
