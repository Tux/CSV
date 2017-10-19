#!perl6

use v6;
use Slang::Tuxic;

use Test;
use Text::CSV;

my $csv = Text::CSV.new ();

is ($csv.formula,		"none",		"default");
is ($csv.formula ("die"),	"die",		"die");
is ($csv.formula ("croak"),	"croak",	"croak");
is ($csv.formula ("diag"),	"diag",		"diag");
is ($csv.formula ("empty"),	"empty",	"empty");
is ($csv.formula (""),		"empty",	"explicit empty");
is ($csv.formula ("undef"),	"undef",	"undef");
is ($csv.formula (Str), 	"undef",	"explicit undef");
is ($csv.formula ("none"),	"none",		"none");

is ($csv.formula_handling,		"none",		"default");
is ($csv.formula_handling ("DIE"),	"die",		"DIE");
is ($csv.formula_handling ("CROAK"),	"croak",	"CROAK");
is ($csv.formula_handling ("DIAG"),	"diag",		"DIAG");
is ($csv.formula_handling ("EMPTY"),	"empty",	"EMPTY");
is ($csv.formula_handling ("UNDEF"),	"undef",	"UNDEF");
is ($csv.formula_handling ("NONE"),	"none",		"NONE");

is ($csv.formula-handling,		"none",		"default");
is ($csv.formula-handling ("die"),	"die",		"die");
is ($csv.formula-handling ("croak"),	"croak",	"croak");
is ($csv.formula-handling ("diag"),	"diag",		"diag");
is ($csv.formula-handling ("empty"),	"empty",	"empty");
is ($csv.formula-handling ("undef"),	"undef",	"undef");
is ($csv.formula-handling ("none"),	"none",		"none");

for ("xxx", "DIAX") -> $f {
    my $e;
    {   is ($csv.formula ($f),	"diag",	"invalid");
        CATCH { default { $e = $_; }}
        }
    is (+$e, 1500, "unsupported attribute '$f'");
    }

for < none die croak diag empty undef > -> $f {
    ok (my $p = Text::CSV.new (formula => $f), "new with $f");
    is ($p.formula, $f, "Set to $f");
    }

for < none die croak diag empty undef > -> $formula {
    ok (my $p = Text::CSV.new (:$formula), "new with named $formula");
    is ($p.formula, $formula, "Set to $formula");
    }

# Parser

my @data =
    "a,b,c",
    "1,2,3",
    "=1+2,3,4",
    "1,=2+3,4",
    "1,2,=3+4";

sub parse (Str $formula) {
    ok (my $csv = Text::CSV.new (:$formula), "new $formula");
    @data.map: { $csv.parse ($_); $csv.strings };
    } # parse

is-deeply (parse ("none"), (
    [ "a",	"b",	"c",	],
    [ "1",	"2",	"3",	],
    [ "=1+2",	"3",	"4",	],
    [ "1",	"=2+3",	"4",	],
    [ "1",	"2",	"=3+4",	],
    ), "Default (none)");

my $e;
{   parse ("die");
    CATCH { default { $e = $_ }}
    }
is ($e, "Formulas are forbidden", "Parse formula with die");
{   parse ("croak");
    CATCH { default { $e = $_ }}
    }
is ($e, "Formulas are forbidden", "Parse formula with croak");

my @e;
{ is-deeply (parse ("diag"), (
    [ "a",	"b",	"c",	],
    [ "1",	"2",	"3",	],
    [ "=1+2",	"3",	"4",	],
    [ "1",	"=2+3",	"4",	],
    [ "1",	"2",	"=3+4",	],
    ), "Default");
  CONTROL { when CX::Warn { @e.push: $_.Str; .resume } };
  }
is-deeply (@e, [ # These will change
    "Field 1 in record 3 contains formula '=1+2'\n",
    "Field 2 in record 4 contains formula '=2+3'\n",
    "Field 3 in record 5 contains formula '=3+4'\n",
    ], "Got expected warnings");

is-deeply (parse ("empty"), (
    [ "a",	"b",	"c",	],
    [ "1",	"2",	"3",	],
    [ "",	"3",	"4",	],
    [ "1",	"",	"4",	],
    [ "1",	"2",	"",	],
    ), "Empty");

is-deeply (parse ("undef"), (
    [ "a",	"b",	"c",	],
    [ "1",	"2",	"3",	],
    [ Str,	"3",	"4",	],
    [ "1",	Str,	"4",	],
    [ "1",	"2",	Str,	],
    ), "Undef");

sub writer (Str $formula) {
    ok (my $csv = Text::CSV.new (:$formula, :quote_empty), "new $formula");
    ok ($csv.combine ("1", "=2+3", "4"), "combine $formula");
    $csv.string;
    } # writer

is (       writer ("none"),	<1,=2+3,4>, "Out none");
is (       writer ("empty"),	<1,"",4>,   "Out empty");
is (       writer ("undef"),	<1,,4>,     "Out undef");

{   writer ("die");
    CATCH { default { $e = $_ }}
    }
is ($e, "Formulas are forbidden", "Combine formula with die");
{   writer ("croak");
    CATCH { default { $e = $_ }}
    }
is ($e, "Formulas are forbidden", "Combine formula with croak");

{ @e = ();
  is (     writer ("diag"),	<1,=2+3,4>, "Out diag");
  CONTROL { when CX::Warn { @e.push: $_.Str; .resume } };
  }
is-deeply (@e, ["Field 2 contains formula '=2+3'\n"], "Got a warning");

{   @e = ();
    ok (my $csv = Text::CSV.new (formula => "diag"), "new diag hr");
    ok ($csv.column_names ("code", "value", "desc"), "Set column names");
    ok ($csv.parse ("1,=2+3,4"), "Parse");
    CONTROL { when CX::Warn { @e.push: $_.Str; .resume } };
    }
is-deeply (@e,
    ["Field 2 (column: 'value') in record 1 contains formula '=2+3'\n"],
    "Warning for HR");

done-testing;
