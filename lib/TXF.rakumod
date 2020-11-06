unit module TXF;

use Text::CSV::LibCSV;
use Text::Utils :normalize-string;
use Config::TOML;

use TXF::CVS2TXF;

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

sub cvs-delim($cvs-fname) {
    # given a CVS type file, guess the delimiter
    # from the extension
    my $delim = ','; # default
    if $cvs-fname ~~ /'.csv'$/ {
        ; # ok, default
    }
    elsif $cvs-fname ~~ /'.tsv'$/ {
        $delim = "\t";
    }
    elsif $cvs-fname ~~ /'.txt'$/ {
        $delim = "\t";
    }
    elsif $cvs-fname ~~ /'.psv'$/ {
        $delim = '|';
    }
    else {
        die "FATAL: Unable to handle 'csv' delimiter for file '{$cvs-fname.IO.basename}'";
    }
    return $delim;
}

sub csvhdrs2irs($cvsfile --> Hash) {
    # given a CVS file with headers, map the appropriate
    # header to the IRS field name

    # get the field names from the first row of the file
    my $delim = cvs-delim $cvsfile;
    my Text::CSV::LibCSV $parser .= new(:auto-decode('utf8'), :delimiter($delim));
    my @rows = $parser.read-file($cvsfile);
    my @fields = @(@rows[0]);
    my $len = @fields.elems;

    # make sure the headers are normalized before assembling
    # into a check string
    my $fstring = '';
    for 0..^$len -> $i {
        @fields[$i] = normalize-string @fields[$i];
        $fstring ~= '|' if $i;
        $fstring ~= @fields[$i];
    }

    # check the field string against known formats
    my %irsfields = find-known-formats $fstring, $cvsfile;
    if not %irsfields.elems {
        # we must abort unless we can get an alternative
        # by allowing the user to provide a map in an input
        # file
    }
    return %irsfields;
}

sub find-known-formats($fstring, $cvsfile --> Hash) {
}

sub Date2date(Date $d --> Str) {
    # convert a Date object to mm/dd/yyyy string format
    return {sprintf "%02d/%02d/%04d", $d.month, $d.day, $d.year};
}

sub date2Date(Str $date --> Date) {
    # date is expected in format: mm/dd/yyyy
    #   but it may be in other, similar formats
    # convert to and return a Date object
    # TODO simplify and make more robust
    my $dt;
    my ($year, $month, $day) = <9999 01 01>;
    if $date ~~ /(\d\d) '/' (\d\d) '/' (d\d\d\d) / {
        $month = ~$0;
        $day   = ~$1;
        $year  = ~$2;
    }
    elsif $date ~~ /(\d\d\d\d) '-' (\d\d) '-' (d\d) / {
        # the preferred ISO format
        my $year  = ~$0;
        my $month = ~$1;
        my $day   = ~$2;
    }
    elsif $date ~~ /(\d\d\d\d) '/' (\d\d) '/' (d\d) / {
        $year  = ~$0;
        $month = ~$1;
        $day   = ~$2;
    }
    elsif $date ~~ /(\d\d\d\d) '.' (\d\d) '.' (d\d) / {
        $year  = ~$0;
        $month = ~$1;
        $day   = ~$2;
    }
    else {
        note "Unexpected date string '$date', expected a variation of 'mm/dd/yyyy' format";
    }
    return Date.new: {sprintf "%04d-%02d-%02d", $year, $month, $day};
}

sub convert-txf($f, :$tax-year!, :$debug) is export {
    my Date $date = DateTime.now.Date;

}

sub convert-cvs($f, $tax-year!, :$debug) is export {
    my Date $date = DateTime.now.Date;
}

sub get-txf-transactions($filename, :$debug) {
    
}

sub get-cvs-transactions($filename, :$debug) {

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
CVS file and map its appropriate field name to the IRS name on the
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

=begin comment
    my $FIRST-LINE = [
        'Security', 'Trans type', 'Qty', 'Open date', 'Adj cost',
        'Close date', 'Adj proceeds', 'Adj gain($)', 'Adj gain(%)',
        'Term'].join(',');

    my $TRANSACTION-TYPE = 'Trans type';

    method name {
        return "TD Ameritrade"
    }

    method buyDate(#$cls,
                   %dict) {
        #"""Returns date of transaction as datetime object."""
        # Our input date format is MM/DD/YYYY.
        my $date = %dict<Open date>;
        return date2Date($date);
        #return datetime.strptime(%dict<Open date>, '%m/%d/%Y')
    }

    method sellDate(#$cls,
                    %dict) {
        #"""Returns date of transaction as datetime object."""
        # Our input date format is MM/DD/YYYY.
        my $date = %dict<Close date>;
        return date2Date($date);
        #return datetime.strptime(dict['Close date'], '%m/%d/%Y')
    }

    method isShortTerm(#$cls,
                       %dict) {
        return %dict<Term> eq 'Short-term'
    }

    method symbol(#$cls,
                  %dict) {
        my $security = %dict<Security>;
        if $security ~~ /^ .* '(' (.*) ')' $/ {
            return ~$0
        }
        else {
            my $s = %dict.Str;
            die "Security symbol not found in: $s"
        }

        =begin comment
        match = re.match('^.*\((.*)\)$', dict['Security'])
        if match {
            return match.group(1)
        }
        else {
            die('Security symbol not found in: %s' % dict)
        }
        =end comment
    }

    method numShares(#$cls,
                     %dict) {
        return %dict<Qty>
    }

    method costBasis(#$cls,
                     %dict) {
        # Proceeds amount may include commas as thousand separators, which
        # Decimal does not handle.
        my $adjcost = %dict<Adj cost>;
        $adjcost ~~ s:g/','//;
        return $adjcost;
        #return Decimal(dict['Adj cost'].replace(',', ''))
    }

    method saleProceeds(#$cls,
                        %dict) {
        # Proceeds amount may include commas as thousand separators, which
        # Decimal does not handle.
        my $adjproceeds = %dict<Adj proceeds>;
        if not $adjproceeds {
            die "Unknown adjproceeds '$adjproceeds'";
        }

        $adjproceeds ~~ s:g/','//;
        return $adjproceeds;
        #return Decimal(dict['Adj proceeds'].replace(',', ''))
    }

    method parseFileToTxnList(#$cls,
                              $filename,
                              $tax-year) {

        # guess delimiter from file extension?
        my $delim = cvs-delim $filename;
        my Text::CSV::LibCSV $parser .= new(:auto-decode('utf8'), :delimiter($delim));
        my @txns = $parser.read-file($filename);

        if 0 {
            # debugging
            for @txns {
                my $s = @($_).join(',');
                say $s;
            }
            die "debug early exit";
        }

        my $line-num = 0;
        my @txn-list = [];
        # the header row
        my @headers;
        my $len;
        for @txns -> $row {
            ++$line-num;
            if $line-num == 1 {
                @headers = @($row); # an array of cells
                $len = @headers.elems;
                # make sure the headers are normalized
                for 0..^$len -> $i {
                    @headers[$i] = normalize-string @headers[$i];
                }
                if 1 {
                    # debug
                    say "{$filename.IO.basename}";
                    for 0..^$len -> $i {
                        print '|' if $i;
                        print @headers[$i];
                    }
                    print "\n";
                    die "DEBUG early exit";
                }
                next; # continue
            }

            my %txn-dict;
            my @cells = @($row);
            for 0..^$len -> $i {
                my $header = @headers[$i];
                my $val = @cells[$i];
                $val = normalize-string $val;
                %txn-dict{$header} = $val;
            }

            =begin comment
            for i in range(0, len(names)):
                %txn-dict[names[i]] = row[i]
            }
            =end comment

            if %txn-dict<Security> eq 'Total:' {
                # This is the summary line where the string 'Total:' appears in
                # the first column, so we're done.
                last; # break
            }

            my $curr-txn = Transaction.new;
            $curr-txn.desc = "{self.numShares(%txn-dict)} shares {self.symbol(%txn-dict)}";

            $curr-txn.buyDate      = self.buyDate(%txn-dict);
            $curr-txn.buyDateStr   = txfDate($curr-txn.buyDate);
            $curr-txn.costBasis    = self.costBasis(%txn-dict);
            $curr-txn.sellDate     = self.sellDate(%txn-dict);
            $curr-txn.sellDateStr  = txfDate($curr-txn.sellDate);
            $curr-txn.saleProceeds = self.saleProceeds(%txn-dict);

            #assert $curr-txn.sellDate >= $curr-txn.buyDate;
            if self.isShortTerm(%txn-dict) {
                # TODO(mbrukman): assert here that (sellDate - buyDate) <= 1 year
                $curr-txn.entryCode = 321;  # "ST gain/loss - security"
            }
            else {
                # TODO(mbrukman): assert here that (sellDate - buyDate) > 1 year
                $curr-txn.entryCode = 323;  # "LT gain/loss - security"
            }

            if $tax-year and $curr-txn.sellDate.year ne $tax-year {
                note qq:to/HERE/;
                Warning: 'ignoring txn: "{$curr-txn.desc}" (line $line-num) as the sale is not from $tax-year
                HERE
                =begin comment
                utils.Warning('ignoring txn: "%s" (line %d) as the sale is not from %d\n' %
                              ($curr-txn.desc, $line-num, $tax-year));
                =end comment
                next; # continue
            }

            @txn-list.push($curr-txn);
        }

        return @txn-list
    }
}





grammar TXF-grammar {
    my @header-field-codes = <V A D>;
    my @record-field-codes = <T N C L P D $>;

    token header-field-code { @header-field-codes }
    token record-field-code { @record-field-codes }    
    token end-of-record     { '^' }
    token header-field      { ^ <header-field-code> $<value>=\N* $ }
    token record-field      { ^ <record-field-code> $<value>=\N* $ }

    token separation { \s* }

    # a header is a collection of the three header fields in a 
    # specific order possibly interspersed with blank lines
    token header {
        <header-field>+
    }

    # a record is a certain collection of fields possibly interspersed
    # with blank lines
    token record {
        <record-field>Â
    }

    token TOP { 
        <.separation>
        <header> \s* <record>+ 
    }



}
