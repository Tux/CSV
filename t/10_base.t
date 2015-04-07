#!perl6

use v6;
use Slang::Tuxic;

use Test;
use Text::CSV;

my $csv = Text::CSV.new;

ok ($csv,                                      "New parser");
is ($csv.fields.elems, 0,                      "fields () before parse ()");
is ($csv.list.elems, 0,                        "list () before parse ()");
is ($csv.string, Str,                          "string () undef before combine");
is ($csv.status, True,                         "No failures yet");

ok (1, "combine () & string () tests");
is ($csv.combine (),    True,                  "Combine no args");
is ($csv.string,        Str,                   "String of no fields");

ok ($csv.combine (""),                         "Empty string - combine ()");
is ($csv.string, "",                           "Empty string - string ()");
ok ($csv.combine ("", " "),                    "Two fields, one space - combine ()");
is ($csv.string, '," "',                       "Two fields, one space - string ()");
ok ($csv.combine ("", 'I said, "Hi!"', ""),    "Hi! - combine ()");
is ($csv.string, ',"I said, ""Hi!""",',        "Hi! - string ()");
ok ($csv.combine ('"', "abc"),                 "abc - combine ()");
is ($csv.string, '"""",abc',                   "abc - string ()");
ok ($csv.combine (","),                        "comma - combine ()");
is ($csv.string, '","',                        "comma - string ()");
ok ($csv.combine ("abc", '"'),                 "abc + \" - combine ()");
is ($csv.string, 'abc,""""',                   "abc + \" - string ()");
ok ($csv.combine ("abc", "def", "ghi", "j,k"), "abc .. j,k - combine ()");
is ($csv.string, 'abc,def,ghi,"j,k"',          "abc .. j,k - string ()");
ok ($csv.combine ("abc\tdef", "ghi"),          "abc + TAB - combine ()");
is ($csv.string, qq{"abc\tdef",ghi},           "abc + TAB - string ()");
is ($csv.status, True,                         "No failures");

$csv.binary (False);
is ($csv.error_input.defined, False,           "No error saved yet");
is ($csv.combine ("abc", "def\n", "g"), False, "Bad character");
is ($csv.error_input, "def\n",                 "Error_input ()");
is ($csv.status, False,                        "Failure");
$csv.binary (True);

ok (1,                                         "parse () tests");
ok ($csv.parse ("\n"),                         "Single newline");
ok ($csv.parse ('","'),                        "comma - parse ()");
is ($csv.fields.elems, 1,                      "comma - fields () - count");
is ($csv.fields[0].text, ",",                  "comma - fields () - content");
is_deeply ([$csv.list], [","],                 "As list");

ok ($csv.parse (qq{"","I said,\t""Hi!""",""}), "Hi! - parse ()");
is ($csv.fields.elems, 3,                      "Hi! - fields () - count");

is ($csv.fields[0].text, "",                   "Hi! - fields () - field 1");
is ($csv.fields[1].text, qq{I said,\t"Hi!"},   "Hi! - fields () - field 2");
is ($csv.fields[2].text, "",                   "Hi! - fields () - field 3");
is ($csv.status, True,                         "status");
is_deeply ([$csv.list], [ "", qq{I said,\t"Hi!"}, "" ], "As list");

ok ($csv.parse (""),                           "Empty line");
is ($csv.fields.elems, 1,                      "Empty - count");
is ($csv.fields[0].text, "",                   "One empty field");
is_deeply ([$csv.list], [""],                  "Return as data");

ok (1,                                         "Integers and Reals");
ok ($csv.combine ("", 2, 3.25, "a", "a b"),    "Mixed - combine ()");
is ($csv.string, ',2,3.25,a,"a b"',            "Mixed - string ()");

# Basic error test
ok (!$csv.parse ('"abc'),            "Missing closing \"");
# Test all error_diag contexts
is (0  + $csv.error_diag,   2027,    "diag numeric");
is ("" ~ $csv.error_diag,   "EIQ - Quoted field not terminated", "diag string");
my @ed = $csv.error_diag;
is (@ed[2],                 4,       "diag pos");
is (@ed[3],                 5,       "diag record");
is (@ed[4],                 '"abc',  "diag buffer");
is ($csv.error_diag[0],     2027,    "diag error  positional");
is ($csv.error_diag[3],     5,       "diag record positional");
is ($csv.error_diag.error,  2027,    "diag OO error");
is ($csv.error_diag.record, 5,       "diag OO record");
ok (True, "The next two lines should show an error");
$csv.error_diag;        # Call in void context
# More fail tests
ok (!$csv.parse ('ab"c'),            "\" outside of \"'s");
ok (!$csv.parse ('"ab"c"'),          "Bad character sequence");
is ($csv.status, False,              "FAIL");
ok ($csv.parse (""),                 "Empty line");
is ($csv.status, True,               "PASS again");

$csv.binary (False);
ok (!$csv.parse (qq{"abc\nc"}),      "Bad character (NL)");
is ($csv.status, False,              "FAIL");

my $csv2 = $csv.new;
ok ($csv2,                           "New from obj");
is ($csv2.^name, "Text::CSV",        "Same object type");

# Test context
my $f = CSV::Field.new ();      # Undefined
is (?$f,          False,      "Undefined in Boolean context");
my $n = +$f;
is ($n.WHICH,     "Num",      "Undefined in Numeric context type");
is ($n.defined,   False,      "Undefined in Numeric context defined");
my $s = ~$f;
is ($s.WHICH,     "Str",      "Undefined in String  context type");
is ($s.defined,   False,      "Undefined in String  context defined");
is ($f.gist,      "<undef>",  "Undefined as gist");

$f.text      = "0";
is (?$f,          False,      "'0' in Boolean context");
$n = +$f;
is ($n.^name,     "Int",      "'0' in Numeric context type");
is ($n.defined,   True,       "'0' in Numeric context defined");
is ($n,           0,          "'0' in Numeric context value");
$s = ~$f;
is ($s.^name,     "Str",      "'0' in String  context type");
is ($s.defined,   True,       "'0' in String  context defined");
is ($s,           "0",        "'0' in String  context value");
is ($f.gist,      'qb7m:"0"', "'0' as gist");

$f.text      = "1";             # "1"
is (?$f,          True,       "'1' in Boolean context");
$n = +$f;
is ($n.^name,     "Int",      "'1' in Numeric context type");
is ($n.defined,   True,       "'1' in Numeric context defined");
is ($n,           1,          "'1' in Numeric context value");
$s = ~$f;
is ($s.^name,     "Str",      "'1' in String  context type");
is ($s.defined,   True,       "'1' in String  context defined");
is ($s,           "1",        "'1' in String  context value");
is ($f.gist,      'qb7m:"1"', "'1' as gist");

$f.text      = "15";            # "15"
$f.is_quoted = True;
is (?$f,          True,       "'15' in Boolean context");
$n = +$f;
is ($n.^name,     "Int",      "'15' in Numeric context type");
is ($n.defined,   True,       "'15' in Numeric context defined");
is ($n,           15,         "'15' in Numeric context value");
$s = ~$f;
is ($s.^name,     "Str",      "'15' in String  context type");
is ($s.defined,   True,       "'15' in String  context defined");
is ($s,           "15",       "'15' in String  context value");
is ($f.gist,      'Qb7m:"15"', "'15' as gist");

$f = CSV::Field.new (text => "\x[246e]", :is_quoted); # "CIRCLED NUMBER FIFTEEN"
is (?$f,          True,       "'\"\x[246e]\"' in Boolean context");
$n = +$f;
is ($n.^name,     "Int",      "'\"\x[246e]\"' in Numeric context type");
is ($n.defined,   True,       "'\"\x[246e]\"' in Numeric context defined");
is ($n,           15,          "'\"\x[246e]\"' in Numeric context value");
$s = ~$f;
is ($s.^name,     "Str",      "'\"\x[246e]\"' in String  context type");
is ($s.defined,   True,       "'\"\x[246e]\"' in String  context defined");
is ($s,           "\x[246e]", "'\"\x[246e]\"' in String  context value");
is ($f.is_binary, True,       "'\"\x[246e]\"' in String  context binary");
is ($f.gist, "QB8m:\"\x[246e]\"", "'\"\x[246e]\"' as gist");

done;
