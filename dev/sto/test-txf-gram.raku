#!/usr/bin/env raku


use lib <./lib>;
use TXF::File;
use Grammar::Tracer;

# use the t/data/*txf file for input
# use real data:
my $rdir = './t/data';
my $f = "{$rdir}/Realized_999999999_2019.txf";
if not @*ARGS.elems {
    say qq:to/HERE/;
    Usage: {$*PROGRAM.basename} go

    Code to test the TXF grammar, a WIP following JJ's
                                    Raku Recipes

    Using file '$f'.
    HERE
    exit;
}

if 0 {
    for $f.IO.lines {
        say $_;
    }
}

if 0 {
    my $g = TXF::Grammar.new;
    say $g.parse: slurp($f);
}

my $m = TXF::File::File-grammar.parse(slurp($f));
say $m.raku;
#say $/<field>.raku;
