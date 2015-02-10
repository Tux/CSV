test:
	@[ -d Text ] || ( mkdir Text ; ln test-t.pl Text/CSV.pm )
	perl6 -I. t/10_base.t
	perl6 -I. t/12_acc.t    2>&1 | tail -5
	perl6 -I. t/15_flags.t  2>&1 | tail -5
	perl6 -I. t/40_misc.t   2>&1 | tail -5
	perl6 -I. t/55_combi.t  2>&1 | tail -5

time:
	perl time.pl
