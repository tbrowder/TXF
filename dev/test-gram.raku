#!/usr/bin/env raku

use lib <./lib>;
use TXF;

# use the t/data/*txf file for input
# use real data:
my $rdir = './t/data';
my $f = "{$rdir}/Realized_999999999_2019.txf";
if not @*ARGS.elems {
    say qq:to/HERE/;
    Usage: {$*PROGRAM.basename} go

    Code to test the TXF grammar, a WIP following JJ's
    Raku Recipes
    HERE
    exit;
}

=begin comment
Code to test the TXF grammar, a WIP following JJ's
Raku Recipes
=end comment


