#!raku

use v6;
use Slang::Tuxic;
use Text::CSV;

# https://github.com/Tux/CSV/issues/34
# https://unix.stackexchange.com/a/755782/227738

# Used the firt 7 lines of the example dat in the stackexchange post
# Removed the last element from line 4, which should warn under strict

my @a = csv (in => "sandbox/issue-34.csv", sep => ";", :auto-diag, :strict);

@a = @a>>.map ({ sprintf "%.2d", $_ });

csv (in => @a, out => $*OUT, sep => ";");
