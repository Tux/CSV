#!perl6

use v6;
use Slang::Tuxic;

use Test;
use Text::CSV;

my $csv = Text::CSV.new;

is ($csv.sep, ",", "Sep = ,");

for < , ; > -> $sep {
    my Str $data = "bAr,foo\n1,2\n3,4,5\n";
    $data ~~ s:g{ "," } = $sep;

    $csv.column-names (False);
    {   my $fh = IO::String.new: $data;
	ok (my $slf = $csv.header ($fh), "header");
	is ($slf, $csv, "Return self");
	is ($csv.sep, $sep, "Sep = $sep");
	is-deeply ([ $csv.column-names ], [< bar foo >], "headers");
	is-deeply ($csv.getline ($fh), ["1", "2"],    "Line 1");
	is-deeply ($csv.getline ($fh), ["3", "4", "5"], "Line 2");
	}

    $csv.column-names (False);
    {   my $fh = IO::String.new: $data;
	ok (my $slf = $csv.header ($fh), "header");
	is ($slf, $csv, "Return self");
	is ($csv.sep, $sep, "Sep = $sep");
	is-deeply ([ $csv.column-names ], [< bar foo >], "headers");
	is-deeply ($csv.getline_hr ($fh), { bar => "1", foo => "2" }, "Line 1");
	is-deeply ($csv.getline_hr ($fh), { bar => "3", foo => "4" }, "Line 2");
	}
    }

my $sep-set = [ "\t", "|", ",", ";" ];
for ",", ";", "|", "\t" -> $sep {
    my Str $data = "bAr,foo\n1,2\n3,4,5\n";
    $data ~~ s:g{ "," } = $sep;

    $csv.column-names (False);
    {   my $fh = IO::String.new: $data;
	ok (my $slf = $csv.header ($fh, :$sep-set), "header with specific sep set");
	is ($slf, $csv, "Return self");
	is ($csv.sep, $sep, "Sep = $sep");
	is-deeply ([ $csv.column-names ], [< bar foo >], "headers");
	is-deeply ($csv.getline ($fh), ["1", "2"],    "Line 1");
	is-deeply ($csv.getline ($fh), ["3", "4", "5"], "Line 2");
	}

    $csv.column-names (False);
    {   my $fh = IO::String.new: $data;
	ok (my $slf = $csv.header ($fh, :$sep-set), "header with specific sep set");
	is ($slf, $csv, "Return self");
	is ($csv.sep, $sep, "Sep = $sep");
	is-deeply ([ $csv.column-names ], [< bar foo >], "headers");
	is-deeply ($csv.getline_hr ($fh), { bar => "1", foo => "2" }, "Line 1");
	is-deeply ($csv.getline_hr ($fh), { bar => "3", foo => "4" }, "Line 2");
	}
    }

for   1010, "",
      1011, "a,b;c,d",
      1012, "a,,b",
      1013, "a,a,b",
      2027, "a,\"b\nc\",d"
      -> $err, $data {
    my $fh = IO::String.new: $data;
    my $e;
    my $self;
    {   $self = $csv.header ($fh);
        CATCH { default { $e = $_; "" }}
        }
    is ($self, Any, "FAIL for {$data.perl}");
    is ($e.error, $err, "Error code $err");
    }
{   my $fh = IO::String.new: "bar,bAr,bAR,BAR\n1,2,3,4";
    $csv.column-names (False);
    ok ($csv.header ($fh, munge-column-names => "none"), "non-unique unfolded headers");
    is-deeply ([ $csv.column-names ], [< bar bAr bAR BAR >], "Headers");
    }

for < , ; > -> $sep {
    my Str $data = "bAr,foo\n1,2\n3,4,5\n";
    $data ~~ s:g{ "," } = $sep;

    $csv.column-names (False);
    {   my $fh = IO::String.new: $data;
	ok (my $slf = $csv.header ($fh, :!set-column-names), "Header without column setting");
	is ($slf, $csv, "Return self");
	is ($csv.sep, $sep, "Sep = $sep");
	is-deeply ([ $csv.column-names ], [], "headers");
	is-deeply ($csv.getline ($fh), ["1", "2"],    "Line 1");
	is-deeply ($csv.getline ($fh), ["3", "4", "5"], "Line 2");
	}
    }

my $n = 0;
for Str, "bar", "fc", "bar", "lc", "bar", "uc", "BAR", "none", "bAr",
    { "column_{$n++}" }, "column_0" -> $munge-column-names, $hdr {
    my Str $data = "bAr,foo\n1,2\n3,4,5\n";

    $csv.column-names (False);
    my $fh = IO::String.new: $data;
    ok (my $slf = $csv.header ($fh, :$munge-column-names), "header with fold {$munge-column-names.perl}");
    is ($csv.column-names[0], $hdr, "folded header to $hdr");
    }

done-testing;
