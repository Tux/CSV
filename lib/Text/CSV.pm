#!perl6

use v6;
use Slang::Tuxic;
use File::Temp;

my $VERSION = "1.00";

my constant $opt_v = %*ENV<PERL6_VERBOSE> // 1;

my %errors =
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
    2021 => "EIQ - NL or EOL inside quotes, binary off",
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

    3100 => "ECB - Unsupported callback",

    # csv CI
    5000 => "CSV - Unsupported type for in",
    5001 => "CSV - Unsupported type for out",
    ;

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

# I don't want this inside Text::CSV
class IO::String is IO::Handle {

    multi method new (Str $str!) returns IO::Handle {
        (my Str $filename, my $fh) = tempfile;
        $fh.print ($str);
        $fh.close;
        open $filename, :r, chomp => False;
        }
    }

class RangeSet {

    has Pair @!ranges;

    method new (**@ranges) {
        self.bless (:@ranges);
        }

    multi method add (Pair:D $p)              { @!ranges.push: $p;               }
    multi method add (Int:D $from)            { @!ranges.push: $from => $from;   }
    multi method add (Int:D $from, Num:D $to) { @!ranges.push: $from => $to;     }
    multi method add (Int:D $from, Any:D $to) { @!ranges.push: $from => $to.Num; }

    method min () { @!ranges>>.key.min   }
    method max () { @!ranges>>.value.max }

    method in (Int:D $i) returns Bool {
        for @!ranges -> $r {
            $i >= $r.key && $i <= $r.value and return True;
            }
        False;
        }

    method to_list () {
        gather {
            my Int $max = -1;
            for sort @!ranges -> $r {
                my $from = ($r.key, $max + 1).max.Int;
                take $from .. $r.value;
                $r.value == Inf and last;
                $max = ($max, $r.value).max.Int;
                }
            }
        }

    method list () {
        # There's a more efficient way to do this... :-)
        gather {
            for $.min .. $.max -> $maybe {
                take $maybe if $maybe ~~ self;
                }
            }
        }
    }

class CellSet {

    class CellRange {

        has RangeSet $.row;
        has RangeSet $.col;

        method in (Int $row, Int $col) {
            $.row && $.col && $.row.in ($row) && $.col.in ($col);
            }
        }

    has CellRange @!cr;

    method add (Int:D $tlr,            Int:D $tlc,
                Num   $brr = $tlr.Num, Num   $brc = $tlc.Num) {
        my $row = RangeSet.new; $row.add ($tlr, $brr);
        my $col = RangeSet.new; $col.add ($tlc, $brc);
        @!cr.push: CellRange.new (:$row, :$col);
        }

    method in (Int:D $row, Int:D $col) returns Bool {
        #return @!cr.any (*.in ($row, $col));
        for @!cr -> $c {
            $c.in ($row, $col) and return True;
            }
        False;
        }
    }

class CSV::Field {

    has Bool $.is_quoted  is rw = False;
    has Str  $.text       is rw = Str;

    has Bool $!is_binary  = False;
    has Bool $!is_utf8    = False;
    has Bool $!is_missing = False;
    has Bool $!analysed   = False;

    multi method new (Str(Cool) $str) {
        $str.defined ?? self.bless.add ($str) !! self.bless;
        }

    method Bool {
        $.text.defined && $.text ne "0" && $.text ne "";
        }

    method Str {
        $.text;
        }

    method Numeric {
        $.text.defined
            ?? $!text ~~ m{^ <[0..9]> } ?? +$!text
            !!                              $!text.unival.Int
            !! Num;
        }

    method gist {
        $.text.defined or return "<undef>";
        my $s  = $.is_quoted  ?? "Q" !! "q";
           $s ~= $!is_binary  ?? "B" !! "b";
           $s ~= $!is_utf8    ?? "8" !! "7";
           $s ~= $!is_missing ?? "M" !! "m";
        $s ~ ":" ~ $.text.perl;
        }

    method add (Str $chunk) {
        $!text ~= $chunk;
        self;
        }

    method set_quoted () {
        $!is_quoted = True;
        $!text      = "";
        }

    method undefined () {
        !$!text.defined;
        }

    method !analyse () {
        $!analysed and return;

        $!analysed = True;

        !$!text.defined || $!text eq "" and
            return; # Default is False for both

        $!text ~~ m{^ <[ \x09, \x20 .. \x7E ]>+ $} or
            $!is_binary = True;

        $!text ~~ m{^ <[ \x00       .. \x7F ]>+ $} or
            $!is_utf8   = True;
        }

    method is_binary () returns Bool {
        $!analysed or self!analyse;
        $!is_binary;
        }

    method is_utf8 () returns Bool {
        $!analysed or self!analyse;
        $!is_utf8;
        }

    method is_missing () returns Bool {
        $!analysed or self!analyse;
        $!is_missing;
        }

    } # CSV::Field

class Text::CSV {

    # Defaults are set in BUILD!
    has Str  $!eol;
    has Str  $!sep;
    has Str  $!quo;
    has Str  $!esc;

    has Bool $!binary;
    has Bool $!decode_utf8;
    has Int  $!auto_diag;
    has Int  $!diag_verbose;
    has Bool $!keep_meta;

    has Bool $!blank_is_undef;
    has Bool $!empty_is_undef;
    has Bool $!allow_whitespace;
    has Bool $!allow_loose_quotes;
    has Bool $!allow_loose_escapes;
    has Bool $!allow_unquoted_escape;

    has Bool $!always_quote;
    has Bool $!quote_space;
    has Bool $!quote_null;
    has Bool $!quote_empty;
    has Bool $!quote_binary;

    has Bool $!build;
    has Int  $!record_number;

    has CSV::Field @!fields;
    has Str        @!ahead;
    has Str        @!cnames;
    has IO         $!io;
    has Bool       $!eof;
    has Int        @!types;
    has Int        @!crange;
    has RangeSet   $!rrange;
    has            %!callbacks;

    has Int  $!errno;
    has Int  $!error_pos;
    has Str  $!error_input;
    has Str  $!error_message;

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
        method Numeric  { $!error; }
        method Str      { $!message; }
        method iterator { [ $!error, $!message, $!pos, $!record, $!buffer ].iterator; }
        method hash     { { errno  => $!error,
                            error  => $!message,
                            pos    => $!pos,
                            recno  => $!record,
                            buffer => $!buffer,
                          }; }
        method AT-POS (int $i) {
               $i == 0 ?? $!error
            !! $i == 1 ?? $!message
            !! $i == 2 ?? $!pos
            !! $i == 3 ?? $!record
            !! $i == 4 ?? $!buffer
            !! Nil;
            }
        }

    # We need this to support aliasses and to catch unsupported attributes
    submethod BUILD (*%init) {
        # Defaults are disabled when BUILD is defined!

        $!sep                   = ',';
        $!quo                   = '"';
        $!esc                   = '"';

        $!binary                = True;
        $!decode_utf8           = True;
        $!auto_diag             = 0;
        $!diag_verbose          = 0;
        $!keep_meta             = False;

        $!blank_is_undef        = False;
        $!empty_is_undef        = False;
        $!allow_whitespace      = False;
        $!allow_loose_quotes    = False;
        $!allow_loose_escapes   = False;
        $!allow_unquoted_escape = False;

        $!always_quote          = False;
        $!quote_empty           = False;
        $!quote_space           = True;
        $!quote_null            = True;
        $!quote_binary          = True;

        $!errno                 = 0;
        $!error_pos             = 0;
        $!error_input           = "";
        $!error_message         = "";
        $!record_number         = 0;

        $!io                    = IO;
        $!eof                   = False;

        self!set-attributes (%init);
        }

    method !set-attributes (%init) {
        $!build = True;
        for keys %init -> $attr {
            my @can = self.can (lc $attr) or self!fail (1000, "Unknown attribute '$attr'");
            .(self, %init{$attr}) for @can;
            }
        $!build = False;

        self!check_sanity;
        }

    CHECK {
        sub alias (Str:D $m, *@aka) {
            my $r := Text::CSV.^find_method ($m);
            my $p := $r.package;
            $p.^add_method ($_, $r) for @aka;
            }

        alias ("sep",                   < sep_char sep-char separator >);
        alias ("quo",                   < quote quote_char quote-char >);
        alias ("esc",                   < escape escape_char escape-char >);
        alias ("always_quote",          < always-quote quote_always quote-always >);
        alias ("quote_empty",           < quote-empty >);
        alias ("quote_space",           < quote-space >);
        alias ("quote_null",            < quote-null escape_null escape-null >);
        alias ("quote_binary",          < quote-binary >);
        alias ("allow_loose_quotes",    < allow-loose-quotes allow_loose_quote allow-loose-quote >);
        alias ("allow_loose_escapes",   < allow-loose-escapes allow_loose_escape allow-loose-escape >);
        alias ("allow_unquoted_escape", < allow-unquoted-escape allow_unquoted_escapes allow-unquoted-escapes >);
        alias ("allow_whitespace",      < allow-whitespace >);
        alias ("blank_is_undef",        < blank-is-undef >);
        alias ("empty_is_undef",        < empty-is-undef >);
        alias ("record_number",         < record-number >);
        alias ("auto_diag",             < auto-diag >);
        alias ("keep_meta",             < keep-meta meta>);
        alias ("diag_verbose",          < diag-verbose verbose_diag verbose-diag >);
        alias ("callbacks",             < hooks >);
        }

    method !fail (Int:D $errno, *@s) {
        $!errno          = $errno;
        $!error_pos      = 0;
        $!error_message  = %errors{$errno};
        $!error_message ~= (":", @s).join (" ") if @s.elems;
        $!error_input    = Str;
        $!auto_diag and self.error_diag;    # Void context
        die self.error_diag;                # Exception object
        }

    method !check_sanity () {
        $!build and return;

        #say "Sanity check: S:"~$!sep~" Q:"~($!quo//"<undef>")~" E:"~($!esc//"<undef>")~" WS:"~$!allow_whitespace;
        $!sep.defined                            or  self!fail (1001);
        $!quo.defined and $!quo eq $!sep         and self!fail (1001);
        $!esc.defined and $!esc eq $!sep         and self!fail (1001);

                          $!sep ~~ m{<[\r\n]>}   and self!fail (1003);
        $!quo.defined and $!quo ~~ m{<[\r\n]>}   and self!fail (1003);
        $!esc.defined and $!esc ~~ m{<[\r\n]>}   and self!fail (1003);

        $!allow_whitespace or return;

                          $!sep ~~ m{ <[\ \t]> } and self!fail (1002);
        $!quo.defined and $!quo ~~ m{ <[\ \t]> } and self!fail (1002);
        $!esc.defined and $!esc ~~ m{ <[\ \t]> } and self!fail (1002);
        }

    # String attributes
    method !a_str ($attr is rw, *@s) returns Str {
        if (@s.elems == 1) {
            my $x = @s[0];
            $x.defined && $x ~~ Str && $x eq "" and $x = Str;
            $attr = $x;
            self!check_sanity;
            }
        $attr;
        }
    method sep (*@s) returns Str { self!a_str ($!sep, @s); }
    method quo (*@s) returns Str { self!a_str ($!quo, @s); }
    method esc (*@s) returns Str { self!a_str ($!esc, @s); }
    method eol (*@s) returns Str { self!a_str ($!eol, @s); }

    # Boolean attributes
    method !a_bool ($attr is rw, *@s) returns Bool {
        if (@s.elems == 1) {
            $attr = ?@s[0];
            self!check_sanity;
            }
        $attr;
        }
    method binary                (*@s) returns Bool { self!a_bool ($!binary,                @s); }
    method always_quote          (*@s) returns Bool { self!a_bool ($!always_quote,          @s); }
    method quote_empty           (*@s) returns Bool { self!a_bool ($!quote_empty,           @s); }
    method quote_space           (*@s) returns Bool { self!a_bool ($!quote_space,           @s); }
    method quote_null            (*@s) returns Bool { self!a_bool ($!quote_null,            @s); }
    method quote_binary          (*@s) returns Bool { self!a_bool ($!quote_binary,          @s); }
    method allow_loose_quotes    (*@s) returns Bool { self!a_bool ($!allow_loose_quotes,    @s); }
    method allow_loose_escapes   (*@s) returns Bool { self!a_bool ($!allow_loose_escapes,   @s); }
    method allow_unquoted_escape (*@s) returns Bool { self!a_bool ($!allow_unquoted_escape, @s); }
    method allow_whitespace      (*@s) returns Bool { self!a_bool ($!allow_whitespace,      @s); }
    method blank_is_undef        (*@s) returns Bool { self!a_bool ($!blank_is_undef,        @s); }
    method empty_is_undef        (*@s) returns Bool { self!a_bool ($!empty_is_undef,        @s); }
    method keep_meta             (*@s) returns Bool { self!a_bool ($!keep_meta,             @s); }
    method eof                   ()    returns Bool { $!eof; }

    # Numeric attributes
    method !a_num ($attr is rw, *@s) returns Int {
        @s.elems == 1 and $attr = +@s[0];
        $attr;
        }
    method record_number (*@s) returns Int { self!a_num ($!record_number, @s); }

    # Numeric attributes, boolean allowed
    method !a_bool_int ($attr is rw, *@s) returns Int {
        if (@s.elems == 1) {
            my $v = @s[0];
            $attr = $v ~~ Bool ?? $v ?? 1 !! 0 !! $v.defined ?? +$v !! 0;
            }
        $attr;
        }
    method auto_diag    (*@s) returns Int { self!a_bool_int ($!auto_diag,    @s); }
    method diag_verbose (*@s) returns Int { self!a_bool_int ($!diag_verbose, @s); }

    method column_names (*@c) returns Array[Str] {
        if (@c.elems == 1 and !@c[0].defined || (@c[0] ~~ Bool && !?@c[0])) {
            @!cnames = @();
            }
        elsif (@c.elems) {
            @!cnames = @c.map (*.Str);
            }
        @!cnames;
        }

    method callbacks (*@cb) {
        if (@cb.elems == 1) {
            my $b = @cb[0];
            !$b.defined ||
               ($b ~~ Bool || $b ~~ Int and !?$b) ||
               ($b ~~ Str  && $b ~~ m:i/^( reset | clear | none | 0 )$/) or
                self!fail (1004);
            %!callbacks = %();
            }
        elsif (@cb.elems % 2) {
            self!fail (1004);
            }
        elsif (@cb.elems) {
            my %hooks;
            for @cb -> $name, $hook {
                $name.defined && $name ~~ Str     &&
                $hook.defined && $hook ~~ Routine or
                    self!fail (1004);

                $name ~~ s{"-"} = "_";
                $name ~~ /^ after_parse
                          | before_print
                          | filter
                          | error
                          $/ or self!fail (3100, $name);
                %hooks{$name} = $hook;
                }
            %!callbacks = %hooks;
            }
        return %!callbacks;
        }

    method !rfc7111ranges (Str:D $spec) returns RangeSet {
        my RangeSet $range = RangeSet.new;
        for $spec.split (/ ";" /) -> $r {
            $r ~~ /^ (<[0..9]>+)["-"[(<[0..9]>+)||("*")]]? $/ or self!fail (2013);
            my Int $from = +$0;
            my Str $tos  = ($1 // $from).Str;
            my Num $to   = $tos eq "*" ?? Inf !! (+$tos - 1).Num;
            --$from <= $to or self!fail (2013);
            $range.add ($from, $to);
            }
        $range;
        }

    multi method colrange (@cr) returns Array[Int] {
        @cr.elems and @!crange = @cr;
        @!crange;
        }

    multi method colrange (Str $range) returns Array[Int] {
        @!crange = ();
        $range.defined and @!crange = self!rfc7111ranges ($range).to_list;
        @!crange;
        }

    multi method colrange () returns Array[Int] {
        @!crange;
        }

    multi method rowrange (Str $range) returns RangeSet {
        $!rrange = RangeSet;
        $range.defined and $!rrange = self!rfc7111ranges ($range);
        $!rrange;
        }

    method version () returns Str {
        $VERSION;
        }

    method status () returns Bool {
        !?$!errno;
        }

    method error_input () returns Str {
        $!errno or return Str;
        $!error_input;
        }

    method error_diag () returns CSV::Diag {
        CSV::Diag.new (
            error   => $!errno,
            message => $!error_message,
            pos     => $!error_pos,
            record  => $!record_number,
            buffer  => $!error_input // "", # // for 2012
            );
        }

    method is_quoted  (Int:D $i) returns Bool {
        $i >= 0 && $i < @!fields.elems && @!fields[$i].is_quoted;
        }

    method is_binary  (Int:D $i) returns Bool {
        $i >= 0 && $i < @!fields.elems && @!fields[$i].is_binary;
        }

    method is_utf8    (Int:D $i) returns Bool {
        $i >= 0 && $i < @!fields.elems && @!fields[$i].is_utf8;
        }

    method is_missing (Int:D $i) returns Bool {
        $i >= 0 && $i < @!fields.elems && @!fields[$i].is_missing;
        }

    method !accept-field (CSV::Field $f) returns Bool {
        @!fields.push: $f;
        True;
        }

    # combine : direction = 0
    # parse   : direction = 1
    method !ready (int $direction, CSV::Field $f) returns Bool {

        if ($f.undefined) {
            if ($direction) {
                $!blank_is_undef || $!empty_is_undef or $f.add ("");
                }
            return self!accept-field ($f);
            }

        if ($f.text eq "") {
            $!empty_is_undef and $f.text = Str;
            return self!accept-field ($f);
            }

        # Postpone all other field attributes like is_binary and is_utf8
        # till it is actually asked for unless it is required right now
        # to fail
        if (!$!binary and $f.text ~~ m{ <[ \x00..\x08 \x0A..\x1F ]> }) {
            $!errno         = $f.is_quoted ??
                 $f.text ~~ m{<[ \r ]>} ?? 2022 !!
                 $f.text ~~ m{<[ \n ]>} ?? 2021 !!  2026 !! 2037;
            $!error_pos     = 0;
            $!error_message = %errors{$!errno};
            $!error_input   = $f.text;
            $!auto_diag and self.error_diag;
            return False;
            }

        self!accept-field ($f);
        } # ready

    method fields () {
        @!crange ?? @!fields[@!crange] !! @!fields;
        } # fields

    method list () {
        self.fields».text;
        }

    method string () returns Str {

        %!callbacks{"before_print"}.defined and
            %!callbacks{"before_print"}.(self, @!fields);

        @!fields or return Str;
        my Str $s = $!sep;
        my Str $q = $!quo;
        my Str $e = $!esc;
        #progress (0, @!fields);
        my Str @f;
        for @!fields -> $f {
            if (!$f.defined || $f.undefined) {
                @f.push: "";
                next;
                }
            my Str $t = $f.text ~ "";
            if ($t eq "") {
                @f.push: $!always_quote || $!quote_empty ?? "$!quo$!quo" !! "";
                next;
                }
            $t .= subst (/( $q | $e )/, { "$e$0" }, :g);
            $t .= subst (/ \x[0] /,     { $e ~ 0 }, :g) if $!quote_null;
            $!always_quote
            ||                    $t ~~ / $e  | $s | \r | \n /
            || ($!quote_space  && $t ~~ / " " | \t /)
            || ($!quote_binary && $t ~~ / <[ \x00..\x08 \x0a..\x1f \x7f..\xa0 ]> /)
                and $t = "$q$t$q";
            @f.push: $t;
            }
        #progress (0, @f);
        my Str $x = join $!sep, @f;
        defined $!eol and $x ~= $!eol;
        #progress (1, $x);
        $x;
        } # string

    multi method combine (Capture $c) returns Bool {
        self.combine ($c.list);
        }
    multi method combine (*@f) returns Bool {
        self.combine ([@f]);
        }
    multi method combine (@f) returns Bool {
        @!fields = ();
        for @f -> $f {
            my CSV::Field $cf;
            if ($f.isa (CSV::Field)) {
                $cf = $f;
                }
            else {
                $cf = CSV::Field.new;
                defined $f and $cf.add ($f.Str);
                }
            unless (self!ready (0, $cf)) {
                $!errno       = 2110;
                $!error_input = $f.Str;
                return False;
                }
            }
        True;
        }

    method parse (Str $buffer) returns Bool {

        my     $field;
        my int $skip = 0;
        my int $pos  = 0;
        my int $ppos = 0;

        $!errno = 0;

        my sub parse_error (Int $errno) {
            $!errno         = $errno;
            $!error_pos     = $pos;
            $!error_message = %errors{$errno};
            $!error_input   = $buffer;
            $!auto_diag and self.error_diag;
            $!eof           = $errno == 2012;
            False;
            }

        my sub chunks (Str $str, Regex:D $re) {
            $str.defined or  return ();
            $str eq ""   and return ("");

            $str.split ($re, :all).map: {
                if $_ ~~ Str {
                    $_   if .chars;
                    }
                else {
                    .Str if .Bool;
                    };
                };
            }

        $!record_number++;
        $opt_v > 4 and progress ($!record_number, $buffer.perl);

        # A scoping bug in perl6 inhibits the use of $!eol inside the split
        # my Regex $chx = rx{ $!eol | $sep | $quo | $esc };
        my            $eol = $!eol // rx{ \r\n | \r | \n };
        my Str        $sep = $!sep;
        my Str        $quo = $!quo;
        my Str        $esc = $!esc;
        my Regex      $chx = $!eol.defined
                       ?? rx{ $eol           | $sep | $quo | $esc }
                       !! rx{ \r\n | \r | \n | $sep | $quo | $esc };
        my CSV::Field $f   = CSV::Field.new;

        @!fields = ();

        my sub keep () {
            self!ready (1, $f) or return False;
            $f = CSV::Field.new;
            True;
            } # add

        my sub parse_done () {
            self!ready (1, $f) or return False;
            %!callbacks{"after_parse"}.defined and
                %!callbacks{"after_parse"}.(self, @!fields);
            True;
            }

        my @ch;
        $!io and @ch = @!ahead;
        @!ahead = ();
        $buffer.defined and @ch.push: chunks ($buffer, $chx);
        @ch or return parse_error (2012);

        $opt_v > 2 and progress (0, @ch.perl);

        @ch.elems or return parse_done ();       # An empty line

        loop {
            loop (my int $i = 0; $i < @ch.elems; $i = $i + 1) {
                my Str $chunk = @ch[$i];
                $ppos += $chunk.chars;

                if ($skip) {
                    $skip--;
                    next;
                    }

                $pos = $ppos;

                $opt_v > 8 and progress ($i, "###", $chunk.perl~"\t", $f.gist);

                if ($chunk eq $sep) {
                    $opt_v > 5 and progress ($i, "SEP - " ~ $f.gist);

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

                    # ,1 ,"foo, 3"  ,,bar ,
                    #    ^          ^     ^
                    $!allow_whitespace && !$f.undefined and $f.text ~~ s{ <[\ \t]>+ $} = "";

                    # ,1,"foo, 3",,bar,
                    #   ^        ^    ^
                    keep () or return False;
                    next;
                    }

                if ($quo.defined and $chunk eq $quo) {
                    $opt_v > 5 and progress ($i, "QUO -" ~ $f.gist);

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
                        $i == @ch - 1 and return parse_done ();

                        my Str $next   = @ch[$i + 1];
                        my int $omit   = 1;
                        my int $quoesc = 0;

                        # , 1 , "foo, 3" , , bar , "" \r\n
                        #               ^            ^
                        if ($!allow_whitespace && $next ~~ /^ <[\ \t]>+ $/) {
                            $i == @ch - 2 and return parse_done ();
                            $next = @ch[$i + 2];
                            $omit++;
                            }

                        $opt_v > 8 and progress ($i, "QUO", "next = $next");

                        # ,1,"foo, 3",,bar,\r\n
                        #           ^
                        if ($next eq $sep) {
                            $opt_v > 7 and progress ($i, "SEP");
                            $skip = $omit;
                            keep () or return False;
                            next;
                            }

                        # ,1,"foo, 3"\r\n
                        #           ^
                        # $next ~~ /^ $eol $/ and return parse_done ();
                        if ($!eol.defined
                                ?? $next eq $!eol
                                !! $next ~~ /^ \r\n | \n | \r $/) {
                            return parse_done ();
                            }

                        if (defined $esc and $esc eq $quo) {
                            $opt_v > 7 and progress ($i, "ESC", "($next)");

                            $quoesc = 1;

                            # ,1,"foo, 3"056",,bar,\r\n
                            #            ^
                            if ($next ~~ /^ "0"/) {
                                @ch[$i + 1] ~~ s{^ "0"} = "";
                                $ppos++;
                                $opt_v > 8 and progress ($i, "Add NIL");
                                $f.add ("\c0");
                                next;
                                }

                            # ,1,"foo, 3""56",,bar,\r\n
                            #            ^
                            if ($next eq $quo) {
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
                    $opt_v > 5 and progress ($i, "ESC - " ~ $f.gist);

                    if ($i >= $@ch.elems - 1) {
                        if ($!allow_loose_escapes) {
                            $f.add ($chunk);
                            next;
                            }
                        return parse_error ($f.is_quoted ?? 2024 !! 2035);
                        }

                    my $next = @ch[$i + 1];

                    # ,1,"foo, 3\056",,bar,\r\n
                    #            ^
                    if ($next ~~ /^ "0"/) {
                        @ch[$i + 1] ~~ s{^ "0"} = "";
                        $ppos++;
                        $opt_v > 8 and progress ($i, "Add NIL");
                        $f.add ("\c0");
                        next;
                        }

                    # ,1,"foo, 3\"56",,bar,\r\n
                    #            ^
                    if ($next eq $quo) {
                        $skip = 1;
                        $f.add ($quo);
                        next;
                        }

                    # ,1,"foo, 3\\56",,bar,\r\n
                    #            ^
                    if ($next eq $esc) {
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

                #if ($chunk ~~ rx{^ $eol $}) {
                if ($!eol.defined
                        ?? $chunk eq $!eol
                        !! $chunk ~~ /^ \r\n | \n | \r $/) {
                    $opt_v > 5 and progress ($i, "EOL - " ~ $f.gist);
                    if ($f.is_quoted) {     # 1,"2\n3"
                        $!binary or
                            return parse_error (
                                $!eol.defined       ?? 2021 !!
                                $chunk ~~ m{<[\r]>} ?? 2022 !!
                                $chunk ~~ m{<[\n]>} ?? 2021 !!  2026);

                        $f.add ($chunk);

                        if ($i == @ch.elems - 1 && $!io.defined) {
                            my $str = $!io.get or return parse_error (2012);
                            @ch.push: chunks ($str, $chx);
                            }

                        next;
                        }

                    # ,1,"foo, 3",,bar
                    #                    ^
                    $!allow_whitespace && !$f.undefined and $f.text ~~ s{ <[\ \t]>+ $} = "";

                    $!io.defined and @!ahead = @ch[($i + 1) .. *];

                    return parse_done ();
                    }

                # 1,foo,  bar,4
                #       ^
                if ($!allow_whitespace) {
                    $f.undefined        and $chunk ~~ s{^ <[\ \t]>+  } = "";
                    $i + 1 == @ch.elems and $chunk ~~ s{  <[\ \t]>+ $} = "";
                    }

                unless ($!binary) {
                    $opt_v > 5 and progress ($i, "data - check binary");
                    if ($f.is_quoted) {
                        $chunk ~~ m/  \r / and return parse_error (2022);
                        $chunk ~~ m/  \n / and return parse_error (2021);
                        }
                    else {
                        $chunk ~~ m/^ \r / and return parse_error (2031);
                        $chunk ~~ m/  \r / and return parse_error (2032);
                        }
                    }
                $chunk ne "" and $f.add ($chunk);
                }

            $f.is_quoted       or last;
            $!io.defined       or return parse_error (2027);

            my $str = $!io.get;
            unless ($str.defined) {
                parse_error (2027);
                $!eof = True;
                return False;
                }

            @ch = chunks ($str, $chx);
            $i = 0;
            };

#       !$!binary && $f.is_binary and
#           return parse_error ($f.is_quoted ?? 2026 !! 2037);

        parse_done ();
        } # parse

    method !row_hr (@row) {
        my @cn  = (@!crange ?? @!cnames[@!crange] !! @!cnames);
        hash @cn Z @row;
        }

    multi method getline_hr (Str $str, Bool :$meta = $!keep_meta) {
        @!cnames.elems or self!fail (3002);
        self!row_hr (self.getline ($str, :$meta));
        } # getline_hr

    multi method getline_hr (IO:D $io, Bool :$meta = $!keep_meta) {
        @!cnames.elems or self!fail (3002);
        self!row_hr (self.getline ($io,  :$meta));
        } # getline_hr

    multi method getline (Str $str, Bool :$meta = $!keep_meta) {
        self.parse ($str) or return ();
        $meta ?? self.fields !! self.list;
        } # getline

    multi method getline (IO:D $io, Bool :$meta = $!keep_meta) {
        my Bool $chomped = $io.chomp;
        my Str  $nl      = $io.nl;
        $!eol.defined  and $io.nl = $!eol;
        $io.chomp = False;
        $!io = $io;
        self.parse ($io.get);
        $!io =  IO;
        $io.nl    = $nl;
        $io.chomp = $chomped;
        $meta ?? self.fields !! self.list;
        } # getline

    method getline_hr_all (IO:D  $io,
                           Int   $offset =  0,
                           Int   $length = -1,
                           Bool :$meta   = False) {
        @!cnames.elems or self!fail (3002);
        self.getline_all ($io, $offset, $length, :$meta, hr => True);
        }

    method !row (Bool:D $meta, Bool:D $hr) {
        my @row = $meta ?? self.fields !! self.list;
        if ($hr) {
            my @cn = (@!crange ?? @!cnames[@!crange] !! @!cnames);
            my %hash = @cn Z @row;
            return { %hash };
            }
        [ @row ];
        }

    # @a = $csv.getline_all ($io);
    # @a = $csv.getline_all ($io, $offset);
    # @a = $csv.getline_all ($io, $offset, $length);
    method getline_all (IO:D  $io,
                        Int   $offset is copy =  0,
                        Int   $length is copy = -1,
                        Bool :$meta = $!keep_meta,
                        Bool :$hr   = False) {
        my Bool $chomped = $io.chomp;
        my Str  $nl      = $io.nl;
        $!eol.defined  and $io.nl = $!eol;
        $io.chomp        = False;
        $!io             = $io;
        $!record_number  = 0;

        my @lines;
        if ($offset >= 0) {
            while (self.parse ($io.get)) {
                !$!rrange || $!rrange.in ($!record_number - 1) or next;

                $offset--  > 0 and next;
                $length-- == 0 and last;

                !%!callbacks{"filter"}.defined ||
                    %!callbacks{"filter"}.(self, @!fields) or next;

                @lines.push: self!row ($meta, $hr);
                }
            }
        else {
            $offset = -$offset;
            while (self.parse ($io.get)) {
                !%!callbacks{"filter"}.defined ||
                    %!callbacks{"filter"}.(self, @!fields) or next;

                @lines.elems == $offset and @lines.shift;
                @lines.push: self!row ($meta, $hr);
                }
            $length >= 0 && @lines.elems > $length and @lines.splice ($length);
            }

        $!io =  IO;
        $io.nl    = $nl;
        $io.chomp = $chomped;
        @lines;
        }

    method fragment (IO:D $io, Str:D $spec is copy, Bool :$meta = $!keep_meta) {

        self.rowrange (Str);
        self.colrange (Str);

        if ($spec ~~ s:i{^ "row=" } = "") {
            self.rowrange ($spec);
            return self.getline_all ($io, :$meta);
            }

        if ($spec ~~ s:i{^ "col=" } = "") {
            self.colrange ($spec);
            return self.getline_all ($io, :$meta);
            }

        $spec ~~ s:i{^ "cell=" } = "" or self!fail (2013);

        my CellSet $cs = CellSet.new;
        # cell=1,1-2,2;3,3-4,4;1,4;4,1
        for $spec.split (/ ";" /) -> $r {
            $r ~~ /^     (<[0..9]>+)         ","  (<[0..9]>+)
                   ["-" [(<[0..9]>+)||("*")] "," [(<[0..9]>+)||("*") ]]?
                   $/ or self!fail (2013);
            my Int $tlr = +$0;
            my Int $tlc = +$1;
            my Str $Brr = ($2 // $tlr).Str;
            my Str $Brc = ($3 // $tlc).Str;
            my Num $brr = $Brr eq "*" ?? Inf !! (+$Brr).Num;
            my Num $brc = $Brc eq "*" ?? Inf !! (+$Brc).Num;
            $tlr <= $brr && --$tlc <= --$brc or self!fail (2013);
            $cs.add ($tlr, $tlc, $brr, $brc);
            }

        my Bool $chomped = $io.chomp;
        my Str  $nl      = $io.nl;
        $!eol.defined  and $io.nl = $!eol;
        $io.chomp        = False;
        $!io             = $io;
        $!record_number  = 0;

        my @lines;
        while (self.parse ($io.get)) {

            my CSV::Field @f = @!fields[
                (^(@!fields.elems)).grep ({
                    $cs.in ($!record_number, $_) })] or next;

            !%!callbacks{"filter"}.defined ||
                %!callbacks{"filter"}.(self, @f) or next;

            @lines.push: [ $meta ?? @f !! @f.map (*.text) ];
            }

        $!io =  IO;
        $io.nl    = $nl;
        $io.chomp = $chomped;
        @lines;
        }

    multi method print (IO:D $io, *%p) returns Bool {
        @!cnames.elems or self!fail (3009);
        self.print ($io, %p{@!cnames});
        }

    multi method print (IO:D $io,  %c) returns Bool {
        @!cnames.elems or self!fail (3009);
        self.print ($io, [ %c{@!cnames} ]);
        }

    multi method print (IO:D $io, Capture $c) returns Bool {
        self.print ($io, $c.list);
        }

    multi method print (IO:D $io,  @fld) returns Bool {
        self.combine (@fld) or return False;
        $io.print (self.string);
        True;
        }

    multi method print (IO:D $io, *@fld) returns Bool {
        # Temp guard ... I expected *%p sig to be called
        if (@fld[0] ~~ Pair) {
            @!cnames.elems or self!fail (3009);
            my %hash;
            for @fld -> $kv {
                %hash{$kv.key} = $kv.value;
                }
            return self.print ($io, [ %hash{@!cnames} ]);
            }
        self.print ($io, [@fld]);
        }

    method say (IO:D $io, *@f) returns Bool {
        my $eol = $!eol;
        $!eol ||= "\r\n";
        my Bool $state = self.print ($io, |@f);
        $!eol = $eol;
        $state;
        }

    # Only as a method, both in and out are required
    method CSV ( Any    :$in!,
                 Any    :$out!,
                 Any    :$headers  is copy,
                 Str    :$key,
                 Str    :$encoding is copy,
                 Str    :$fragment is copy,
                 Bool   :$strict = False,
                 Bool   :$meta   = False,
                 *%args            is copy) {

        # Aliasses
        #   frag   fragment
        #   enc    encoding
        %args{"frag"}.defined and $fragment ||= %args{"frag"} :delete;
        %args{"enc" }.defined and $encoding ||= %args{"enc"}  :delete;

        # Check csv-only args
        # Hooks
        #   after_in    after-in    after_parse  after-parse
        #   before_out  before-out
        #   filter
        #   error
        #   on_in       on-in
        my Routine $on-in;
        for (%args.keys) -> $k {
            my %hooks;
            if ($k.lc ~~ m{^ "on"     <[-_]>   "in"             $}) {
                $on-in                 = %args{$k} :delete;
                next;
                }
            if ($k.lc ~~ m{^ "after"  <[-_]> ( "parse" | "in" ) $}) {
                %hooks{"after_parse"}  = %args{$k} :delete;
                next;
                }
            if ($k.lc ~~ m{^ "before" <[-_]>   "print"          $}) {
                %hooks{"before_print"} = %args{$k} :delete;
                next;
                }
            if ($k.lc eq "filter") {
                %hooks{"filter"}       = %args{$k} :delete;
                next;
                }
            if ($k.lc eq "error") {
                %hooks{"error"}        = %args{$k} :delete;
                next;
                }
            self.callbacks (%hooks);
            }

        # Rest is for Text::CSV
        self!set-attributes (%args);

        my @in; # Either AoA or AoH

        my IO $io-in;
        # in
        #   parse
        #     "file.csv"                       Str
        #     $io                              IO::Handle
        #     \"str,ing"                       Capture
        #   generate
        #     [["a","b"][1,2],[3,4]]     AoA   Array
        #     [{a=>1,b=>2},{a=>3,b=>4}]  AoH   Array
        #     sub { ... }                      Sub
        #     Supply.new                       Supply
        given ($in.WHAT) {
            when Str {
                $io-in = open $in, :r, chomp => False;
                }
            when IO {
                $io-in = $in;
                }
            when Array {
                $in.list.elems or return;
                given ($in.list[0].WHAT) {
                    when Str {
                        $io-in = IO::String.new ($in.list.join ($!eol // "\n"));
                        }
                    default {
                        @in = $in.list;
                        }
                    }
                }
            when Capture {
                $io-in = IO::String.new ($in.list.map (*.Str).join ($!eol // "\n"));
                }
            when Supply {
                @in = gather while ($in.tap)  -> $r { take $r };
                }
            when Routine {
                @in = gather while  $in()     -> $r { take $r };
                }
            when Any {
                $io-in = $*IN;
                }
            default {
                self!fail (5000);
                }
            }

        my IO  $io-out;
        my Str $tmpfn;
        # out
        #   Array       - return AoA (default)
        #   Hash        - return AoH (headers required)
        #   Str         - return output as Str
        #   "file.csv"  - write to file
        #   $fh         - write to $fh
        #   Supply:D    - emit to Supply
        #   Routine:D   - pass row(s) to Routine
        given ($out.WHAT) {
            when Str {
                ($tmpfn, $io-out) = $out.defined
                    ?? (Str, open $out, :w, chomp => False)
                    !! tempfile;
                }
            when IO {
                $io-out = $out;
                }
            when Any {
                $in ~~ Array and $io-out = $*OUT;
                }
            default {
                self!fail (5001);
                }
            }

        if ($io-in ~~ IO and $io-in.defined) {
            @in = $fragment
                ?? self.fragment    ($io-in, :$meta, $fragment)
                !! self.getline_all ($io-in, :$meta);
            }

        ?$out || ?$tmpfn or return @in;

        {   my $eol = self.eol;
            $eol.defined or self.eol ("\r\n");
            for @in -> @row {
                @!fields = @row[0] ~~ CSV::Field
                    ?? @row
                    !! @row.map ({ CSV::Field.new.add ($_.Str); });
                $io-out.print (self.string);
                }
            self.eol ($eol);
            }

        if (?$tmpfn) {
            $io-out.close;
            my $fh = open $tmpfn, :r, chomp => False;
            return $fh.slurp-rest;
            }

        True;
        }

    method csv ( Any       :$in,
                 Any       :$out,
                 Any       :$headers,
                 Str       :$key,
                 Str       :$encoding,
                 Str       :$fragment,
                 Bool      :$meta = $!keep_meta,
                 Text::CSV :$csv  = self || Text::CSV.new,
                 *%args ) {

        $csv.CSV (:$in, :$out, :$headers, :$key, :$encoding, :$fragment, :$meta, |%args);
        }
    }

sub csv (*%args) is export {
    %args{"meta"} //= False;
    Text::CSV.csv (|%args);
    }

1;
