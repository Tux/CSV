#!perl6

use v6;
use Slang::Tuxic;
use CSV::Parser;

my $fh = open "/tmp/hello.csv", :r, chomp => False;
my $parser = CSV::Parser.new (file_handle => $fh, contains_header_row => False);

my int $r   = 0;
my int $sum = 0;
while (my $rec = $parser.get_line) {
    $r++;
    my int $n = +$rec.keys or last;
    $sum += $n;
    }
$sum.say;
