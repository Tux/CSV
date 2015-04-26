#!/pro/bin/perl

use 5.18.0;
use warnings;
use Term::ANSIColor;

sub usage
{
    my $err = shift and select STDERR;
    say "usage: $0 [--test]";
    exit $err;
    } # usage

use Getopt::Long qw(:config bundling);
GetOptions (
    "help|?"      => sub { usage (0); },
    "s|summary!"  => \my $opt_s,
    "v|verbose:1" => \my $opt_v,
    ) or usage (1);

my $t = "t$$.pl";
my $e = "e$$.pl";
END { unlink $t, $e; }

$opt_s and say "Bug summary:";

my $title = "";
{   my $b = 1;
    sub title {
        my ($class, $t, $rt) = @_;
        $title = sprintf "%2d  %-11s %-60s %s",
            $b++, "[$class]",
            colored (["blue"], $t), colored (["blue"], $rt // "");
        $opt_s or say "\n", $title;
        }
    }

sub test
{
    my ($re, $p, @arg) = @_;

    open my $fh, ">", $t or die "$t: $!\n";
    print $fh $p;
    close $fh;

    eval {
        local $SIG{ALRM} = sub {
            open my $fh, ">", $e;
            print $fh "TIMEOUT\n";
            close $fh;
            };
        alarm (3);
        system "perl6 $t @arg >$e 2>&1";
        alarm (0);
        };
    my $E = do { local (@ARGV, $/) = $e; <> };
    (my $P = $E) =~ s{^}{  }gm;
    $P =~s/[\s\r\n]+\z//;
    $opt_v and say "Expected: $re\nGot     : $E\n";
    my $fail = $E =~ $re;
    if ($opt_s) {
        my $color = $fail ? 31 : 32;
        (my $msg = $title) =~ s/34m/${color}m/;
        say $msg;
        return;
        }
    printf "\n  --8<--- %s\n%s\n  -->8---\n", $fail
        ? colored (["red"  ], "BUG")
        : colored (["green"], "Fixed"), $P;
    } # test

{   title "Scope", "class variables cannot be used in regex", "RT#122892";
    # https://rt.perl.org/Ticket/Display.html?id=122892
    # Nil
    # Match.new(orig => "baz", from => 1, to => 2, ast => Any, list => ().list, hash => EnumMap.new())
    test (qr{
        \A Nil
        \n Match
        }x, <<'EOP');
      use v6;

      class c {
            has Str $.foo is rw = "a";

            method bar (Str $s) {
                return $s ~~ / $!foo /;
                }
            method bux (Str $s) {
                my $foo = $!foo;
                return $s ~~ / $foo /;
                }
            }

      c.new.bar("baz").perl.say;
      c.new.bux("baz").perl.say;
EOP
    }

{   title "Operation", "s{} fails on native type (int)", "RT#123597";
    # https://rt.perl.org//Public/Bug/Display.html?id=123597 
    # bar
    # 000:
    # 1x
    # Cannot call 'subst-mutate'; none of these signatures match:
    #   in method subst-mutate at src/gen/m-CORE.setting:4255
    #   in sub foo at t.pl:7
    #   in block <unit> at t.pl:15
    test (qr{
        \A bar
        \n 000:
        \n 1x
        \n Cannot \s+ call \s+ 'subst-mutate'
        }x, <<'EOP');
      use v6;

      sub foo (*@y) {
          for @y {
              s{^(\d+)$} = sprintf "%03d:", $_;
              .say;
              }
          }

      foo("bar");
      foo("0");
      foo("1x");
      foo(0);
EOP
    }

{   title "Scope", "Placeholder variables cannot be used in a method";
    # They work in sub but not in method
    # ===SORRY!=== Error while compiling t.pl
    # Placeholder variables cannot be used in a method
    # at t.pl:16
    test (qr{
        (?-x:Placeholder variables cannot be used in a method)
        }x, <<'EOP');
      use v6;

      class c {
          method foo (*@y) {
              for @y -> $y {
                  $y.say;
                  }
              }
          method bar () {
              for @_ -> $y {  # FAIL
                  $y.say;
                  }
              }
          }

      sub foo (*@y) {
          for @y -> $y {
              $y.say;
              }
          }
      sub bar () {
          for @_ ->$y {      # PASS
              $y.say;
              }
          }

      foo("bux");
      bar("bux");
      c.new.foo("bux");
      c.new.bar("bux");
EOP
    }

{   title "Operation", "++ and += do not work on basic types";

    # Cannot assign to an immutable value
    #   in sub postfix:<++> at src/gen/m-CORE.setting:5082
    #   in block <unit> at t.pl:7
    test (qr{
        (?-x:Cannot assign to an immutable value)
        }x, <<'EOP');
  use v6;

  my int $foo = 1;

  $foo++;
EOP
    }

{   title "Lists", "Nil in list is silently dropped";

    # Array.new("foo", 1, 2, "a", "", 3)
    test (qr{1, 2},
          q{my @x = ("foo",1,Nil,2,"a","",3); @x.perl.say});
    }

{   title "Test", "Compare to undefined type", "RT#123924";

    # Failed test at lib/Test.pm line 110
    # expected: something with undefine
    #      got: something with undefine
    test (qr{expected:},
          q{use Test;my Str $s;is($s, Str, "");});
    }

{   title "IO", "Cannot change input-line-separator", "RT#123888";
    open my $fh, ">", "xx.txt";
    print $fh "A+B+C+D+";
    close $fh;
    test (qr{A\+B\+C\+D\+},
          q{$*IN.input-line-separator="+";.say for lines():eager},
          "xx.txt");
    }

{   title "IO", "Cannot clear \$*OUT.nl", "RT#123978";
    # Invalid string index: max 4294967295, got 4294967295
    #   in block  at src/gen/m-CORE.setting:16933
    #   in block <unit> at t23114.pl:1
    test (qr{index:},
          q{$*OUT.nl = ""});
    }

{   title "Scope", "* does not allow // in map", "RT#123980";
    # Returns (Str) instead of "-"
    test (qr{Str},
          q{(1,Str,"a").map(*//"-")[1].say});
    }

#   title "Range", "plan is not lazy", "RT#124059";

{   title "Type", "Int \$i cannot be Int.Range.max", "RT#124082";
    # Type check failed in assignment to '$i'; expected 'Int' but got 'Num'
    #   in block <unit> at t4156.pl:1
    test (qr{expected 'Int' but got 'Num'},
          q{my Int $i = Int.Range.max});
    }

{   title "Exception", "For loop fails to CATCH exception", "RT#124191";
    # OH NOES
    #    in block  at -e:1
    test (qr{OH NOES},
          q{class C is Exception { method message { "OH NOES" } }; for ^208 { { die C.new; CATCH { default {} } }; print "" }});
    }

{   title "Precomp", "Precompilations causes segfault", "RT#124298";
    qx{mkdir -p blib/lib/Text};
    qx{perl6 --target=mbc --output=blib/lib/Text/CSV.pm.moarvm lib/Text/CSV.pm};
    test (qr{Segmentation fault},
          q{use lib "blib/lib";use Text::CSV; my $c = Text::CSV.new});
    qx{rm -rf blib};
    }

{   title "MoarVM", "Read bytes too often", "RT#124394";
    test (qr{\+\+},
          q{my$fh=open "t.csv",:w;$fh.print("+");$fh.close;$fh=open "t.csv",:r;$fh.get.perl.say;});
    }
