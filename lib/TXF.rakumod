unit module TXF;

use Text::CSV::LibCSV;
use Text::Utils :normalize-string;
use Config::TOML;

use TXF::Utils;
use TXF::CSV2TXF;

constant $END-RECORD  = '^';
constant $TXF-VERSION = '042'; # TXF format version

=begin comment
V0[version]                                     V042
A[application]                                  ATax Tool
D[date of export]                               D02/11/2006

Header	[V-A-D-^]
Records	[T-N-C-L-P-D-D-$-$-$-^]
=end comment

constant %RECORD-IDS = [
    # The key is the leading field code, its value is number of the fields allowed per record.
    # There are more field codes but they will be added as I discover
    # them.

    # There are other rules that need to be handled before final testing.
    T   => 1,
    N   => 1,
    C   => 1,
    L   => 1,
    P   => 1,
    D   => 2,
    '$' => 2,
];


class TXF-field {
    has $.id      is rw;
    has $.value   is rw;
    has $.linenum is rw;

    method write($fh, :$debug) {
        $fh.print: self.id;
        $fh.say:   self.value;
    }
}

class TXF-record {
    # has various fields and some can be repeated
    # records are terminated with a carat character
    has           $.linenum is rw = -1;
    has TXF-field @.fields  is rw;

    method write($fh, :$debug) {
        for @.fields -> $field {
            $field.write: $fh;
        }
    }
}

class TXF-file {
    # has some headers
    has $.V is rw; # throw if value is not '042'
    has $.A is rw;
    has $.D is rw;

    has TXF-record @.records is rw;

    method write-file($f, :$create, :$debug) {
        my $fh = open $f, :w, :create;
        for @.records -> $rec {
            $rec.write: $fh;
        }
    }

    method read-file($f, :$debug) {
        my $in-record   = 0;
        my $has-headers = 0;
        my $num-headers = 0; # should have 3
        my $curr-rec    = 0; # hold the current record object
        my $lnum        = 0;
        LINE: for $f.IO.lines -> $line is copy {
            ++$lnum;
            # skip blank lines
            next LINE if $line !~~ /\S/;

            # get the first char
            my @c = $line.comb;
            my $c = @c.shift;
            # ^ is end of the record
            if $c eq $END-RECORD {
                # check error conditions
                if not $in-record {
                    die "end of record flag without being in a record on line $lnum of file $f";
                }
                if $has-headers {
                    # there should be a curr-rec
                    self.records.push: $curr-rec;
                    $curr-rec = 0;
                }
                $in-record = 0;
                next LINE;
            }

            #=======================================================
            # at this point we should be in or starting a new record
            my $val = @c.join;
            #=======================================================

            #=======================================================
            # is it a header?
            if not $has-headers {
                # handle and go to next line
                if $c eq 'V' {
                    die "duplicate header flag $c on line $lnum of file $f" if self.V;
                    if $val ne $TXF-VERSION {
                        die "non-current TXF version number $val (expected '$TXF-VERSION') on line $lnum of file $f";
                    }
                    self.V = $val;
                }
                elsif $c eq 'A' {
                    die "duplicate header flag $c on line $lnum of file $f" if self.A;
                    self.A = $val;
                }
                elsif $c eq 'D' {
                    die "duplicate header flag $c on line $lnum of file $f" if self.D;
                    self.D = $val;
                }
                else {
                    die "unknown header flag $c on line $lnum of file $f";
                }
                ++$num-headers; # should have 3
                if $num-headers > 3 {
                    die "more than 3 header records with header flag $c on line $lnum of file $f";
                }
                next LINE
            }

            #=======================================================
            # now we must be in a transaction record
            if not $curr-rec {
                $curr-rec = TXF-record.new;
            }
            # assign the field to the current record
            my $field      = TXF-field.new;
            $field.id      = $c;
            $field.linenum = $lnum;
            $field.value   = $val;


        }

    }

}

sub csv-delim($csv-fname) {
    # given a CSV type file, guess the delimiter
    # from the extension
    my $delim = ','; # default
    if $csv-fname ~~ /'.csv'$/ {
        ; # ok, default
    }
    elsif $csv-fname ~~ /'.tsv'$/ {
        $delim = "\t";
    }
    elsif $csv-fname ~~ /'.txt'$/ {
        $delim = "\t";
    }
    elsif $csv-fname ~~ /'.psv'$/ {
        $delim = '|';
    }
    else {
        die "FATAL: Unable to handle 'csv' delimiter for file '{$csv-fname.IO.basename}'";
    }
    return $delim;
}

sub csvhdrs2irs($csvfile --> Hash) {
    # given a CSV file with headers, map the appropriate
    # header to the IRS field name

    # get the field names from the first row of the file
    my $delim = csv-delim $csvfile;
    my Text::CSV::LibCSV $parser .= new(:auto-decode('utf8'), :delimiter($delim));
    my @rows = $parser.read-file($csvfile);
    my @fields = @(@rows[0]);
    my $len = @fields.elems;
    # make sure the headers are normalized before assembling into a check string
    my $fstring = '';
    for 0..^$len -> $i {
        @fields[$i] = normalize-string @fields[$i];
        $fstring ~= '|' if $i;
        $fstring ~= @fields[$i];
    }

    # check the field string against known formats
    my %irsfields = find-known-formats $fstring, $csvfile;
    if not %irsfields.elems {
        # we must abort unless we can get an alternative
        # by allowing the user to provide a map in an input
        # file
    }
    return %irsfields;
}

sub find-known-formats($fstring, $csvfile --> Hash) {
}


sub convert-txf($f, :$tax-year!, :$debug) is export {
    my Date $date = DateTime.now.Date;

}

sub convert-csv($f, $tax-year!, :$debug) is export {
    my Date $date = DateTime.now.Date;
}

sub get-txf-transactions($filename, :$debug) {

}

sub check-field-map(%field-map) {
}

multi write-f8949-pdf(@f8949, 
    :$debug) is export {

    # we write a separate F8949 for each Part I and Part II and their individual
    # boxes A-F. Output file names will be:
    #    taxyear-F8949-PartX-BoxX.pdf
    my @a; # p1boxA;
    my @b; # p1boxB;
    my @c; # p1boxC; # shouldn't have any for the author
    my @d; # p2boxD;
    my @e; # p2boxE;
    my @f; # p2boxF; # shouldn't have any for the author

    if $debug {
        my $n = @f8949.elems;
        say "DEBUG: \@f8949.elems = $n";
    }

    for @f8949 -> $ft {
        say "DEBUG: \$ft is an instance of class {$ft.raku}" if $debug;
    }

    =begin comment
    # separate into parts
    for @f8949 -> $ft {
        say $ft.raku if $debug;
        =begin comment
        if $ft.box eq 'a' {
            @a.push: $ft;
        }
        elsif $ft.box eq 'b' {
            @b.push: $ft;
        }
        elsif $ft.box eq 'c' {
            @c.push: $ft;
        }
        elsif $ft.box eq 'd' {
            @d.push: $ft;
        }
        elsif $ft.box eq 'e' {
            @e.push: $ft;
        }
        elsif $ft.box eq 'f' {
            @f.push: $ft;
        }
        =end comment
    }
    write-f8949-pdf @a, :box<a>, :$debug;
    write-f8949-pdf @b, :box<b>, :$debug;
    write-f8949-pdf @c, :box<c>, :$debug;
    write-f8949-pdf @d, :box<d>, :$debug;
    write-f8949-pdf @e, :box<e>, :$debug;
    write-f8949-pdf @f, :box<f>, :$debug;
    =end comment

}

multi write-f8949-pdf(@f8949, 
                      :$box! is copy, :$debug) {
    my $part = $box ~~ /:i a|b|c/ ?? 'I' !! 'II';
    $box.= uc; 
    my $fname = "F8949-Part{$part}-Box{$box}.pdf";

    if not @f8949.elems {
        say "No Part $part, Box $box transactions found.";
        return;
    }

    my $fh = open $fname, :w;
    for @f8949 -> $ft {
    }
    $fh.close;
    say "See F8949 file: $fname";

}

sub get-csv-transactions($filename,
                         :$config     = "{%*ENV<HOME>}/.TXF/config.toml",
                         :$config-key = 'default-map', # default is 'default-map'
                         :$debug,
#                         --> List
                        ) is export {
    # we need the base config hash
    my %config;
    if $config.IO.f {
        %config = from-toml :file($config);
    }
    else {
        die "FATAL: No CSV field map found.";
    }

    # we need the map of standard fields to the input
    # file's fields
    my $map-key = %config{$config-key};
    my %irs-csv-map = %config{$map-key};
    # make sure we covered all required fields
    # TODO complete the following sub:
    check-field-map %irs-csv-map;
    # get its inverse
    my %csv-irs-map = %irs-csv-map.invert;

    # some other necessary vars
    my $tax-year = %config<tax-year>;
    my $broker   = %config<broker>;

    # read the input file
    # guess delimiter from file extension?
    my $delim = csv-delim $filename;
    my Text::CSV::LibCSV $parser .= new(:auto-decode('utf8'), :delimiter($delim), :has-headers);
    my @rows = $parser.read-file($filename);
    my @F8949-transactions;

    for @rows.kv -> $i, $row {
        my %cells = %($row);
        # skip invalid rows
        next if %cells<Ignore>:exists and %cells<Ignore>;
        # skip empty rows
        next if %cells<Security>:exists and not %cells<Security>;

        say "DEBUG ROW ==========================" if $debug;
        for %cells.kv -> $k, $v is copy {
            $v = normalize-string $v;
            say "DEBUG: key: '$k'; value: '$v'" if $debug;
        }
        last if $debug > 1 and $i > 3;

        my $ft = F8949-transaction.new;
        # for the transaction class object we need another mapping
        # check for all required fields
        
        for %irs-csv-map.kv -> $irs-key, $csv-key {
            say "DEBUG: checking for irs/csv keys '$irs-key' and '$csv-key'..." if $debug;
            if %cells{$csv-key}:exists {
                my $value = %cells{$csv-key};
                $ft.set-attr(:attr($irs-key), :$value); 
                say "  setting irs key to value '$value'" if $debug;
            }
            else {
                die "FATAL: missing cvs key '$csv-key' at line {$i+1}";
            }
        }
        $ft.finish-building: :$debug;
        @F8949-transactions.push: $ft;
    }

    return @F8949-transactions;

=begin comment

The following lines are the headers for the following five file types
from TDAmeritrade as of 2020-11-01 for tax year 2019.

It looks as if we can use parts of the file name to identify the file
without date or account information.

R8949_883226430_20190101_20191231.txt
=====                            ====
Close Date|Rec type|Open Date|Security|Shares Sold|Proceeds|Cost|8949 Code|Gain/Loss Adj|ST/LT|8949 Box|Gain/Loss

RC_883226430_20190101_20191231.tsv
==                            ====
Security|Trans type|Qty|Open date|Cost|Close date|Proceeds|ST gain($)|LT gain($)|OR gain($)

R1099_883226430_20190101_20191231.csv
=====                            ====
SL|ID|Cvrd|8949 Box|Close Date|Sec Type|Tax Class|Symbol|Security ID|CoT|Security Name|Open Date|Open ID|Units|Proceeds|Procds type|Calc Mthd|Cost|MD Gain Adj|Ordinary Gain/Loss|GainLoss 1099B|Term|Deferred loss|s1256 Unrealized Prior Period|s1256 Unrealized|s1256 Realized|s1256 Total|RecType|TrMethod|Settled|Recon Cost|Recon Proceeds|Close Tran Type|Elections|Rec Status|Rec Flags

R8949_883226430_2019.csv
=====               ====
Close Date|Rec type|Open Date|Security|Shares Sold|Proceeds|Cost|Code|Gain/Loss Adjustment|ST/LT|Box|Gain/Loss

RC_883226430_20190101_20191231.csv
==                            ====
Security|Trans type|Qty|Open date|Cost|Close date|Proceeds|ST gain($)|LT gain($)|OR gain($)

One solution is, for each input file, group the common headers to
satisfy the TXF output requirements Create a class or sub to take a
CSV file and map its appropriate field name to the IRS name on the
Form 8949.

That way we can run a data check on the common data among the data
files.

The output data fields will be (based on Form 8949):

  --------------
  security
  quantity sold
  sell date
  sale proceeds
  open date
  LT/ST
  gain

  open date


=end comment

}
