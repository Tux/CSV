#!perl6

use v6;
use Slang::Tuxic;

use Test;
use Text::CSV;

my %err;

# Read errors from pm
{   my $pm = open "lib/Text/CSV.pm", :r;
    for $pm.lines () {
        m{^ \s* ";" $} and last;
        m{^ \s+ (<[0..9]>+) \s+ "=>" \s+ '"' (.*) '",' $}
            and %err{$0.Num} = $1.Str;
        }
    }

my $csv = Text::CSV.new ();
is (+$csv.error_diag,  0,       "initial state is no error");
is (~$csv.error_diag, "",       "initial state is no error");
is_deeply ([ $csv.error_diag ], [ 0, "", 0, 0, 0, ""], "OK in list context");

my $recno = 1;

sub parse_err (Int $err, Int $pos, Int $fld, Str $buf) {
    my $s_err = %err{$err};
    is ($csv.parse ($buf), False, "$err - Err for parse ({$buf.perl})");
    is (+$csv.error_diag, $err,   "$err - Diag in numerical context");
    is (~$csv.error_diag, $s_err, "$err - Diag in string context");
    my @diag = $csv.error_diag;
    is (@diag[0], $err,     "$err - Num diag in list context");
    is (@diag[1], $s_err,   "$err - Str diag in list context");
    is (@diag[2], $pos,     "$err - Pos diag in list context");
    is (@diag[3], $fld,     "$err - Fld diag in list context");
    is (@diag[4], $recno++, "$err - Rec diag in list context");
    is (@diag[9], Any,      "$err - no such diag");
    } # parse_err

parse_err (2023, 19, 2, qq{2023,",2008-04-05,"Foo, Bar",\n}); # "

$csv = Text::CSV.new (escape => "+", eol => "\n", :!binary);
is (~$csv.error_diag, "", "No errors yet");

$recno = 1;
#parse_err (2010,  3, 1, qq{"x"\r});    # perl5 only
 parse_err (2011,  3, 1, qq{"x"x});

 parse_err (2021,  2, 1, qq{"\n"});
 parse_err (2022,  2, 1, qq{"\r"});
 parse_err (2025,  2, 1, qq{"+ "});
 parse_err (2026,  2, 1, qq{"\0 "});
 parse_err (2027,  1, 1,   '"');
 parse_err (2031,  1, 1, qq{\r });
 parse_err (2032,  2, 1, qq{ \r});
 parse_err (2034,  4, 2, qq{1, "bar",2});
 parse_err (2037,  1, 1, qq{\0 });

# Test error_diag in void context
{   my $e;
    #$csv.error_diag ();
    #ok (@warn == 1, "Got error message");
    #like ($warn[0], qr{^# CSV ERROR: 2037 - EIF}, "error content");
    }

is ($csv.eof, False, "No EOF");
$csv.SetDiag (2012);
is ($csv.eof, True,  "EOF caused by 2012");

{   my $e;
    ok (1, "Expecting an error line here:");
    {   Text::CSV.new (ecs_char => ":");
        CATCH { default { $e = $_; }}
        }
    is (+$e, 1000, "unsupported attribute");
    is (~$e, "INI - constructor failed: Unknown attribute 'ecs_char'", "Reported back");
    }

$csv.set_diag (1000);
is (+$csv.error_diag, 1000,                       "1000 - Set error Num");
is (~$csv.error_diag, "INI - constructor failed", "1000 - Set error Str");
$csv.set-diag (0);
is (+$csv.error_diag,    0,                       "Reset error Num");
is (~$csv.error_diag, "",                         "Reset error Str");

ok ($csv.parse (q{,cat,}),                        "Parse ASCII");
is (($csv.fields)[1].gist, q{qb7m:"cat"},         "ASCII.gist");
ok ($csv.parse (q{"Ħēłĺº"}),                 "Parse UTF-8");
is (($csv.fields)[0].gist, q{QB8m:"Ħēłĺº"},  "UTF-8.gist");

{   my $csv = Text::CSV.new ();
    is ($csv.parse (q{1,"abc"}), True,     "Valid parse");
    is ($csv.error_input,        Str,      "No error_input");
    is ($csv.error_diag.error,   0,        "Error code");
    is ($csv.error_diag.record,  1,        "Error line");
    is ($csv.error_diag.field,   0,        "Error field");
    is ($csv.error_diag.pos,     0,        "Error pos");
    is ($csv.parse (q{a"bc"}),   False,    "Invalid parse");
    is ($csv.error_input,        q{a"bc"}, "Error_input");
    is ($csv.error_diag.error,   2034,     "Error code");
    is ($csv.error_diag.record,  2,        "Error line");
    is ($csv.error_diag.field,   1,        "Error field");
    is ($csv.error_diag.pos,     2,        "Error pos");
    }

for    (Str,            # No spec at all
        "",             # No spec at all
        "row=0",        # row > 0
        "col=0",        # col > 0
        "cell=0",       # cell = r,c
        "cell=0,0",     # col & row > 0
        "row=*",        # * only after n-
        "col=3-1",      # to >= from
        "cell=4,1;1",   # cell has no ;
        "cell=3,3-2,1", # bottom-right should be right to and below top-left
        "cell=1,*",     # * in single cell col
        "cell=*,1",     # * in single cell row
        "cell=*,*",     # * in single cell row and column
        "cell=1,*-8,9", # * in cell range top-left cell col
        "cell=*,1-8,9", # * in cell range top-left cell row
        "cell=*,*-8,9", # * in cell range top-left cell row and column
        "row=/",        # illegal character
        "col=4;row=3",  # cannot combine rows and columns
        ) -> $spec {
    my $csv = Text::CSV.new;
    my $e;
    my @r;
    {   @r = $csv.fragment (IO::String.new (""), $spec);
        CATCH { default { $e = $_; 1; }}
        }
    #$csv.error-diag;
    $e ||= $csv.error-diag;
    is (@r, [], "Cannot do fragment with bad RFC7111 spec");
    is ($e.error, 2013, "Illegal RFC7111 spec ({$spec.perl})");
    }
done;

=finish

ok (1, "Test auto_diag");
$csv = Text::CSV.new (:auto_diag);
{   my @warn;
    local $SIG{__WARN__} = sub { push @warn, @_ };
    is ($csv.{_RECNO}, 0, "No records read yet");
    is ($csv.parse ('"","'), 0, "1 - bad parse");
    ok (@warn == 1, "1 - One error");
    like ($warn[0], qr '^# CSV ERROR: 2027 -', "1 - error message");
    is ($csv.{_RECNO}, 1, "One record read");
    }
{   my @warn;
    local $SIG{__WARN__} = sub { push @warn, @_ };
    is ($csv.diag_verbose (3), 3, "Set diag_verbose");
    is ($csv.parse ('"","'), 0, "1 - bad parse");
    ok (@warn == 1, "1 - One error");
    @warn = split m/\n/ => $warn[0];
    ok (@warn == 3, "1 - error plus two lines");
    like ($warn[0], qr '^# CSV ERROR: 2027 -', "1 - error message");
    like ($warn[1], qr '^"","',                   "1 - input line");
    like ($warn[2], qr '^   \^',                 "1 - position indicator");
    is ($csv.{_RECNO}, 2, "Another record read");
    }

done;
