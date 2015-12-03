#!perl6

# Cannot set $*OUT.nl-out to Str

use v6;
use Slang::Tuxic;

use Test;
use Text::CSV;

my @rs  = "\n", "\r\n", "\r";
my @eol = "\r", "\n", "\r\n", "\n\r";#, "";

my $def_rs = $*IN.nl-in;

for (|@rs) -> $rs {
    for (Str, $rs) -> $ors {

        my $csv = Text::CSV.new ();
        $ors.defined or $csv.eol ($rs);

        for (|@eol) -> $eol {
            for (0, 1) -> $pass {
                my IO $fh;

                if ($pass) {
                    $fh = open "_eol.csv", :r;
                    $fh.nl-in  = $rs;
                    }
                else {
                    $fh = open "_eol.csv", :w;
                    $fh.nl-out = $ors.defined ?? $ors !! "";
                    }

                my $s_eol = join " - ", $rs.perl, $ors.perl, $eol.perl;

                my @p;
                my @f = ("", "1",
                    $eol, " $eol", "$eol ", " $eol ", "'$eol'",
                    "\"$eol\"", " \" $eol \"\n ", "EOL");

                 if ($pass == 0) {
                     ok ($csv.combine (@f),              "combine |$s_eol|");
                     ok (my Str $str = $csv.string,      "string  |$s_eol|");
                     my $state = $csv.parse ($str);
                     ok ($state,                         "parse   |$s_eol|");
                     if ($state) {
                         @p = $csv.list;
                         ok (@p.elems,                   "fields  |$s_eol|");
                         }
                     else{
                         is ($csv.error_input, $str,     "error   |$s_eol|");
                         }
 
                     $fh.print ($str);
                     }
                 else {
                     my @row = $csv.getline ($fh);
                     ok (@row.elems,                     "getline |$s_eol|");
                     @p = @row;
                     }

                is (@p.perl, @f.perl,                    "result  |$s_eol|");

                $fh.close;
                }
            }

        unlink "_eol.csv";
        }
    }
$*IN.nl-in = $def_rs;

{   my $csv = Text::CSV.new (escape_char => Str);

    ok ($csv.parse (qq{"x"\r\n}),  "Trailing \\r\\n with no escape char");

    is ($csv.eol ("\r"), "\r",     "eol set to \\r");
    ok ($csv.parse (qq{"x"\r}),    "Trailing \\r with no escape char");

    ok ($csv.allow_whitespace (1), "Allow whitespace");
    ok ($csv.parse (qq{"x" \r}),   "Trailing \\r with no escape char");
    }
=finish

{   local $*OUT.nl = "#\r\n";
    my $csv = Text::CSV.new ();
    open  my $fh, ">", "_eol.csv";
    $csv.print ($fh, [ "a", 1 ]);
    close $fh;
    open  $fh, "<", "_eol.csv";
    local $*IN.input-line-separator;
    is (<$fh>, "a,1#\r\n", "Strange \$\\");
    close $fh;
    unlink "_eol.csv";
    }
{   local $*OUT.nl = "#\r\n";
    my $csv = Text::CSV.new ({ eol => $*OUT.nl });
    open  my $fh, ">", "_eol.csv";
    $csv.print ($fh, [ "a", 1 ]);
    close $fh;
    open  $fh, "<", "_eol.csv";
    local $*IN.input-line-separator;
    is (<$fh>, "a,1#\r\n", "Strange \$\\ + eol");
    close $fh;
    unlink "_eol.csv";
    }
$*IN.nl-in = $def_rs;

ok (1, "Auto-detecting \\r");
{   my @row = qw( a b c ); local $" = ",";
    for (["\n", "\\n"], ["\r\n", "\\r\\n"], ["\r", "\\r"]) {
        my ($eol, $s_eol) = @$_;
        open  my $fh, ">", "_eol.csv";
        print $fh qq{@row$eol@row$eol@row$eol\x91};
        close $fh;
        open  $fh, "<", "_eol.csv";
        my $c = Text::CSV.new ({ binary => 1, auto_diag => 1 });
        is ($c.eol (),                  "",             "default EOL");
        is_deeply ($c.getline ($fh),    [ @row ],       "EOL 1 $s_eol");
        is ($c.eol (),  $eol eq "\r" ? "\r" : "",       "EOL");
        is_deeply ($c.getline ($fh),    [ @row ],       "EOL 2 $s_eol");
        is_deeply ($c.getline ($fh),    [ @row ],       "EOL 3 $s_eol");
        close $fh;
        unlink "_eol.csv";
        }
    }

ok (1, "Specific \\r test from tfrayner");
{   $*IN.input-line-separator = "\r";
    open  my $fh, ">", "_eol.csv";
    print $fh qq{a,b,c$*IN.input-line-separator}, qq{"d","e","f"$*IN.input-line-separator};
    close $fh;
    open  $fh, "<", "_eol.csv";
    my $c = Text::CSV.new ({ eol => $*IN.input-line-separator });

    my $row;
    local $" = " ";
    ok ($row = $c.getline ($fh),        "getline 1");
    is (scalar @$row, 3,                "# fields");
    is ("@$row", "a b c",               "fields 1");
    ok ($row = $c.getline ($fh),        "getline 2");
    is (scalar @$row, 3,                "# fields");
    is ("@$row", "d e f",               "fields 2");
    close $fh;
    unlink "_eol.csv";
    }
$*IN.input-line-separator = $def_rs;

ok (1, "EOL undef");
{   $*IN.input-line-separator = "\r";
    ok (my $csv = Text::CSV.new ({ eol => undef }), "new csv with eol => undef");
    open  my $fh, ">", "_eol.csv";
    ok ($csv.print ($fh, [1, 2, 3]), "print");
    ok ($csv.print ($fh, [4, 5, 6]), "print");
    close $fh;

    open  $fh, "<", "_eol.csv";
    ok (my $row = $csv.getline ($fh),   "getline 1");
    is (scalar @$row, 5,                "# fields");
    is_deeply ($row, [ 1, 2, 34, 5, 6], "fields 1");
    close $fh;
    unlink "_eol.csv";
    }
$*IN.input-line-separator = $def_rs;

foreach my $eol ("!", "!!", "!\n", "!\n!", "!!!!!!!!", "!!!!!!!!!!",
                 "\n!!!!!\n!!!!!", "!!!!!\n!!!!!\n", "%^+_\n\0!X**",
                 "\r\n", "\r") {
    (my $s_eol = $eol) =~ s/\n/\\n/g;
    $s_eol =~ s/\r/\\r/g;
    $s_eol =~ s/\0/\\0/g;
    ok (1, "EOL $s_eol");
    ok (my $csv = Text::CSV.new ({ eol => $eol }), "new csv with eol => $s_eol");
    open  my $fh, ">", "_eol.csv";
    ok ($csv.print ($fh, [1, 2, 3]), "print");
    ok ($csv.print ($fh, [4, 5, 6]), "print");
    close $fh;

    foreach my $rs (undef, "", "\n", $eol, "!", "!\n", "\n!", "!\n!", "\n!\n") {
        local $*IN.input-line-separator = $rs;
        (my $s_rs = defined $rs ? $rs : "-- undef --") =~ s/\n/\\n/g;
        ok (1, "with RS $s_rs");
        open $fh, "<", "_eol.csv";
        ok (my $row = $csv.getline ($fh),       "getline 1");
        is (scalar @$row, 3,                    "field count");
        is_deeply ($row, [ 1, 2, 3],            "fields 1");
        ok (   $row = $csv.getline ($fh),       "getline 2");
        is (scalar @$row, 3,                    "field count");
        is_deeply ($row, [ 4, 5, 6],            "fields 2");
        close $fh;
        }
    unlink "_eol.csv";
    }
$*IN.input-line-separator = $def_rs;

{   open my $fh, "<", "files/macosx.csv" or die "Ouch $!";
    ok (1, "MacOSX exported file");
    ok (my $csv = Text::CSV.new ({ auto_diag => 1, binary => 1 }), "new csv");
    diag ();
    ok (my $row = $csv.getline ($fh),   "getline 1");
    is (scalar @$row, 15,               "field count");
    is ($row.[7], "",                   "field 8");
    ok (   $row = $csv.getline ($fh),   "getline 2");
    is (scalar @$row, 15,               "field count");
    is ($row.[6], "Category",           "field 7");
    ok (   $row = $csv.getline ($fh),   "getline 3");
    is (scalar @$row, 15,               "field count");
    is ($row.[5], "Notes",              "field 6");
    ok (   $row = $csv.getline ($fh),   "getline 4");
    is (scalar @$row, 15,               "field count");
    is ($row.[7], "Points",             "field 8");
    ok (   $row = $csv.getline ($fh),   "getline 5");
    is (scalar @$row, 15,               "field count");
    is ($row.[7], 11,                   "field 8");
    ok (   $row = $csv.getline ($fh),   "getline 6");
    is (scalar @$row, 15,               "field count");
    is ($row.[8], 34,                   "field 9");
    ok (   $row = $csv.getline ($fh),   "getline 7");
    is (scalar @$row, 15,               "field count");
    is ($row.[7], 12,                   "field 8");
    ok (   $row = $csv.getline ($fh),   "getline 8");
    is (scalar @$row, 15,               "field count");
    is ($row.[8], 2,                    "field 9");
    ok (   $row = $csv.getline ($fh),   "getline 9");
    is (scalar @$row, 15,               "field count");
    is ($row.[3], "devs",               "field 4");
    ok (   $row = $csv.getline ($fh),   "getline 10");
    is (scalar @$row, 15,               "field count");
    is ($row.[3], "",                   "field 4");
    ok (   $row = $csv.getline ($fh),   "getline 11");
    is (scalar @$row, 15,               "field count");
    is ($row.[6], "Mean",               "field 7");
    ok (   $row = $csv.getline ($fh),   "getline 12");
    is (scalar @$row, 15,               "field count");
    is ($row.[6], "Median",             "field 7");
    ok (   $row = $csv.getline ($fh),   "getline 13");
    is (scalar @$row, 15,               "field count");
    is ($row.[6], "Mode",               "field 7");
    ok (   $row = $csv.getline ($fh),   "getline 14");
    is (scalar @$row, 15,               "field count");
    is ($row.[6], "Min",                "field 7");
    ok (   $row = $csv.getline ($fh),   "getline 15");
    is (scalar @$row, 15,               "field count");
    is ($row.[6], "Max",                "field 7");
    ok (   $row = $csv.getline ($fh),   "getline 16");
    is (scalar @$row, 15,               "field count");
    is ($row.[0], "",                   "field 1");
    close $fh;
    }

1;
