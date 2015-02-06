#!perl6

use v6;
use Slang::Tuxic;
use Inline::Perl5;

my $p5 = Inline::Perl5.new;

$p5.use ("DBI");

my $dbh = $p5.invoke ("DBI", "connect", "dbi:Pg:");

my $sth = $dbh.prepare ("select count (*) from url");
$sth.execute;
$sth.bind_columns (\my $count);
my @count = $sth.fetchrow_array;
@count[0].say;
