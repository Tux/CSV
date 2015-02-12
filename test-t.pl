#!perl6

use v6;
use Slang::Tuxic;

my $VERSION = "1.00";

my constant $opt_v = %*ENV<PERL6_VERBOSE> // 1;
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
        .add ("");
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

    method is_binary () returns Bool {
        $!analysed or self!analyse;
        return $!is_binary;
        }

    method is_utf8 () returns Bool {
        $!analysed or self!analyse;
        return $!is_utf8;
        }

    method is_missing () returns Bool {
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
    has Bool $!build                 = False;

    has Int  $!record_number         = 0;

    has CSV::Field @!fields;
    has Str        $!ahead;
    has Int        @!types;
    has            @!callbacks;

    has Int  $!errno                 = 0;
    has Int  $!error_pos             = 0;
    has Str  $!error_input           = Nil;
    has Str  $!error_message         = "";
    has Str  %!errors{Int} =
        # Success
           0 => "",

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

    class CSV::Diag is Iterable does Positional is Exception {
        has Int $.error   is readonly;
        has Str $.message is readonly;
        has Int $.pos     is readonly;
        has Int $.record  is readonly;
        has Str $.buffer  is readonly;

        method sink {
            # See also src/core/Exception.pm - role X::Comp  method gist
            # I do not want the "in method sink at ..." here, but there
            # is no way yet to suppress that, so say instead of warn for now
            say  "\e[34m" ~ $!message
               ~ "\e[0m"  ~ " : error $!error @ rec $!record, pos $!pos\n"
               ~ "\e[32m" ~ substr ($!buffer, 0, $!pos)
               ~ "\e[33m" ~ "\x[23CF]"
               ~ "\e[31m" ~ substr ($!buffer,    $!pos)
               ~ "\e[0m";
            }
        method Numeric  { return   $!error; }
        method Str      { return   $!message; }
        method iterator { return [ $!error, $!message, $!pos, $!record, $!buffer ].iterator; }
        method hash     { return { errno  => $!error,
                                   error  => $!message,
                                   pos    => $!pos,
                                   recno  => $!record,
                                   buffer => $!buffer,
                                   }; }
        method at_pos (int $i) {
            return $i == 0 ?? $!error
                !! $i == 1 ?? $!message
                !! $i == 2 ?? $!pos
                !! $i == 3 ?? $!record
                !! $i == 4 ?? $!buffer
                !! Nil;
            }
        }

    # We need this to support aliasses and to catch unsupported attributes
    submethod BUILD (*%init) {
        $!build = True;
        for keys %init -> $attr {
            my @can = self.can (lc $attr) or self!fail (1000);
            .(self, %init{$attr}) for @can;
            }
        $!build = False;
        #self!check_sanity;
        }

    method !fail (Int $errno) {
        $!errno         = $errno;
        $!error_pos     = 0;
        $!error_message = %!errors{$errno};
        $!error_input   = Str;
        $!auto_diag and self.error_diag;    # Void context
        die self.error_diag;                # Exception object
        }

    method !check_sanity () {
        $!build and return;

        $!sep.defined                        or  self!fail (1001);
        $!quo.defined and $!quo eq $!sep     and self!fail (1001);
        $!esc.defined and $!esc eq $!sep     and self!fail (1001);

                          $!sep ~~ m{[\r\n]} and self!fail (1003);
        $!quo.defined and $!quo ~~ m{[\r\n]} and self!fail (1003);
        $!esc.defined and $!esc ~~ m{[\r\n]} and self!fail (1003);

        $!allow_whitespace or return;

                          $!sep ~~ m{[ \t]}  and self!fail (1002);
        $!quo.defined and $!quo ~~ m{[ \t]}  and self!fail (1002);
        $!esc.defined and $!esc ~~ m{[ \t]}  and self!fail (1002);
        }

    # String attributes
    method !a_str ($attr is rw, *@s) returns Str {
        @s.elems == 1 and $attr = @s[0];
        self!check_sanity;
        return $attr;
        }
    method sep (*@s) { return self!a_str ($!sep, @s); }
    method quo (*@s) { return self!a_str ($!quo, @s); }
    method esc (*@s) { return self!a_str ($!esc, @s); }
    method eol (*@s) { return self!a_str ($!eol, @s); }

    # Boolean attributes
    method !a_bool ($attr is rw, *@s) {
        @s.elems == 1 and $attr = ?@s[0];
        self!check_sanity;
        return $attr;
        }
    method binary                (*@s) { return self!a_bool ($!binary,                @s); }
    method always_quote          (*@s) { return self!a_bool ($!always_quote,          @s); }
    method quote_space           (*@s) { return self!a_bool ($!quote_space,           @s); }
    method quote_null            (*@s) { return self!a_bool ($!quote_null,            @s); }
    method quote_binary          (*@s) { return self!a_bool ($!quote_binary,          @s); }
    method allow_loose_quotes    (*@s) { return self!a_bool ($!allow_loose_quotes,    @s); }
    method allow_loose_escapes   (*@s) { return self!a_bool ($!allow_loose_escapes,   @s); }
    method allow_unquoted_escape (*@s) { return self!a_bool ($!allow_unquoted_escape, @s); }
    method allow_whitespace      (*@s) { return self!a_bool ($!allow_whitespace,      @s); }
    method blank_is_undef        (*@s) { return self!a_bool ($!blank_is_undef,        @s); }
    method empty_is_undef        (*@s) { return self!a_bool ($!empty_is_undef,        @s); }

    # Numeric attributes
    method !a_num ($attr is rw, *@s) returns Int {
        @s.elems == 1 and $attr = +@s[0];
        return $attr;
        }
    method record_number (*@s) { return self!a_num ($!record_number, @s); }

    # Numeric attributes, boolean allowed
    method !a_bool_int ($attr is rw, *@s) returns Int {
        if (@s.elems == 1) {
            my $v = @s[0];
            $attr = $v ~~ Bool ?? $v ?? 1 !! 0 !! $v.defined ?? +$v !! 0;
            }
        return $attr;
        }
    method auto_diag    (*@s) { return self!a_bool_int ($!auto_diag,    @s); }
    method diag_verbose (*@s) { return self!a_bool_int ($!diag_verbose, @s); }

    CHECK {
        sub alias (Str:D $m, *@aka) {
            my $r := Text::CSV.^find_method ($m);
            my $p := $r.package;
            $p.^add_method ($_, $r) for @aka;
            }

        alias ("sep",                   < sep_char sep-char >);
        alias ("quo",                   < quote quote_char quote-char >);
        alias ("esc",                   < escape escape_char escape-char >);
        alias ("always_quote",          < always-quote quote_always quote-always >);
        alias ("quote_space",           < quote-space >);
        alias ("quote_null",            < quote-null>);
        alias ("quote_binary",          < quote-binary >);
        alias ("allow_loose_quotes",    < allow-loose-quotes allow_loose_quote allow-loose-quote >);
        alias ("allow_loose_escapes",   < allow-loose-escapes allow_loose_escape allow-loose-escape >);
        alias ("allow_unquoted_escape", < allow-unquoted-escape allow_unquoted_escapes allow-unquoted-escapes >);
        alias ("allow_whitespace",      < allow-whitespace >);
        alias ("blank_is_undef",        < blank-is-undef >);
        alias ("empty_is_undef",        < empty-is-undef >);
        alias ("record_number",         < record-number >);
        alias ("auto_diag",             < auto-diag >);
        alias ("diag_verbose",          < diag-verbose verbose_diag verbose-diag >);
        }

    method version () {
        return $VERSION;
        }

    method status () returns Bool {
        return $!errno ?? False !! True;
        }

    method error_input () {
        $!errno or return Nil;
        return $!error_input;
        }

    method error_diag () {
        return CSV::Diag.new (
            error   => $!errno,
            message => $!error_message,
            pos     => $!error_pos,
            record  => $!record_number,
            buffer  => $!error_input,
            );
       }

    method !ready (CSV::Field $f) returns Bool {
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
                @f.push ($!always_quote ?? "$!quo$!quo" !! "");
                next;
                }
            my $t = $f.text;
            if (!$t.defined || $t eq "") {
                @f.push ($!always_quote ?? "$!quo$!quo" !! "");
                next;
                }
            $t .= subst (/( $q | $e )/, { "$e$0" }, :g);
            $t .= subst (/ \x[0] /,     { $e ~ 0 }, :g) if $!quote_null;
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

    method combine (*@f) returns Bool {
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

    method parse (Str $buffer) returns Bool {

        my     $field;
        my int $skip = 0;
        my int $i    = -1;
        my int $pos  = 0;
        my int $ppos = 0;

        $!errno = 0;

        my sub parse_error (Int $errno) {
            $!errno         = $errno;
            $!error_pos     = $pos;
            $!error_message = %!errors{$errno};
            $!error_input   = $buffer;
            $!auto_diag and self.error_diag;
            return False;
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

        for @ch -> Str $chunk {
            $i = $i + 1;        #++
            $ppos += $chunk.chars;

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

            $pos = $ppos;

            $opt_v > 8 and progress ($i, "###", $chunk.perl~"\t", $f.perl);

            if ($chunk eq $sep) {
                $opt_v > 5 and progress ($i, "SEP");

                # ,1,"foo, 3",,bar,
                # ^           ^
                if ($f.undefined) {
                    $!blank_is_undef || $!empty_is_undef or
                        $f.add ("");
                    keep () or return False;
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
                keep () or return False;
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
                    $i == @ch - 1 and return keep ();

                    my Str $next   = @ch[$i + 1] // Nil;
                    my int $lastf  = ($next eq Nil ?? 1 !! 0);
                    my int $omit   = 1;
                    my int $quoesc = 0;

                    # , 1 , "foo, 3" , , bar , "" \r\n
                    #               ^            ^
                    if ($!allow_whitespace && !$lastf && $next ~~ /^ \s+ $/) {
                        $next = @ch[$i + 2] // Nil;
                        $omit = $omit + 1; #++
                        }

                    $opt_v > 8 and progress ($i, "QUO", "next = $next");

                    # ,1,"foo, 3",,bar,\r\n
                    #           ^
                    if (!$lastf and $next eq $sep) {
                        $opt_v > 7 and progress ($i, "SEP");
                        $skip = $omit;
                        keep () or return False;
                        next;
                        }

                    # ,1,"foo, 3"\r\n
                    #           ^
                    $lastf || !$next.defined || $next ~~ /^ $eol $/ and
                        return keep ();

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

                    .perl.say for @!fields;
                    $f.perl.say;
                    $chunk.perl.say;
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

                # ,1,"foo, 3\056",,bar,\r\n
                #            ^
                if (@ch[$i + 1] ~~  /^ "0"/) {  # cannot use $next
                    @ch[$i + 1] ~~ s{^ "0"} = "";
                    $opt_v > 8 and progress ($i, "Add NIL");
                    $f.add ("\c0");
                    next;
                    }

                # ,1,"foo, 3\"56",,bar,\r\n
                #            ^
                if (@ch[$i + 1] eq $quo) {
                    $skip = 1;
                    $f.add ($quo);
                    next;
                    }

                # ,1,"foo, 3\\56",,bar,\r\n
                #            ^
                if (@ch[$i + 1] eq $esc) {
                    $skip = 1;
                    $f.add ($esc);
                    next;
                    }

                if ($!allow_loose_escapes) {
                    # ,1,"foo, 3\56",,bar,\r\n
                    #            ^
                    next;
                    }

                return parse_error (2025);
                }

            if ($chunk ~~ rx{^ $eol $}) {
                $opt_v > 5 and progress ($i, "EOL");
                if ($f.is_quoted) {     # 1,"2\n3"
                    $!binary or
                        return parse_error (2021);

                    $f.add ($chunk);
                    next;
                    }
                return keep ();
                }

            $chunk ne "" and $f.add ($chunk);
            }

        $f.is_quoted and
            return parse_error (2027);

#       !$!binary && $f.is_binary and
#           return parse_error ($f.is_quoted ?? 2026 !! 2037);

        return keep ();
        } # parse

    method getline (IO $io) {
        self.parse ($io.get);   # Continue with next line on 2027
        return @!fields;
        } # getline

    method print (IO $io, *@fld) returns Bool {
        self.combine (@fld) or return False;
        $io.print (self.string);
        return True;
        }
    }

sub MAIN () {

    my $csv = Text::CSV.new;

    if ($opt_v) {
        $opt_v > 1 and say $csv.perl;
        $csv.parse ($test) or die $csv.error_diag;
        progress (.perl) for $csv.fields;
        < Expected: Str 1 ab cd e\0f g,h nl\nz\0i""3 Str >.say;
        }

    my Int $sum = 0;
    for lines () :eager {
        $csv.parse ($_);
        $sum += $csv.fields.elems;
        }
    $sum.say;
    }

1;
