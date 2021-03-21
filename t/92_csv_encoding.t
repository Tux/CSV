#!raku

use v6;
use Slang::Tuxic;

use Test;
use Text::CSV;

my $csv    = Text::CSV.new;

my $fni    = "_92in.csv";
END { unlink $fni; }

spurt $fni, 'ID;Gerät;Nr', :enc<latin1>;

my $csv-in = csv :in($fni), :encoding('latin1'), :sep_char<;>;
ok $csv-in, "No problems with encoding";

done-testing;
