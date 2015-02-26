#!perl6

use v6;
use Slang::Tuxic;

use Test;
use Text::CSV;

# Test all methods that were defined as sub in XS and still supported in P6

# sub new
ok (my $csv = Text::CSV.new,            "new");

# sub version
ok (my $version = $csv.version,         "version");
ok ($version ~~ m{^ <[0..9.-]>+ $},     "CSV-$version");

# sub quote_char
is ($csv.quote_char,            '"',    "quote_char");
# sub quote
is ($csv.quote,                 '"',    "quote");
# sub escape_char
is ($csv.escape_char,           '"',    "escape_char");
# sub sep_char
is ($csv.sep_char,              ",",    "sep_char");
# sub sep
is ($csv.sep,                   ",",    "sep");
# sub eol
is ($csv.eol,                   Str,    "eol");
# sub always_quote
is ($csv.always_quote,          False,  "always_quote");
# sub quote_space
is ($csv.quote_space,           True,   "quote_space");
# sub escape_null
is ($csv.escape_null,           True,   "escape_null");
# sub quote_binary
is ($csv.quote_binary,          True,   "quote_binary");
# sub binary
is ($csv.binary,                True,   "binary");
# sub allow_loose_quotes
is ($csv.allow_loose_quotes,    False,   "allow_loose_quotes");
# sub allow_loose_escapes
is ($csv.allow_loose_escapes,   False,   "allow_loose_escapes");
# sub allow_whitespace
is ($csv.allow_whitespace,      False,   "allow_whitespace");
# sub allow_unquoted_escape
is ($csv.allow_unquoted_escape, False,   "allow_unquoted_escape");
# sub blank_is_undef
is ($csv.blank_is_undef,        False,   "blank_is_undef");
# sub empty_is_undef
is ($csv.empty_is_undef,        False,   "empty_is_undef");
# sub auto_diag
is ($csv.auto_diag,             0,       "auto_diag");
# sub diag_verbose
is ($csv.diag_verbose,          0,       "diag_verbose");
# sub status
is ($csv.status,                True,    "status");
# sub eof
is ($csv.eof,                   False,   "eof");
# sub error_diag
is ($csv.error_diag,            "",      "error_diag");
# sub record_number
is ($csv.record_number,         0,       "record_number");
# sub string
is ($csv.string,                Str,     "string");
# sub fields
is_deeply ($csv.fields, Array[CSV::Field].new (), "fields");
# sub is_quoted
is ($csv.is_quoted (0),         False,   "is_quoted");
# sub is_binary
is ($csv.is_binary (0),         False,   "is_binary");
# sub is_missing
is ($csv.is_missing (0),        False,   "is_missing");
# sub combine
is ($csv.combine (),            True,    "combine");
# sub parse
is ($csv.parse (""),            True,    "parse");

# sub callbacks
# sub column_names
# sub bind_columns
# sub getline_hr
# sub getline_hr_all
# sub print_hr
# sub fragment
# sub csv

done;

=finish

# Not ported - deprecated
sub PV { 0 }
sub IV { 1 }
sub NV { 2 }
sub decode_utf8
sub keep_meta_info
sub verbatim
sub meta_info
sub types
