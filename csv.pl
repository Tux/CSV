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

    has @!fields;

    method parse(Str:D $line){
        enum State <Start Data QuotedData Finish Escape>;

        my State $state = State::Start;
        my State $saved_state;
        my Str:D $field;
        my Int:D $index;
        my Str:D $input;

        my sub append(Str:D $char){
            $field ~= $char;
            }

        my sub non_nil{
            $field ~= '';
            }

        my sub store(){
            @!fields.push($field);
            $field = Nil;
            }

        my sub push_state(State $ns){
            $saved_state = $state;
            $state = $ns;
            }

        my sub pop_state(){
            $state = $saved_state;
            }

        my sub parse_error(Str:D $reason, *@args){
            my $msg = $reason.sprintf(@args);
            die "$msg\n$line\n" ~ ' ' x $index ~ "^\n";
            }
            
        @!fields = ();

        my Int $last=$line.chars;
        $index=0;
        while $index < $last { # 30% faster than 0..^$line.chars ...
        #for 0..^$line.chars -> Int:D $lindex {
        #    $index = $lindex;
            $input = $line.substr($index,1);
            given $state {
                when State::Start {
                    given $input {
                        when $!sep_char   { store; }
                        when $!quote_char { non_nil; $state = State::QuotedData; }
                        #when $!escape_char { $state = State::Data; push_state(State::Escape); }
                        default           { append($_); $state = State::Data; }
                        }
                    }
                when State::Data {
                    given $input {
                        when $!sep_char   { store;      $state = State::Start; }
                        #when $!escape_char {                 push_state(State::Escape); }
                        when $!quote_char { parse_error("Halfway quoting is forbidden"); }
                        default           { append($_); }
                        }
                    }
                when State::QuotedData {
                    given $input {
                        when $!quote_char {                  $state = State::Finish; }
                        #when $!escape_char {                 push_state(State::Escape); }
                        default           { append($_); }
                        }
                    }
                when State::Escape {
                    given $input {
                        when $!sep_char|$!quote_char|$!escape_char    { append($_); pop_state; }
                        default           { parse_error("Illegally escaped character"); }
                        }
                    }
                when State::Finish {
                    given $input {
                        when $!sep_char   { store;      $state = State::Start; }
                        default           { parse_error("Seperator ('%s') expected", $!sep_char); }
                        }
                    }
                default { say "What state?", $_ }
                }
            ++$index;
            }
        given $state {
            when State::Start|State::Finish|State::Data  { store }
            default            { parse_error("Inproper state to end the line (%s)", $state); }
            }
        }

    method getline(){
        return @!fields;
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
            :$quote_char
            :$escape_char
            :$sep_char
            :$eol
            :$always_quote
            :$quote_space
            :$quote_null
            :$quote_binary
            :$binary
            :$keep_meta_info
            :$allow_loose_quotes
            :$allow_loose_escapes
            :$allow_whitespace
            :$blank_is_undef
            :$empty_is_undef
            :$verbatim
            :$auto_diag
            ;
    #my Str $sep ='"';
    #say $csv_parser.perl;
    $csv_parser.parse(q/ab,cde,"q",/);
        say $csv_parser.getline().perl;
    $csv_parser.sep_char='e';
    $csv_parser.parse(q/ab,cde"q"e/);
        say $csv_parser.getline().perl;
    #$csv_parser.parse(q/ab,cde"q"eaa"aaarghh/);
    #$csv_parser.parse(q/ab,cde"q"e"aaarghh/);
    $csv_parser.sep_char=',';
    my $sum = 0;
    for lines() :eager {
        $csv_parser.parse($_);
        my @r = $csv_parser.getline();
        #say @r.perl;
        $sum += +@r;
        }
    say $sum;
    }
