#!/usr/bin/env raku

use Config::TOML;

my $file = "{%*ENV<HOME>}/.TXF/config.toml";

my %h = from-toml :$file;

my $key = %h<default-map>;
#say "key = '$key'";

my %hh = %h{$key};
say %hh.raku;


