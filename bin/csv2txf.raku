#!/usr/bin/env raku

use lib <./lib>;
use TXF;

my $tax-year = '2019';

# use real data:
my $rdir = './t/data';

# the real data in various formats:
# as downloaded and named:
my @f;
@f[1] = "{$rdir}/R8949_999999999_20190101_20191231.txt"; # really tsv
@f[2] = "{$rdir}/RC_999999999_20190101_20191231.tsv";

# downloaded as xlsx and converted to plain csv:
my $rdir2 = "{$rdir}/xlsx/csv";
@f[3] = "{$rdir2}/R1099_999999999_20190101_20191231.csv";
@f[4] = "{$rdir2}/R8949_999999999_2019.csv";
@f[5] = "{$rdir2}/RC_999999999_20190101_20191231.csv";

my $fnum  = 1;
my $all   = 0;
my $help  = 0;
my $debug = 0;
if !@*ARGS.elems {
    say qq:to/HERE/;
    Usage: {$*PROGRAM.basename} 1|2|3|4|5|all|help [debug help]

    Converts the input CSV file to a TXF file.
    Runs with the following inputs with an argument of 1:
        tax-year: $tax-year
        csv file: {@f[1].IO.basename}
    Output is to STDOUT.
    HERE
    exit;
}

for @*ARGS {
    when /^ h / {
        $help  = 1;
    }
    when /^ (\d+) / {
        my $n = +$0;
        if $n > 0 and $n < 6 {
            $fnum = $n;
            $all  = 0;
        }
        else {
            die "FATAL: Unknown arg '$_'";
        }
    }
    when /^ a / {
        $all  = 1;
        $fnum = 0;
    }
    when /^ d / {
        $debug = 1;
    }
    default {
        die "FATAL: Unknown arg '$_'";
    }
}

if $help {
    say "The following input files are available:";
    say "    {$_.IO.basename}" for @f[1..5];
    exit;
}

if not $fnum and not $all {
    die "FATAL: No valid option entered";
}

if $fnum {
    convert-csv @f[$fnum], :$tax-year, :$date, :$debug;
    exit;
}

# $all must be true:
for @f[1..5] -> $f {
    convert-csv $f, $tax-year, $date, :$debug;
}
