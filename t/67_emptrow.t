#!raku

use v6;
use Slang::Tuxic;

use Test;
use Text::CSV;

my $csv = Text::CSV.new ();

my $tfn = "_67test.csv"; END { unlink $tfn; }

is ($csv.skip_empty_rows,		0,	"default");
is ($csv.skip_empty_rows (False),	0,	"False");
is ($csv.skip_empty_rows (0),		0,	"+0");
is ($csv.skip_empty_rows ("0"),		0,	"'0'");
is ($csv.skip_empty_rows (True),	1,	"True");
is ($csv.skip_empty_rows (1),		1,	"+1");
is ($csv.skip_empty_rows ("1"),		1,	"'1'");
is ($csv.skip_empty_rows ("skip"),	1,	"skip");
is ($csv.skip_empty_rows ("SKIP"),	1,	"SKIP");
is ($csv.skip_empty_rows (2),		2,	"+2");
is ($csv.skip_empty_rows ("2"),		2,	"'2'");
is ($csv.skip_empty_rows ("eof"),	2,	"eof");
is ($csv.skip_empty_rows ("EOF"),	2,	"EOF");
is ($csv.skip_empty_rows ("stop"),	2,	"stop");
is ($csv.skip_empty_rows ("STOP"),	2,	"STOP");
is ($csv.skip_empty_rows (3),		3,	"+3");
is ($csv.skip_empty_rows ("3"),		3,	"'3'");
is ($csv.skip_empty_rows ("die"),	3,	"die");
is ($csv.skip_empty_rows ("DIE"),	3,	"DIE");
is ($csv.skip_empty_rows (4),		4,	"+4");
is ($csv.skip_empty_rows ("4"),		4,	"'4'");
is ($csv.skip_empty_rows ("croak"),	4,	"croak");
is ($csv.skip_empty_rows ("CROAK"),	4,	"CROAK");
is ($csv.skip_empty_rows (5),		5,	"+5");
is ($csv.skip_empty_rows ("5"),		5,	"'5'");
is ($csv.skip_empty_rows ("error"),	5,	"error");
is ($csv.skip_empty_rows ("ERROR"),	5,	"ERROR");
is ($csv.skip_empty_rows ({<1>}),	6,	"<1>");

is ($csv.skip-empty-rows (True),	1,	"True");
is ($csv.skip-empty-rows (1),		1,	"+1");
is ($csv.skip-empty-rows ("1"),		1,	"'1'");
is ($csv.skip-empty-rows ("skip"),	1,	"skip");
is ($csv.skip-empty-rows ("SKIP"),	1,	"SKIP");
is ($csv.skip-empty-rows (2),		2,	"+2");
is ($csv.skip-empty-rows ("2"),		2,	"'2'");
is ($csv.skip-empty-rows ("eof"),	2,	"eof");
is ($csv.skip-empty-rows ("EOF"),	2,	"EOF");
is ($csv.skip-empty-rows ("stop"),	2,	"stop");
is ($csv.skip-empty-rows ("STOP"),	2,	"STOP");
is ($csv.skip-empty-rows (3),		3,	"+3");
is ($csv.skip-empty-rows ("3"),		3,	"'3'");
is ($csv.skip-empty-rows ("die"),	3,	"die");
is ($csv.skip-empty-rows ("DIE"),	3,	"DIE");
is ($csv.skip-empty-rows (4),		4,	"+4");
is ($csv.skip-empty-rows ("4"),		4,	"'4'");
is ($csv.skip-empty-rows ("croak"),	4,	"croak");
is ($csv.skip-empty-rows ("CROAK"),	4,	"CROAK");
is ($csv.skip-empty-rows (5),		5,	"+5");
is ($csv.skip-empty-rows ("5"),		5,	"'5'");
is ($csv.skip-empty-rows ("error"),	5,	"error");
is ($csv.skip-empty-rows ("ERROR"),	5,	"ERROR");
is ($csv.skip-empty-rows ({<1>}),	6,	"<1>");

is ($csv.skip-empty-rows (False),	0,	"False");
is ($csv.skip-empty-rows (0),		0,	"+0");
is ($csv.skip-empty-rows ("0"),		0,	"'0'");

sub CB (Text::CSV $x) returns Str { return "3,42,,3" }

is ($csv.skip-empty-rows (&CB),	6,		"callback");

my $fh = open $tfn, :w;
$fh.say: "a,b,c,d";
$fh.say: "1,2,0,4";
$fh.say: "4,0,9,1";
$fh.say: "";
$fh.say: "8,2,7,1";
$fh.say: "";
$fh.say: "";
$fh.say: "5,7,9,3";
$fh.say: "";
$fh.close;

sub ser_csv (Bool $hsh, Any $ser) {
    return csv (auto-diag => 0, in => $tfn, skip-empty-rows => $ser, headers => $hsh);
    } # ser_csv

sub check (Bool $hsh, Any $ser, Str $tst, *@exp) {
    my @got = ser_csv ($hsh, $ser);
    is-deeply (@got, @exp, $tst);
    } # check

# Array behavior
check (False, False,   "A default", [
    ["a","b","c","d"], ["1","2","0","4"], ["4","0","9","1"],
    [""], ["8","2","7","1"], [""], [""], ["5","7","9","3"], [""]]);

check (False, True,    "A skip", [
    ["a","b","c","d"], ["1","2","0","4"], ["4","0","9","1"],
    ["8","2","7","1"], ["5","7","9","3"]]);

check (False, "stop",  "A stop", [
    ["a","b","c","d"], ["1","2","0","4"], ["4","0","9","1"]]);

check (False, "error", "A error", [ # Error 2015
    ["a","b","c","d"], ["1","2","0","4"], ["4","0","9","1"]]);

{   my $x;
    my $e;
    {   $x = check (False, "die", "A die", []);
        CATCH { default { $e = $_ }}
        }
    is ($x,         Any,         "A It should have stopped");
    is ($e.payload, "Empty row", "A Error message");
    }

check (False, { "1,2,3,4" }, "A cb", [
    ["a","b","c","d"], ["1","2","0","4"], ["4","0","9","1"],
    ["1","2","3","4"], ["8","2","7","1"], ["1","2","3","4"],
    ["1","2","3","4"], ["5","7","9","3"], ["1","2","3","4"]]);

# Hash behavior
check (True,  False,   "H default", [
    {:a("1"),:b("2"),:c("0"),:d("4")}, {:a("4"),:b("0"),:c("9"),:d("1")},
    {:a("")}, {:a("8"),:b("2"),:c("7"),:d("1")},
    {:a("")}, {:a("")},
    {:a("5"),:b("7"),:c("9"),:d("3")},
    {:a("")}]);

check (True,  True,    "H skip", [
    {:a("1"),:b("2"),:c("0"),:d("4")}, {:a("4"),:b("0"),:c("9"),:d("1")},
    {:a("8"),:b("2"),:c("7"),:d("1")}, {:a("5"),:b("7"),:c("9"),:d("3")}]);

check (True,  "stop",  "H stop", [
    {:a("1"),:b("2"),:c("0"),:d("4")}, {:a("4"),:b("0"),:c("9"),:d("1")}]);

check (True,  "error", "H error", [ # Error 2015
    {:a("1"),:b("2"),:c("0"),:d("4")}, {:a("4"),:b("0"),:c("9"),:d("1")}]);

{   my $x;
    my $e;
    {   $x = check (True, "die", "H die", []);
        CATCH { default { $e = $_ }}
        }
    is ($x,         Any,         "H It should have stopped");
    is ($e.payload, "Empty row", "H Error message");
    }

check (True,  { "1,2,3,4" }, "H cb", [
    {:a("1"),:b("2"),:c("0"),:d("4")}, {:a("4"),:b("0"),:c("9"),:d("1")},
    {:a("1"),:b("2"),:c("3"),:d("4")}, {:a("8"),:b("2"),:c("7"),:d("1")},
    {:a("1"),:b("2"),:c("3"),:d("4")}, {:a("1"),:b("2"),:c("3"),:d("4")},
    {:a("5"),:b("7"),:c("9"),:d("3")}, {:a("1"),:b("2"),:c("3"),:d("4")}]);

done-testing;
