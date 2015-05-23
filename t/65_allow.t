#!perl6

use v6;
use Slang::Tuxic;

use Test;
use Text::CSV;

my $csv  = Text::CSV.new;
my $csvf = "_65test.csv";

# Allow unescaped quotes inside an unquoted field
ok (1, "Allow unescaped quotes");
sub test_auq (int $tst, int $err, Str $bad) {
    $csv = Text::CSV.new ();
    ok ($csv,                      "$tst - new (alq => 0)");
    is ($csv.parse ($bad),  !$err, "$tst - parse () fail");
    is (0 + $csv.error_diag, $err, "$tst - error $err");

    $csv.allow_loose_quotes (1);
    ok ($csv.parse ($bad),         "$tst - parse () pass");
    ok (my @f = $csv.fields,       "$tst - fields");
    }
test_auq (1,    0, qq{foo,bar,"baz",quux}                            );
test_auq (2, 2034, qq{rj,bs,r"jb"s,rjbs}                             );
test_auq (3, 2034, qq{some "spaced" quote data,2,3,4}                );
test_auq (4,    0, qq{and an,entirely,quoted,"field"}                );
test_auq (5,    0, qq{and then,"one with ""quoted"" quotes",okay,?}  );

$csv = Text::CSV.new (quote => '"', escape => "=");
is ($csv.parse (qq{foo,d'uh"bar}), False, "should fail"); #"

# Allow unescaped quotes inside a quoted field
ok (1, "Allow loose quotes inside quoted");
sub test_alqiq (int $tst, int $err, Str $bad) {
    $csv = Text::CSV.new ();
    ok ($csv,                      "$tst - new (alq => 0)");
    is ($csv.parse ($bad),  !$err, "$tst - parse () fail");
    is (0 + $csv.error_diag, $err, "$tst - error $err");

    $csv.allow_loose_quotes (1);
    is ($csv.parse ($bad),  !$err, "$tst - parse () fail with lq");
    is (0 + $csv.error_diag, $err, "$tst - error $err");

    $csv.escape_char (Str);
    ok ($csv.parse ($bad),         "$tst - parse () pass");
    ok (my @f = $csv.fields,       "$tst - fields");
    }
test_alqiq (1,    0, qq{foo,bar,"baz",quux}                           );
test_alqiq (2, 2023, qq{rj,bs,"r"jb"s",rjbs}                          );
test_alqiq (3, 2023, qq{"some "spaced" quote data",2,3,4}             );
test_alqiq (4,    0, qq{and an,entirely,quoted,"field"}               );
test_alqiq (5,    0, qq{and then,"one with ""quoted"" quotes",okay,?} );

# Allow escapes to escape characters that should not be escaped
ok (1, "Allow loose escapes");
sub test_ale (int $tst, int $err, Str $bad) {
    $csv = Text::CSV.new (escape => "+");
    ok ($csv,                       "$tst - new (ale => 0)");
    is ($csv.parse ($bad),  !$err,  "$tst - parse () fail");
    is (0 + $csv.error_diag, $err,  "$tst - error $err");

    $csv.allow_loose_escapes (1);
    ok ($csv.parse ($bad),      "$tst - parse () pass");
    ok (my @f = $csv.fields,    "$tst - fields");
    }
test_ale (1,    0, qq{1,foo,bar,"baz",quux}                         );
test_ale (2,    0, qq{2,escaped,"quote+"s",in,"here"}              );
test_ale (3,    0, qq{3,escaped,quote+"s,in,"here"}                );
test_ale (4,    0, qq{4,escap+"d chars,allowed,in,unquoted,fields} );
test_ale (5, 2025, qq{5,42,"and it+'s dog",}                       );

test_ale (6, 2025, qq{+,}                                          );
test_ale (7, 2035, qq{+}                                           );
test_ale (8, 2035, qq{foo+}                                        );

# Allow whitespace to surround sep char
ok (1, "Allow whitespace");
my $awec_bad = qq{1,foo,bar,baz,quux};
sub test_awec (int $tst, int $err, Str $eol, Str $bad) {
    my $s_eol = $eol.perl;
    $csv = Text::CSV.new (eol => $eol);
    ok ($csv,                      "$s_eol / $tst - new - '$bad')");
    is ($csv.parse ($bad),  !$err, "$s_eol / $tst - parse () fail");
    is (0 + $csv.error_diag, $err, "$s_eol / $tst - error $err");

    $csv.allow_whitespace (True);
    ok ($csv.parse ("$bad$eol"),   "$s_eol / $tst - parse () pass");

    my @f = $csv.fields;
    is (@f.elems, 5,               "$s_eol / $tst - fields");

    my $got = join ",", @f.map (~*);
    is ($got, $awec_bad,           "$s_eol / $tst - content");
    }

for ("", "\n", "\r", "\r\n") -> $eol {
    test_awec ( 1,    0, $eol, qq{1,foo,bar,baz,quux}                        );
    test_awec ( 2,    0, $eol, qq{1,foo,bar,"baz",quux}                      );
    test_awec ( 3,    0, $eol, qq{1, foo,bar,"baz",quux}                     );
    test_awec ( 4,    0, $eol, qq{ 1,foo,bar,"baz",quux}                     );
    test_awec ( 5, 2034, $eol, qq{1,foo,bar, "baz",quux}                     );
    test_awec ( 6,    0, $eol, qq{1,foo ,bar,"baz",quux}                     );
    test_awec ( 7,    0, $eol, qq{1,foo,bar,"baz",quux }                     );
    test_awec ( 8,    0, $eol, qq{1,foo,bar,"baz","quux"}                    );
    test_awec ( 9, 2023, $eol, qq{1,foo,bar,"baz" ,quux}                     );
    test_awec (10, 2023, $eol, qq{1,foo,bar,"baz","quux" }                   );
    test_awec (11, 2034, $eol, qq{ 1 , foo , bar , "baz" , quux }            );
    test_awec (12, 2034, $eol, qq{  1  ,  foo  ,  bar  ,  "baz"  ,  quux  }  );
    test_awec (13, 2034, $eol, qq{  1  ,  foo  ,  bar  ,  "baz"\t ,  quux  } );
    }

ok (1, "blank_is_undef");
sub test_biu (int $aq, int $aw, int $bu, *@expect) {
    $csv = Text::CSV.new (always_quote => $aq, allow_whitespace => $aw, blank_is_undef => $bu);
    ok ($csv,   "new (aq $aq aw $aw bu $bu)");
    ok ($csv.combine (1, "", " ", '""', 2, Str, "", Str), "combine ()");
    ok (my $str = $csv.string,      "string ()");
    for ("", "\n", "\r\n") -> $eol {
        my $s_eol = $eol.perl;
        ok ($csv.parse ($str~$eol), "parse (*$str$s_eol*)");
        my @f = $csv.fields;
        is (@f.elems, 8,            "parse ()");
        is (~@f[$_]//"-", @expect[$_]//"-",   "content $_") for ^8;
        }
    }
test_biu (0, 0, 0,   1, "",  " ", '""', 2, "",  "",  "" );
test_biu (0, 0, 1,   1, Str, " ", '""', 2, Str, Str, Str);
test_biu (0, 1, 0,   1, "",  " ", '""', 2, "",  "",  "" );
test_biu (0, 1, 1,   1, Str, " ", '""', 2, Str, Str, Str);
test_biu (1, 0, 0,   1, "",  " ", '""', 2, "",  "",  "" );
test_biu (1, 0, 1,   1, "",  " ", '""', 2, Str, "",  Str);
test_biu (1, 1, 0,   1, "",  " ", '""', 2, "",  "",  "" );
test_biu (1, 1, 1,   1, "",  " ", '""', 2, Str, "",  Str);

ok (1, "empty_is_undef");
sub test_eiu (int $aq, int $aw, int $eu, *@expect) {
    $csv = Text::CSV.new (always_quote => $aq, allow_whitespace => $aw, empty_is_undef => $eu);
    ok ($csv,   "new (aq $aq aw $aw eu $eu)");
    ok ($csv.combine (1, "", " ", '""', 2, Str, "", Str), "combine ()");
    ok (my $str = $csv.string,      "string ()");
    for ("", "\n", "\r\n") -> $eol {
        my $s_eol = $eol.perl;
        ok ($csv.parse ($str~$eol), "parse (*$str$s_eol*)");
        my @f = $csv.fields;
        is (@f.elems, 8,            "parse ()");
        is (~@f[$_]//"-", @expect[$_]//"-",   "content $_") for ^8;
        }
    }
test_eiu (0, 0, 0,   1, "",  " ", '""', 2, "",  "",  "" );
test_eiu (0, 0, 1,   1, Str, " ", '""', 2, Str, Str, Str);
test_eiu (0, 1, 0,   1, "",  " ", '""', 2, "",  "",  "" );
test_eiu (0, 1, 1,   1, Str, " ", '""', 2, Str, Str, Str);
test_eiu (1, 0, 0,   1, "",  " ", '""', 2, "",  "",  "" );
test_eiu (1, 0, 1,   1, Str, " ", '""', 2, Str, Str, Str);
test_eiu (1, 1, 0,   1, "",  " ", '""', 2, "",  "",  "" );
test_eiu (1, 1, 1,   1, Str, " ", '""', 2, Str, Str, Str);


ok (1, "Trailing junk");
sub test_tj (int $tst, int $bin, Str $eol, Str $bad) {

    my $err = $bin ?? $tst < 4 ?? 0 !! 2023 !! $eol ?? 2021 !! 2022;

    $csv = Text::CSV.new (binary => $bin, eol => $eol);

    $csv.allow_whitespace (1);
    $bin and $err = 0;
    #$csv.parse ($bad);
    #("# $tst $bin " ~ $eol.perl ~ "\t" ~ $csv.error_diag.error).say;
    is ($csv.parse ($bad),  !$err, "$tst - parse () allow");
    is (0 + $csv.error_diag, $err, "$tst - error $err");
    }
for (Str, "\r") -> $eol {
    for (0, 1) -> $bin {
        my $s_eol = $eol.perl;
        ok ($csv, "$s_eol - new ()");
        test_tj (1, $bin, $eol, qq{"\r\r\n"\r}       );
        test_tj (2, $bin, $eol, qq{"\r\r\n"\r\r}     );
        test_tj (3, $bin, $eol, qq{"\r\r\n"\r\r\n}   );
        test_tj (4, $bin, $eol, qq{"\r\r\n"\t \r}    );
        test_tj (5, $bin, $eol, qq{"\r\r\n"\t \r\r}  );
        test_tj (6, $bin, $eol, qq{"\r\r\n"\t \r\r\n});
        }
    }

{   ok (1, "keep_meta_info on getline ()");

    my $csv = Text::CSV.new (eol => "\n");

    my $fh = open $csvf, :w;
    $fh.print (qq{1,"",,"Q",2\n});
    close $fh;

    $fh = open $csvf, :r;
    my @row = $csv.getline ($fh);
    is (@row.elems,  5,                         "Get line");
    is ($csv.is_quoted (2), False,              "Is field 2 quoted?");
    is ($csv.is_quoted (3), True,               "Is field 3 quoted?");
    $fh.close;
    unlink $csvf;
    }

{   my $csv = Text::CSV.new ();

    my $s2023 = qq{2023,",2008-04-05,"  \tFoo, Bar",\n}; # "
    #                                ^

    is ( $csv.parse ($s2023),       False, "Parse 2023");
    is (($csv.error_diag)[0],       2023,  "Fail code 2023");
    is (($csv.error_diag)[2],       19,    "Fail position");

    is ( $csv.allow_whitespace (1), True,  "Allow whitespace");
    is ( $csv.parse ($s2023),       False, "Parse 2023");
    is (($csv.error_diag)[0],       2023,  "Fail code 2023");
    is (($csv.error_diag)[2],       19,    "Space not skipped");
    }

{   my $csv = Text::CSV.new (esc => Str);

    my $s2011 = qq{2011,",2008-04-05,"  "Foo, Bar",\n};
    #                                ^

    is ($csv.parse ($s2011),       False, "Parse 2011");
    is ($csv.error_diag[0],        2011,  "Fail code 2011");
    is ($csv.error_diag[2],        19,    "Fail position");

    is ($csv.allow_whitespace (1), True,  "Allow whitespace");
    is ($csv.parse ($s2011),       False, "Parse 2021");
    is ($csv.error_diag[0],        2011,  "Fail code 2021");
    is ($csv.error_diag[2],        19,    "Space not skipped");
    }

{   my $csv = Text::CSV.new (allow_unquoted_escape => 1, escape_char => "=");
    my $str = q{1,3,=};
    is ($csv.parse ($str),         False, "Parse trailing ESC");
    is ($csv.error_diag[0],        2035,  "Fail code 2035");

    $str ~= "0";
    is ($csv.parse ($str),    True,               "Parse trailing ESC");
    is-deeply ([ $csv.list ], [ "1", "3", "\0" ], "Parse passed");
    }

done;
