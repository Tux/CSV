#!perl6

use v6;
use Slang::Tuxic;
use Inline::Perl5;

my $p5 = Inline::Perl5.new;

$p5.use ("Text::CSV_XS");

my @rows;
my $csv = $p5.invoke ("Text::CSV_XS", "new")
    or die "Cannot use CSV: ", $p5.invoke ("Text::CSV_XS", "error_diag");
$csv.binary (1);
$csv.auto_diag (1);

my $fh = open "/tmp/hello.csv", :r, chomp => False;

my Int $sum = 0;
while (my $r = $csv.getline ($fh)) {
    $sum += +$r;
    }
$sum.say;
