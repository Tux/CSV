#!raku

use v6.c;
use Slang::Tuxic;

use Test;
use Text::CSV;

my $csv = Text::CSV.new (
     sep_char => "|",
    :binary,
    :allow_loose_quotes,
    :auto_diag,
    );

my $fh = IO::String.new (q{first|second|third|fourth|fifth|sixth|seventh|eigth|ninth|tenth|eleventh|twelth|thriteenth|fourteenth|fifteenth|sixteenth|seventeenth|eighteenth|nineteenth
1|||||||156999||12 Valley||D||N|3610|||68 V D|EA MATCH
2|||||||195658|"""The Cottage"" 54"|"""The "|K|||||307652|R, M|"""The ", K, |EA MATCH
3|||||||216058|117 The K|||||||||117 The K, |EA MATCH
});

$csv.column_names ($csv.getline ($fh));

my $nbr_lines = 0;
my @rows = $csv.getline_all ($fh);

is (@rows.elems, 3, "processed expected number of lines");

done-testing;
