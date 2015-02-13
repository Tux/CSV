#!perl6

use v6;
use Slang::Tuxic;
use Inline::Perl5;

my $p5 = Inline::Perl5.new;

$p5.use ("Text::CSV_PP");

my @rows;
my $csv = $p5.invoke ("Text::CSV_PP", "new")
    or die "Cannot use CSV: ", $p5.invoke ("Text::CSV_PP", "error_diag");
$csv.binary (1);
$csv.auto_diag (1);

my Int $sum = 0;
for lines () :eager {
    $csv.parse ($_);
    $sum += $csv.fields.elems;
    }
$sum.say;
