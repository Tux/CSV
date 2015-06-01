#!perl6

use v6;
use Slang::Tuxic;
use Text::CSV;

@*ARGS.elems or @*ARGS.push: [ q:to/EOD/;
    a;b;c;d;e;f
    1;2;3;4;5;6
    2;3;4;5;6;7
    3;4;5;6;7;8
    4;5;6;7;8;9
    EOD
    ];

csv (in => csv (in => $_, sep_char => ";"), out => $*OUT) for @*ARGS;
