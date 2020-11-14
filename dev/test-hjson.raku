#!/usr/bin/env raku

use JSON::Hjson;

my $file = "../resources/irs-forms.hjson";

my %h = from-hjson slurp($file);
say %h.gist;
