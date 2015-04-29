#!perl6

use v6;
use Slang::Tuxic;

use Test;
use Text::CSV;

my $csv = Text::CSV.new (:!binary, eol => "\n", :meta);

my $tf20 = "_20test.csv";

my $fh = open $tf20, :w or die "$tf20: $!";
ok (!$csv.print ($fh, "abc", "def\007", "ghi"), "print bad character");
$fh.close;

# All these tests are without EOL, thus testing EOF
sub io_test (int $tst, Bool $print-valid, int $error, *@arg) {

    $fh = open $tf20, :w or die "$tf20: $!";
    is ($csv.print ($fh, @arg), $print-valid, "$tst - print ()");
    $fh.close;

    $fh = open $tf20, :w or die "$tf20: $!";
    $fh.print (join ",", @arg);
    $fh.close;

    $fh = open $tf20, :r or die "$tf20: $!";
    my @row = $csv.getline ($fh);
    is ($csv.status,         !?$error, "$tst - getline status");
    is ($csv.error_diag.error, $error, "$tst - getline error code");
    $error and return;
    ok (@row.elems, "$tst - good getline ()");
    $tst == 12 and @arg = (",", "", "");
    loop (my $a = 0; $a < @arg.elems; $a++) {
	my $exp = @arg[$a];
	$exp ~~ s{^ '"' (.*) '"' $} = $0;
	is (@row[$a].text, $exp, "$tst - field $a");
	}
    ok ($csv.parse (""), "$tst - reset parser");
    }
io_test ( 1, True,     0, '""'                   );
io_test ( 2, True,     0, '', ''                 );
io_test ( 3, True,  2034, '', 'I said, "Hi!"', '');
io_test ( 4, True,  2027, '"', 'abc'             );
io_test ( 5, True,  2027, 'abc', '"'             );
io_test ( 6, True,     0, 'abc', 'def', 'ghi'    );
io_test ( 7, True,     0, "abc\tdef", 'ghi'      );
io_test ( 8, True,  2027, '"abc'                 );
io_test ( 9, True,  2034, 'ab"c'                 );
io_test (10, True,  2023, '"ab"c"'               );
io_test (11, False, 2021, qq{"abc\nc"}           );
io_test (12, True,     0, qq{","}, ','           );
io_test (13, True,  2034, qq{"","I said,\t""Hi!""",""}, '', qq{I said,\t"Hi!"}, '' );

unlink $tf20;

# This test because of a problem with DBD::CSV

ok (1, "Tests for DBD::CSV");
$fh = open  $tf20, :w or die "$tf20: $!";
$csv.binary (True);
$csv.eol    ("\r\n");
ok ($csv.print ($fh, "id", "name"                ), "Bad character");
ok ($csv.print ($fh,   1,  "Alligator Descartes" ), "Name 1");
ok ($csv.print ($fh,  "3", "Jochen Wiedmann"     ), "Name 2");
ok ($csv.print ($fh,   2,  "Tim Bunce"           ), "Name 3");
ok ($csv.print ($fh, " 4", "Andreas König"      ), "Name 4");
ok ($csv.print ($fh,   5                         ), "Name 5");
$fh.close;

my $expected = qq :to "CONTENTS";
id,name\r
1,"Alligator Descartes"\r
3,"Jochen Wiedmann"\r
2,"Tim Bunce"\r
" 4","Andreas König"\r
5\r
CONTENTS

my $content = slurp $tf20;
is ($content, $expected, "Content");

$fh = open  $tf20, :r or die "$tf20: $!";
my @fields;
ok (True, "# Retrieving data");
for ^6 -> $tst {
    ok ((@fields = $csv.getline ($fh)), "Fetch record $tst");
    is ($csv.eof, False,                "EOF");
    }
ok (!$csv.getline ($fh),                "Fetch record 6");
is ($csv.eof, True,                     "EOF");

# Edge cases
$csv = Text::CSV.new (escape => "+", :!binary, eol => "\n");
sub esc_test (int $tst, int $err is copy, Str $str) {
    $fh = open $tf20, :w or die "$tf20: $!";
    $fh.print ($str);
    $fh.close;
    $fh = open $tf20, :r or die "$tf20: $!";
    my @row = $csv.getline ($fh);
    $fh.close;
    is (+$csv.error_diag, $err, "$tst - expected error $err (IO)");

    $err == 2012 and $err = 2027;
    @row = $csv.getline ($str);
    is (+$csv.error_diag, $err, "$tst - expected error $err (Str)");
    }

 esc_test ( 1,    0, "\n");
 esc_test ( 2, 2025, "+\n");
 esc_test ( 3, 2035, "+");
 esc_test ( 4, 2021, qq{"+"\n});
 esc_test ( 5, 2025, qq{"+\n});
 esc_test ( 6, 2011, qq{""+\n});
 esc_test ( 7, 2027, qq{"+"});
 esc_test ( 8, 2024, qq{"+});
 esc_test ( 9, 2011, qq{""+});
 esc_test (10, 2031, "\r");
 esc_test (11, 2031, "\r\r");
 esc_test (12, 2032, " \r");
 esc_test (13, 2025, "+\r\r");
 esc_test (14, 2025, "+\r\r+");
 esc_test (15, 2022, qq{"\r"});
 esc_test (16, 2022, qq{"\r\r" });
 esc_test (17, 2022, qq{"\r\r"\t});
 esc_test (18, 2025, qq{"+\r\r"});
 esc_test (19, 2025, qq{"+\r\r+"});
 esc_test (20, 2022, qq{"\r"\r});
 esc_test (21, 2022, qq{"\r\r"\r});
 esc_test (22, 2025, qq{"+\r\r"\r});
 esc_test (23, 2025, qq{"+\r\r+"\r});

 $csv.binary (True);
 esc_test (31,    0, "\n");
 esc_test (32, 2025, "+\n");
 esc_test (33, 2035, "+");
 esc_test (34, 2012, qq{"+"\n});
 esc_test (35, 2025, qq{"+\n});
 esc_test (36, 2011, qq{""+\n});
 esc_test (37, 2027, qq{"+"});
 esc_test (38, 2024, qq{"+});
 esc_test (39, 2011, qq{""+});
 esc_test (40,    0, "\r");
 esc_test (41,    0, "\r\r");
 esc_test (41,    0, " \r");
 esc_test (42, 2025, "+\r\r");
 esc_test (43, 2025, "+\r\r+");
 esc_test (44,    0, qq{"\r"});
 esc_test (45, 2011, qq{"\r\r" });
 esc_test (46, 2011, qq{"\r\r"\t});
 esc_test (47, 2025, qq{"+\r\r"});
 esc_test (48, 2025, qq{"+\r\r+"});
 esc_test (49, 2011, qq{"\r"\r});
 esc_test (50, 2011, qq{"\r\r"\r});
 esc_test (51, 2025, qq{"+\r\r"\r});
 esc_test (52, 2025, qq{"+\r\r+"\r});

unlink $tf20;

done;
