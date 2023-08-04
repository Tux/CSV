# ex:se inputtab=tab autotab:

.PHONY:         test test-verbose profile time tt doc
.PRECIOUS:      test-t.pl

test:
	@perl bugs.pl -s
	podchecker Text-CSV.pod 2>&1 | grep -v WARNING:
	pod-spell-check --aspell --ispell Text-CSV.pod
	prove -j4 -e 'raku -I. -Ilib' t

tt:     test time html

test-verbose:	lib/Text/CSV.rakumod
	raku -I. -Ilib t/10_base.t
	raku -I. -Ilib t/12_acc.t
	raku -I. -Ilib t/15_flags.t
	raku -I. -Ilib t/16_methods.t
	raku -I. -Ilib t/20_file.t
	raku -I. -Ilib t/21_combine.t
	raku -I. -Ilib t/22_print.t
	raku -I. -Ilib t/30_field.t
	raku -I. -Ilib t/31_row.t
	raku -I. -Ilib t/32_getline.t
	raku -I. -Ilib t/40_misc.t
	raku -I. -Ilib t/41_null.t
	raku -I. -Ilib t/45_eol.t
	raku -I. -Ilib t/46_eol_si.t
	raku -I. -Ilib t/47_comment.t
	raku -I. -Ilib t/50_utf8.t
	raku -I. -Ilib t/55_combi.t
	raku -I. -Ilib t/60_samples.t
	raku -I. -Ilib t/65_allow.t
	raku -I. -Ilib t/66_formula.t
	raku -I. -Ilib t/75_hashref.t
	raku -I. -Ilib t/77_getall.t
	raku -I. -Ilib t/78_fragment.t
	raku -I. -Ilib t/79_callbacks.t
	raku -I. -Ilib t/80_diag.t
	raku -I. -Ilib t/81_subclass.t
	raku -I. -Ilib t/82_subclass.t
	raku -I. -Ilib t/85_util.t
	raku -I. -Ilib t/90_csv.t
	raku -I. -Ilib t/91_csv_cb.t
	raku -I. -Ilib t/92_csv_encoding.t
	raku -I. -Ilib t/99_meta.t

profile:
	raku -Ilib --profile test-t.pl < /tmp/hello.csv
	mv profile-[0-9]* profile.html

check:
	head -5 /tmp/hello.csv | raku -Ilib test-t.pl

time:
	perl time.pl

dist:
	perl make-dist

html:
	test -d ../Talks/CSVh && pod2html Text-CSV.pod >../Talks/CSVh/pod6.html 2>/dev/null

doc:    doc/Text-CSV.md doc/Text-CSV.pdf doc/Text-CSV.man 
doc/Text-CSV.pod:	lib/Text/CSV.pod6
	perl -ne'/^=(begin|end) pod/ or print' lib/Text/CSV.pod6 > doc/Text-CSV.pod
doc/Text-CSV.md:	doc/Text-CSV.pod
	pod2markdown  < doc/Text-CSV.pod > doc/Text-CSV.md
doc/Text-CSV.html:	doc/Text-CSV.pod
	pod2html      < doc/Text-CSV.pod 2>&1 |\
		  grep -v "^Cannot find" > doc/Text-CSV.html
doc/Text-CSV.pdf:	doc/Text-CSV.html
	html2pdf.pl -f -o doc/Text-CSV.pdf doc/Text-CSV.html
doc/Text-CSV.3:		doc/Text-CSV.pod
	pod2man       < doc/Text-CSV.pod  > doc/Text-CSV.3
doc/Text-CSV.man:	doc/Text-CSV.3
	nroff -mandoc < doc/Text-CSV.3    > doc/Text-CSV.man

opencsv-2.3.jar:
	test -f opencsv-2.3.jar || wget -q http://www.java2s.com/Code/JarDownload/opencsv/opencsv-2.3.jar.zip
	test -f opencsv-2.3.jar || unzip opencsv-2.3.jar.zip
	-@rm opencsv-2.3.jar.zip

# If you have more than one java version, just use this as a guide
csv-java.jar:	csvJava.java opencsv-2.3.jar
	javac -cp opencsv-2.3.jar csvJava.java
	zip -9 csv-java.jar csvJava.class

csv-c:	csv-c.c
	cc -O3 -s -o csv-c csv-c.c -lcsv3

csv-cc: csv-cc.cc
	g++ -Werror -Wall -pedantic -std=c++11 -s -O2 -fpic -march=native csv-cc.cc -o csv-cc

csv-go: csv-go.go
	go build csv-go.go
