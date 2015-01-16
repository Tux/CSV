#!/bin/sh

export PERL6_VERBOSE=0

perl -pe's/^ ?(?=\s*.opt_v)/#/' test-t.pl > test-x.pl

(
for t in csv-easy-xs csv-easy-pp csv-test-xs csv-test-pp csv-pegex ; do
    echo
    echo "******* $t"
    head -30 /tmp/hello.csv | perl  $t.pl >/dev/null 2>&1
    time perl  $t.pl < /tmp/hello.csv
    done

for t in csv csv_gram test test-x ; do
    echo
    echo "******* $t"
    head -30 /tmp/hello.csv | perl6 $t.pl >/dev/null 2>&1
    time perl6 $t.pl < /tmp/hello.csv
    done
) 2>&1 | perl -ne'm/^(user|sys|Array|\$)/ or print'

rm -f test-x.pl
