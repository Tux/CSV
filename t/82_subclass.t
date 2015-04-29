#!perl6

use v6;
use Slang::Tuxic;

use Test;
use Text::CSV;

class Text::CSV::Subclass is Text::CSV { }

ok (1, "Subclassed");

my $csvs = Text::CSV::Subclass.new ();
is (~$csvs.error_diag (), "", "Last failure for new () - OK");

my $sc_csv;
{   my $e;
    {   $sc_csv = Text::CSV::Subclass.new (:!auto_diag, ecs_char => ":");
        CATCH { default { $e = $_; "" }}
        }
    is ($e.error,   1000,   "Fail new because of unknown attribute");
    is ($e.message, "INI - constructor failed: Unknown attribute 'ecs_char'",
                            "Reason feeedback");
    }
is ($sc_csv.defined, False, "Unsupported attribute");

done;
