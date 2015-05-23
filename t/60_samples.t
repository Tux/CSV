#!perl6

use v6;
use Slang::Tuxic;

use Test;
use Text::CSV;

# Some assorted examples from the XS' history

# "Pavel Kotala" <pkotala@logis.cz>
{
    my $csv = Text::CSV.new (
        quote_char      => '"',
        escape_char     => '\\',
        sep_char        => ';',
        binary          => 1,
        );
    ok ($csv,                           "new (\", \\\\, ;, 1)");

    my @list = ("c:\\winnt", "text");
    ok ($csv.combine (@list),           "combine ()");
    my $line = $csv.string;
    ok ($line,                          "string ()");
    ok ($csv.parse ($line),             "parse ()");
    my @olist = $csv.fields;
    is (@list.elems, @olist.elems,      "field count");
    is (@list[0], @olist[0],            "field 1");
    is (@list[1], @olist[1],            "field 2");
    is-deeply ($csv.list, @olist».text, "As list");
    }

done;
