#!perl6

use v6;
use Slang::Tuxic;

use Test;
use Text::CSV;

# Test rejection of binary whilst accepting UTF-8
my $csv = Text::CSV.new (:always_quote, :!binary, :meta);

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
    my Str @in  = ("", " ", $u, "");
    my $exp = join ",", @in.map ($q~*~$q);
    ok ($csv.combine (@in),             "combine $msg");

    my $str = $csv.string;
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

my $file = "files/utf8.csv";
SKIP: {
    my $fh = open $file, :r;

    my @row;
    ok (@row = $csv.getline ($fh), "read/parse");

    is (@row[0].is_quoted,  True,  "First  field is quoted");
    is (@row[1].is_quoted,  False, "Second field is not quoted");
    is (@row[0].is_binary,  True,  "First  field is binary");
    is (@row[1].is_binary,  False, "Second field is not binary");

    is ($csv.is_quoted (0), True,  "First  field is quoted");
    is ($csv.is_quoted (1), False, "Second field is not quoted");
    is ($csv.is_binary (0), True,  "First  field is binary");
    is ($csv.is_binary (1), False, "Second field is not binary");

    ok (@row[0].is_utf8,           "First field is valid utf8");

    $csv.combine (@row);
    ok ($csv.string,               "Combined string is valid utf8");
    }

# Test quote_binary
$csv.always_quote (0);
$csv.quote_space  (0);
$csv.quote_binary (0);
ok ($csv.combine (" ", 1, "\x[20ac] "), "Combine");
is ($csv.string,    qq{ ,1,\x[20ac] },  "String 0-0");
$csv.quote_binary (1);
ok ($csv.combine (" ", 1, "\x[20ac] "), "Combine");
is ($csv.string,    qq{ ,1,\x[20ac] },  "String 0-1");

$csv.quote_space  (1);
$csv.quote_binary (0);
ok ($csv.combine (" ", 1, "\x[20ac] "), "Combine");
is ($csv.string, qq{" ",1,"\x[20ac] "}, "String 1-0");
ok ($csv.quote_binary (1),              "quote binary on");
ok ($csv.combine (" ", 1, "\x[20ac] "), "Combine");
is ($csv.string, qq{" ",1,"\x[20ac] "}, "String 1-1");

my $fh = open "_50test.csv", :w;
$fh.print ("euro\n\x[20ac]\neuro\n");
$fh.close;
$fh = open "_50test.csv", :r;

ok ($csv.auto_diag (1),                     "auto diag");
ok ($csv.binary (1),                        "set binary");
ok (my @row = $csv.getline ($fh),           "parse");
is ($csv.is_binary (0),     False,          "not binary");
is (@row[0].text,           "euro",         "euro");
is ($csv.is_utf8 (1),       False,          "not utf8");
ok (@row = $csv.getline ($fh),              "parse");
is ($csv.is_binary (0),     True,           "is binary");
is (@row[0].text,           "\x[20ac]",     "euro");
is (@row[0].is_utf8,        True,           "is utf8");
ok (@row = $csv.getline ($fh),              "parse");
is ($csv.is_binary (0),     False,          "not binary");
is (@row[0].text,           "euro",         "euro");
is (@row[0].is_utf8,        False,          "not utf8");
$fh.close;
unlink "_50test.csv";

done;
