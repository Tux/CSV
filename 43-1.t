#!perl6

use v6;
use Slang::Tuxic;

use Text::CSV;
use Test;

my $b = Buf.new(224,34,204,182);
dd $b;

my $csv = Text::CSV.new (:auto-diag);

ok ((my Str $u = $b.decode ("utf8-c8")), "decode");
note $u;
note $u.uninames.perl;
# ("<private-use-10FFFD>", "LATIN SMALL LETTER X", "LATIN CAPITAL LETTER E",
#  "DIGIT ZERO", "QUOTATION MARK", "COMBINING LONG STROKE OVERLAY")

ok ($csv.combine (1, $u, 3), "Combine");

ok ((my $s = $csv.string), "String");
note $s;
note $s.uninames.perl;

ok ($csv.parse ($s), "Parse");

dd $csv.fields;
dd $csv.fields[1].text;
note $csv.fields[1].text.uninames.perl;
is ($csv.fields[1].text, $u, "Data");
#is ($csv.fields[1].text.encode ("utf8-c8"), $b, "Data");
