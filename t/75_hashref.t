#!perl6

use v6;
use Slang::Tuxic;

my $tfn = "_75in.csv";

use Test;
use Text::CSV;

my $fh = open $tfn, :w;
$fh.print (q:to/EOC/);
code,name,price,description
1,Dress,240.00,"Evening gown"
2,Drinks,82.78,"Drinks"
3,Sex,-9999.99,"Priceless"
4,Hackathon,Free,"QA Hackathon Oslo 2008"
EOC
close $fh;

ok (my $csv = Text::CSV.new (),	"new");
is ($csv.column_names.elems, 0, "No headers yet");

ok ($csv.column_names ("name"),	        "One single name");
is ($csv.column_names.elems, 1,         "column_names");
is ($csv.column_names, [< name >],      "column_name stored");
is ($csv.column_names (False).elems, 0, "reset column_names");

$fh = open $tfn, :r, chomp => False;

my Int $error = 0;
{   my $hr = $csv.getline_hr ($fh);
    CATCH { default { $error = .error }}
    }
is ($error, 3002, "_hr call before column_names");

ok ($csv.column_names ("name", "code"), "column_names (list)");
is_deeply ([$csv.column_names], [ "name", "code" ], "well set");

my @hdr = < code name price description >;
is_deeply ([$csv.getline ($fh, meta => False)], @hdr, "Header still not _hr");

ok ($csv.column_names (@hdr), "Set whole header");
is_deeply ([$csv.column_names], @hdr, "Inspect header");

while $csv.getline_hr ($fh) -> %row {
    ok (%row{$_}, "Has $_") for @hdr;
    like (%row{"code"}.Str, rx{^ <[0..9]>+ $},                  "Code numeric");
#   like (%row{"name"}.Str, rx{^ <["A".."Z"]> <["a".."z"]>+ $}, "Name Alpha");
    }

$fh.close;

$fh = open $tfn, :r, chomp => False;
$csv.colrange ([0, 2]);
is_deeply ($csv.getline_hr ($fh, meta => False),
 { :code("code"), :price("price") }, "selection");
$fh.close;

unlink $tfn;

done;

=finish

open $fh, ">", "_75test.csv";
$hr = { c_foo => 1, foo => "poison", zebra => "Of course" };
is ($csv.column_names (undef), undef,           "reset column headers");
ok ($csv.column_names (sort keys %$hr), "set column names");
ok ($csv.eol ("\n"),                            "set eol for output");
ok ($csv.print ($fh, [ $csv.column_names ]),    "print header");
ok ($csv.print_hr ($fh, $hr),                   "print_hr");
ok ($csv.print ($fh, []),                       "empty print");
close $fh;
ok ($csv.keep_meta_info (1),                    "keep meta info");
open $fh, "<", "_75test.csv";
ok ($csv.column_names ($csv.getline ($fh)),     "get column names");
is_deeply ($csv.getline_hr ($fh), $hr,          "compare to written hr");

is_deeply ($csv.getline_hr ($fh),
    { c_foo => "", foo => undef, zebra => undef },      "compare to written hr");
is ($csv.is_missing (1), 1,                     "No col 1");
close $fh;

unlink "_75test.csv";
