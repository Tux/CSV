#!perl6

use v6;
use Slang::Tuxic;

use Test;
use Text::CSV;

my Str $efn;
my Str @rs  = "\n", "\r\n", "\r";
my Str @eol = "\r", "\n", "\r\n", "\n\r", "";

for (|@rs) -> $rs {
    for (Str, $rs) -> $ors {

        my $csv = Text::CSV.new ();
        $ors.defined or $csv.eol ($rs);

        for (|@eol) -> $eol {
            $efn = "";
            for (0, 1) -> $pass {
                my IO $fh;

                $fh = IO::String.new ($efn, nl-in => $rs);
                $fh.nl-out = $ors.defined ?? $ors !! "";

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
                         @p = $csv.strings;
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
        }
    }

ok (True, "Auto-detecting \\r");
{   my @row = < a b c >;
    my $row = @row.join (",");
    for ("\n", "\r\n", "\r") -> $eol {
        my $s_eol = $eol.perl;
        $efn = qq{$row$eol$row$eol$row$eol\x91};
        my $fh = IO::String.new ($efn, nl-in => Str, nl-out => Str);
        my $c = Text::CSV.new (:auto_diag);
        is ( $c.eol (),                  Str,       "default EOL");
        is ([$c.getline ($fh, :!meta)],  [ @row, ], "EOL 1 $s_eol");
        is ([$c.getline ($fh, :!meta)],  [ @row, ], "EOL 2 $s_eol");
        is ([$c.getline ($fh, :!meta)],  [ @row, ], "EOL 3 $s_eol");
        $fh.close;
        $efn = "";
        }
    }

ok (True, "EOL undefined");
{   ok (my $csv = Text::CSV.new (eol => Str), "new csv with eol => Str");
    my $fh = IO::String.new ($efn);
    ok ($csv.print ($fh, [1, 2, 3]), "print 1");
    ok ($csv.print ($fh, [4, 5, 6]), "print 2");
    $fh.close;

    $fh = IO::String.new ($efn);
    ok ((my @row = $csv.getline ($fh, :!meta)), "getline");
    is (@row.elems, 5,                          "# fields");
    is ([|@row], [ 1, 2, 34, 5, 6 ],            "fields 1+2");
    $fh.close;
    $efn = "";
    }

for ("!", "!!", "!\n", "!\n!", "!!!!!!!!", "!!!!!!!!!!",
     "\n!!!!!\n!!!!!", "!!!!!\n!!!!!\n", "%^+_\n\0!X**",
     "\r\n", "\r") -> $eol {
    my $s_eol = $eol.perl;
    ok (True, "EOL $s_eol");
    ok ((my $csv = Text::CSV.new (:$eol)), "new csv with eol => $s_eol");
    $efn = "";
    my $fh = IO::String.new ($efn, nl-out => Str);
    ok ($csv.print ($fh, [1, 2, 3]), "print 1");
    ok ($csv.print ($fh, [4, 5, 6]), "print 2");
    $fh.close;

    $csv.auto-diag (True);
    for (Str, "", "\n", $eol, "!", "!\n", "\n!", "!\n!", "\n!\n") -> $rs {
        my $s_rs = $rs.perl;
        ok (True, "with RS $s_rs / EOL $s_eol");
        my $fh  = IO::String.new ($efn, :ro, nl-in => $rs);
        my @row = $csv.getline ($fh, :!meta);
        if (@row.elems == 3 && @row[2] eq "3") {
            is (@row.elems, 3,                          "field count");
            is ([|@row], [ 1, 2, 3 ],                   "fields 1");
            ok ((   @row = $csv.getline ($fh, :!meta)), "getline 2");
            is (@row.elems, 3,                          "field count");
            is ([|@row], [ 4, 5, 6 ],                   "fields 2");
            }
        else { #TODO? Or is this just too weird to try to support
            note "TODO: EOL = $s_eol, RS = $s_rs";
            note "      ", $efn.perl;
            note "  --> ", @row.perl;
            #$csv.diag;
            }
        $fh.close;
        }
    $efn = "";
    }

done-testing;
