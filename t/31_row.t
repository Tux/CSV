#!perl6

use v6;
use Slang::Tuxic;

use Test;
use Text::CSV;

my CSV::Row $r .= new;

is ($r.csv,          Text::CSV, "No csv");
is ($r.fields.elems, 0,         "No fields");
is ($r.Str,          Str,       "No csv to do string");

ok ($r.push (1),                        "push int");
ok ($r.push ("foo"),                    "push Str");
ok ($r.push (CSV::Field.new (2)),       "push C::F (int)");
ok ($r.push (CSV::Field.new ("bar")),   "push C::F (Str)");

is (+$r[0],          1,         "1");
is (~$r[1],          "foo",     "foo");
is (+$r[2],          2,         "2");
is (~$r[3],          "bar",     "bar");

ok (my $t = CSV::Row.new (csv => Text::CSV.new), "New with CSV");
$t.push ($r);

is (~$t, "1,foo,2,bar", "String");

is ($t<B>, Any, "No hash possible yet");

ok ($t.csv.column_names (<A B C D>), "Set headers");

is (~$t[0],     "1",   "Str indexed access");
is ( $t<B>.Str, "foo", "Str hash    access");
is (+$t[2],     2,     "Num indexed access");
is (~$t<D>,     "bar", "Str hash    access");

is-deeply ( $t.hash,  { :A("1"), :B("foo"), :C("2"), :D("bar") }, "hash");
is-deeply ([$t.list], [    "1",     "foo",     "2",     "bar"  ], "list");

my $csv = Text::CSV.new (:!keep_meta);
is-deeply ([$csv.getline ("foo,bar,zip")], [<foo bar zip>], "getline");
ok (my $row = $csv.row, "Get last row");
is-deeply ([$row.list], [<foo bar zip>], "list");

done;
