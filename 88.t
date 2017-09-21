#!perl6

use v6;

use Test;

for ^2048 {

    #say "";
    #say $_;

    my @data = ^20 .map({ 255.rand.Int }).list;
    @data.unshift: 61;

    #dd @data;

    my $b = Buf.new(@data);

    ok((my Str $u = $b.decode("utf8-c8")), "decode");

    my @back = $u.encode("utf8-c8").list;

    #dd @back;

    my $n = Buf.new(@back);

    is-deeply($n, $b, "Data");
    }
