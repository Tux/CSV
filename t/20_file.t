#!perl6

use v6;
use Slang::Tuxic;

use Test;
use Text::CSV;

my $csv = Text::CSV.new (binary => False);

#$|  = 1;
#$/  = "\n";
#$\  = undef;

#my $UTF8 = ($ENV{LANG} || "C").($ENV{LC_ALL} || "C") =~ m/utf-?8/i ? 1 : 0;

my $fh = open "_20test.csv", :w or die "_20test.csv: $!";
ok (!$csv.print ($fh, "abc", "def\007", "ghi"), "print bad character");
$fh.close;

# All these tests are without EOL, thus testing EOF
sub io_test (int $tst, Bool $print-valid, int $error, *@arg) {

    $fh = open "_20test.csv", :w or die "_20test.csv: $!";
    is ($csv.print ($fh, @arg), $print-valid, "$tst - print ()");
    $fh.close;

    $fh = open "_20test.csv", :w or die "_20test.csv: $!";
    $fh.print (join ",", @arg);
    $fh.close;

    $fh = open "_20test.csv", :r or die "_20test.csv: $!";
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

unlink "_20test.csv";

=finish

# This test because of a problem with DBD::CSV

ok (1, "Tests for DBD::CSV");
open  FH, ">", "_20test.csv" or die "_20test.csv: $!";
$csv.binary (1);
$csv.eol    ("\r\n");
ok ($csv.print (*FH, [ "id", "name"			]), "Bad character");
ok ($csv.print (*FH, [   1,  "Alligator Descartes"	]), "Name 1");
ok ($csv.print (*FH, [  "3", "Jochen Wiedmann"		]), "Name 2");
ok ($csv.print (*FH, [   2,  "Tim Bunce"		]), "Name 3");
ok ($csv.print (*FH, [ " 4", "Andreas König"		]), "Name 4");
ok ($csv.print (*FH, [   5				]), "Name 5");
close FH;

my $expected = <<"CONTENTS";
id,name\015
1,"Alligator Descartes"\015
3,"Jochen Wiedmann"\015
2,"Tim Bunce"\015
" 4","Andreas König"\015
5\015
CONTENTS

open  FH, "<", "_20test.csv" or die "_20test.csv: $!";
my $content = do { local $/; <FH> };
close FH;
is ($content, $expected, "Content");
open  FH, ">", "_20test.csv" or die "_20test.csv: $!";
print FH $content;
close FH;
open  FH, "<", "_20test.csv" or die "_20test.csv: $!";

my $fields;
print "# Retrieving data\n";
for (0 .. 5) {
    ok ($fields = $csv.getline (*FH),			"Fetch field $_");
    is ($csv.eof, "",					"EOF");
    print "# Row $_: $fields (@$fields)\n";
    }
is ($csv.getline (*FH), undef,				"Fetch field 6");
is ($csv.eof, 1,					"EOF");

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
    open  FH, ">", "_20test.csv" or die "_20test.csv: $!";
    print FH $str;
    close FH;
    open  FH, "<", "_20test.csv" or die "_20test.csv: $!";
    my $row = $csv.getline (*FH);
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

unlink "_20test.csv";
