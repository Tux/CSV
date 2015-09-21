#!perl6

use v6;
use Slang::Tuxic;
use Text::CSV;

sub MAIN (:$getline, :$getline_all) {

    my $csv = Text::CSV.new;

    my Int $sum = 0;
    if ($getline_all) { # slowest
        $sum = [+] $csv.getline_all ($*IN)».map(*.elems);
        }
    elsif ($getline) {  # middle, but safe
        while ($csv.getline ($*IN)) {
            $sum += $csv.fields.elems;
            }
        }
    else {              # fastest, but unsafe
        for lines () {
            $csv.parse ($_);
            $sum += $csv.fields.elems;
            }
        }
    $sum.say;
    }
