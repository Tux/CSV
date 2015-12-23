#!perl6

# Cannot set $*OUT.nl-out to Str

use v6;
use Slang::Tuxic;

use Test;
use Text::CSV;

my $efn = "_eol.csv";
my @rs  = "\n", "\r\n", "\r";
my @eol = "\r", "\n", "\r\n", "\n\r", "";

for (|@rs) -> $rs {
    for (Str, $rs) -> $ors {

        my $csv = Text::CSV.new ();
        $ors.defined or $csv.eol ($rs);

        for (|@eol) -> $eol {
            for (0, 1) -> $pass {
                my IO $fh;

                if ($pass) {
                    $fh = open $efn, :r;
                    $fh.nl-in  = $rs;
                    $rs eq "\r\n" and $csv.eol (Str);
                    }
                else {
                    $fh = open $efn, :w;
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

                for (^@f.elems) -> $idx {
                    my $expect = @f[$idx];
                    if ($expect.defined && $expect ~~ m/ "\r\n" /) {
                        my $r = $expect;
                        my $n = $expect;
                        $n ~~ s:g{ "\r\n" } = "\n";
                        $expect = $r | $n;
                        }
                    is (@p[$idx], $expect,               "result  |$s_eol|$idx");
                    }

                $fh.close;
                }
            }

        unlink $efn;
        }
    }

{   my $csv = Text::CSV.new (escape_char => Str);

    ok ($csv.parse (qq{"x"\r\n}),  "Trailing \\r\\n with no escape char");

    is ($csv.eol ("\r"), "\r",     "eol set to \\r");
    ok ($csv.parse (qq{"x"\r}),    "Trailing \\r with no escape char");

    ok ($csv.allow_whitespace (1), "Allow whitespace");
    ok ($csv.parse (qq{"x" \r}),   "Trailing \\r with no escape char");
    }

{   my $csv = Text::CSV.new ();
    my $fh = open $efn, :w;
    $fh.nl-out = "#\r\n";
    $csv.print ($fh, [ "a", 1 ]);
    close $fh;
    $fh = open $efn, :r;
    $fh.nl-in = "";
    #is ($fh.get, "a,1#\r\n", "Strange \$\\");  # TODO
    $fh.close;
    unlink $efn;
    }
{   my $csv = Text::CSV.new (eol => $*OUT.nl-out);
    my $fh = open $efn, :w;
    $fh.nl-out = "#\r\n";
    $csv.print ($fh, [ "a", 1 ]);
    close $fh;
    $fh = open $efn, :r;
    $fh.nl-in = "";
    #is ($fh.get, "a,1#\r\n", "Strange \$\\ + eol");  # TODO
    $fh.close;
    unlink $efn;
    }

ok (True, "Auto-detecting \\r");
{   my @row = < a b c >;
    my $row = @row.join (",");
    for ("\n", "\r\n", "\r") -> $eol {
        my $s_eol = $eol.perl;
        my $fh = open $efn, :w;
        $fh.print: qq{$row$eol$row$eol$row$eol\x91};
        $fh.close;
        $fh = open $efn, :r;
        my $c = Text::CSV.new (:auto_diag);
        is ( $c.eol (),                  Str,       "default EOL");
        is ([$c.getline ($fh, :!meta)],  [ @row, ], "EOL 1 $s_eol");
        is ([$c.getline ($fh, :!meta)],  [ @row, ], "EOL 2 $s_eol");
        is ([$c.getline ($fh, :!meta)],  [ @row, ], "EOL 3 $s_eol");
        $fh.close;
        unlink $efn;
        }
    }

ok (True, "EOL undefined");
{   ok (my $csv = Text::CSV.new (eol => Str), "new csv with eol => Str");
    my $fh = open $efn, :w;
    ok ($csv.print ($fh, [1, 2, 3]), "print 1");
    ok ($csv.print ($fh, [4, 5, 6]), "print 2");
    close $fh;

    $fh = open $efn, :r;
    ok ((my @row = $csv.getline ($fh, :!meta)), "getline");
    is (@row.elems, 5,                          "# fields");
    is ([|@row], [ 1, 2, 34, 5, 6 ],            "fields 1+2");
    $fh.close;
    unlink $efn;
    }

for ("!", "!!", "!\n", "!\n!", "!!!!!!!!", "!!!!!!!!!!",
     "\n!!!!!\n!!!!!", "!!!!!\n!!!!!\n", "%^+_\n\0!X**",
     "\r\n", "\r") -> $eol {
    my $s_eol = $eol.perl;
    ok (True, "EOL $s_eol");
    ok ((my $csv = Text::CSV.new (:$eol)), "new csv with eol => $s_eol");
    my $fh = open $efn, :w;
    ok ($csv.print ($fh, [1, 2, 3]), "print 1");
    ok ($csv.print ($fh, [4, 5, 6]), "print 2");
    $fh.close;

    $eol eq "\r\n" and $csv.eol (Str);
    for (Str, "", "\n", $eol, "!", "!\n", "\n!", "!\n!", "\n!\n") -> $rs {
        my $s_rs = $rs.perl;
        #(my $s_rs = defined $rs ? $rs : "-- undef --") =~ s/\n/\\n/g;
        ok (True, "with RS $s_rs");
        my $fh = open $efn, :r;
        ok ((my @row = $csv.getline ($fh, :!meta)), "getline 1");
        is (@row.elems, 3,                          "field count");
        is ([|@row], [ 1, 2, 3 ],                   "fields 1");
        ok ((   @row = $csv.getline ($fh, :!meta)), "getline 2");
        is (@row.elems, 3,                          "field count");
        is ([|@row], [ 4, 5, 6 ],                   "fields 2");
        $fh.close;
        }
    unlink $efn;
    }

my Str $osxfn = "files/macosx.csv";
if ($osxfn.IO.r && my $fh = open $osxfn, :r) {
    ok (True, "MacOSX exported file");
    ok ((my $csv = Text::CSV.new (:auto_diag, :!meta)), "new csv");
    #diag ();
    my @row;
    ok ((@row = $csv.getline ($fh)), "getline 1");
    is ( @row.elems, 15,             "field count");
    is ( @row.[7], "",               "field 8");
    ok ((@row = $csv.getline ($fh)), "getline 2");
    is ( @row.elems, 15,             "field count");
    is ( @row.[6], "Category",       "field 7");
    ok ((@row = $csv.getline ($fh)), "getline 3");
    is ( @row.elems, 15,             "field count");
    is ( @row.[5], "Notes",          "field 6");
    ok ((@row = $csv.getline ($fh)), "getline 4");
    is ( @row.elems, 15,             "field count");
    is ( @row.[7], "Points",         "field 8");
    ok ((@row = $csv.getline ($fh)), "getline 5");
    is ( @row.elems, 15,             "field count");
    is ( @row.[7], 11,               "field 8");
    ok ((@row = $csv.getline ($fh)), "getline 6");
    is ( @row.elems, 15,             "field count");
    is ( @row.[8], 34,               "field 9");
    ok ((@row = $csv.getline ($fh)), "getline 7");
    is ( @row.elems, 15,             "field count");
    is ( @row.[7], 12,               "field 8");
    ok ((@row = $csv.getline ($fh)), "getline 8");
    is ( @row.elems, 15,             "field count");
    is ( @row.[8], 2,                "field 9");
    ok ((@row = $csv.getline ($fh)), "getline 9");
    is ( @row.elems, 15,             "field count");
    is ( @row.[3], "devs",           "field 4");
    ok ((@row = $csv.getline ($fh)), "getline 10");
    is ( @row.elems, 15,             "field count");
    is ( @row.[3], "",               "field 4");
    ok ((@row = $csv.getline ($fh)), "getline 11");
    is ( @row.elems, 15,             "field count");
    is ( @row.[6], "Mean",           "field 7");
    ok ((@row = $csv.getline ($fh)), "getline 12");
    is ( @row.elems, 15,             "field count");
    is ( @row.[6], "Median",         "field 7");
    ok ((@row = $csv.getline ($fh)), "getline 13");
    is ( @row.elems, 15,             "field count");
    is ( @row.[6], "Mode",           "field 7");
    ok ((@row = $csv.getline ($fh)), "getline 14");
    is ( @row.elems, 15,             "field count");
    is ( @row.[6], "Min",            "field 7");
    ok ((@row = $csv.getline ($fh)), "getline 15");
    is ( @row.elems, 15,             "field count");
    is ( @row.[6], "Max",            "field 7");
    ok ((@row = $csv.getline ($fh)), "getline 16");
    is ( @row.elems, 15,             "field count");
    is ( @row.[0], "",               "field 1");
    close $fh;
    }

done-testing;
