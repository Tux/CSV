#!perl6

use v6;
use Slang::Tuxic;

use Test;
use Text::CSV;

my CSV::Field $f .= new;      # Undefined
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

done-testing;
