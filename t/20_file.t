#!perl6

use v6;
use Slang::Tuxic;

use Test;
use Text::CSV;

my $csv = Text::CSV.new (binary => False);

my $tf20 = "_20test.csv";

#$|  = 1;
#$/  = "\n";
#$\  = undef;

#my $UTF8 = ($ENV{LANG} || "C").($ENV{LC_ALL} || "C") =~ m/utf-?8/i ? 1 : 0;

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
io_test ( 4, True,  2012, '"', 'abc'             );
io_test ( 5, True,  2012, 'abc', '"'             );
io_test ( 6, True,     0, 'abc', 'def', 'ghi'    );
io_test ( 7, True,     0, "abc\tdef", 'ghi'      );
io_test ( 8, True,  2012, '"abc'                 );
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

=finish

# Edge cases
$csv = Text::CSV_XS.new ({ escape_char => "+" });
for ([  1, 1,    0, "\n"		],
     [  2, 1,    0, "+\n"		],
     [  3, 1,    0, "+"			],
     [  4, 0, 2021, qq{"+"\n}		],
     [  5, 0, 2025, qq{"+\n}		],
     [  6, 0, 2011, qq{""+\n}		],
     [  7, 0, 2027, qq{"+"}		],
     [  8, 0, 2024, qq{"+}		],
     [  9, 0, 2011, qq{""+}		],
     [ 10, 0, 2037, "\r"		],
     [ 11, 0, 2031, "\r\r"		],
     [ 12, 0, 2032, "+\r\r"		],
     [ 13, 0, 2032, "+\r\r+"		],
     [ 14, 0, 2022, qq{"\r"}		],
     [ 15, 0, 2022, qq{"\r\r" }		],
     [ 16, 0, 2022, qq{"\r\r"\t}	],
     [ 17, 0, 2025, qq{"+\r\r"}		],
     [ 18, 0, 2025, qq{"+\r\r+"}	],
     [ 19, 0, 2022, qq{"\r"\r}		],
     [ 20, 0, 2022, qq{"\r\r"\r}	],
     [ 21, 0, 2025, qq{"+\r\r"\r}	],
     [ 22, 0, 2025, qq{"+\r\r+"\r}	],
     ) {
    my ($tst, $valid, $err, $str) = @$_;
    open  FH, ">", $tf20 or die "$tf20: $!";
    print FH $str;
    close FH;
    open  FH, "<", $tf20 or die "$tf20: $!";
    my $row = $csv.getline ($fh);
    close FH;
    my @err  = $csv.error_diag;
    my $sstr = _readable ($str);
    SKIP: {
	$tst == 10 && $] >= 5.008 && $] < 5.008003 && $UTF8 and
	    skip "Be reasonable, this perl version does not do Unicode reliable", 2;
	ok ($valid ? $row : !$row, "$tst - getline ESC +, '$sstr'");
	is ($err[0], $err, "Error expected $err");
	}
    }

unlink $tf20;
