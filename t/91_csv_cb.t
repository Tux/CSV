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

sub Empty (Text::CSV $c, CSV::Field @f) {}

for (< after_in on_in before_out >) -> $t {
    is-deeply (csv (in => $file,             |( $t => &Empty )), @aoa, "callback $t on AOA with empty sub");
    is-deeply (csv (in => $file, callbacks => { $t => &Empty }), @aoa, "callback $t on AOA with empty sub");
    }
is-deeply (csv (in => $file, after_in => &Empty,
    callbacks => { on_in => &Empty }), @aoa, "callback after_in and on_in on AOA");

for (< after_in on_in before_out >) -> $t {
    is-deeply ([csv (in => $file, headers => "auto",             |( $t => &Empty ))], @aoh, "callback $t on AOH with empty sub");
    is-deeply ([csv (in => $file, headers => "auto", callbacks => { $t => &Empty })], @aoh, "callback $t on AOH with empty sub");
    }
is-deeply ([csv (in => $file, headers => "auto", after_in => &Empty,
    callbacks => { on_in => &Empty })], @aoh, "callback after_in and on_in on AOH");

sub Push (Text::CSV $c, CSV::Field @f is rw) { @f.push: "A"; }

done;

=finish

is-deeply ([csv (in => $file, after_in => &Push)], [
    [< foo bar    baz  A >],
    [  1,  2,     3,  "A" ],
    [  2,  "a b", "", "A" ],
    ], "AOA ith after_in callback");

sub Change (Text::CSV $c, CSV::Field %f is rw) { %f<baz> = "A"; }

is-deeply (csv (in => $file, headers => "auto", after_in => &Change), [
    { foo => 1, bar => 2, baz => "A" },
    { foo => 2, bar => "a b", baz => "A" },
    ], "AOH with after_in callback");
