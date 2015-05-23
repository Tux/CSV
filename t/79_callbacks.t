#!perl6

use v6;
use Slang::Tuxic;

use Test;
use Text::CSV;

my $tfn = "_79_callbacks.csv";

my $csv = Text::CSV.new (:meta);

is ($csv.callbacks.keys.elems,           0, "No callbacks");
is ($csv.callbacks (0).keys.elems,       0, "Reset no callbacks");
is ($csv.callbacks (Hash).keys.elems,    0, "Reset no callbacks");
is ($csv.callbacks (Array).keys.elems,   0, "Reset no callbacks");
is ($csv.callbacks (False).keys.elems,   0, "Reset no callbacks");
is ($csv.callbacks ("reset").keys.elems, 0, "Reset no callbacks");
is ($csv.callbacks ("clear").keys.elems, 0, "Reset no callbacks");
is ($csv.callbacks ("RESET").keys.elems, 0, "Reset no callbacks");
is ($csv.callbacks ("CLEAR").keys.elems, 0, "Reset no callbacks");

ok ($csv = Text::CSV.new (callbacks => 0),       "new with empty callbacks");
ok ($csv = Text::CSV.new (callbacks => Hash),    "new with empty callbacks");
ok ($csv = Text::CSV.new (callbacks => Array),   "new with empty callbacks");
ok ($csv = Text::CSV.new (callbacks => False),   "new with empty callbacks");
ok ($csv = Text::CSV.new (callbacks => "reset"), "new with empty callbacks");
ok ($csv = Text::CSV.new (callbacks => "clear"), "new with empty callbacks");
ok ($csv = Text::CSV.new (callbacks => "RESET"), "new with empty callbacks");
ok ($csv = Text::CSV.new (callbacks => "CLEAR"), "new with empty callbacks");

sub Empty (CSV::Row $r) {}
sub Drop  (CSV::Row $r) { $r.fields.pop; }
sub Push  (CSV::Row $r) { $r.fields.push (CSV::Field.new); }
sub Replc (CSV::Row $r) { $r.fields[1] =  CSV::Field.new; }
sub Unshf (CSV::Row $r) { $r.fields.unshift (CSV::Field.new ("0")); }

ok ($csv.meta (True), "Set meta again");
is-deeply ([$csv.getline ("1,2").map (~*)], ["1","2"],     "Parse no cb");
ok ($csv.callbacks ("after_parse", &Empty), "Empty ap cb");
is-deeply ([$csv.getline ("1,2").map (~*)], ["1","2"],     "Parse empty cb");
ok ($csv.callbacks ("after_parse", &Drop),  "Drop ap cb");
is-deeply ([$csv.getline ("1,2").map (~*)], ["1"],         "Parse dropping cb");
ok ($csv.callbacks ("after_parse", &Push),  "Push ap cb");
is-deeply ([$csv.getline ("1,2").map (~*)], ["1","2",Str], "Parse pushing cb");
ok ($csv.callbacks ("after_parse", &Replc), "Replc ap cb");
is-deeply ([$csv.getline ("1,2").map (~*)], ["1",Str],     "Parse pushing cb");
ok ($csv.callbacks ("after_parse", &Unshf), "Unshf ap cb");
is-deeply ([$csv.getline ("1,2").map (~*)], ["0","1","2"], "Parse unshifting cb");

my $fh = open $tfn, :w;
$fh.say ("1,a");
$fh.say ("2,b");
$fh.say ("3,c");
$fh.say ("4,d");
$fh.say ("5,e");
$fh.say ("6,f");
$fh.say ("7,g");
$fh.close;

$fh = open $tfn, :r;

sub Filter (CSV::Row $r) returns Bool { +$r[0] % 2 && $r[1] ~~ /^ <[abcd]> / ?? True !! False };
$csv = Text::CSV.new;
ok ($csv.callbacks ("filter", &Filter), "Add filer");
ok ((my @r = $csv.getline_all ($fh)), "Fetch all with filter");
for @r -> @f { $_ = ~$_ for @f; }
is-deeply (@r, [["1","a"],["3","c"]], "Filtered content");

unlink $tfn;

# These tests are for the method to fail
ok ($csv = Text::CSV.new, "new for method fails");
for  ([ 1                           ],
      [ []                          ],
      [ sub {}                      ],
      [ 1,        2                 ],
      [ 1,        2, 3              ],
      [ "",       "error"           ],
      [ Str,      "error"           ], # X::AdHoc.new
      [ "error",  Str               ],
      [ "%23bad", sub {}            ], # X::AdHoc.new
      [ "error",  []                ],
      [ "error",  "error"           ],
      [ "",       sub { 0; }        ],
      [ sub { 0; }, 0               ], # Code object coerced to string
      [ [],       ""                ],
      [ "error",  sub {0; }, Str, 1 ],
      ) -> @args {
    my $e;
    ok (True, "Callbacks:  "~@args.perl);
    {   $csv.callbacks (@args);
        CATCH { default { $e = $_; ""; }}
        }
    is ($e.error, any (1004, 3100),   "invalid callbacks: "~$e.error);
    is ($csv.callbacks.keys.elems, 0, "not set");
    }

done;

=finish

# These tests are for invalid arguments *inside* the hash
foreach my $arg (undef, 0, 1, \1, "", [], $csv) {
    eval { $csv->callbacks ({ error => $arg }); };
    my @diag = $csv->error_diag;
    is ($diag[0], 1004,                 "invalid callbacks");
    is ($csv->callbacks, undef,         "not set");
    }
ok ($csv->callbacks (bogus => sub { 0; }), "useless callback");

my $error = 3006;
sub ignore
{
    is ($_[0], $error, "Caught error $error");
    $csv->SetDiag (0); # Ignore this error
    } # ignore

my $idx = 1;
ok ($csv->auto_diag (1), "set auto_diag");
my $callbacks = {
    error        => \&ignore,
    after_parse  => sub {
        my ($c, $av) = @_;
        # Just add a field
        push @$av, "NEW";
        },
    before_print => sub {
        my ($c, $av) = @_;
        # First field set to line number
        $av->[0] = $idx++;
        # Maximum 2 fields
        @{$av} > 2 and splice @{$av}, 2;
        # Minimum 2 fields
        @{$av} < 2 and push @{$av}, "";
        },
    };
is (ref $csv->callbacks ($callbacks), "HASH", "callbacks set");
ok ($csv->getline (*DATA),              "parse ok");
is ($c, 1,                              "key");
is ($s, "foo",                          "value");
ok ($csv->getline (*DATA),              "parse bad, skip 3006");
ok ($csv->getline (*DATA),              "parse good");
is ($c, 2,                              "key");
is ($s, "bar",                          "value");

$csv->bind_columns (undef);
ok (my $row = $csv->getline (*DATA),    "get row");
is-deeply ($row, [ 1, 2, 3, "NEW" ],    "fetch + value from hook");

$error = 2012; # EOF
ok ($csv->getline (*DATA),              "parse past eof");

my $fn = "_79test.csv";
END { unlink $fn; }

ok ($csv->eol ("\n"), "eol for output");
open my $fh, ">", $fn or die "$fn: $!";
ok ($csv->print ($fh, [ 0, "foo"    ]), "print OK");
ok ($csv->print ($fh, [ 0, "bar", 3 ]), "print too many");
ok ($csv->print ($fh, [ 0           ]), "print too few");
close $fh;

open $fh, "<", $fn or die "$fn: $!";
is (do { local $/; <$fh> }, "1,foo\n2,bar\n3,\n", "Modified output");
close $fh;

# Test the non-IO interface
ok ($csv->parse ("10,blah,33\n"),                       "parse");
is-deeply ([ $csv->fields ], [ 10, "blah", 33, "NEW" ], "fields");

ok ($csv->combine (11, "fri", 22, 18),                  "combine - no hook");
is ($csv->string, qq{11,fri,22,18\n},                   "string");

is ($csv->callbacks (undef), undef,                     "clear callbacks");

is-deeply (Text::CSV_XS::csv (in => $fn, callbacks => $callbacks),
    [[1,"foo","NEW"],[2,"bar","NEW"],[3,"","NEW"]], "using getline_all");

__END__
1,foo
1
foo
2,bar
3,baz,2
1,foo
3,baz,2
2,bar
1,2,3
