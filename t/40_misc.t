#!perl6

use v6;
use Slang::Tuxic;

use Test;
use Text::CSV;

sub is_binary (Str $got, Str $exp, Str $tst) { is ($got.perl, $exp.perl, $tst); }
    
my @binField = ("abc\0def\n\rghi", "ab\"ce,\x[1a]\"'", "\x[ff]");

my $csv = Text::CSV.new (:binary, :escape-null);
ok ($csv.combine (@binField),                                   "combine ()");

my $string;
is_binary ($string = $csv.string,
           qq{"abc"0def\n\rghi","ab""ce,\x[1a]""'",\x[ff]},     "string ()");

ok ($csv.parse ($string),                                       "parse ()");
is ($csv.fields.elems, @binField.elems,                         "field count");

my @field = $csv.fields ();
for (flat 0 .. @binField.elems - 1) {
    is (@field[$_].text, @binField[$_],                         "Field $_");
    }

ok (1,                                                          "eol \\r\\n");
$csv.eol ("\r\n");
ok ($csv.combine (@binField),                                   "combine ()");
is_binary ($csv.string,
           qq{"abc"0def\n\rghi","ab""ce,\x[1a]""'",\x[ff]\r\n}, "string ()");

ok (1,                                                          "eol \\n");
$csv.eol ("\n");
ok ($csv.combine (@binField),                                   "combine ()");
is_binary ($csv.string,
           qq{"abc"0def\n\rghi","ab""ce,\x[1a]""'",\x[ff]\n},   "string ()");

ok (1,                                                          "eol ,xxxxxxx\\n");
$csv.eol (",xxxxxxx\n");
ok ($csv.combine (@binField),                                   "combine ()");
is_binary ($csv.string,
           qq{"abc"0def\n\rghi","ab""ce,\x[1a]""'",\x[ff],xxxxxxx\n}, "string ()");

$csv.eol ("\n");
ok (1,                                                          "quote_char Str");
$csv.quote_char (Str);
ok ($csv.combine ("abc","def","ghi"),                           "combine");
is ($csv.string, "abc,def,ghi\n",                               "string ()");

ok (1,                                                          "always_quote");
my $csv2 = Text::CSV.new (:always_quote);
ok ($csv2,                                                      "new ()");
ok ($csv2.combine ("abc","def","ghi"),                          "combine ()");
is ($csv2.string, '"abc","def","ghi"',                          "string ()");

done-testing;
