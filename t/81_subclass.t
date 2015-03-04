#!perl6

use v6;
use Slang::Tuxic;

use Test;
use Text::CSV;

class CSV2 is Text::CSV {
    }

my $csv = CSV2.new;

is ($csv.^name, "CSV2",              "Classname");

is ($csv.version, Text::CSV.version, "Version");

ok ($csv.parse (""),                 "Subclass parse ()");
ok ($csv.combine (""),               "Subclass combine ()");
is ($csv.binary (),   True,          "Basic attribute");
is ($csv.sep-char (), ",",           "Aliassed attribute");

ok ($csv.new,                        "new () based on object");

done;
