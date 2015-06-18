# ex:se inputtab=tab autotab:

.PHONY:         test test-verbose profile time
.PRECIOUS:      test-t.pl

test:
	@perl bugs.pl -s
	podchecker Text-CSV.pod 2>&1 | grep -v WARNING:
	pod-spell-check --aspell --ispell Text-CSV.pod
	prove -j4 -e 'perl6 -I. -Ilib' t

test-verbose:	Text/CSV.pm
	perl6 -Ilib t/10_base.t
	perl6 -Ilib t/12_acc.t
	perl6 -Ilib t/15_flags.t
	perl6 -Ilib t/16_methods.t
	perl6 -Ilib t/20_file.t
	perl6 -Ilib t/21_combine.t
	perl6 -Ilib t/22_print.t
	perl6 -Ilib t/30_field.t
	perl6 -Ilib t/31_row.t
	perl6 -Ilib t/32_getline.t
	perl6 -Ilib t/40_misc.t
	perl6 -Ilib t/41_null.t
	perl6 -Ilib t/50_utf8.t
	perl6 -Ilib t/55_combi.t
	perl6 -Ilib t/60_samples.t
	perl6 -Ilib t/65_allow.t
	perl6 -Ilib t/75_hashref.t
	perl6 -Ilib t/77_getall.t
	perl6 -Ilib t/78_fragment.t
	perl6 -Ilib t/79_callbacks.t
	perl6 -Ilib t/80_diag.t
	perl6 -Ilib t/81_subclass.t
	perl6 -Ilib t/82_subclass.t
	perl6 -Ilib t/90_csv.t
	perl6 -Ilib t/91_csv_cb.t

profile:
	perl6 -Ilib --profile test-t.pl < /tmp/hello.csv
	mv profile-[0-9]* profile.html

check:
	head -5 /tmp/hello.csv | perl6 -Ilib test-t.pl

time:
	perl time.pl
	rm -rf /tmp/*-p5helper.so
