#!perl6

use v6;
use Slang::Tuxic;
use Text::CSV_XS:from<Perl5>;

my @rows;
my $csv = Text::CSV_XS.new ()
    or die "Cannot use CSV: ", Text::CSV_XS.error_diag ();
$csv.binary (1);
$csv.auto_diag (1);

my $fh = open "/tmp/hello.csv", :r, chomp => False;

my Int $sum = 0;
while (my $r = $csv.getline ($fh)) {
    $sum += +$r;
    }
$sum.say;
