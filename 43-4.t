#!perl6

use v6;

use Test;

my $b = Buf.new(224,34,204,182);
dd $b;

ok ((my Str $u = $b.decode("utf8-c8")), "decode");

note $u;

my $s = <\x[10fffd]xE0\"\x[336]>; #"
my @re = <">, <,>;
my @x = $s.split(@re, :v, :skip-empty);

dd @x;
