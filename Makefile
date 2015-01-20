test:
	@[ -d Text ] || ( mkdir Text ; ln test-t.pl Text/CSV.pm )
	perl6 -I. t/10_base.t
	perl6 -I. t/12_acc.t
	perl6 -I. t/15_flags.t

time:
	perl time.pl
