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

is ($t<B>.Str, "foo",                    "Hash access");

done;
