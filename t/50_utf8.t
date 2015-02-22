#!perl6

use v6;
use Slang::Tuxic;

use Test;
use Text::CSV;

# Test rejection of binary whilst accepting UTF-8
my $csv = Text::CSV.new (always_quote => True, binary => False);

# Special characters to check:
# 0A = \n  2C = ,  20 =     22 = "  
# 0D = \r  3B = ;
my @special = (
  # Space-like characters
  [ "\x[0000A0]", "U+0000A0 NO-BREAK SPACE"                             ],
  [ "\x[00200B]", "U+00200B ZERO WIDTH SPACE"                           ],
  # Some characters with possible problems in the code point
  [ "\x[000122]", "U+000122 LATIN CAPITAL LETTER G WITH CEDILLA"        ],
  [ "\x[002C22]", "U+002C22 GLAGOLITIC CAPITAL LETTER SPIDERY HA"       ],
  [ "\x[000A2C]", "U+000A2C GURMUKHI LETTER BA"                         ],
  [ "\x[000E2C]", "U+000E2C THAI CHARACTER LO CHULA"                    ],
  [ "\x[010A2C]", "U+010A2C KHAROSHTHI LETTER VA"                       ],
  # Characters with possible problems in the encoded representation
  #  Should not be possible. ASCII is coded in 000..127, all other
  #  characters in 128..255
  );

my $q = $csv.quo;
for @special -> @test {
    (my $u, my $msg) = @test;
    #($u = "$u\x[0123]") ~~ s/.$//;
    #$u.perl.say;
    #$msg.perl.say;
    my Str @in  = ("", " ", $u, "");
    my $exp = join ",", @in.map ($q~*~$q);
    #$exp.perl.say;
    ok ($csv.combine (@in),             "combine $msg");

    my $str = $csv.string;
    #$str.perl.say;
    is ($str.perl, $exp.perl,           "string  $msg");

    ok ($csv.parse ($str),              "parse   $msg");
    my @out = $csv.fields;
    is (@in.elems, @out.elems,          "fields  $msg");
    is ((@out[$_]//CSV::Field.new).text.perl, @in[$_].perl, "field $_ $msg") for ^@in.elems;
    }

# Test if the UTF8 part is accepted, but the \n is not
is ($csv.parse (qq{"\x[0123]\n\x[20ac]"}), False, "\\n still needs binary");
is ($csv.binary, False, "bin flag still unset");
is ($csv.error_diag + 0, 2021, "Error 2021");

done;

=finish

my $file = "files/utf8.csv";
SKIP: {
    open my $fh, "<:encoding(utf8)", $file or
        skip "Cannot open UTF-8 test file", 6;

    my $row;
    ok ($row = $csv.getline ($fh), "read/parse");

    is ($csv.is_quoted (0),     1,      "First  field is quoted");
    is ($csv.is_quoted (1),     0,      "Second field is not quoted");
    is ($csv.is_binary (0),     1,      "First  field is binary");
    is ($csv.is_binary (1),     0,      "Second field is not binary");

    ok (utf8::valid ($row.[0]), "First field is valid utf8");

    $csv.combine (@$row);
    ok (utf8::valid ($csv.string),      "Combined string is valid utf8");
    }

# Test quote_binary
$csv.always_quote (0);
$csv.quote_space  (0);
$csv.quote_binary (0);
ok ($csv.combine (" ", 1, "\x{20ac} "), "Combine");
is ($csv.string, qq{ ,1,\x{20ac} },             "String 0-0");
$csv.quote_binary (1);
ok ($csv.combine (" ", 1, "\x{20ac} "), "Combine");
is ($csv.string, qq{ ,1,"\x{20ac} "},           "String 0-1");

$csv.quote_space  (1);
$csv.quote_binary (0);
ok ($csv.combine (" ", 1, "\x{20ac} "), "Combine");
is ($csv.string, qq{" ",1,"\x{20ac} "}, "String 1-0");
ok ($csv.quote_binary (1),                      "quote binary on");
ok ($csv.combine (" ", 1, "\x{20ac} "), "Combine");
is ($csv.string, qq{" ",1,"\x{20ac} "}, "String 1-1");

open  my $fh, ">:encoding(utf-8)", "_50test.csv";
print $fh "euro\n\x{20ac}\neuro\n";
close $fh;
open     $fh, "<:encoding(utf-8)", "_50test.csv";

SKIP: {
    my $out = "";
    my $isutf8 = $] < 5.008001 ?
        sub { !$_[0]; } :       # utf8::is_utf8 () not available in 5.8.0
        sub { utf8::is_utf8 ($out); };
    ok ($csv.auto_diag (1),                     "auto diag");
    ok ($csv.binary (1),                        "set binary");
    ok ($csv.bind_columns (\$out),              "bind");
    ok ($csv.getline ($fh),                     "parse");
    is ($csv.is_binary (0),     0,              "not binary");
    is ($out,                   "euro",         "euro");
    ok (!$isutf8.(1),                           "not utf8");
    ok ($csv.getline ($fh),                     "parse");
    is ($csv.is_binary (0),     1,              "is binary");
    is ($out,                   "\x{20ac}",     "euro");
    ok ($isutf8.(0),                            "is utf8");
    ok ($csv.getline ($fh),                     "parse");
    is ($csv.is_binary (0),     0,              "not binary");
    is ($out,                   "euro",         "euro");
    ok (!$isutf8.(1),                           "not utf8");
    close $fh;
    unlink "_50test.csv";
    }
