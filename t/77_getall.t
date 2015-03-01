#!perl6

use v6;
use Slang::Tuxic;

use Test;
use Text::CSV;

my $csv = Text::CSV.new;
my $tfn = "_77test.csv";

my @testlist = (
    [ "1", "a", "\x01", "A" ],
    [ "2", "b", "\x02", "B" ],
    [ "3", "c", "\x03", "C" ],
    [ "4", "d", "\x04", "D" ],
    );

my @list;

sub un-obj (@aoo) {
    my @aoa;
    for @aoo -> @aof {
        @aoa.push ([ @aof.map (~*) ]);
        }
    return @aoa;
    } # un-obj

sub do_tests (Sub $sub) {
    $sub.(@list);
    } # do_tests

for ("\n", "\r") -> $eol {

    @list = @testlist;

    {   ok (my $csv = Text::CSV.new (eol => $eol), "csv out EOL "~$eol.perl);
        my $fh = open $tfn, :w or die "$tfn: $!";
        ok ($csv.print ($fh, $_), "write "~$_.perl) for @list;
        $fh.close;
        }

#   {   my $fh = open $tfn, :r or die "$tfn: $!";
#       .say for $fh.lines;
#       }

    {   ok (my $csv = Text::CSV.new (eol => $eol), "csv in");

        do_tests (anon sub ($expect, *@args) {
            my $fh = open $tfn, :r or die "$tfn: $!";
            my $s_args = join ", " => @args;
            # un-obj for is_deeply
            my @f = un-obj ($csv.getline_all ($fh, |@args));
            is_deeply (@f, $expect, "getline_all ($s_args)");
            $fh.close;
            });
        }

    #unlink $tfn;
    }

done;

=finish

sub do_tests
{
    my $sub = shift;

    $sub->(\@list);
    $sub->(\@list,         0);
    $sub->([@list[2,3]],   2);
    $sub->([],             0,  0);
    $sub->(\@list,         0, 10);
    $sub->([@list[0,1]],   0,  2);
    $sub->([@list[1,2]],   1,  2);
    $sub->([@list[1..3]], -3);
    $sub->([@list[1,2]],  -3,  2);
    $sub->([@list[1..3]], -3,  3);
    } # do_tests

foreach my $eol ("\n", "\r") {

    @list = @testlist;

    {   ok (my $csv = Text::CSV.new ({ binary => 1 }), "csv in");
        ok ($csv.column_names (my @cn = qw( foo bar bin baz )), "Set column names");
        @list = map { my %h; @h{@cn} = @$_; \%h } @list;

        do_tests (sub {
            my ($expect, @args) = @_;
            open my $fh, "<", $tfn or die "$tfn: $!";
            my $s_args = join ", " => @args;
            is_deeply ($csv.getline_hr_all ($fh, @args), $expect, "getline_hr_all ($s_args)");
            close $fh;
            });
        }

    {   ok (my $csv = Text::CSV.new ({ binary => 1 }), "csv in");
        open my $fh, "<", $tfn or die "$tfn: $!";
        eval { my $row = $csv.getline_hr_all ($fh); };
        is ($csv.error_diag () + 0, 3002, "Use _hr before colnames ()");
        }

    }
