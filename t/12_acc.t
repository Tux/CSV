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
is ($csv.escape-char,           '"',   "escape-char");
is ($csv.sep,                   ",",   "sep");
is ($csv.sep_char,              ",",   "sep_char");
is ($csv.sep-char,              ",",   "sep-char");
is ($csv.separator,             ",",   "separator");
is ($csv.eol.defined,           False, "eol");
is ($csv.always_quote,          False, "always_quote");
is ($csv.always-quote,          False, "always-quote");
is ($csv.quote_always,          False, "quote_always");
is ($csv.quote-always,          False, "quote-always");
is ($csv.binary,                True,  "binary");
is ($csv.allow_loose_quotes,    False, "allow_loose_quotes");
is ($csv.allow-loose-quotes,    False, "allow-loose-quotes");
is ($csv.allow_loose_quote,     False, "allow_loose_quote");
is ($csv.allow-loose-quote,     False, "allow-loose-quote");
is ($csv.allow_loose_escapes,   False, "allow_loose_escapes");
is ($csv.allow-loose-escapes,   False, "allow-loose-escapes");
is ($csv.allow_loose_escape,    False, "allow_loose_escape");
is ($csv.allow-loose-escape,    False, "allow-loose-escape");
is ($csv.allow_unquoted_escape, False, "allow_unquoted_escape");
is ($csv.allow_unquoted_escape, False, "allow_unquoted_escape");
is ($csv.allow_unquoted_escapes,False, "allow_unquoted_escapes");
is ($csv.allow_unquoted_escapes,False, "allow_unquoted_escapes");
is ($csv.allow_whitespace,      False, "allow_whitespace");
is ($csv.blank_is_undef,        False, "blank_is_undef");
is ($csv.blank-is-undef,        False, "blank-is-undef");
is ($csv.empty_is_undef,        False, "empty_is_undef");
is ($csv.empty-is-undef,        False, "empty-is-undef");
is ($csv.keep_meta,             False, "keep_meta");
is ($csv.keep-meta,             False, "keep-meta");
is ($csv.meta,                  False, "meta");
is ($csv.auto_diag,             False, "auto_diag");
is ($csv.auto-diag,             False, "auto-diag");
is ($csv.diag_verbose,          0,     "diag_verbose");
is ($csv.diag-verbose,          0,     "diag-verbose");
is ($csv.verbose_diag,          0,     "verbose_diag");
is ($csv.verbose-diag,          0,     "verbose-diag");
is ($csv.quote_space,           True,  "quote_space");
is ($csv.quote-space,           True,  "quote-space");
is ($csv.quote_empty,           False, "quote_empty");
is ($csv.quote-empty,           False, "quote-empty");
is ($csv.quote_null,            False, "quote_null");
is ($csv.quote-null,            False, "quote-null");
is ($csv.escape_null,           False, "escape_null");
is ($csv.escape-null,           False, "escape-null");
is ($csv.quote_binary,          True,  "quote_binary");
is ($csv.quote-binary,          True,  "quote-binary");
is ($csv.record_number,         0,     "record_number");
is ($csv.record-number,         0,     "record-number");

is ($csv.binary (),             True,  "binary ()");
is ($csv.binary (False),        False, "binary (False)");
is ($csv.binary (Bool),         False, "binary (False)");
is ($csv.binary (Str),          False, "binary (False)");
is ($csv.binary (""),           False, "binary (False)");
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
is ($csv.separator (";"),   ";",    "separator (;)");
is ($csv.separator,         ";",    "separator ()");
is ($csv.quote_char ("="),  "=",    "quote_char (=)");
is ($csv.quote ("="),       "=",    "quote (=)");
is ($csv.eol (Str).defined, False,  "eol (Str)");
is ($csv.eol ("").defined,  False,  "eol ('') => Str");
is ($csv.eol ("\r"),        "\r",   "eol (\\r)");

is ($csv.always_quote (False),         False, "always_quote (False)");
is ($csv.always_quote (True),          True,  "always_quote (True)");
is ($csv.always-quote (True),          True,  "always-quote (True)");
is ($csv.quote_always (True),          True,  "quote_always (True)");
is ($csv.quote-always (True),          True,  "quote-always (True)");
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
is ($csv.empty_is_undef (False),       False, "empty_is_undef (True)");
is ($csv.empty_is_undef (0),           False, "empty_is_undef (1)");
is ($csv.keep_meta (True),             True,  "keep_meta (True)");
is ($csv.keep-meta (1),                True,  "keep-meta (1)");
is ($csv.auto_diag (1),                True,  "auto_diag (1)");
is ($csv.auto_diag (True),             True,  "auto_diag (True)");
is ($csv.auto_diag (False),            False, "auto_diag (False)");
is ($csv.auto_diag (Str),              False, "auto_diag (Str)");
is ($csv.auto_diag (""),               False, "auto_diag (\"\")");
is ($csv.diag_verbose (1),             1,     "diag_verbose (1)");
is ($csv.diag_verbose (2),             2,     "diag_verbose (2)");
is ($csv.diag_verbose (9),             9,     "diag_verbose (9)");
is ($csv.diag_verbose (True),          1,     "diag_verbose (True)");
is ($csv.diag_verbose (False),         0,     "diag_verbose (False)");
is ($csv.diag_verbose (Str),           0,     "diag_verbose (Str)");
is ($csv.diag_verbose (""),            0,     "diag_verbose (\"\")");
is ($csv.quote_space (True),           True,  "quote_space (True)");
is ($csv.quote_space (1),              True,  "quote_space (1)");
is ($csv.quote_empty (True),           True,  "quote_empty (True)");
is ($csv.quote_empty (1),              True,  "quote_empty (1)");
is ($csv.quote_null (True),            True,  "quote_null (True)");
is ($csv.quote_null (1),               True,  "quote_null (1)");
is ($csv.quote_binary (True),          True,  "quote_binary (True)");
is ($csv.quote_binary (1),             True,  "quote_binary (1)");
is ($csv.escape_char ("\\"),           "\\",  "escape_char (\\)");
ok ($csv.combine (@fld),                      "combine");
is ($csv.string, qq{=txt \\=, "Hi!"=;=Yes=;==;=2=;;=1.09=;=\r=;\r}, "string");

is ($csv.allow_whitespace (False), False, "allow_whitespace (False)");
is ($csv.allow_whitespace (0),     False, "allow_whitespace (0)");
is ($csv.quote_space (False),      False, "quote_space (False)");
is ($csv.quote_space (0),          False, "quote_space (0)");
is ($csv.quote_empty (False),      False, "quote_empty (False)");
is ($csv.quote_empty (0),          False, "quote_empty (0)");
is ($csv.quote_null (False),       False, "quote_null (False)");
is ($csv.quote_null (0),           False, "quote_null (0)");
is ($csv.quote_binary (False),     False, "quote_binary (False)");
is ($csv.quote_binary (0),         False, "quote_binary (0)");
is ($csv.sep ("--"),               "--",  "sep (\"--\")");
is ($csv.sep_char (),              "--",  "sep_char");
is ($csv.sep-char,                 "--",  "sep_char");
is ($csv.separator,                "--",  "sep_char");
is ($csv.quote ("++"),             "++",  "quote (\"++\")");
is ($csv.quote_char (),            "++",  "quote_char");

# Attribute aliasses
ok ($csv = Text::CSV.new (quote_always => 1, verbose_diag => 1), "New with aliasses");
is ($csv.always_quote, True, "always_quote = quote_always");
is ($csv.diag_verbose, 1,    "diag_verbose = verbose_diag");

# Funny settings
ok ($csv = Text::CSV.new (
    # sep_char    => Str, -- sep cannot be undefined!
    quote  => Str,
    Escape => Str,
    ),                                  "new (Str ...)");
is ($csv.quote_char.defined,     False, "quote_char  Str");
is ($csv.quote.defined,          False, "quote       Str");
is ($csv.escape_char.defined,    False, "escape_char Str");
ok ($csv.parse ("foo"),                 "parse (foo)");
is ($csv.sep (","),              ",",   "sep = ,");
is ($csv.record_number,          1,     "record_number 1");
ok ($csv.parse ("bar"),                 "parse (bar)");
is ($csv.record_number,          2,     "record_number 2");
is ($csv.binary (False),         False, "no binary");
ok (!$csv.parse ("foo,foo\0bar"),       "parse (foo,foo)");
ok ($csv.escape_char ("\\"),            "set escape");
ok (!$csv.parse ("foo,foo\0bar"),       "parse (foo)");
is ($csv.binary (1),             True,  "binary (1)");
ok ($csv.parse ("foo,foo\0bar"),        "parse (foo)");

# Some forbidden combinations
{   my Int $e = 0;
    {   $csv = Text::CSV.new (Sep => Str);
        CATCH { default { $e = .error; }}
        }
    is ($e, 1008, "Sanity check");
    {   $csv = Text::CSV.new (Sep => "");
        CATCH { default { $e = .error; }}
        }
    is ($e, 1008, "Sanity check");
    ok ($csv = Text::CSV.new (), "New for undefined Sep");
    {   $csv.sep (Str);
        CATCH { default { $e = .error; }}
        }
    is ($e, 1008, "Sanity check");
    {   $csv.sep ("");
        CATCH { default { $e = .error; }}
        }
    is ($e, 1008, "Sanity check");
    }
for (" ", "\t") -> $ws {
    my Int $e = 0;
    ok ($csv = Text::CSV.new (escape_char => $ws), "New blank escape");
    {   $csv.allow_whitespace (True);
        CATCH { default { $e = .error; }}
        }
    is ($e, 1002, "Sanity check"); $e = 0;
    ok ($csv = Text::CSV.new (quote_char  => $ws), "New blank quote");
    {   $csv.allow_whitespace (True);
        CATCH { default { $e = .error; }}
        }
    is ($e, 1002, "Sanity check"); $e = 0;
    ok ($csv = Text::CSV.new (:allow_whitespace), "New ws True");
    {   $csv.escape_char ($ws);
        CATCH { default { $e = .error; }}
        }
    is ($e, 1002, "Sanity check"); $e = 0;
    ok ($csv = Text::CSV.new (:allow_whitespace), "New ws True");
    {   $csv.quote_char  ($ws);
        CATCH { default { $e = .error; }}
        }
    is ($e, 1002, "Sanity check"); $e = 0;
    }

# Test 1002 in constructor
{   my Int $e = 0;
    {   $csv = Text::CSV.new (esc => "\t", quo => " ", :allow-whitespace);
        CATCH { default { $e = .error; }}
        }
    is ($e, 1002, "no whitespace in descriptor");
    }

# Test 1003 in constructor
for ("\r", "\n", "\r\n", "x\n", "\rx") -> $x {
    for <sep_char quote_char escape_char> -> $attr {
        my Int $e = 0;
        {   $csv = Text::CSV.new (|($attr => $x));
            CATCH { default { $e = .error; }}
            }
        is ($e, 1003, $x.perl ~ " in $attr");
        }
    }

# Test 1003 in methods
for <sep_char quote_char escape_char> -> $attr {
    my Int $e = 0;
    ok ($csv = Text::CSV.new, "New");
    {   $csv."$attr"("\n");
        CATCH { default { $e = .error; }}
        }
    is ($e, 1003, "$attr => \\n is not allowed");
    }

{   my Int $e = 0;
    {   $csv = Text::CSV.new (oel => "\n"); # TYPO
        CATCH { default { $e = .error; }}
        }
    is ($e, 1000, "Typo in attribute name");
    }

done-testing;
