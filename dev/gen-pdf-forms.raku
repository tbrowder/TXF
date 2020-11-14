#!/usr/bin/env raku

use Text::Utils :strip-comment, :commify;
use PDF::API6;
use PDF::Page;
use PDF::Content::Page :PageSizes;
use PDF::Content::Font::CoreFont;
constant CoreFont = PDF::Content::Font::CoreFont;

my $pdf = PDF::API6.new;

my $ifil  = "../irs-forms/f8949.pdf"; # two pages
my $ifil2 = "../irs-forms/f1040sd.pdf"; # two pages
my $ofil  = "/tmp/f8949-overlay.pdf";
my $ofil2 = "/tmp/f1040sd-overlay.pdf";

# form description files
my $f8949 = './f8949.txt';
use lib <../lib>;
use TXF::IRS-Forms;

if not @*ARGS.elems {
    say qq:to/HERE/;
    Usage: {$*PROGRAM.IO.basename} 1 | 2 [debug]

    Uses file 1 ($ifil)
      or 
         file 2 ($ifil2)
    and generates a filled form for tweaking cell coords.
    HERE
    exit;
}

my %h = get-boxes $f8949;

exit;

# Open an existing PDF file
$pdf .= open($ifil);

# Add a blank page
#my $page = $pdf.add-page();

# Retrieve an existing page
my $page1 = $pdf.page(1);
my $page2 = $pdf.page(2);

# Set the default page size for all pages
$pdf.media-box = Letter;

# Use a standard PDF core font
#my CoreFont $font = $pdf.core-font('Helvetica-Bold');
my $font = $pdf.core-font: :family<Helvetica>; #, :weight<Bold>;

# Add some text to the page
# page 1 blocks A
#               B
#               C
$page1.text: {
    .font = $font, 9;
    # line 1, col 1, (of 14), y increment 24 points
    .text-position = 35, 420+2;
    .say('100 sh XYZ');
    .text-position = 176, 420+2;
    .say('10/12/2019');
    .text-position = 226, 420+2;
    .say('07/22/2000');

    .text-position = 35, 396+2;
    .say('100 sh XYZ');

    .text-position = 35, 374;
    .say('100 sh XYZ');

    .text-position = 35, 350;
    .say('100 sh XYZ');

}
$page2.text: {
    .font = $font, 9;

    .text-position = 35, 458;
    .say('100 sh XYZ');

    .text-position = 35, 434;
    .say('100 sh XYZ');

    .text-position = 35, 410;
    .say('100 sh XYZ');

    .text-position = 35, 386;
    .say('100 sh XYZ');
}

# Save the new PDF
$pdf.save-as($ofil);
say "See file '$ofil'";

#### SUBROUTINES ####
sub write-f8949-p1 {
}

sub get-boxes($file) {
    # read box data for each form and page
    # current objects
    my $form;
    my $page;
    my $box;
    my $row;
    my $field;

    for $file.IO.lines -> $line is copy {
        $line = strip-comment $line;
        next if $line !~~ /\S/;
        # remove commas, replace with spaces
        $line ~~ s:g/','/ /;
        if $line ~~ /^ \h* (\S+) ':' \h* (\S+)     # key + 1 arg
                       [ \h+ (\S+) \h+ (\S+)       # key + 3 args
                          [ \h+ (\S+) \h+ (\S+) ]? # key + 5 args 
                       ]? \h* $/ {
            # this ought to match all input
            my $key  = ~$0;
            my $arg1 = ~$1;
            my ($arg2, $arg3, $arg4, $arg5);
            $arg2 = ~$2 if $2;
            $arg3 = ~$3 if $3;
            $arg4 = ~$4 if $4;
            $arg5 = ~$5 if $5;
            given $key {
                when /form/  { 
                    $form = Form.new;
                }
                when /row/   { 
                    $row = Row.new;
                }
                when /field/ { 
                    $field = Field.new;
                }
                when /box/   { 
                    $box = Box.new;
                }
                when /page/  { 
                    $page = Page.new;
                }
                default {
                    die "FATAL: Unknown key '$key'";
                }
            }

            if $key = 'form' {
            }
        }
        else {
            die "FATAL: unexpected line '$line'";
        }
    }
    return %h;

}
