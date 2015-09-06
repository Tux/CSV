#!perl6

use v6;
use Slang::Tuxic;

use Text::CSV;
use Test;

my $fh = IO::String.new (q:to/EOC/);
a,b,c
1,foo,bar
EOC

my int $i = 0;
ok (my $csv = Text::CSV.new, "new CSV");
while (my @row = $csv.getline ($fh)) {
    $i++;
    }
is ($i, 2, "Number of correct lines");
is (+$csv.error-diag, 2012, "Parse should have stopped with EOF");
$fh.close;

# Check that while stops on error in getline
$fh = IO::String.new (q:to/EOC/);
a,b,c
1,foo,bar
2,"d" fail,3
3,baz,
EOC

$i = 0;
ok ($csv = Text::CSV.new, "new CSV");
while (@row = $csv.getline ($fh)) {
    $i++;
    }
is ($i, 2, "Number of correct lines");
is (+$csv.error-diag, 2023, "Parse should have stopped on error");

done-testing;
