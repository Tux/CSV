#!perl6

use v6;
use Slang::Tuxic;

use Test;
use Text::CSV;

my $csv    = Text::CSV.new;

my $fni    = "_92in.csv";

END { unlink $fni }

my $handle = $fni.IO.open( :enc("latin1"), :w );
say $handle.perl;

my $latin1-str = 'ID;Gerät;Nr'.encode('latin1');
say $latin1-str.perl;
$handle.write( $latin1-str);
$handle.close;

my $csv-in = csv :in($fni), :encoding('latin1'), :sep_char<;>;
say $csv-in;

done-testing;
