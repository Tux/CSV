#!perl6

use v6;
use Slang::Tuxic;

use Test;
use Text::CSV;

my @attrib  = ("quote_char", "escape_char", "sep_char");
my @special = ('"', "'", ",", ";", "\t", "\\", "~");
my @input   = ( "", 1, "1", 1.4, "1.4", " - 1,4", "1+2=3", "' ain't it great '",
    Str, '"foo"! said the `bär', q{the ~ in "0 \0 this l'ne is \r ; or "'"} );
my $ninput  = @input.elems;
my $string  = join "=", "", @input.map ({$_//""}), "";
my %fail;

ok (1, "--     qc     ec     sc     ac     aw");

sub combi (*%attr)
{
    my $combi = join " ", "--", map { sprintf "%6s", %attr{$_}.perl; },
        @attrib, "always_quote", "allow_whitespace";
    ok (1, $combi);

    my $csv = Text::CSV.new (
        binary => 1,
        sep    => "\x03",
        quo    => "\x04",
        esc    => "\x05",
        );

    # Set the attributes and check failure
    my %state;
    for sort keys %attr -> $attr {
        my $v = %attr{$attr};
        {   $csv."$attr"(%attr{$attr});

            CATCH { default {
                %state{.error} ||= .message;
                }}
            };
        }
    if (%attr<sep_char> eq %attr<quote_char> ||
        %attr<sep_char> eq %attr<escape_char>) {
        ok (%state{1001}.defined, "Illegal combo sep == quo || sep == esc");
        #ok (%state{1001} ~~ m{"sep_char is equal to"}, "Illegal combo 1001");
        }
    else {
        ok (!%state{1001}.defined, "No char conflict");
        }
    if (!%state{1001}.defined and
            %attr<sep_char>    ~~ m/[\r\n]/ ||
            %attr<quote_char>  ~~ m/[\r\n]/ ||
            %attr<escape_char> ~~ m/[\r\n]/
            ) {
        ok (%state{1003}.defined, "Special contains eol");
        ok (%state{1003} ~~ rx{"in main attr not"}, "Illegal combo (1003)");
        }
    if (%attr<allow_whitespace> and
            %attr<quote_char>  ~~ m/^[ \t]/ ||
            %attr<escape_char> ~~ m/^[ \t]/
            ) {
        #diag (join " -> ** " => $combi, join ", " => sort %state);
        ok (%state{1002}.defined, "Illegal combo under allow_whitespace");
        ok (%state{1002} ~~ rx{"allow_whitespace with"}, "Illegal combo (1002)");
        }
    %state and return;

    # Check success
    is ($csv."$_"(), %attr{$_},  "check $_") for sort keys %attr;

    my $ret = $csv.combine (@input);

    ok ($ret, "combine");
    ok (my $str = $csv.string, "string");
    #"# @$?LINE ‹$str›".say;

    $csv.auto-diag (True);
    ok (my $ok = $csv.parse ($str), "parse");

    unless ($ok) {
        $csv.error_diag.perl.say;
        %fail<parse>{$combi} = $csv.error_input;
        return;
        }

    my @ret = $csv.fields;
    ok (@ret.elems, "fields");
    unless (@ret.elems) {
        %fail<fields>{$combi} = $csv.error_input;
        return;
        }

    is (@ret.elems, $ninput,   "$ninput fields");
    unless (@ret.elems == $ninput) {
        %fail{'$#fields'}{$combi} = $str;
        skip "# fields failed",  1;
        }

    $ret = join "=", "", @ret.map ({$_.text.Str}), "";
    is ($ret, $string,          "content");
    } # combi

for ( False, True    ) -> $aw {
for ( False, True    ) -> $aq {
for ( @special       ) -> $qc {
for ( @special, "+"  ) -> $ec {
for ( @special, "\0" ) -> $sc {
    combi (
        sep_char         => $sc,
        quote_char       => $qc,
        escape_char      => $ec,
        always_quote     => $aq,
        allow_whitespace => $aw,
        );
     }
    }
   }
  }
 }

done;

=finish

foreach my $fail (sort keys %fail) {
    print STDERR "Failed combi for $fail ():\n",
                 "--     qc     ec     sc     ac\n";
    foreach my $combi (sort keys %{$fail{$fail}}) {
        printf STDERR "%-20s - %s\n", map { _readable $_ } $combi, $fail{$fail}{$combi};
        }
    }
1;
