#!/bin/sh

export PERL6_VERBOSE=0

perl -pe's/^ ?(?=\s*.opt_v)/#/' test-t.pl > test-x.pl

# make FS cache hello.csv to make a more honest test case
cat      /tmp/hello.csv | perl  csv-easy-xs.pl >/dev/null 2>&1
head -30 /tmp/hello.csv | perl  csv-easy-pp.pl >/dev/null 2>&1
head -30 /tmp/hello.csv | perl  csv-test-xs.pl >/dev/null 2>&1
head -30 /tmp/hello.csv | perl  csv-test-pp.pl >/dev/null 2>&1
head -30 /tmp/hello.csv | perl  csv-pegex.pl   >/dev/null 2>&1
head -30 /tmp/hello.csv | perl6 csv.pl         >/dev/null 2>&1
head -30 /tmp/hello.csv | perl6 csv_gram.pl    >/dev/null 2>&1
head -30 /tmp/hello.csv | perl6 test.pl        >/dev/null 2>&1
head -30 /tmp/hello.csv | perl6 test-x.pl      >/dev/null 2>&1

for t in csv-easy-xs csv-easy-pp csv-test-xs csv-test-pp csv-pegex ; do
    echo
    echo "******* $t"
    time perl  $t.pl < /tmp/hello.csv
    done

for t in csv csv_gram test test-x ; do
    echo
    echo "******* $t"
    time perl6 $t.pl < /tmp/hello.csv
    done

rm -f test-x.pl
