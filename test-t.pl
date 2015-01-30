use v6;
use Slang::Tuxic;

my $opt_v = %*ENV<PERL6_VERBOSE> // 1;
my $test  = qq{,1,ab,"cd","e"0f","g,h","nl\nz"0i""""3",\r\n};
my @rslt  = ("", "1", "ab", "cd", "e\c0f", "g,h", qq{nl\nz\c0i""3}, "");

sub progress (*@y) {
    my Str $x;
    @y[0] = @y[0].Str;  # Still a bug
    my $line = callframe (1).annotations<line>;
    for (@y) {
        #$opt_v > 9 and .say;
        s{^(\d+)$}   = sprintf "@%3d %3d -", $line, $_;
        s:g{"True,"} = "True, ";
        s:g{"new("}  = "new (";
        $x ~= .Str ~ " ";
        }
    $x.say;
    } # progress

class CSV::Field {

    has Bool $.is_quoted  is rw = False;
    has Bool $.undefined  is rw = True;
    has Str  $.text       is rw;

    has Bool $!is_binary  = False;
    has Bool $!is_utf8    = False;
    has Bool $!is_missing = False;
    has Bool $!analysed   = False;

    enum Type < NA INT NUM STR BOOL >;

    method add (Str $chunk) {
        $!text     ~= $chunk;
        $!undefined = False;
        } # add

    method set_quoted () {
        $!is_quoted = True;
        $!undefined = False;
        .add("");
        }

    method !analyse () {
        $!analysed and return;

        $!analysed = True;

        $!text eq Nil || !$!text.defined and
            $!undefined = True;

        $!undefined || $!text eq "" and
            return; # Default is False for both

        $!text ~~ m{^ <[ \x09, \x20 .. \x7E ]>+ $} or
            $!is_binary = True;

        $!text ~~ m{^ <[ \x00       .. \x7F ]>+ $} or
            $!is_utf8   = True;
        }

    method is_binary () {
        $!analysed or self!analyse;
        return $!is_binary;
        }

    method is_utf8 () {
        $!analysed or self!analyse;
        return $!is_utf8;
        }

    method is_missing () {
        $!analysed or self!analyse;
        return $!is_missing;
        }

    } # CSV::Field

class Text::CSV {

    has Str  $!eol;         # = ($*IN.newline),
    has Str  $!sep                   = ',';
    has Str  $!quo                   = '"';
    has Str  $!esc                   = '"';

    has Bool $!binary                = True;  # default changed
    has Bool $!decode_utf8           = True;
    has Int  $!auto_diag             = 0;
    has Int  $!diag_verbose          = 0;

    has Bool $!blank_is_undef        = False;
    has Bool $!empty_is_undef        = False;
    has Bool $!allow_whitespace      = False;
    has Bool $!allow_loose_quotes    = False;
    has Bool $!allow_loose_escapes   = False;
    has Bool $!allow_unquoted_escape = False;

    has Bool $!always_quote          = False;
    has Bool $!quote_space           = True;
    has Bool $!quote_null            = True;
    has Bool $!quote_binary          = True;
    has Bool $!keep_meta_info        = False;

    has Int  $!record_number         = 0;

    has CSV::Field @!fields;
    has Int        @!types;
    has            @!callbacks;

    has Int  $!errno                 = 0;
    has Int  $!error_pos             = 0;
    has Str  $!error_input           = Nil;
    has Str  $!error_message         = "";
    has Str  %!errors{Int} =
        # Generic errors
        1000 => "INI - constructor failed",
        1001 => "INI - sep_char is equal to quote_char or escape_char",
        1002 => "INI - allow_whitespace with escape_char or quote_char SP or TAB",
        1003 => "INI - \r or \n in main attr not allowed",
        1004 => "INI - callbacks should be undef or a hashref",

        # Parse errors
        2010 => "ECR - QUO char inside quotes followed by CR not part of EOL",
        2011 => "ECR - Characters after end of quoted field",
        2012 => "EOF - End of data in parsing input stream",
        2013 => "ESP - Specification error for fragments RFC7111",

        #  EIQ - Error Inside Quotes
        2021 => "EIQ - NL char inside quotes, binary off",
        2022 => "EIQ - CR char inside quotes, binary off",
        2023 => "EIQ - QUO character not allowed",
        2024 => "EIQ - EOF cannot be escaped, not even inside quotes",
        2025 => "EIQ - Loose unescaped escape",
        2026 => "EIQ - Binary character inside quoted field, binary off",
        2027 => "EIQ - Quoted field not terminated",

        # EIF - Error Inside Field
        2031 => "EIF - CR char is first char of field, not part of EOL",
        2032 => "EIF - CR char inside unquoted, not part of EOL",
        2034 => "EIF - Loose unescaped quote",
        2035 => "EIF - Escaped EOF in unquoted field",
        2036 => "EIF - ESC error",
        2037 => "EIF - Binary character in unquoted field, binary off",

        # Combine errors
        2110 => "ECB - Binary character in Combine, binary off",

        # IO errors
        2200 => "EIO - print to IO failed. See errno",

        # Hash-Ref errors
        3001 => "EHR - Unsupported syntax for column_names ()",
        3002 => "EHR - getline_hr () called before column_names ()",
        3003 => "EHR - bind_columns () and column_names () fields count mismatch",
        3004 => "EHR - bind_columns () only accepts refs to scalars",
        3006 => "EHR - bind_columns () did not pass enough refs for parsed fields",
        3007 => "EHR - bind_columns needs refs to writable scalars",
        3008 => "EHR - unexpected error in bound fields",
        3009 => "EHR - print_hr () called before column_names ()",
        3010 => "EHR - print_hr () called with invalid arguments",
        ;

    # We need this to support aliasses and to catch unsupported attributes
    submethod BUILD (*%init) {
        for keys %init -> $attr {
            my $m = lc $attr;
            if (self.can ($m)) {
                self."$m"(%init{$attr}); # space before ( not (yet) allowed under Tuxic
                next;
                }
            die "attribute $attr is not supported\n";
            }
        }

    # String attributes
    method sep          (*@s) { @s.elems == 1 and $!sep = @s[0]; return $!sep; }
    method sep_char     (*@s) { @s.elems == 1 and $!sep = @s[0]; return $!sep; }
    method quo          (*@s) { @s.elems == 1 and $!quo = @s[0]; return $!quo; }
    method quote        (*@s) { @s.elems == 1 and $!quo = @s[0]; return $!quo; }
    method quote_char   (*@s) { @s.elems == 1 and $!quo = @s[0]; return $!quo; }
    method esc          (*@s) { @s.elems == 1 and $!esc = @s[0]; return $!esc; }
    method escape       (*@s) { @s.elems == 1 and $!esc = @s[0]; return $!esc; }
    method escape_char  (*@s) { @s.elems == 1 and $!esc = @s[0]; return $!esc; }
    method eol          (*@s) { @s.elems == 1 and $!eol = @s[0]; return $!eol; }

    # Boolean attributes
    method binary                (*@s) { @s.elems == 1 and $!binary                = @s[0] ?? True !! False; return $!binary;                }
    method always_quote          (*@s) { @s.elems == 1 and $!always_quote          = @s[0] ?? True !! False; return $!always_quote;          }
    method quote_always          (*@s) { @s.elems == 1 and $!always_quote          = @s[0] ?? True !! False; return $!always_quote;          }
    method quote_space           (*@s) { @s.elems == 1 and $!quote_space           = @s[0] ?? True !! False; return $!quote_space;           }
    method quote_null            (*@s) { @s.elems == 1 and $!quote_null            = @s[0] ?? True !! False; return $!quote_null;            }
    method quote_binary          (*@s) { @s.elems == 1 and $!quote_binary          = @s[0] ?? True !! False; return $!quote_binary;          }
    method allow_loose_quotes    (*@s) { @s.elems == 1 and $!allow_loose_quotes    = @s[0] ?? True !! False; return $!allow_loose_quotes;    }
    method allow_loose_escapes   (*@s) { @s.elems == 1 and $!allow_loose_escapes   = @s[0] ?? True !! False; return $!allow_loose_escapes;   }
    method allow_unquoted_escape (*@s) { @s.elems == 1 and $!allow_unquoted_escape = @s[0] ?? True !! False; return $!allow_unquoted_escape; }
    method allow_whitespace      (*@s) { @s.elems == 1 and $!allow_whitespace      = @s[0] ?? True !! False; return $!allow_whitespace;      }
    method blank_is_undef        (*@s) { @s.elems == 1 and $!blank_is_undef        = @s[0] ?? True !! False; return $!blank_is_undef;        }
    method empty_is_undef        (*@s) { @s.elems == 1 and $!empty_is_undef        = @s[0] ?? True !! False; return $!empty_is_undef;        }

    # Numeric attributes
    method record_number (*@s) { @s.elems == 1 and $!record_number = @s[0] + 0; return $!record_number  ; }

    # Numeric attributes, boolean allowed
    method !bool_int ($d is rw, *@s) {
        if (@s.elems == 1) {
            my $v = @s[0];
            $d = $v ~~ Bool ?? $v ?? 1 !! 0 !! $v.defined ?? $v + 0 !! 0;
            }
        return $d;
        }
    method auto_diag    (*@s) { return self!bool_int ($!auto_diag,    @s); }
    method diag_verbose (*@s) { return self!bool_int ($!diag_verbose, @s); }
    method verbose_diag (*@s) { return self!bool_int ($!diag_verbose, @s); }

    method status () {
        return $!errno ?? False !! True;
        }

    method error_input () {
        $!errno or return Nil;
        return $!error_input;
        }

    method !ready (CSV::Field $f) {
        defined $f.text or $f.undefined = True;

        if ($f.undefined) {
            $!blank_is_undef or $f.add ("");
            push @!fields, $f;
            return True;
            }

        if ($f.text eq Nil || !$f.text.defined || $f.text eq "") {
            if ($!empty_is_undef) {
                $f.undefined = True;
                $f.text      = Nil;
                }
            push @!fields, $f;
            return True;
            }

        # Postpone all other field attributes like is_binary and is_utf8
        # till it is actually asked for unless it is required right now
        # to fail
        !$!binary && $f.is_binary and return False;

        push @!fields, $f;
        return True;
        } # ready

    method fields () {
        return @!fields;
        } # fields

    method string () {
        @!fields or return;
        my Str $s = $!sep;
        my Str $q = $!quo;
        my Str $e = $!esc;
        #progress (0, @!fields.perl);
        my Str @f;
        for @!fields -> $f {
            if ($f.undefined) {
                @f.push ($!quote_null   ?? "$!quo$!quo" !! "");
                next;
                }
            my $t = $f.text;
            if (!$t.defined || $t eq "") {
                @f.push ($!always_quote ?? "$!quo$!quo" !! "");
                next;
                }
            $t .= subst (/( $q | $e )/, { "$e$0" }, :g);
            $!always_quote
            ||                   $t ~~ / $e  | $s | \r | \n /
            || ($!quote_space && $t ~~ / " " | \t /)
                and $t = "$!quo$t$!quo";
            push @f, $t;
            }
        #progress (0, @f.perl);
        my Str $x = join $!sep, @f;
        defined $!eol and $x ~= $!eol;
        #progress (1, $x);
        return $x;
        } # string

    method combine (*@f) {
        @!fields = ();
        for @f -> $f {
            my $cf = CSV::Field.new;
            defined $f and $cf.add ($f.Str);
            unless (self!ready ($cf)) {
                $!errno       = 2110;
                $!error_input = $f.Str;
                return False;
                }
            }
        return True;
        }

    method parse (Str $buffer) {

        my     $field;
        my int $pos = 0;

        $!errno = 0;

        my sub parse_error (Int $errno) {
            $!errno         = $errno;
            $!error_pos     = 0;
            $!error_message = %!errors{$errno};
            $!error_input   = $buffer;
            $!auto_diag and # warn has no means to prevent location
                note $!error_message ~ " @ pos " ~ $pos ~ "\n" ~ $buffer ~ "\n" ~ ' ' x $pos ~ "^\n"; 
            return;
            }

        $!record_number++;
        $opt_v > 4 and progress ($!record_number, $buffer.perl);

        # A scoping bug in perl6 inhibits the use of $!eol inside the split
        #for $buffer.split (rx{ $!eol | $!sep | $!quo | $!esc }, :all).map (~*) -> Str $chunk
        my     $eol = $!eol // rx{ \r\n | \r | \n };
        my Str $sep = $!sep;
        my Str $quo = $!quo;
        my Str $esc = $!esc;
        my $f = CSV::Field.new;

        @!fields = Nil;

        sub keep () {
            self!ready ($f) or return False;
            $f = CSV::Field.new;
            return True;
            } # add

        my @ch = $buffer.split (rx{ $eol | $sep | $quo | $esc }, :all).map: {
            if $_ ~~ Str {
                $_   if .chars;
                }
            else {
                .Str if .Bool;
                };
            };
        $opt_v > 2 and progress (0, @ch.perl);

        my int $skip = 0;
        my int $i    = -1;

        for @ch -> Str $chunk {
            $i = $i + 1;

            if ($skip) {
                # $skip-- fails:
                # Masak: there's wide agreement that that should work, but
                #  it's difficult to implement. here's (I think) why: usually
                #  the $value gets replaced by $value.pred and then put back
                #  into the variable's container. but natives have no
                #  containers, only the value itself.
                $skip = $skip - 1;      # $i-- barfs. IMHO a bug
                next;
                }

            $opt_v > 8 and progress ($i, "###", $chunk.perl~"\t", $f.perl);

            if ($chunk eq $sep) {
                $opt_v > 5 and progress ($i, "SEP");

                # ,1,"foo, 3",,bar,
                # ^           ^
                if ($f.undefined) {
                    $!blank_is_undef || $!empty_is_undef or
                        $f.add ("");
                    keep () or return;
                    next;
                    }

                # ,1,"foo, 3",,bar,
                #        ^
                if ($f.is_quoted) {
                    $opt_v > 9 and progress ($i, "    inside quoted field ", @ch[$i..*-1].perl);
                    $f.add ($chunk);
                    next;
                    }

                # ,1,"foo, 3",,bar,
                #   ^        ^    ^
                keep () or return;
                next;
                }

            if ($quo.defined and $chunk eq $quo) {
                $opt_v > 5 and progress ($i, "QUO", $f.perl);

                # ,1,"foo, 3",,bar,\r\n
                #    ^
                if ($f.undefined) {
                    $opt_v > 9 and progress ($i, "    initial quote");
                    $f.set_quoted;
                    next;
                    }

                if ($f.is_quoted) {

                    $opt_v > 9 and progress ($i, "    inside quoted field ", @ch[$i..*-1].perl);
                    # ,1,"foo, 3"
                    #           ^
                    if ($i == @ch - 1) {
                        keep () or return;
                        return @!fields;
                        }

                    my Str $next   = @ch[$i + 1] // Nil;
                    my int $omit   = 1;
                    my int $quoesc = 0;

                    # , 1 , "foo, 3" , , bar , "" \r\n
                    #               ^            ^
                    if ($!allow_whitespace && $next ~~ /^ \s+ $/) {
                        $next = @ch[$i + 2] // Nil;
                        $omit++;
                        }

                    $opt_v > 8 and progress ($i, "QUO", "next = $next");

                    # ,1,"foo, 3",,bar,\r\n
                    #           ^
                    if ($next eq $sep) {
                        $opt_v > 7 and progress ($i, "SEP");
                        $skip = $omit;
                        keep () or return;
                        next;
                        }

                    # ,1,"foo, 3"\r\n
                    #           ^
                    # Nil can also indicate EOF
                    if ($next eq Nil || !$next.defined || $next ~~ /^ $eol $/) {
                        keep () or return;
                        return @!fields;
                        }

                    if (defined $esc and $esc eq $quo) {
                        $opt_v > 7 and progress ($i, "ESC", "($next)");

                        $quoesc = 1;

                        # ,1,"foo, 3"056",,bar,\r\n
                        #            ^
                        if (@ch[$i + 1] ~~  /^ "0"/) {  # cannot use $next
                            @ch[$i + 1] ~~ s{^ "0"} = "";
                            $opt_v > 8 and progress ($i, "Add NIL");
                            $f.add ("\c0");
                            next;
                            }

                        # ,1,"foo, 3""56",,bar,\r\n
                        #            ^
                        if (@ch[$i + 1] eq $quo) {
                            $skip = $omit;
                            $f.add ($chunk);
                            next;
                            }

                        if ($!allow_loose_escapes) {
                            # ,1,"foo, 3"56",,bar,\r\n
                            #            ^
                            next;
                            }
                        }

                    # No need to special-case \r

                    if ($quoesc == 1) {
                        # 1,"foo" ",3
                        #        ^
                        return parse_error (2023);
                        }

                    if ($!allow_loose_quotes) {
                        # ,1,"foo, 3"456",,bar,\r\n
                        #            ^
                        $f.add ($chunk);
                        next;
                        }
                    # Keep rest of @ch for hooks?
                    return parse_error (2011);
                    }

                # 1,foo "boo" d'uh,1
                #       ^
                if ($!allow_loose_quotes) {
                    $f.add ($chunk);
                    next;
                    }
                return parse_error (2034);
                }

            if ($esc.defined and $chunk eq $esc) {
                $opt_v > 5 and progress ($i, "ESC", $f.perl);
                }

            if ($chunk ~~ rx{^ $eol $}) {
                $opt_v > 5 and progress ($i, "EOL");
                if ($f.is_quoted) {     # 1,"2\n3"
                    $!binary or
                        return parse_error (2021);

                    $f.add ($chunk);
                    next;
                    }
                keep () or return;
                return @!fields;
                }

            $chunk ne "" and $f.add ($chunk);
            $pos += .chars;
            }

        $f.is_quoted and
            return parse_error (2027);

#       !$!binary && $f.is_binary and
#           return parse_error ($f.is_quoted ?? 2026 !! 2037);

        keep () or return;
        return @!fields;
        } # parse

    method getline () {
        return @!fields;
        } # getline
    }

sub MAIN () {

    my $csv_parser = Text::CSV.new;

    $opt_v > 1 and say $csv_parser.perl;
    $opt_v and progress (.perl) for $csv_parser.parse ($test);
    $opt_v and Qw { Expected: Str 1 ab cd e\0f g,h nl\nz\0i""3 Str }.say;

    my Int $sum = 0;
    for lines () :eager {
        my @r = $csv_parser.parse ($_);
        $sum += +@r;
        }
    $sum.say;
    }

1;
