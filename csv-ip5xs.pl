#!perl6

use v6;
use Slang::Tuxic;
use Text::CSV_XS:from<Perl5>;

my @rows;
my $csv = Text::CSV_XS.new ()
    or die "Cannot use CSV: ", Text::CSV_XS.error_diag ();
$csv.binary (1);
$csv.auto_diag (1);

my Int $sum = 0;
for lines () :eager {
    $csv.parse ($_);
    $sum += $csv.fields.elems;
    }
$sum.say;
