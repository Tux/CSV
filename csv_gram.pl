use v6;

class Text::CSV {
    has Str  $.quote_char          is rw = '"';
    has Str  $.escape_char         is rw = '"';
    has Str  $.sep_char            is rw    = ',';
    has Str  $.eol                 is rw; #          = ($*IN.newline),
    has Bool $.always_quote        is rw;
    has Bool $.quote_space         is rw = True;
    has Bool $.quote_null          is rw  = True;
    has Bool $.quote_binary        is rw = True;
    has Bool $.binary              is rw;
    has Bool $.keep_meta_info      is rw;
    has Bool $.allow_loose_quotes  is rw;
    has Bool $.allow_loose_escapes is rw;
    has Bool $.allow_whitespace    is rw;
    has Bool $.blank_is_undef      is rw;
    has Bool $.empty_is_undef      is rw;
    has Bool $.verbatim            is rw;
    has Bool $.auto_diag           is rw;

    class CSV_Actions {
        method fields($/){
            make $<field>>><text>>>.Str;
            }
        method line($/){
            make $<fields>.ast;
            }
        }
    method compose {
        my $q = $!quote_space;
        my $s = $!sep_char;
        my $e = $!escape_char;
        my $l = $!eol;
        grammar {
            token lines       { <line>* }
            token line        { <fields> <lineend> }
            token fields      { <field>* % <separator> }
            token field       { <quote> : $<text>=<quotedvalue> <quote> | $<text>=<value> }
            token value       { [ <-separator> & <-quote> & <-lineend> ] * }
            token quotedvalue { <-quote> * }
            token separator   { "$s" }
            token quote       { "$q" }
            token escape      { "$e" }
            token lineend     { $l }
            }
        }
    has $!gram = self.compose();#.new;
    has $!ast;

    method parse(Str:D $line){
        #say nqp::objectid($!gram);
        $!ast = $!gram.parse($line, :rule<fields>, :actions(CSV_Actions)).ast;
        }

    method getline(){
        $!ast;
        }
    }

sub MAIN(
            Str  :$quote_char   = '"',
            Str  :$escape_char  = '"',
            Str  :$sep_char     = ',',
            Str  :$eol, #          = ($*IN.newline),
            Bool :$always_quote,
            Bool :$quote_space  = True,
            Bool :$quote_null   = True,
            Bool :$quote_binary = True,
            Bool :$binary,
            Bool :$keep_meta_info,
            Bool :$allow_loose_quotes,
            Bool :$allow_loose_escapes,
            Bool :$allow_whitespace,
            Bool :$blank_is_undef,
            Bool :$empty_is_undef,
            Bool :$verbatim,
            Bool :$auto_diag,
            ) {

    my $csv_parser = Text::CSV.new
##            :$quote_char
##            :$escape_char
##            :$sep_char
##            :$eol
##            :$always_quote
##            :$quote_space
##            :$quote_null
##            :$quote_binary
##            :$binary
##            :$keep_meta_info
##            :$allow_loose_quotes
##            :$allow_loose_escapes
##            :$allow_whitespace
##            :$blank_is_undef
##            :$empty_is_undef
##            :$verbatim
##            :$auto_diag
            ;

    $csv_parser.parse(q/ab,cde,"q",/);
    say $csv_parser.getline().perl;

    my $csv_parser2 = Text::CSV.new :sep_char<e> ;

    $csv_parser2.parse(q/ab,cde"q"e/);
    say $csv_parser2.getline().perl;

    $csv_parser.parse(q/ab,cde,"q",/);
    say $csv_parser.getline().perl;

    my $csv_parser3 = Text::CSV.new :sep_char<,> ;

    $csv_parser2.parse(q/ab,cde"q"e/);
    say $csv_parser2.getline().perl;

    #$csv_parser.parse(q/ab,cde"q"eaa"aaarghh/);
    #$csv_parser.parse(q/ab,cde"q"e"aaarghh/);
    ## $csv_parser.sep_char=',';
    my $sum = 0;
    for lines() :eager {
        $csv_parser.parse($_);
        my $r = $csv_parser.getline();
#       say $r.perl;
#       say +$r;
        $sum += +$r;
#last;
        }
    say $sum;
    }
