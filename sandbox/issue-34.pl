#!/pro/bin/perl

use 5.018002;
use warnings;
use Text::CSV_XS qw( csv );

# https://github.com/Tux/CSV/issues/34
# https://unix.stackexchange.com/a/755782/227738

# Used the firt 7 lines of the example dat in the stackexchange post
# Removed the last element from line 4, which should warn under strict

-d "sandbox" and chdir "sandbox";
csv (sep => ";", in =>
csv (in        => "issue-34.csv",
     sep       => ";",
     auto_diag => 1,
     strict    => 1,
     on_in     => sub { $_ = sprintf "%02d", $_ for @{$_[1]} },
     ));
