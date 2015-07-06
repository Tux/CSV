#!perl6

use v6;
use Slang::Tuxic;

use Test;
use Text::CSV;

my $csv = Text::CSV.new (:quote-empty);

my $expect = q{1,foo,"a b",,3,""};

my @args = (1, "foo", "a b", Str, 3, "");
ok ($csv.combine (1, "foo", "a b", Str, 3, ""), "combine (list)");
is ($csv.string, $expect, "string");
ok ($csv.combine ( @args),                      "combine (array)");
is ($csv.string, $expect, "string");
ok ($csv.combine (|@args),                      "combine (flattened array)");
is ($csv.string, $expect, "string");
ok ($csv.combine ([@args]),                     "combine (anon array)");
is ($csv.string, $expect, "string");
ok ($csv.combine (\(@args)),                    "combine (array ref)");
is ($csv.string, $expect, "string");

done;
