#!perl6

use v6;
use Slang::Tuxic;

use Test;
use Text::CSV;

sub crnlsp (Text::CSV $csv) {
    if (defined $csv.eol and $csv.eol eq "\r") {
        ok (!$csv.parse ("\n"),                         "NL");
        ok (!$csv.parse ("\n "),                        "NL + Space");
        ok ( $csv.parse ("\r"),                         "CR");
        ok ( $csv.parse ("\r\r"),                       "CR CR");
        ok ( $csv.parse ("\r "),                        "CR + Space");
        ok ( $csv.parse (" \r"),                        "Space + CR");
        }
    else {
        ok ( $csv.parse ("\n"),                         "NL");
        ok ( $csv.parse ("\n "),                        "NL + Space");
        ok ( $csv.parse ("\r"),                         "CR");
        ok ( $csv.parse ("\r\r"),                       "CR CR");
        if ($csv.binary || not defined $csv.eol) {
            ok ( $csv.parse ("\r "),                    "CR + Space");
            ok ( $csv.parse (" \r"),                    "Space + CR");
            }
        else {
            ok (!$csv.parse ("\r "),                    "CR + Space");
            ok (!$csv.parse (" \r"),                    "Space + CR");
            }
        }
    ok ( $csv.parse ("\r\n"),                           "CR NL");
    ok ( $csv.parse ("\r\n "),                          "CR NL + Space");
    if ($csv.binary) {
        ok ( $csv.parse (qq{"\n"}),                     "Quoted NL");
        ok ( $csv.parse (qq{"\r"}),                     "Quoted CR");
        ok ( $csv.parse (qq{"\r\n"}),                   "Quoted CR NL");
        ok ( $csv.parse (qq{"\n "}),                    "Quoted NL + Space");
        ok ( $csv.parse (qq{"\r "}),                    "Quoted CR + Space");
        ok ( $csv.parse (qq{"\r\n "}),                  "Quoted CR NL + Space");
        }
    else {
        ok (!$csv.parse (qq{"\n"}),                     "Quoted NL");
        ok (!$csv.parse (qq{"\r"}),                     "Quoted CR");
        ok (!$csv.parse (qq{"\r\n"}),                   "Quoted CR NL");
        ok (!$csv.parse (qq{"\n "}),                    "Quoted NL + Space");
        ok (!$csv.parse (qq{"\r "}),                    "Quoted CR + Space");
        ok (!$csv.parse (qq{"\r\n "}),                  "Quoted CR NL + Space");
        }

    ok (!$csv.parse (qq{"\r\r\n"\r}),                   "Quoted CR CR NL >CR");
    ok (!$csv.parse (qq{"\r\r\n"\r\r}),                 "Quoted CR CR NL >CR CR");
    ok (!$csv.parse (qq{"\r\r\n"\r\r\n}),               "Quoted CR CR NL >CR CR NL");
    ok (!$csv.parse (qq{"\r\r\n"\t \r}),                "Quoted CR CR NL >TAB Space CR");
    ok (!$csv.parse (qq{"\r\r\n"\t \r\r}),              "Quoted CR CR NL >TAB Space CR CR");
    ok (!$csv.parse (qq{"\r\r\n"\t \r\r\n}),            "Quoted CR CR NL >TAB Space CR CR NL");
    } # crnlsp

{   my $csv = Text::CSV.new (:!binary);
    my $c11 = chr (0x11);       # A random binary character

    is ($csv.fields.elems, 0,                           "meta_info () before parse ()");

    ok (1,                                              "parse () tests - No meta_info");
    crnlsp ($csv);
    ok (!$csv.parse ('"abc'),                           "Missing closing \"");
    ok (!$csv.parse ('ab"c'),                           "\" outside of \"'s");
    ok (!$csv.parse ('"ab"c"'),                         "Bad character sequence");
    ok (!$csv.parse ("ab{$c11}c"),                      "Binary character");
    ok (!$csv.parse (qq{"ab{$c11}c"}),                  "Binary character in quotes");
    ok (!$csv.parse (qq{"abc\nc"}),                     "Bad character (NL)");
    is ($csv.status, False,                             "Wrong status ()");
    ok ( $csv.parse ('","'),                            "comma - parse ()");
    is ( $csv.fields.elems, 1,                          "comma - fields () - count");
    is ( $csv.fields[0].text, ",",                      "comma - fields () - content");
    is ( $csv.fields[0].is_quoted, True,                "comma - fields () - quoted");
    is-deeply ([$csv.list], [","],                      "As list");
    ok ( $csv.parse (qq{,"I said,\t""Hi!""",""}),       "Hi! - parse ()");
    is ( $csv.fields.elems, 3,                          "Hi! - fields () - count");
    is ( $csv.fields[0].text, "",                       "comma - fields () - content");
    is ( $csv.fields[0].is_quoted, False,               "comma - fields () - quoted");
    is ( $csv.fields[1].text, "I said,\t\"Hi!\"",       "comma - fields () - content");
    is ( $csv.fields[1].is_quoted, True,                "comma - fields () - quoted");
    is ( $csv.fields[2].text, "",                       "comma - fields () - content");
    is ( $csv.fields[2].is_quoted, True,                "comma - fields () - quoted");
    is-deeply ([$csv.list], ["",qq{I said,\t"Hi!"},""], "As list");
    }

{   my $csv = Text::CSV.new (eol => "\r", :!binary);

    ok (1,                                              "parse () tests - With flags");
    is ($csv.fields.elems, 0,                           "meta_info () before parse ()");

    crnlsp ($csv);
    ok (!$csv.parse ('"abc'),                           "Missing closing \"");
    ok (!$csv.parse ('ab"c'),                           "\" outside of \"'s");
    ok (!$csv.parse ('"ab"c"'),                         "Bad character sequence");
    ok (!$csv.parse (qq{"abc\nc"}),                     "Bad character (NL)");
    is ($csv.status, False,                             "Wrong status ()");
    ok ( $csv.parse ('","'),                            "comma - parse ()");
    is ( $csv.fields.elems, 1,                          "comma - fields () - count");
    is ( $csv.fields[0].text, ",",                      "comma - fields () - content");
    ok ( $csv.parse (qq{"","I said,\t""Hi!""",}),       "Hi! - parse ()");
    is ( $csv.fields.elems, 3,                          "Hi! - fields () - count");

    is ( $csv.fields[0].text, "",                       "Hi! - fields () - field 1");
    is ( $csv.fields[0].is_quoted, True,                "Hi! - fields () - quoted 1");
    is ( $csv.fields[1].text, qq{I said,\t"Hi!"},       "Hi! - fields () - field 2");
    is ( $csv.fields[1].is_quoted, True,                "Hi! - fields () - quoted 1");
    is ( $csv.fields[2].text, "",                       "Hi! - fields () - field 3");
    is ( $csv.fields[2].is_quoted, False,               "Hi! - fields () - quoted 1");
    }

{   my $csv = Text::CSV.new ();

    is ($csv.fields.elems, 0,                   "no fields no properties");

    my $bintxt = chr (0x20ac);
    ok ($csv.parse (qq{,"1","a\rb",0,"a\nb",1,\x8e,"a\r\n","$bintxt","",}),
                        "parse () - mixed quoted/binary");
    is ($csv.fields.elems, 11,                  "fields () - count");
    my @fflg;
    is ($csv.fields[$_].is_quoted, False, "Field $_ is not quoted") for      0, 3, 5, 6, 10;
    is ($csv.fields[$_].is_quoted, True,  "Field $_ is quoted")     for      1, 2, 4, 7, 8, 9;
    is ($csv.fields[$_].is_binary, False, "Field $_ is not quoted") for      0, 1, 3, 5, 9, 10;
    is ($csv.fields[$_].is_binary, True,  "Field $_ is quoted")     for      2, 4, 6, 7, 8;
    is ($csv.fields[$_].is_utf8,   False, "Field $_ is not utf8")   for flat 0 .. 5, 7, 9, 10;
    is ($csv.fields[$_].is_utf8,   True,  "Field $_ is utf8")       for      6, 8;
    }

{   my $csv = Text::CSV.new (escape_char => "+");

    ok (!$csv.parse ("+"),              "ESC");
    ok ( $csv.parse ("++"),             "ESC ESC");
    ok (!$csv.parse ("+ "),             "ESC Space");
    ok ( $csv.parse ("+0"),             "ESC NUL");
    ok (!$csv.parse ("+\n"),            "ESC NL");
    ok (!$csv.parse ("+\r"),            "ESC CR");
    ok (!$csv.parse ("+\r\n"),          "ESC CR NL");
    ok (!$csv.parse (qq{"+"}),          "Quo ESC");
    ok (!$csv.parse (qq{""+}),          "Quo ESC >");
    ok ( $csv.parse (qq{"++"}), "Quo ESC ESC");
    ok (!$csv.parse (qq{"+ "}), "Quo ESC Space");
    ok ( $csv.parse (qq{"+0"}), "Quo ESC NUL");
    ok (!$csv.parse (qq{"+\n"}),        "Quo ESC NL");
    ok (!$csv.parse (qq{"+\r"}),        "Quo ESC CR");
    ok (!$csv.parse (qq{"+\r\n"}),      "Quo ESC CR NL");
    }

{   my $csv = Text::CSV.new (escape_char => "+", :binary);

    ok (!$csv.parse ("+"),              "ESC");
    ok ( $csv.parse ("++"),             "ESC ESC");
    ok (!$csv.parse ("+ "),             "ESC Space");
    ok ( $csv.parse ("+0"),             "ESC NUL");
    ok (!$csv.parse ("+\n"),            "ESC NL");
    ok (!$csv.parse ("+\r"),            "ESC CR");
    ok (!$csv.parse ("+\r\n"),          "ESC CR NL");
    ok (!$csv.parse (qq{"+"}),          "Quo ESC");
    ok ( $csv.parse (qq{"++"}),         "Quo ESC ESC");
    ok (!$csv.parse (qq{"+ "}),         "Quo ESC Space");
    ok ( $csv.parse (qq{"+0"}),         "Quo ESC NUL");
    ok (!$csv.parse (qq{"+\n"}),        "Quo ESC NL");
    ok (!$csv.parse (qq{"+\r"}),        "Quo ESC CR");
    ok (!$csv.parse (qq{"+\r\n"}),      "Quo ESC CR NL");
    }

ok (1, "Testing always_quote");
{   ok (my $csv = Text::CSV.new (:!always-quote), "new (:always-quote)");
    ok ($csv.combine (1..3),                      "Combine");
    is ($csv.string,              q{1,2,3},       "String");
    is ($csv.always_quote,        False,          "Attr 0");
    ok ($csv.always_quote (1),                    "Attr 1");
    ok ($csv.combine (1..3),                      "Combine");
    is ($csv.string,              q{"1","2","3"}, "String");
    is ($csv.always_quote,        True,           "Attr 1");
    is ($csv.always_quote (0),    False,          "Attr 0");
    ok ($csv.combine (1..3),                      "Combine");
    is ($csv.string,              q{1,2,3},       "String");
    is ($csv.always_quote,        False,          "Attr 0");
    }

ok (1, "Testing quote_space");
{   ok (my $csv = Text::CSV.new (:quote-space), "new (:quote-space)");
    ok ($csv.combine (1, " ", 3),               "Combine");
    is ($csv.string,                q{1," ",3}, "String");
    is ($csv.quote_space,           True,       "Attr 1");
    is ($csv.quote_space (0),       False,      "Attr 0");
    ok ($csv.combine (1, " ", 3),               "Combine");
    is ($csv.string,                q{1, ,3},   "String");
    is ($csv.quote_space,           False,      "Attr 0");
    is ($csv.quote_space (1),       True,       "Attr 1");
    ok ($csv.combine (1, " ", 3),               "Combine");
    is ($csv.string,                q{1," ",3}, "String");
    is ($csv.quote_space,           True,       "Attr 1");
    }

ok (1, "Testing quote_empty");
{   ok (my $csv = Text::CSV.new,               "new (default)");
    is ($csv.quote_empty,     False,           "default = False");
    ok ($csv.combine (1, Str, "", " ", 2),     "combine qe = False");
    is ($csv.string,          qq{1,,," ",2},   "string");
    is ($csv.quote-empty (1), True,            "enable quote_empty");
    ok ($csv.combine (1, Str, "", " ", 2),     "combine qe = True");
    is ($csv.string,          qq{1,,""," ",2}, "string");
    }

done-testing;
