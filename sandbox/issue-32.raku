#!raku

use v6;
use Slang::Tuxic;
use Text::CSV;

my $csv  = Text::CSV.new;
my $fh   = open "issue-32.csv", :r, :!chomp;  
my @hdr  = $csv.header ($fh, munge-column-names => "fc").column-names;
my @rows = $csv.getline_hr_all ($fh); .say for @rows;

dd @hdr;

Text::CSV.csv (in => "issue-32.csv", keep-headers => my @h);
@h.dd;
