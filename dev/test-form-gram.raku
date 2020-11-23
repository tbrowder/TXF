#!/usr/bin/env raku

use lib <./lib ../lib>;
use TXF::Forms;
use Grammar::Tracer;

# use the ./f8949.data file for input
my $f = './f8949.data';
if not @*ARGS.elems {
    say qq:to/HERE/;
    Usage: {$*PROGRAM.basename} go

    Code to test the Forms grammar, a WIP following JJ's
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

my $a = TXF::Forms::Form-actions.new;
my $m = TXF::Forms::Form-grammar.parsefile($f,
#my $m = TXF::Forms::Form-grammar.subparse(slurp($f),
   #:subparse, 
   :actions($a),
   );

#say $m;
#say $m.raku;
#say $/<field>.raku;
