use v6;

my $opt_v = %*ENV<PERL6_VERBOSE> // 1;
my $test  = qq{,1,ab,"cd","e"0f","g,h","nl\nz"0i""""3",\r\n};
my @rslt  = ("", "1", "ab", "cd", "e\c0f", "g,h", qq{nl\nz\c0i""3}, "");

sub progress (*@y) {
    my Str $x;
    my @x = @y.map(*.Str);
    my $line = callframe(1).annotations<line>;
    for (@x) {
        s{^(\d+)$}   = sprintf "%3d -", $_;
        s:g{"True,"} = "True, ";
        s:g{"new("}  = "new (";
        $x ~= $_ ~ " ";
        }
    $x.say;
    } # progress

class CSV::Field {

    has Bool $.is_quoted        is rw = False;
#   has Bool $.is_binary        is rw = False;
#   has Bool $.is_utf8          is rw = False;
    has Bool $.undefined        is rw = True;
    # text last for formatted output of .perl (for now)
    has Str  $.text                is rw;

    enum Type < NA INT NUM STR BOOL >;

    method add (Str $chunk) {
        $!text     ~= $chunk;
        $!undefined = False;
        } # add

    method set_quoted () {
        $!is_quoted = True;
        $!undefined = False;
        self.add("");
        }

    } # CSV::Field

class Text::CSV {

    has Str  $.eol                 is rw;                # = ($*IN.newline),
    has Str  $.sep                 is rw = ',';
    has Str  $.quo                 is rw = '"';
    has Str  $.esc                 is rw = '"';

    has Bool $.binary              is rw = True;        # default changed
    has Bool $.decode_utf8         is rw = True;
    has Bool $.auto_diag           is rw = False;
    has Bool $.diag_verbose        is rw = False;

    has Bool $.blank_is_undef      is rw = False;
    has Bool $.empty_is_undef      is rw = False;
    has Bool $.allow_whitespace    is rw = False;
    has Bool $.allow_loose_quotes  is rw = False;
    has Bool $.allow_loose_escapes is rw = False;
    has Bool $.always_quote        is rw = False;
    has Bool $.quote_space         is rw = True;
    has Bool $.quote_null          is rw = True;
    has Bool $.quote_binary        is rw = True;
    has Bool $.keep_meta_info      is rw = False;
    has Bool $.verbatim            is rw;                # Should die!

    has @!fields;
    has @!types;
    has @!callbacks;
    method compose {
        # A scoping bug in perl6 inhibits the use of $!eol inside the split
        my     $eol = $!eol // rx{ \r\n | \r | \n };
        my Str $sep = $!sep;
        my Str $quo = $!quo;
        my Str $esc = $!esc;
        rx{ $eol | $sep | $quo | $esc }
        };
    has $!regex = self.compose();

    method parse (Str $buffer) {

        my     $field;
        my Int $pos   = 0;

        my sub parse_error (Str $reason, *@args) {
            my $msg = $reason.sprintf(@args);
            die "$msg\n$buffer\n" ~ ' ' x $pos ~ "^\n";
            }

        $opt_v > 8 and say $buffer.perl;
        ## A scoping bug in perl6 inhibits the use of $!eol inside the split
        #for $buffer.split(rx{ $!eol | $!sep | $!quo | $!esc }, :all).map(~*) -> Str $chunk {
        my     $eol = $!eol // rx{ \r\n | \r | \n };
        my Str $sep := $!sep;
        my Str $quo := $!quo;
        my Str $esc := $!esc;
        my     $regex := $!regex;
        my $f = CSV::Field.new;

        @!fields = ();

        sub keep {
            # Set is_binary
            # Set is_utf8
            @!fields.push($f);
            $f = CSV::Field.new;
            } # add

        my @ch = $buffer.split($regex,:v).flat.map: {
            if $_ ~~ Str {
                $_ if .chars;
                }
            else {
                .Str if .Bool;
                };
            }

        my int $skip;
        my int $i = -1;

        for @ch -> Str $chunk {
            $i = $i + 1;

            if $skip {
                $skip = 0;
                next;
                }

            $opt_v > 8 and progress($i, "###", "'$chunk'", $f.perl);

            if $chunk ~~ rx{^ $eol $} {
                $opt_v > 5 and progress($i, "EOL");
                if $f.is_quoted {        # 1,"2\n3"
                    $f.add($chunk);
                    next;
                    }
                keep;
                return @!fields;
                }

            if $chunk eq $sep {
                $opt_v > 5 and progress($i, "SEP");
                if $f.is_quoted {        # "1,2"
                    $f.add($chunk);
                    next;
                    }
                keep;                        # 1,2
                next;
                }

            if $chunk eq $quo {
                $opt_v > 5 and progress($i, "QUO", $f.perl);

                if $f.undefined {
                    $f.set_quoted;
                    next;
                    }

                if $f.is_quoted {

                    if $i + 1 >= @ch.elems {
                        keep;
                        return @!fields;
                        }

                    my Str $next = @ch[$i + 1];

                    if $next ~~ /^ $eol $/ {
                        keep;
                        return @!fields;
                        }

                    $opt_v > 8 and progress($i, "QUO", "next = $next");

                    if $next eq $sep { # "1",
                        $opt_v > 7 and progress($i, "SEP");
                        $skip = 1;
                        keep;
                        next;
                        }

                    if $esc eq $quo {
                        $opt_v > 7 and progress($i, "ESC", "($next)");
                        if $next ~~ /^ "0"/ {
                            @ch[$i + 1] ~~ s{^ "0"} = "";
                            $opt_v > 8 and progress($i, "Add NIL");
                            $f.add("\c0");
                            next;
                            }
                        if $next eq $quo {
                            $skip = 1;
                            }
                        }

                    $f.add($chunk);
                    next;
                    }
                keep;
                next;
                }

            if $chunk eq $esc {
                $opt_v > 5 and progress($i, "ESC", $f.perl);
                }

            $chunk ne "" and $f.add($chunk);
            $pos += $chunk.chars;
            }

        keep;
        return @!fields;
        } # parse

    method getline () {
        return @!fields;
        } # getline
    }

sub MAIN () {

    my $csv_parser = Text::CSV.new;

    $opt_v > 1 and say $csv_parser.perl;
    $opt_v and progress(.perl) for $csv_parser.parse($test);
    $opt_v and Qw { Expected: Str 1 ab cd e\0f g,h nl\nz\0i""3 Str }.say;

    my Int $sum = 0;
    for lines() {
        my @r = $csv_parser.parse($_);
        $sum += +@r;
        }
    $sum.say;
    }
