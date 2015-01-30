#!perl6

use v6;
use Slang::Tuxic;

use Test;
use Text::CSV;

my $csv = Text::CSV.new;

ok ($csv,                              "new ()");

is ($csv.quote_char,            '"',   "quote_char");
is ($csv.quote,                 '"',   "quote");
is ($csv.escape_char,           '"',   "escape_char");
is ($csv.sep_char,              ",",   "sep_char");
is ($csv.sep,                   ",",   "sep");
is ($csv.eol.defined,           False, "eol");
is ($csv.always_quote,          False, "always_quote");
is ($csv.binary,                True,  "binary");
is ($csv.allow_loose_quotes,    False, "allow_loose_quotes");
is ($csv.allow_loose_escapes,   False, "allow_loose_escapes");
is ($csv.allow_unquoted_escape, False, "allow_unquoted_escape");
is ($csv.allow_whitespace,      False, "allow_whitespace");
is ($csv.blank_is_undef,        False, "blank_is_undef");
is ($csv.empty_is_undef,        False, "empty_is_undef");
is ($csv.auto_diag,             0,     "auto_diag");
is ($csv.diag_verbose,          0,     "diag_verbose");
is ($csv.quote_space,           True,  "quote_space");
is ($csv.quote_null,            True,  "quote_null");
is ($csv.quote_binary,          True,  "quote_binary");
is ($csv.record_number,         0,     "record_number");

is ($csv.binary (),             True,  "binary ()");
is ($csv.binary (False),        False, "binary (False)");
is ($csv.binary (0),            False, "binary (0)");
is ($csv.binary (True),         True,  "binary (True)");
is ($csv.binary (1),            True,  "binary (1)");
is ($csv.binary (42),           True,  "binary (42)");

my @fld = ('txt =, "Hi!"', "Yes", "", 2, Str, "1.09", "\r", Str);
ok ($csv.combine (@fld),                                "combine");
is ($csv.string, qq{"txt =, ""Hi!""",Yes,,2,,1.09,"\r",}, "string");

is ($csv.sep_char (";"),    ";",    "sep_char (;)");
is ($csv.sep (";"),         ";",    "sep (;)");
is ($csv.sep_char (),       ";",    "sep_char ()");
is ($csv.quote_char ("="),  "=",    "quote_char (=)");
is ($csv.quote ("="),       "=",    "quote (=)");
is ($csv.eol (Str).defined, False,  "eol (Str)");
is ($csv.eol (""),          "",     "eol ('')");
is ($csv.eol ("\r"),        "\r",   "eol (\\r)");

is ($csv.always_quote (False),         False, "always_quote (False)");
is ($csv.always_quote (True),          True,  "always_quote (True)");
is ($csv.always_quote (1),             True,  "always_quote (1)");
is ($csv.allow_loose_quotes (True),    True,  "allow_loose_quotes (True)");
is ($csv.allow_loose_quotes (1),       True,  "allow_loose_quotes (1)");
is ($csv.allow_loose_escapes (True),   True,  "allow_loose_escapes (True)");
is ($csv.allow_loose_escapes (1),      True,  "allow_loose_escapes (1)");
is ($csv.allow_unquoted_escape (True), True,  "allow_unquoted_escape (True)");
is ($csv.allow_unquoted_escape (1),    True,  "allow_unquoted_escape (1)");
is ($csv.allow_whitespace (True),      True,  "allow_whitespace (True)");
is ($csv.allow_whitespace (1),         True,  "allow_whitespace (1)");
is ($csv.blank_is_undef (True),        True,  "blank_is_undef (True)");
is ($csv.blank_is_undef (1),           True,  "blank_is_undef (1)");
is ($csv.empty_is_undef (True),        True,  "empty_is_undef (True)");
is ($csv.empty_is_undef (1),           True,  "empty_is_undef (1)");
is ($csv.auto_diag (1),                1,     "auto_diag (1)");
is ($csv.auto_diag (2),                2,     "auto_diag (2)");
is ($csv.auto_diag (9),                9,     "auto_diag (9)");
is ($csv.auto_diag (True),             1,     "auto_diag (True)");
is ($csv.auto_diag (False),            0,     "auto_diag (False)");
is ($csv.auto_diag (Str),              0,     "auto_diag (Str)");
is ($csv.auto_diag (""),               0,     "auto_diag (\"\")");
is ($csv.diag_verbose (1),             1,     "diag_verbose (1)");
is ($csv.diag_verbose (2),             2,     "diag_verbose (2)");
is ($csv.diag_verbose (9),             9,     "diag_verbose (9)");
is ($csv.diag_verbose (True),          1,     "diag_verbose (True)");
is ($csv.diag_verbose (False),         0,     "diag_verbose (False)");
is ($csv.diag_verbose (Str),           0,     "diag_verbose (Str)");
is ($csv.diag_verbose (""),            0,     "diag_verbose (\"\")");
is ($csv.quote_space (True),           True,  "quote_space (True)");
is ($csv.quote_space (1),              True,  "quote_space (1)");
is ($csv.quote_null (True),            True,  "quote_null (True)");
is ($csv.quote_null (1),               True,  "quote_null (1)");
is ($csv.quote_binary (True),          True,  "quote_binary (True)");
is ($csv.quote_binary (1),             True,  "quote_binary (1)");
is ($csv.escape_char ("\\"),           "\\",  "escape_char (\\)");
ok ($csv.combine (@fld),                      "combine");
is ($csv.string,
    qq{=txt \\=, "Hi!"=;=Yes=;==;=2=;==;=1.09=;=\r=;==\r},  "string");

is ($csv.allow_whitespace (0), False, "allow_whitespace (0)");
is ($csv.quote_space (0),      False, "quote_space (0)");
is ($csv.quote_null (0),       False, "quote_null (0)");
is ($csv.quote_binary (0),     False, "quote_binary (0)");
is ($csv.sep ("--"),           "--",  "sep (\"--\")");
is ($csv.sep_char (),          "--",  "sep_char");
is ($csv.quote ("++"),         "++",  "quote (\"++\")");
is ($csv.quote_char (),        "++",  "quote_char");

# Attribute aliasses
ok ($csv = Text::CSV.new (quote_always => 1, verbose_diag => 1), "New with aliasses");
is ($csv.always_quote, True, "always_quote = quote_always");
is ($csv.diag_verbose, 1,    "diag_verbose = verbose_diag");

# Funny settings, all three translate to \0 internally
ok ($csv = Text::CSV.new (
    # sep_char    => Str, -- sep cannot be undefined!
    quote  => Str,
    Escape => Str,
    ),                                  "new (Str ...)");
is ($csv.quote_char.defined,     False, "quote_char  Str");
is ($csv.quote.defined,          False, "quote       Str");
is ($csv.escape_char.defined,    False, "escape_char Str");
ok ($csv.parse ("foo"),                 "parse (foo)");
is ($csv.sep_char (","),         ",",   "sep = ,");
is ($csv.record_number,          1,     "record_number 1");
ok ($csv.parse ("bar"),                 "parse (bar)");
is ($csv.record_number,          2,     "record_number 2");
is ($csv.binary (False),         False, "no binary");
ok (!$csv.parse ("foo,foo\0bar"),       "parse (foo,foo)");
ok ($csv.escape_char ("\\"),            "set escape");
ok (!$csv.parse ("foo,foo\0bar"),       "parse (foo)");
is ($csv.binary (1),             True,  "binary (1)");
ok ($csv.parse ("foo,foo\0bar"),        "parse (foo)");

=finish

# Some forbidden combinations
foreach my $ws (" ", "\t") {
    ok ($csv = Text::CSV.new ({ escape_char => $ws }), "New blank escape");
    eval { ok ($csv.allow_whitespace (1), "Allow ws") };
    is (($csv.error_diag)[0], 1002, "Wrong combo");
    ok ($csv = Text::CSV.new ({ quote_char  => $ws }), "New blank quote");
    eval { ok ($csv.allow_whitespace (1), "Allow ws") };
    is (($csv.error_diag)[0], 1002, "Wrong combo");
    ok ($csv = Text::CSV.new ({ allow_whitespace => 1 }), "New ws 1");
    eval { ok ($csv.escape_char ($ws),     "esc") };
    is (($csv.error_diag)[0], 1002, "Wrong combo");
    ok ($csv = Text::CSV.new ({ allow_whitespace => 1 }), "New ws 1");
    eval { ok ($csv.quote_char  ($ws),     "esc") };
    is (($csv.error_diag)[0], 1002, "Wrong combo");
    }
eval { $csv = Text::CSV.new ({
    escape_char      => "\t",
    quote_char       => " ",
    allow_whitespace => 1,
    }) };
like ((Text::CSV_XS::error_diag)[1], qr{^INI - allow_whitespace}, "Wrong combo - error message");
is   ((Text::CSV_XS::error_diag)[0], 1002, "Wrong combo - numeric error");

# Test 1003 in constructor
foreach my $x ("\r", "\n", "\r\n", "x\n", "\rx") {
    foreach my $attr (qw( sep_char quote_char escape_char )) {
        eval { $csv = Text::CSV.new ({ $attr => $x }) };
        is ((Text::CSV_XS::error_diag)[0], 1003, "eol in $attr");
        }
    }
# Test 1003 in methods
foreach my $attr (qw( sep_char quote_char escape_char )) {
    ok ($csv = Text::CSV.new, "New");
    eval { ok ($csv.$attr ("\n"), "$attr => \\n") };
    is (($csv.error_diag)[0], 1003, "not allowed");
    }

# And test erroneous calls
is (Text::CSV_XS::new (0),                 undef,       "new () as function");
is (Text::CSV_XS::error_diag (), "usage: my \$csv = Text::CSV.new ([{ option => value, ... }]);",
                                                        "Generic usage () message");
is (Text::CSV.new ({ oel     => "" }), undef,        "typo in attr");
is (Text::CSV_XS::error_diag (), "INI - Unknown attribute 'oel'",       "Unsupported attr");
is (Text::CSV.new ({ _STATUS => "" }), undef,        "private attr");
is (Text::CSV_XS::error_diag (), "INI - Unknown attribute '_STATUS'",   "Unsupported private attr");

foreach my $arg (undef, 0, "", " ", 1, [], [ 0 ], *STDOUT) {
    is  (Text::CSV.new ($arg),         undef,        "Illegal type for first arg");
    is ((Text::CSV_XS::error_diag)[0], 1000, "Should be a hashref - numeric error");
    }

1;
