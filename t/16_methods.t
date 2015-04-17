#!perl6

use v6;
use Slang::Tuxic;

use Test;
use Text::CSV;

# Test all methods that were defined as sub in XS and still supported in P6

ok (my $csv = Text::CSV.new,            "new");

ok (my $version = $csv.version,         "version");
ok ($version ~~ m{^ <[0..9.-]>+ $},     "CSV-$version");

is ($csv.quote_char,            '"',    "quote_char");
is ($csv.quote,                 '"',    "quote");
is ($csv.escape_char,           '"',    "escape_char");
is ($csv.sep_char,              ",",    "sep_char");
is ($csv.sep,                   ",",    "sep");
is ($csv.eol,                   Str,    "eol");
is ($csv.always_quote,          False,  "always_quote");
is ($csv.quote_space,           True,   "quote_space");
is ($csv.escape_null,           True,   "escape_null");
is ($csv.quote_binary,          True,   "quote_binary");
is ($csv.binary,                True,   "binary");
is ($csv.allow_loose_quotes,    False,  "allow_loose_quotes");
is ($csv.allow_loose_escapes,   False,  "allow_loose_escapes");
is ($csv.allow_whitespace,      False,  "allow_whitespace");
is ($csv.allow_unquoted_escape, False,  "allow_unquoted_escape");
is ($csv.blank_is_undef,        False,  "blank_is_undef");
is ($csv.empty_is_undef,        False,  "empty_is_undef");
is ($csv.auto_diag,             False,  "auto_diag");
is ($csv.keep_meta,             False,  "keep_meta"); 
is ($csv.keep-meta,             False,  "keep-meta");
is ($csv.meta,                  False,  "meta");
is ($csv.diag_verbose,          0,      "diag_verbose");
is ($csv.status,                True,   "status");
is ($csv.eof,                   False,  "eof");
is ($csv.error_diag,            "",     "error_diag");
is ($csv.record_number,         0,      "record_number");
is ($csv.string,                Str,    "string");
is ($csv.fields.elems,          0,      "fields");
is ($csv.list.elems,            0,      "list");
is ($csv.is_quoted (0),         False,  "is_quoted");
is ($csv.is_binary (0),         False,  "is_binary");
is ($csv.is_missing (0),        False,  "is_missing");
is ($csv.combine (),            True,   "combine");
is ($csv.parse (""),            True,   "parse");
is ($csv.column_names.elems,    0,      "column_names");

# Done or work-in progress (more tests needed?)
# getline
# getline_hr
# getline_all
# getline_hr_all
# fragment
# callbacks
# sub csv

done;

=finish

# Not ported - deprecated
sub PV { 0 }
sub IV { 1 }
sub NV { 2 }
sub decode_utf8
sub verbatim
sub types
