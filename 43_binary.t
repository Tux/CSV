#!perl6

use v6;
use Slang::Tuxic;

use Text::CSV;
use Test;

for (^32) {

    my $b = Buf.new (61, ^2048 .map ({ 256.rand.Int }));

    my $csv = Text::CSV.new;

    ok ((my Str $u = $b.decode ("utf8-c8")), "decode");

    ok ($csv.combine (1, $u, 3), "Combine");

    ok ((my $s = $csv.string), "String");

    ok ($csv.parse ($s), "Parse");

    is ($csv.fields[1].encode ("utf-c8"), $b, "Data");
    }
