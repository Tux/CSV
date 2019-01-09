#!perl6

use v6;

use Test;
use Text::CSV;
use Slang::Tuxic;

my $file = "_91test.csv"; END { unlink $file }
my $data =
    "foo,bar,baz\n"~
    "1,2,3\n"~
    "2,a b,\n";
my $fh = open $file, :w;
$fh.print ($data);
$fh.close;

my @aoa =
    [< foo  bar    baz >],
    [  "1", "2",   "3"  ],
    [  "2", "a b", ""   ];
my @aoh =
    { foo => "1", bar => "2",   baz => "3" },
    { foo => "2", bar => "a b", baz => ""  };

sub Empty (CSV::Row $r) {}

for (< after_in on_in before_out >) -> $t {
    is-deeply (csv (in => $file,             |( $t => &Empty )), @aoa, "callback $t on AOA with empty sub");
    is-deeply (csv (in => $file, callbacks => { $t => &Empty }), @aoa, "callback $t on AOA with empty sub");
    }
is-deeply (csv (in => $file, after_in => &Empty,
    callbacks => { on_in => &Empty }), @aoa, "callback after_in and on_in on AOA");

for (< after_in on_in before_out >) -> $t {
    is-deeply (csv (in => $file, headers => "auto",             |( $t => &Empty )), @aoh, "callback $t on AOH with empty sub");
    is-deeply (csv (in => $file, headers => "auto", callbacks => { $t => &Empty }), @aoh, "callback $t on AOH with empty sub");
    }
is-deeply (csv (in => $file, headers => "auto", after_in => &Empty,
    callbacks => { on_in => &Empty }), @aoh, "callback after_in and on_in on AOH");

sub Push (CSV::Row $r) { $r.push: "A"; }

is-deeply (csv (in => $file, after_in => &Push), [
    [< foo  bar   baz   A >],
    [  "1", "2",  "3", "A" ],
    [  "2", "a b", "", "A" ],
    ], "AOA ith after_in callback function");

sub Change (CSV::Row $r) { $r.csv.column-names and $r<baz>.text = "A"; }

is-deeply (csv (in => $file, headers => "auto", after_in => &Change), [
    { foo => "1", bar => "2",   baz => "A" },
    { foo => "2", bar => "a b", baz => "A" },
    ], "AOH with after_in callback function");

is-deeply (csv (in => $file, key => "foo"), {
    "1" => { foo => "1", bar => "2",   baz => "3" },
    "2" => { foo => "2", bar => "a b", baz => ""  },
    }, "Simple key");

is-deeply (csv (in => $file, key => "foo", on_in => -> CSV::Row $r {
        $r.csv.column_names and $r<bar>.text = "" }), {
    "1" => { foo => "1", bar => "", baz => "3" },
    "2" => { foo => "2", bar => "", baz => ""  },
    }, "Simple key with in-line on_in");

is-deeply (csv (in => $file, key => "foo", on_in => {
        $^r.csv.column_names and $^r<bar>.text = "" }), {
    "1" => { foo => "1", bar => "", baz => "3" },
    "2" => { foo => "2", bar => "", baz => ""  },
    }, "Simple key with in-line typeless on_in");

is-deeply (csv (in => $file, key => "foo", on_in => { $^r<bar> = "" }), {
    "1" => { foo => "1", bar => "", baz => "3" },
    "2" => { foo => "2", bar => "", baz => ""  },
    }, "Simple key with in-line on_in with direct key assignment");

is-deeply (csv (in => $file, on_in => { $^r[1] = "x" }), [
    [< foo   x   baz >],
    [  "1", "x", "3"  ],
    [  "2", "x", ""   ],
    ], "on-in with direct index assignment");

done-testing;
