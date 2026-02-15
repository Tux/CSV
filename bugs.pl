#!/pro/bin/perl

use 5.18.0;
use warnings;
use Term::ANSIColor;

sub usage {
    my $err = shift and select STDERR;
    say "usage: $0 [--test]";
    exit $err;
    } # usage

use Getopt::Long qw(:config bundling);
GetOptions (
    "help|?"      => sub { usage (0); },
    "s|summary!"  => \ my $opt_s,
    "v|verbose:1" => \(my $opt_v = 0),
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

sub test {
    my ($re, $p, @arg) = @_;

    $opt_v > 2 and say "Writing test file $t ...";
    open my $fh, ">", $t or die "$t: $!\n";
    print $fh $p;
    close $fh;

    my $exit;
    eval {
        local $SIG{ALRM} = sub {
            open my $fh, ">", $e;
            print $fh "TIMEOUT\n";
            close $fh;
            };
        alarm (3);
        my $cmd = "raku -Ilib -I. $t @arg >$e 2>&1";
        $opt_v > 1 and say $cmd;
        system $cmd;
        $exit = $?;
        alarm (0);
        };
    my $E = do { local (@ARGV, $/) = $e; <> };
    (my $P = $E) =~ s{^}{  }gm;
    $P =~s/[\s\r\n]+\z//;
    $opt_v and say "Expected: $re\nGot     : $E\n";
    my $fail = $E =~ $re || $exit || $E =~ m/(?:Error while compiling|===SORRY!===)/;
    if ($opt_s) {
        my $color = $fail ? 31 : 32;
        (my $msg = $title) =~ s/34m/${color}m/;
        say $msg;
        return;
        }
    printf "\n  --8<--- %s\n%s\n(exit: $exit)\n  -->8---\n", $fail
        ? colored (["red"  ], "BUG")
        : colored (["green"], "Fixed"), $P;
    alarm (0);
    } # test

{   title "Scope", "class variables cannot be used in regex", "issue#3430";#"RT#122892";
    # https://rt.perl.org/Ticket/Display.html?id=122892
    # https://github.com/Raku/old-issue-tracker/issues/3430
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

      c.new.bar("baz").raku.say;
      c.new.bux("baz").raku.say;
EOP
    }

{   title "Operation", "s{} fails on native type (int)", "issue#3645";#"RT#123597";
    # https://rt.perl.org//Public/Bug/Display.html?id=123597 
    # https://github.com/Raku/old-issue-tracker/issues/3645
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
          q{my @x = ("foo",1,Nil,2,"a","",3); @x.raku.say});
    }

{   title "Test", "Compare to undefined type", "issue#3700";#"RT#123924";
    # https://rt.perl.org//Public/Bug/Display.html?id=123924 
    # https://github.com/Raku/old-issue-tracker/issues/3700

    # Failed test at lib/Test.pm line 110
    # expected: something with undefine
    #      got: something with undefine
    test (qr{expected:},
          q{use Test;my Str $s;is($s, Str, "");});
    }

{   title "IO", "Cannot change nl-in", "issue#3693";#"RT#123888";
    # https://rt.perl.org//Public/Bug/Display.html?id=123888 
    # https://github.com/Raku/old-issue-tracker/issues/3693

    open my $fh, ">", "xx.txt";
    print $fh "A+B+C+D+";
    close $fh;
    test (qr{A\+B\+C\+D\+},
          q{$*ARGFILES.nl-in="+";.say for lines():eager},
          "xx.txt");
    }

{   title "IO", "Cannot clear \$*OUT.nl-out", "issue#3715";#"RT#123978";
    # https://rt.perl.org//Public/Bug/Display.html?id=123978 
    # https://github.com/Raku/old-issue-tracker/issues/3715

    # Invalid string index: max 4294967295, got 4294967295
    #   in block  at src/gen/m-CORE.setting:16933
    #   in block <unit> at t23114.pl:1
    test (qr{index:},
          q{$*OUT.nl-out = ""});
    }

{   title "Scope", "* does not allow // in map", "issue#3717";#"RT#123980";
    # https://rt.perl.org//Public/Bug/Display.html?id=123980 
    # https://github.com/Raku/old-issue-tracker/issues/3717

    # Returns (Str) instead of "-"
    test (qr{Str},
          q{(1,Str,"a").map(*//"-")[1].say});
    }

#   title "Range", "plan is not lazy", "RT#124059";

{   title "Type", "Int \$i cannot be Int.Range.max", "issue#520";#"RT#61602"; # RT#124082
    # https://rt.perl.org//Public/Bug/Display.html?id=61602
    # https://github.com/Raku/old-issue-tracker/issues/520

    # Type check failed in assignment to '$i'; expected 'Int' but got 'Num'
    #   in block <unit> at t4156.pl:1
    test (qr{expected '?Int'? but got '?Num'?},
          q{my Int $i = Int.Range.max});
    }

{   title "Exception", "For loop fails to CATCH exception", "issue#3759";#"RT#124191";
    # https://rt.perl.org//Public/Bug/Display.html?id=124191
    # https://github.com/Raku/old-issue-tracker/issues/3759

    # OH NOES
    #    in block  at -e:1
    test (qr{OH NOES},
          q{class C is Exception { method message { "OH NOES" } }; for ^208 { { die C.new; CATCH { default {} } }; print "" }});
    }

#{  title "Precomp", "Precompilations causes segfault", "RT#124298";
#   qx{mkdir -p blib/lib/IO};
#   qx{raku --target=mbc --output=blib/lib/IO/String.pm.moarvm lib/IO/String.rakumod};
#   qx{mkdir -p blib/lib/Text};
#   qx{raku -Iblib/lib --target=mbc --output=blib/lib/Text/CSV.rakumod.moarvm lib/Text/CSV.rakumod};
#   ^^^^ Could not find IO::String at line 6
#   test (qr{Segmentation fault},
#         q{use lib "blib/lib"; use Text::CSV; my $c = Text::CSV.new});
#   qx{find blib};
#   qx{rm -rf blib};
#   }

{   title "MoarVM", "Read bytes too often", "issue#3795";#"RT#124394";
    # https://rt.perl.org//Public/Bug/Display.html?id=124393
    # https://github.com/Raku/old-issue-tracker/issues/3795

    test (qr{\+\+},
          q{my$fh=open "t.csv",:w;$fh.print("+");$fh.close;$fh=open "t.csv",:r;$fh.get.raku.say;});
    }

{   title "IO", "Mangle CRNL", "issue#5082";#"RT#127358";
    # https://rt.perl.org//Public/Bug/Display.html?id=127358
    # https://github.com/Raku/old-issue-tracker/issues/5082

    test (qr{\\\\r\\\\n\\n}, # should be \\\\r\\\\n\\r\\n
          q{my$fh=open "crnl.csv",:r,:!chomp;$fh.get.raku.say;});
    }

{   title "Encoding", "utf8-c8", "-";
    test (qr{^Exit [1-9]},
          q{my Str$s=Buf.new(^2048 .map({256.rand.Int})).decode("utf8-c8") for 1..1024});
    }
