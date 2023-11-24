#!raku

# Cannot set $*OUT.nl-out to Str

use v6;
use Slang::Tuxic;

use Test;
use Text::CSV;

my $efn = "_cmnt.csv";
my @cs  = "#", "//", "Comment ", "\x[2603]";
my @rst = "", " 1,2", "a,b";

for (|@cs) -> $cs {
    for (|@rst) -> $rs {

        my $csv = Text::CSV.new ();
           $csv.comment-str ($cs);

        my IO::Handle $fh = open $efn, :w;
        $fh.say (           $cs,      $rs);
        $fh.say ("c,",      $cs          );
        $fh.say (" ",       $cs          );
        $fh.say ("e,",      $cs, ",", $rs);
        $fh.say (           $cs          );
        $fh.say ("g,i",     $cs          );
        $fh.say ("j,\"k\n", $cs, "k\""   );
        $fh.close;

        $fh = open $efn, :r;

        my @r = $rs.split (",");
        is-deeply ($csv.getline ($fh), [ "c", $cs          ], "$cs , $rs");
        is-deeply ($csv.getline ($fh), [ " $cs"            ], "leading space");
        is-deeply ($csv.getline ($fh), [ "e", $cs, |@r     ], "not start of line");
        is-deeply ($csv.getline ($fh), [ "g", "i$cs"       ], "not start of field");
        is-deeply ($csv.getline ($fh), [ "j", "k\n$cs"~"k" ], "inside quoted after newline");

        $fh.close;

        unlink $efn;
        }
    }

{   my IO::Handle $fh = open $efn, :w;
    $fh.say ("id | name");
    $fh.say ("# ");
    $fh.say ("42 | foo");
    $fh.say ("#");
    $fh.close;

    is-deeply ([csv (
        in               => $efn,
        sep              => "|",
        headers          => "auto",
        allow_whitespace => 1,
        comment_str      => "#",
        )], [{ :id("42"), :name("foo") },], "Auto with last line comment");

    unlink $efn;
    }

done-testing;
