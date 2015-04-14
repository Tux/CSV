Module
------
Text::CSV - Handle CSV data in perl6

Description
-----------
Text::CSV provides facilities for the composition and decomposition
of comma-separated values.  An instance of the Text::CSV class can
combine fields into a CSV string and parse a CSV string into fields.

This module provides both an OO API and a functional API to parse
and produce CSV data.
```
 use Text::CSV;

 my $csv = Text::CSV.new;
 my $io  = open "file.csv", :r, chomp => False;
 my @dta = $csv.getline_all($io);

 my @dta = csv(in => "file.csv");
```
Copying
-------
Copyright (c) 2015-2015 H.Merijn Brand.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Recent changes can be (re)viewed in the public GIT repository at
https://github.com/Tux/CSV
Feel free to clone your own copy:
```
 $ git clone https://github.com/Tux/CSV Text-CSV
```

Prerequisites
-------------
* perl6 2015.03
* File::Temp   - as long as in-memory IO is not native
* Slang::Tuxic - to support my style

Build/Installation
------------------
```
 $ panda install Text::CSV
```

Author
------
H.Merijn Brand <h.m.brand@xs4all.nl>
