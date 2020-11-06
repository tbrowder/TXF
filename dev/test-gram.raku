#!/usr/bin/env raku

# use the t/data/*txf file for input
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


