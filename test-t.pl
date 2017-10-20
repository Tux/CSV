#!perl6

use v6;
use Text::CSV;

sub MAIN (Bool :$getline, Bool :$getline_all, Bool :$hyper) {

    my atomicint $sum = 0;
    if $getline_all {
        my $csv = Text::CSV.new;
        $sum = [+] $csv.getline_all($*IN)».map(*.elems);
        }

    elsif $getline {
        my $csv = Text::CSV.new;
        while $csv.getline($*IN) {
            $sum += $csv.fields.elems;
            }
        }

    elsif $hyper {
        # see https://irclog.perlgeek.de/perl6-dev/2017-10-20#i_15329645
        @*ARGS.pop;

        lines.hyper.map: {
            my $csv = once Text::CSV.new;
            $csv.parse($_);
            $sum ⚛+= $csv.fields.elems;
            }
        }

    else {
        my $csv = Text::CSV.new;
        for lines() {
            $csv.parse($_);
            $sum += $csv.fields.elems;
            }
        }
    $sum.say;
    }
