unit module TXF;

use Text::CSV::LibCSV;
use Text::Utils :normalize-string;

use TXF::CVS2TXF;

constant $END-RECORD = '^';

=begin comment
V0[version]                                     V042
A[application]                                  ATax Tool
D[date of export]                               D02/11/2006
=end comment

class TXF-record {
    # has some headers
    has $.V is rw;
    has $.A is rw;
    has $.D is rw;

    method write($fh, :$debug) {
    }
}

class TXF-file {
    has $.D;

    has @.records;
    
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
        my $curr-rec    = 0;
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

sub convert-txf($f, $tax-year, Date $date, :$debug) is export {
}

sub convert-cvs($f, $tax-year, Date $date, :$debug) is export {
}

sub get-transactions($filename, :$debug) {

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

    method isFileForBroker(#$cls,
                           $filename) {
        my $first-line = $filename.IO.lines[0];
        return $first-line eq $FIRST-LINE;
        =begin comment
        with open(filename) as f {
            first_line = f.readline()
            return first_line == $FIRST_LINE;
        }
        =end comment
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

sub RunConverter($broker-name, $filename, $tax-year, $date) is export {
    # get a $broker class object
    my $broker = GetBroker($broker-name, $filename);
    my @txn-list = $broker.parseFileToTxnList($filename, $tax-year);
    return ConvertTxnListToTxf(@txn-list, $tax-year, $date);
}

sub hasattr($obj,
            $attrname, # e.g., '$!foo' or '@!foo'
           ) {
    my $res = False;
    my %attrs = set $obj.^attributes;
    $res = True if %attrs{$attrname}:exists;
    return $res;
}

sub hasmethod($obj,
              $methname, # e.g., 'isFileForBroker',
             ) {
    if $obj.^can($methname) {
        return True
    }
    else {
        return False
    }
}

sub ConvertTxnListToTxf(@txn-list,
                        $tax-year,
                        $date is copy,
                       ) {
    my @lines;
    @lines.push('V042');      # Version
    @lines.push('Acsv2txf');  # Program name/version
    if not $date {
        #$date = txfDate(datetime.today())
        $date = DateTime.now.sprintf("%02d/%02d/%04d", .month, .day, .year).Str;
    }
    @lines.push('D' ~ $date);  # Export date
    @lines.push('^');
    for @txn-list -> $txn {
        @lines.push('TD');
        @lines.push('N' ~ $txn.entryCode);
        @lines.push('C1');
        @lines.push('L1');
        @lines.push('P' ~ $txn.desc);
        @lines.push('D' ~ $txn.buyDateStr);
        @lines.push('D' ~ $txn.sellDateStr);
        @lines.push(sprintf('$%.2f', $txn.costBasis));
        @lines.push(sprintf('$%.2f', $txn.saleProceeds));
        if $txn.adjustment {
            @lines.push(sprintf('$%.2f', $txn.adjustment));
        }
        @lines.push('^');
    }
    return @lines;
}

#| Returns a date string in the TXF format, which is MM/DD/YYYY.
sub txfDate(Date $date --> Str) {
    return sprintf("%02d/%02d/%04d", $date.month, $date.day, $date.year);
}

sub DetectBroker($filename) {
    for %BROKERS.kv -> $broker-name, $broker {
        if hasmethod($broker, 'isFileForBroker') {
            if $broker.isFileForBroker($filename) {
                return $broker;
            }
        }
    }
    return Nil;
}

sub GetBroker($broker-name is copy, $filename) {
    $broker-name .= lc;
    my $broker;
    if not $broker-name or not %BROKERS{$broker-name}:exists {
        note "DEBUG: using sub DetectBroker";
        $broker = DetectBroker($filename);
    }
    else {
        note "DEBUG: using \%BROKERS hash" if 0;
        $broker = %BROKERS{$broker-name}.new;
        #note "DEBUG broker hash value: '{$broker.raku}'";
    }

    if not $broker {
        die('Invalid broker name: ' ~ $broker-name);
    }

    return $broker;
}







=finish

=begin comment
#=== brokers.py
"""Code for figuring out which broker to use.

To define a new broker:
1) Create a new class and define the following method:
  @classmethod
  def parseFileToTxnList(cls, filename, tax_year):
    Note that if tax_year == None, then all transactions should be accepted.
2) If there is an easy way to determine if a particular file is usable
   by your class, then define the method:
  @classmethod
  def isFileForBroker(cls, filename):
    Note that if this method is not defined, then you may need to modify
    update_testdata.py as well.
3) Add your class to the BROKERS map below.
"""

from interactive_brokers import InteractiveBrokers
from tdameritrade import TDAmeritrade
from vanguard import Vanguard
=end comment

=begin comment

#=== interactive_brokers.py
"""Implements InteractiveBrokers.

Does not handle:
* dividends
"""

import csv
from datetime import datetime
from decimal import Decimal
import utils


FIRST_LINE = 'Title,Worksheet for Form 8949,'

class InteractiveBrokers:
    @classmethod
    def name(cls):
        return 'Interactive Brokers'

    @classmethod
    def DetermineEntryCode(cls, part, box):
        if part == 1:
            if box == 'A':
                return 321
            elif box == 'B':
                return 711
            elif box == 'C':
                return 712
        elif part == 2:
            if box == 'A':
                return 323
            elif box == 'B':
                return 713
            elif box == 'C':
                return 714
        return None

    @classmethod
    def TryParseYear(cls, date_str):
        try:
            return datetime.strptime(date_str, '%m/%d/%Y').year
        except ValueError:
            return None

    @classmethod
    def ParseDollarValue(cls, value):
        return Decimal(value.replace(',', '').replace('"', ''))

    @classmethod
    def isFileForBroker(cls, filename):
        with open(filename) as f:
            first_line = f.readline()
            return first_line.find(FIRST_LINE) == 0

    @classmethod
    def parseFileToTxnList(cls, filename, tax_year):
        f = open(filename)
        # First 2 lines are headers.
        f.readline()
        f.readline()
        txns = csv.reader(f, delimiter=',', quotechar='"')

        txn_list = []
        part = None
        box = None
        entry_code = None

        for row in txns:
            if row[0] == 'Part' and len(row) == 3:
                box = None
                if row[1] == 'I':
                    part = 1
                elif row[1] == 'II':
                    part = 2
                else:
                    utils.Warning('unknown part line: "%s"\n' % row)
            elif row[0] == 'Box' and len(row) == 3:
                if row[1] == 'A' or row[1] == 'B' or row[1] == 'C':
                    box = row[1]
                    entry_code = cls.DetermineEntryCode(part, box)
                else:
                    utils.Warning('unknown box line: "%s"\n' % row)
            elif row[0] == 'Data' and len(row) == 9:
                if not entry_code:
                    utils.Warning(
                        'ignoring data: "%s" as the code is not defined\n')
                    continue
                txn = utils.Transaction()
                txn.desc = row[1]
                txn.buyDateStr = row[3]
                txn.sellDateStr = row[4]
                year = cls.TryParseYear(txn.sellDateStr)
                txn.saleProceeds = cls.ParseDollarValue(row[5])
                txn.costBasis = cls.ParseDollarValue(row[6])
                if row[7]:
                    txn.adjustment = cls.ParseDollarValue(row[7])
                txn.entryCode = entry_code
                if tax_year and year and year != tax_year:
                    utils.Warning('ignoring txn: "%s" as the sale is not from %d\n' %
                                  (txn.desc, tax_year))
                else:
                    txn_list.append(txn)
                txn = None
            elif (row[0] != 'Header' and row[0] != 'Footer') or len(row) != 9:
                utils.Warning('unknown line: "%s"\n' % row)

        return txn_list

#=== interactive_brokers_test.py
"""Tests for interactive_brokers module."""

from datetime import datetime
import glob
import os
import unittest
from interactive_brokers import InteractiveBrokers


class InteractiveBrokersTest(unittest.TestCase):
    def testDetect(self):
        for csv in glob.glob('testdata/*.csv'):
            self.assertEqual(os.path.basename(csv) == 'interactive_brokers.csv',
                             InteractiveBrokers.isFileForBroker(csv))

    def testParse(self):
        data = InteractiveBrokers.parseFileToTxnList(
            'testdata/interactive_brokers.csv', 2011)
        with open('testdata/interactive_brokers.parse') as expected_file:
            for txn in data:
                expected_txn = expected_file.readline().strip()
                self.assertEqual(expected_txn, str(txn))


if __name__ == '__main__':
    unittest.main()
=end comment

=begin comment
#=== tdameritrade.py
"""Implements TD Ameritrade.

TD Ameritrade gain/loss output provides already-reconciled transactions, i.e.,
each buy/sell pair comes in a single record, on a single line.

Does not handle:
* dividends
* short sales
* partial lot sales
"""

import csv
from datetime import datetime
from decimal import Decimal
import re
import utils
=end comment

=begin comment

#=== update_testdata.py
"""Updates the testdata/*.golden files for various brokers.

Re-generates the transactions for each broker and writes them out as ASCII
strings.
"""

import glob
import os
import sys

from brokers import DetectBroker

# If your broker parser does not support isFileForBroker, you'll need
# need to add an entry here.
# Example:
# 'vanguard.csv' : Vanguard
BROKER_CSV = {}


def main(argv):
    for csv in glob.glob('testdata/*.csv'):
        (path, filename) = os.path.split(csv)
        if filename in BROKER_CSV:
            broker = BROKER_CSV[filename]
        else:
            broker = DetectBroker(csv)
        if not broker:
            continue

        golden = csv.replace('.csv', '.parse')
        if not os.access(path, os.W_OK) or (not os.access(golden, os.W_OK) and
                                            os.path.exists(golden)):
            sys.stderr.write('error: %s is not writeable\n' % golden)
            sys.exit(1)

        with open(golden, 'w') as out:
            data = broker.parseFileToTxnList(csv, None)
            for txn in data:
                out.write('%s\n' % str(txn))
            print("Generated: %s from %s" % (golden, csv))


if __name__ == '__main__':
    main(sys.argv)

#=== utils.py
"""Utility methods/classes."""

import sys


class Error(Exception):
    pass


class ValueError(Error):
    def __init__(self, msg):
        self.msg = msg

    def __str__(self):
        return self.msg


class UnimplementedError(Error):
    def __init__(self, msg):
        self.msg = msg

    def __str__(self):
        return self.msg


def Warning(str):
    sys.stderr.write('warning: %s' % str)


class Transaction(object):
    def __init__(self):
        self.desc = None
        self.buyDateStr = None
        self.costBasis = None
        self.sellDateStr = None
        self.saleProceeds = None
        self.adjustment = None
        self.entryCode = None

    def __str__(self):
        data = [
            ('desc:%s', self.desc),
            ('buyDateStr:%s', self.buyDateStr),
            ('costBasis:%.2f', self.costBasis),
            ('sellDateStr:%s', self.sellDateStr),
            ('saleProceeds:%.2f', self.saleProceeds),
            ('adjustment:%.2f', self.adjustment),
            ('entryCode:%d', self.entryCode)
        ]
        formatted_data = [(fmt % value) for (fmt, value) in data if value]
        return ','.join(formatted_data)


def txfDate(date):
    """Returns a date string in the TXF format, which is MM/DD/YYYY."""
    return date.strftime('%m/%d/%Y')


def isLongTerm(buy_date, sell_date):
    # To handle leap years, cannot use a standard number of days, i.e.:
    #   sell_date - buy_date > timedelta(days=365)
    #   - doesn't work for leap years
    #   sell_date - buy_date > timedelta(days=366)
    #   - doesn't work for non-leap years
    if sell_date < buy_date:
        raise ValueError('Sell date before buy date')
    if sell_date.year > buy_date.year + 1:
        return True
    return (sell_date.year == buy_date.year + 1 and
            (sell_date.month > buy_date.month or
             (sell_date.month == buy_date.month and
              sell_date.day > buy_date.day)))

#=== utils_test.py
"""Tests for utils module."""

from datetime import datetime
import unittest
import utils


class UtilsTest(unittest.TestCase):
    def testIsLongTermNonLeapYear(self):
        buy = datetime(2010, 1, 4)
        sell = datetime(2011, 1, 5)
        self.assertTrue(utils.isLongTerm(buy, sell))

    def testIsLongTermLeapYear(self):
        buy = datetime(2008, 1, 4)
        sell = datetime(2009, 1, 4)
        self.assertFalse(utils.isLongTerm(buy, sell))

    def testIsLongTermCorrectOrder(self):
        buy = datetime(2005, 1, 1)
        sell = datetime(2000, 1, 4)
        # TODO: verify error message.
        self.assertRaises(utils.ValueError, utils.isLongTerm, buy, sell)


if __name__ == '__main__':
    unittest.main()

#=== vanguard.py
"""Implements Vanguard.

Assumes reconciled transactions, i.e., sell follows buy.

Does not handle:
* dividends
* short sales
* partial lot sales
"""

import csv
from datetime import datetime
from decimal import Decimal
import utils


FIRST_LINE = ','.join(['"Trade Date"', '"Transaction Type"',
                       '"Investment Name"', '"Symbol"', '"Shares"',
                       '"Principal Amount"', '"Net Amount"\n'])


class Vanguard:
    @classmethod
    def name(cls):
        return 'Vanguard'

    @classmethod
    def isBuy(cls, dict):
        return dict['Transaction Type'] == 'Buy'

    @classmethod
    def isSell(cls, dict):
        return dict['Transaction Type'] == 'Sell'

    @classmethod
    def date(cls, dict):
        """Returns date of transaction as datetime object."""
        # Our input date format is YYYY/MM/DD.
        return datetime.strptime(dict['Trade Date'], '%Y-%m-%d')

    @classmethod
    def symbol(cls, dict):
        return dict['Symbol']

    @classmethod
    def investmentName(cls, dict):
        return dict['Investment Name']

    @classmethod
    def numShares(cls, dict):
        shares = int(dict['Shares'])
        if cls.isSell(dict):
            return shares * -1
        else:
            return shares

    @classmethod
    def netAmount(cls, dict):
        amount = Decimal(dict['Net Amount'])
        if cls.isBuy(dict):
            return amount * -1
        else:
            return amount

    @classmethod
    def isFileForBroker(cls, filename):
        with open(filename) as f:
            first_line = f.readline()
            return first_line == FIRST_LINE

    @classmethod
    def parseFileToTxnList(cls, filename, tax_year):
        txns = csv.reader(open(filename), delimiter=',', quotechar='"')
        row_num = 0
        txn_list = []
        names = None
        curr_txn = None
        buy = None
        sell = None
        for row in txns:
            row_num = row_num + 1
            if row_num == 1:
                names = row
                continue

            txn_dict = {}
            for i in range(0, len(names)):
                txn_dict[names[i]] = row[i]

            if cls.isBuy(txn_dict):
                buy = txn_dict
                curr_txn = utils.Transaction()
                curr_txn.desc = '%d shares %s' % (
                    cls.numShares(buy), cls.symbol(buy))
                curr_txn.buyDate = cls.date(txn_dict)
                curr_txn.buyDateStr = utils.txfDate(curr_txn.buyDate)
                curr_txn.costBasis = cls.netAmount(txn_dict)
            elif cls.isSell(txn_dict):
                sell = txn_dict
                # Assume that sells follow the buys, so we can attach this sale to the
                # current buy txn we are processing.
                assert cls.numShares(buy) == cls.numShares(sell)
                assert cls.symbol(buy) == cls.symbol(sell)
                assert cls.investmentName(buy) == cls.investmentName(sell)

                curr_txn.sellDate = cls.date(sell)
                curr_txn.sellDateStr = utils.txfDate(curr_txn.sellDate)
                curr_txn.saleProceeds = cls.netAmount(sell)

                if utils.isLongTerm(curr_txn.buyDate, curr_txn.sellDate):
                    curr_txn.entryCode = 323  # "LT gain/loss - security"
                else:
                    curr_txn.entryCode = 321  # "ST gain/loss - security"

                assert curr_txn.sellDate >= curr_txn.buyDate
                if tax_year and curr_txn.sellDate.year != tax_year:
                    utils.Warning('ignoring txn: "%s" as the sale is not from %d\n' %
                                  (curr_txn.desc, tax_year))
                    continue

                txn_list.append(curr_txn)

                # Clear both the buy and the sell as we have matched them up.
                buy = None
                sell = None
                curr_txn = None

        return txn_list

#=== vanguard_test.py
"""Tests for the vanguard module."""

from datetime import datetime
import glob
import os
import unittest
from vanguard import Vanguard


class VanguardTest(unittest.TestCase):
    def testDetect(self):
        for csv in glob.glob('testdata/*.csv'):
            self.assertEqual(os.path.basename(csv) == 'vanguard.csv',
                             Vanguard.isFileForBroker(csv))

    def testParse(self):
        data = Vanguard.parseFileToTxnList('testdata/vanguard.csv', 2011)
        with open('testdata/vanguard.parse') as expected_file:
            for txn in data:
                expected_txn = expected_file.readline().strip()
                self.assertEqual(expected_txn, str(txn))


if __name__ == '__main__':
    unittest.main()
=end comment
