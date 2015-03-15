# ex:se inputtab=tab autotab:

.PHONY:         test test-verbose profile time
.PRECIOUS:      test-t.pl

test:
	@perl bugs.pl -s
	prove -e 'perl6 -I. -Ilib' t

test-verbose:	Text/CSV.pm
	perl6 -I. -Ilib t/10_base.t
	perl6 -I. -Ilib t/12_acc.t
	perl6 -I. -Ilib t/15_flags.t
	perl6 -I. -Ilib t/16_methods.t
	perl6 -I. -Ilib t/20_file.t
	perl6 -I. -Ilib t/21_combine.t
	perl6 -I. -Ilib t/22_print.t
	perl6 -I. -Ilib t/40_misc.t
	perl6 -I. -Ilib t/41_null.t
	perl6 -I. -Ilib t/50_utf8.t
	perl6 -I. -Ilib t/55_combi.t
	perl6 -I. -Ilib t/60_samples.t
	perl6 -I. -Ilib t/65_allow.t
	perl6 -I. -Ilib t/77_getall.t
	perl6 -I. -Ilib t/78_fragment.t
	perl6 -I. -Ilib t/79_callbacks.t
	perl6 -I. -Ilib t/81_subclass.t
	perl6 -I. -Ilib t/82_subclass.t

profile:
	perl6 -I. -Ilib --profile test-t.pl < /tmp/hello.csv
	mv profile-[0-9]* profile.html

time:
	perl time.pl
