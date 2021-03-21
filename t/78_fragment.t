#!raku

use v6;
use Slang::Tuxic;

my $tfn = "_78matrix.csv"; END { unlink $tfn; }

use Test;
use Text::CSV;

my $csv = Text::CSV.new;

# Colranges on a single row
my Str $str = (1 .. 10).join (",");
my Str @exp = (1 .. 10).map (~*);
is ([$csv.getline ($str).map (~*)], @exp,                "no fragments");
$csv.colrange ([1,]);
is ([$csv.getline ($str).map (~*)], @exp[1],             "fragment [1]");
$csv.colrange ([1, 4]);
is ([$csv.getline ($str).map (~*)], @exp[1,4],           "fragment [1,4]");
$csv.colrange ([1, 4..6]);
is ([$csv.getline ($str).map (~*)], @exp[1,4..6],        "fragment [1,4..6]");
$csv.colrange ([1, 4..6, 8..Inf]);
is ([$csv.getline ($str).map (~*)], @exp[1,4..6,8..Inf], "fragment [1,4..6,8..Inf]");

$csv.colrange ("2");
is ([$csv.getline ($str).map (~*)], @exp[1],             "fragment '2'");
$csv.colrange ("2;5");
is ([$csv.getline ($str).map (~*)], @exp[1,4],           "fragment '2;5'");
$csv.colrange ("2;5-7");
is ([$csv.getline ($str).map (~*)], @exp[1,4..6],        "fragment '2;5-7'");
$csv.colrange ("2;5-7;9-*");
is ([$csv.getline ($str).map (~*)], @exp[1,4..6,8..Inf], "fragment '2;5-7;9-*'");
$csv.colrange ("2;5-7;5-6;2-2;7-7;9-*;12-*");
is ([$csv.getline ($str).map (~*)], @exp[1,4..6,8..Inf], "fragment '2;5-7;9-*' with overlaps");
$csv.colrange ("12-24;14-*");
is ([$csv.getline ($str).map (~*)], [[],], "out of bound fragment");

# Tests on a matrix
my @expect =
    [11,12,13,14,15,16,17,18,19],
    [21,22,23,24,25,26,27,28,29],
    [31,32,33,34,35,36,37,38,39],
    [41,42,43,44,45,46,47,48,49],
    [51,52,53,54,55,56,57,58,59],
    [61,62,63,64,65,66,67,68,69],
    [71,72,73,74,75,76,77,78,79],
    [81,82,83,84,85,86,87,88,89],
    [91,92,93,94,95,96,97,98,99];

my $fh = open $tfn, :w;
$fh.say ($_.join (",")) for @expect;
$fh.close;

sub to-int (@str) { [ @str.map ({$[ $_.map (*.Int) ]}) ]; }

$csv = Text::CSV.new;

$fh = open $tfn, :r;
my @matrix = $csv.getline_all ($fh, :!meta);
is-deeply (to-int (@matrix), @expect, "Whole matrix");
$fh.close;

my @test =
    "row=1"         => [[ 11,12,13,14,15,16,17,18,19 ],],
    "row=2-3"       => [[ 21,22,23,24,25,26,27,28,29 ],
			[ 31,32,33,34,35,36,37,38,39 ]],
    "row=2;4;6"     => [[ 21,22,23,24,25,26,27,28,29 ],
			[ 41,42,43,44,45,46,47,48,49 ],
			[ 61,62,63,64,65,66,67,68,69 ]],
    "row=1-2;4;6-*" => [[ 11,12,13,14,15,16,17,18,19 ],
			[ 21,22,23,24,25,26,27,28,29 ],
			[ 41,42,43,44,45,46,47,48,49 ],
			[ 61,62,63,64,65,66,67,68,69 ],
			[ 71,72,73,74,75,76,77,78,79 ],
			[ 81,82,83,84,85,86,87,88,89 ],
			[ 91,92,93,94,95,96,97,98,99 ]],
    "row=24"        => $[],

    "col=1"         => [[11],[21],[31],[41],[51],[61],[71],[81],[91]],
    "col=2-3"       => [[12,13],[22,23],[32,33],[42,43],[52,53],
			[62,63],[72,73],[82,83],[92,93]],
    "col=2;4;6"     => [[12,14,16],[22,24,26],[32,34,36],[42,44,46],[52,54,56],
			[62,64,66],[72,74,76],[82,84,86],[92,94,96]],
    "col=1-2;4;6-*" => [[11,12,14,16,17,18,19], [21,22,24,26,27,28,29],
			[31,32,34,36,37,38,39], [41,42,44,46,47,48,49],
			[51,52,54,56,57,58,59], [61,62,64,66,67,68,69],
			[71,72,74,76,77,78,79], [81,82,84,86,87,88,89],
			[91,92,94,96,97,98,99]],
    "col=24"        => [[],[],[],[],[],[],[],[],[]],

    #cell=R,C
    "cell=7,7"      => [[ 77 ],],
    "cell=7,7-8,8"  => [[ 77,78 ], [ 87,88 ]],
    "cell=7,7-*,8"  => [[ 77,78 ], [ 87,88 ], [ 97,98 ]],
    "cell=7,7-8,*"  => [[ 77,78,79 ], [ 87,88,89 ]],
    "cell=7,7-*,*"  => [[ 77,78,79 ], [ 87,88,89 ], [ 97,98,99 ]],

    "cell=1,1-2,2;3,3-4,4"	=> [
	[11,12],
	[21,22],
		[33,34],
		[43,44]],
    "cell=1,1-3,3;2,3-4,4"	=> [
	[11,12,13],
	[21,22,23,24],
	[31,32,33,34],
	      [43,44]],
    "cell=1,1-3,3;2,2-4,4;2,3;4,2"	=> [
	[11,12,13],
	[21,22,23,24],
	[31,32,33,34],
	   [42,43,44]],
    "cell=1,1-2,2;3,3-4,4;1,4;4,1"	=> [
	[11,12,     14],
	[21,22],
		[33,34],
	[41,     43,44]],
    ;

for @test -> $t {
    my $spec = $t.key;
    my $expt = $t.value;

    $fh = open $tfn, :r;
    is-deeply (to-int ($csv.fragment ($fh, $spec, :!meta)), $expt, "spec: $spec");
    $fh.close;
    }

$csv.column_names ("c1");
$fh = open $tfn, :r;
is-deeply ($csv.fragment ($fh, "row=3"),
    [{ :c1("31") },],            "Fragment to AoH (row)");
$fh.close;

$csv.column_names (< x x c3 >);
$fh = open $tfn, :r;
my @rx;
# { c3 => 3 }              is a hash
# { c3 => ~(10 * $_ + 3) } is a closure generating a pair
# @rx = (1..9).map ({ :c3(~(10 * $_ + 3)).hash.item });
for (flat 1..9) -> $x { @rx.push: ${ c3 => ~(10 * $x + 3) }};
is-deeply ($csv.fragment ($fh, "col=3"),
    [ @rx ],                    "Fragment to AoH (col)");
$fh.close;

$csv.column_names ("c3","c4");
$fh = open $tfn, :r;
is-deeply ($csv.fragment ($fh, "cell=3,2-4,3"),
    [{ :c3("32"), :c4("33") },
     { :c3("42"), :c4("43") }], "Fragment to AoH (cell)");
$fh.close;

done-testing;
