#!perl6

use v6;
use Slang::Tuxic;

use Test;
use Text::CSV;

my $csv    = Text::CSV.new;
my $sup;

my $fni    = "_90in.csv";
my $fno    = "_90out.csv";

my Str @hdr  = < foo bar baz >;
my Str $hdr  = @hdr.join (",");
my Str @data = $hdr, "1,2,3", "2,a b,";
my Str $data = @data.map (*~"\r\n").join ("");
my @expect   = @data.map ({[ $_.split (",") ]});

{   my $fh = open $fni, :w;
    $fh.say ($_) for @data;
    $fh.close;
    }

my $io-in  = open $fni, :r;
my $io-out = open $fno, :w;

sub provider {
    state Str @dta = @data;
    if (@dta.elems == 0) {
        @dta = @data;
        return False;
        }
    return [ @dta.shift.split (",") ];
    }

my $full-aoa = [[@hdr],["1","2","3"],["2","a b",""]];
my Str $s-in;

my @in =
    $fni,                       # Str
    $io-in,                     # IO::Handle
   \($data),                    # Capture
    [$data],                    # Array
    [@data],                    # Array
    $full-aoa,                  # Array
#   [{a=>1,b=>2},{a=>3,b=>4}],

    &provider,                  # Sub
    #                           # Callable
    # Supply push later         # Supply
    ;

sub in {
    my @i = @in;
    $sup = Supply.new;
    start { sleep (1); $sup.emit ($_) for @data; $sup.done; };
    @i.push: $sup;
    @i;
    }

sub inok (@r, Str $diag) {
    ok (@r, $diag); # Expect Array.new (["a", "b"], ["1", "2"], ["3", "4"])
    #@r.perl.say;
    $io-in.seek (0, 0);
    is (@r.elems, 3, "AoA should have 3 rows");
    is-deeply (@r, @expect, "Content");
    }

# Test supported "in" formats
for in () -> $in {
    $s-in = $in.WHAT.gist~$in.gist; $s-in ~~ s:g{\n} = "\\n";
    inok (Text::CSV.csv (in => $in, meta => False), "Class   $s-in");
    }
for in () -> $in {
    $s-in = $in.WHAT.gist~$in.gist; $s-in ~~ s:g{\n} = "\\n";
    inok (     $csv.csv (in => $in, meta => False), "Method  $s-in");
    }
for in () -> $in {
    $s-in = $in.WHAT.gist~$in.gist; $s-in ~~ s:g{\n} = "\\n";
    inok (          csv (in => $in, meta => False), "Sub     $s-in");
    }
for in () -> $in {
    $s-in = $in.WHAT.gist~$in.gist; $s-in ~~ s:g{\n} = "\\n";
    inok (          csv (in => $in, csv  => $csv),  "Sub/Obj $s-in");
    }

# Test supported "out" formats
for in () -> $in {
    $s-in = $in.WHAT.gist~$in.gist; $s-in ~~ s:g{\n} = "\\n";
    is (csv (in => $in, out => Str, :!quote-space), $data, "csv => Str $s-in");
    }

is (csv (in => $fni, out => Str, fragment => "row=2"),    "1,2,3\r\n",        "Fragment, row");
is (csv (in => $fni, out => Str, fragment => "col=3"),    "baz\r\n3\r\n\r\n", "Fragment, col");
is (csv (in => $fni, out => Str, fragment => "cell=1,1"), "foo\r\n",          "Fragment, cell");

$io-in.seek (0, 0);
for in () -> $in {
    $s-in = $in.WHAT.gist~$in.gist; $s-in ~~ s:g{\n} = "\\n";
    is-deeply (csv (in => $in, out => Array),
        [["foo", "bar", "baz"], ["1", "2", "3"], ["2", "a b", ""]], "csv => Array $s-in");
    }

$io-in.seek (0, 0);
for in () -> $in {
    $s-in = $in.WHAT.gist~$in.gist; $s-in ~~ s:g{\n} = "\\n";
    is-deeply ([csv (in => $in, out => Hash)],
        [{foo=>"1",bar=>"2",baz=>"3"},{foo=>"2",bar=>"a b",baz=>""}], "csv => Hash $s-in");
    }

$io-in.seek (0, 0);
for in () -> $in {
    $s-in = $in.WHAT.gist~$in.gist; $s-in ~~ s:g{\n} = "\\n";
    ok (my $csv = Text::CSV.new,           "new");
    ok ($csv.column_names (<foo bar baz>), "colnames");
    is-deeply ([$csv.csv (in => $in, out => Hash, skip => 1)],
        [{foo=>"1",bar=>"2",baz=>"3"},{foo=>"2",bar=>"a b",baz=>""}], "csv => Hash + skip $s-in");
    }

$io-in.seek (0, 0);
for in () -> $in {
    $s-in = $in.WHAT.gist~$in.gist; $s-in ~~ s:g{\n} = "\\n";
    ok (my $csv = Text::CSV.new,           "new");
#   is-deeply ([$csv.csv (in => $in, headers => "auto")],
#       [{foo=>"1",bar=>"2",baz=>"3"},{foo=>"2",bar=>"a b",baz=>""}], "csv => Hash + auto $s-in");
    }

$io-in.seek (0, 0);
for in () -> $in {
    $s-in = $in.WHAT.gist~$in.gist; $s-in ~~ s:g{\n} = "\\n";
    ok (my $csv = Text::CSV.new,           "new");
    is-deeply ([$csv.csv (in => $in, headers => [<foo bar baz>], frag => "row=2-*")],
        [{foo=>"1",bar=>"2",baz=>"3"},{foo=>"2",bar=>"a b",baz=>""}], "csv => Hash + hdrs $s-in");
    }

unlink $fni, $fno;

done;

=finish

my $aoh = [
    { foo => 1, bar => 2, baz => 3 },
    { foo => 2, bar => "a b", baz => "" },
    ];

my @aoa = @{$aoa}[1,2];
is-deeply (csv (file => $file, headers  => "skip"),    \@aoa, "AOA skip");
is-deeply (csv (file => $file, fragment => "row=2-3"), \@aoa, "AOA fragment");

is-deeply (csv (in => $file, encoding => "utf-8", headers => ["a", "b", "c"],
                fragment => "row=2", sep_char => ","),
       [{ a => 1, b => 2, c => 3 }], "AOH headers fragment");

ok (csv (in => $aoa, out => $file), "AOA out file");
is-deeply (csv (in => $file), $aoa, "AOA parse out");

ok (csv (in => $aoh, out => $file, headers => "auto"), "AOH out file");
is-deeply (csv (in => $file, headers => "auto"), $aoh, "AOH parse out");

ok (csv (in => $aoh, out => $file, headers => "skip"), "AOH out file no header");
is-deeply (csv (in => $file, headers => [keys %{$aoh->[0]}]),
    $aoh, "AOH parse out no header");

my $idx = 0;
sub getrowa { return $aoa->[$idx++]; }
sub getrowh { return $aoh->[$idx++]; }

ok (csv (in => \&getrowa, out => $file), "out from CODE/AR");
is-deeply (csv (in => $file), $aoa, "data from CODE/AR");

$idx = 0;
ok (csv (in => \&getrowh, out => $file, headers => \@hdr), "out from CODE/HR");
is-deeply (csv (in => $file, headers => "auto"), $aoh, "data from CODE/HR");

$idx = 0;
ok (csv (in => \&getrowh, out => $file), "out from CODE/HR (auto headers)");
is-deeply (csv (in => $file, headers => "auto"), $aoh, "data from CODE/HR");

unlink $file;

eval {
    exists  $Config{useperlio} &&
    defined $Config{useperlio} &&
    $] >= 5.008                &&
    $Config{useperlio} eq "define" or skip "No scalar ref in this perl", 4;
    my $out = "";
    open my $fh, ">", \$out;
    ok (csv (in => [[ 1, 2, 3 ]], out => $fh), "out to fh to scalar ref");
    is ($out, "1,2,3\r\n",	"Scalar out");
    $out = "";
    ok (csv (in => [[ 1, 2, 3 ]], out => \$out), "out to scalar ref");
    is ($out, "1,2,3\r\n",	"Scalar out");
    };
