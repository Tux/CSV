#!raku

use v6;
use Slang::Tuxic;
use lib "lib";

use Test;
use Test::META;

plan 1;

# That's it
meta-ok ();

done-testing;
