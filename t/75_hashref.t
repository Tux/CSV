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

done;

=finish

while (my $hr = $csv.getline_hr ($fh)) {
    ok (exists $hr.{code},                      "Line has a code field");
    like ($hr.{code}, qr/^[0-9]+$/,             "Code is numeric");
    ok (exists $hr.{name},                      "Line has a name field");
    like ($hr.{name}, qr/^[A-Z][a-z]+$/,        "Name");
    }
close $fh;

my ($code, $name, $price, $desc) = (1..4);
is ($csv.bind_columns (), undef,                "No bound columns yet");
eval { $csv.bind_columns (\$code) };
is ($csv.error_diag () + 0, 3003,               "Arg cound mismatch");
eval { $csv.bind_columns ({}, {}, {}, {}) };
is ($csv.error_diag () + 0, 3004,               "bad arg types");
is ($csv.column_names (undef), undef,           "reset column_names");
ok ($csv.bind_columns (\($code, $name, $price)), "Bind columns");

eval { $csv.column_names ("foo") };
is ($csv.error_diag () + 0, 3003,               "Arg cound mismatch");
$csv.bind_columns (undef);
eval { $csv.bind_columns ([undef]) };
is ($csv.error_diag () + 0, 3004,               "legal header defenition");

my @bcr = \($code, $name, $price, $desc);
open $fh, "<", "_75test.csv";
ok ($row = $csv.getline ($fh),                  "getline headers");
ok ($csv.bind_columns (@bcr),                   "Bind columns");
ok ($csv.column_names ($row),                   "column_names from array_ref");
is_deeply ([ $csv.column_names ], [ @$row ],    "Keys set");

$row = $csv.getline ($fh);
is_deeply ([ $csv.bind_columns ], [ @bcr ],     "check refs");
is_deeply ($row, [],            "return from getline with bind_columns");

is ($csv.column_names (undef), undef,           "reset column headers");
is ($csv.bind_columns (undef), undef,           "reset bound columns");

my $foo;
ok ($csv.bind_columns (@bcr, \$foo),            "bind too many columns");
($code, $name, $price, $desc, $foo) = (101 .. 105);
ok ($csv.getline ($fh),                 "fetch less than expected");
is_deeply ([ $code, $name, $price, $desc, $foo ],
           [ 2, "Drinks", "82.78", "Drinks", 105 ],     "unfetched not reset");

my @foo = (0) x 0x012345;
ok ($csv.bind_columns (\(@foo)),                "bind a lot of columns");

ok ($csv.bind_columns (\1, \2, \3, \""),        "bind too constant columns");
is ($csv.getline ($fh), undef,                  "fetch to read-only ref");
is ($csv.error_diag () + 0, 3008,               "Read-only");

ok ($csv.bind_columns (\$code),         "bind not enough columns");
eval { $row = $csv.getline ($fh) };
is ($csv.error_diag () + 0, 3006,               "cannot read all fields");

close $fh;

open $fh, "<", "_75test.csv";

is ($csv.column_names (undef), undef,           "reset column headers");
is ($csv.bind_columns (undef), undef,           "reset bound columns");
is_deeply ([ $csv.column_names (undef, "", "name", "name") ],
           [ "\cAUNDEF\cA", "", "name", "name" ],       "undefined column header");
ok ($hr = $csv.getline_hr ($fh),                "getline_hr ()");
is (ref $hr, "HASH",                            "returned a hashref");
is_deeply ($hr, { "\cAUNDEF\cA" => "code", "" => "name", "name" => "description" },
    "Discarded 3rd field");

close $fh;

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
