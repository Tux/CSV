#!/bin/sh

# make FS cache hello.csv to make a more honest test case
cat      /tmp/hello.csv | perl  csv-easy-xs.pl >/dev/null 2>&1
head -30 /tmp/hello.csv | perl  csv-easy-pp.pl >/dev/null 2>&1
head -30 /tmp/hello.csv | perl  csv-test-xs.pl >/dev/null 2>&1
head -30 /tmp/hello.csv | perl  csv-test-pp.pl >/dev/null 2>&1
head -30 /tmp/hello.csv | perl  csv-pegex.pl   >/dev/null 2>&1
head -30 /tmp/hello.csv | perl6 csv.pl         >/dev/null 2>&1
head -30 /tmp/hello.csv | perl6 csv_gram.pl    >/dev/null 2>&1
head -30 /tmp/hello.csv | perl6 test.pl        >/dev/null 2>&1
head -30 /tmp/hello.csv | perl6 test-t.pl      >/dev/null 2>&1

time perl  csv-easy-xs.pl < /tmp/hello.csv
time perl  csv-easy-pp.pl < /tmp/hello.csv
time perl  csv-test-xs.pl < /tmp/hello.csv
time perl  csv-test-pp.pl < /tmp/hello.csv
time perl  csv-pegex.pl   < /tmp/hello.csv
time perl6 csv.pl         < /tmp/hello.csv
time perl6 csv_gram.pl    < /tmp/hello.csv
time perl6 test.pl        < /tmp/hello.csv
time perl6 test-t.pl      < /tmp/hello.csv

