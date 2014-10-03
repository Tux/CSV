use v6;

class CSV::Field {

    has Str  $.text		is rw;
    has Bool $.is_quoted	is rw = False;
    has Bool $.is_binary	is rw = False;
    has Bool $.is_utf8		is rw = False;

    enum Type < NA INT NUM STR BOOL >;

    method add (Str $chunk) {
        $.text ~= $chunk;
        } # add

    } # CSV::Field

class Text::CSV {

    has Str  $.eol                 is rw;		# = ($*IN.newline),
    has Str  $.sep                 is rw = ',';
    has Str  $.quo                 is rw = '"';
    has Str  $.esc                 is rw = '"';

    has Bool $.binary              is rw = True;	# default changed
    has Bool $.decode_utf8         is rw = True;
    has Bool $.auto_diag           is rw = False;
    has Bool $.diag_verbose        is rw = False;

    has Bool $.blank_is_undef      is rw = False;
    has Bool $.empty_is_undef      is rw = False;
    has Bool $.allow_white_space   is rw = False;
    has Bool $.allow_loose_quotes  is rw = False;
    has Bool $.allow_loose_escapes is rw = False;
    has Bool $.always_quote        is rw = False;
    has Bool $.quote_space         is rw = True;
    has Bool $.quote_null          is rw = True;
    has Bool $.quote_binary        is rw = True;
    has Bool $.keep_meta_info      is rw = False;
    has Bool $.verbatim            is rw;		# Should die!

    has @!fields;
    has @!types;
    has @!callbacks;

    method parse (Str $buffer) {

        my     $field;
        my Int $pos   = 0;

        my sub store () {
            @!fields.push($field);
            $field = Nil;
	    }

        my sub parse_error (Str $reason, *@args) {
            my $msg = $reason.sprintf(@args);
            die "$msg\n$buffer\n" ~ ' ' x $pos ~ "^\n";
            }

        @!fields = Nil;

        say $buffer.perl;
        for split(rx{ $!eol | $!sep | $!quo | $!esc }, $buffer, :all) {
	    .say;
            $pos += .length;
            }
        } # parse

    method getline () {
        return @!fields;
	} # getline
    }

sub MAIN () {

    my $csv_parser = Text::CSV.new;

    say $csv_parser.perl;
    $csv_parser.parse(q{ab,cde,,1,"q",});
        #say $csv_parser.getline().perl;
    }

#
#{   local $/ = $eol;
#    my @field;
#    my $field;
#    # split - and keep - on special sequences
#    while (my @chunks = split m{ ( $eol | $sep | $quo | $esc ) } => <$fh>) {
#        foreach my $chunk (@chunk) {
#            if ($chunk eq $eol) {
#                if ($field.quoted) {
#                    $field.add ($chunk)
#                    next;
#                    }
#                $field.defined or push @fields, $field;
#                return @fields;
#                }
#            if ($chunk eq $sep) {
#                if ($field.quoted) {
#                    $field.add ($chunk)
#                    next;
#                    }
#                push @fields, $field;
#                undef $field;
#                next;
#                }
#            if ($chunk eq $quo) {
#                if (!defined $field) {
#                    $field = "";
#                    $field.set_quoted;
#                    next;
#                    }
#                # moeilijke code als omschreven in flow
#                # deal with esc eq sep
#                next;
#                }
#            if ($chunk eq $esc) {
#                ...
#                next;
#                }
#            $field.add ($chunk);
#            }
#        }
#    }
