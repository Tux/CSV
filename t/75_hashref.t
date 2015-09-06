#!perl6

use v6;
use Slang::Tuxic;

my $tfn = "_75in.csv"; END { unlink $tfn; }

use Test;
use Text::CSV;

my $fh = open $tfn, :w;
$fh.print (q:to/EOC/);
code,name,price,description
1,Dress,240.00,"Evening gown"
2,Drinks,82.78,"Drinks"
3,Sex,-9999.99,"Priceless"
4,Hackathon,0.00,"QA Hackathon Oslo 2008"
EOC
$fh.close;

ok (my $csv = Text::CSV.new,	"new");
is ($csv.column_names.elems, 0, "No headers yet");

ok ($csv.column_names ("name"),	        "One single name");
is ($csv.column_names.elems, 1,         "column_names");
is ($csv.column_names, [< name >],      "column_name stored");
is ($csv.column_names (False).elems, 0, "reset column_names");

$fh = open $tfn, :r, :!chomp;

my $e;
{   my $hr = $csv.getline_hr ($fh);
    CATCH { default { $e = $_; 1; }}
    }
is   (+$e, 3002,           "3002 - _hr call before column_names");
like (~$e, rx{^ "EHR" >>}, "3002 - EHR");

ok ($csv.column_names (< name code >), "column_names (list)");
is-deeply ([$csv.column_names], [< name code >], "well set");

my @hdr = < code name price description >;
is-deeply ([$csv.getline ($fh, :!meta)], @hdr, "Header still not _hr");

ok ($csv.column_names (@hdr), "Set whole header");
is-deeply ([$csv.column_names], @hdr, "Inspect header");

while $csv.getline_hr ($fh) -> %row {
    ok (%row{$_}, "Has $_") for @hdr;
    like (~%row<code>, rx{^ <[0..9]>+ $},          "Code numeric");
    like (~%row<name>, rx{^ <[A..Z]> <[a..z]>+ $}, "Name Alpha");
    }

$fh.close;

$fh = open $tfn, :r, :!chomp;
$csv.colrange ([0, 2]);
is-deeply ($csv.getline_hr ($fh, :!meta),
    { :code("code"), :price("price") }, "selection");
$fh.close;

unlink $tfn;

$csv = Text::CSV.new;
$fh = open $tfn, :w;
my %hr = :c_foo("1"), :foo("poison"), :zebra("Of course");
is ([$csv.column_names (False)], [],                   "reset column headers");
ok ($csv.column_names (sort keys %hr),                 "set column names");
ok ($csv.eol ("\n"),                                   "set eol for output");
ok ($csv.print ($fh, $csv.column_names),               "print header");
ok ($csv.print ($fh, %hr),                             "print (IO, Hash)");
ok ($csv.print ($fh, {}),                              "empty print");
ok ($fh.say (""),                                      "empty line");
$fh.close;
ok ($csv.keep_meta (True),                             "keep meta info");
$fh = open $tfn, :r;
is ([$csv.column_names (False)], [],                   "reset column headers");
ok ($csv.column_names ($csv.getline ($fh)),            "get column names");
is-deeply ([$csv.column_names], [< c_foo foo zebra >], "column names");
my %gth = $csv.getline_hr ($fh);
is-deeply ([ sort keys %gth ],  [< c_foo foo zebra >], "keys");
is-deeply ([%gth<c_foo foo zebra>».Str],
    [%hr<c_foo foo zebra>],                            "field values");
is ($csv.keep_meta (False), False,                     "reset meta");
is-deeply ($csv.getline_hr ($fh),
    {:c_foo(""), :foo(""), :zebra("")},                "empty record");
is-deeply ($csv.getline_hr ($fh), {:c_foo("")},        "empty line");
# TODO: Test for missing columns 2 and 3
$fh.close;

done-testing;
