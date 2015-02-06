#!/pro/bin/perl

use 5.20.0;
use warnings;

use DBI;

my $dbh = DBI->connect ("dbi:Pg:");

my $sth = $dbh->prepare ("select count (*) from url");
$sth->execute;
$sth->bind_columns (\my $count);
$sth->fetch;
say $count;
