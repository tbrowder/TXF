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
my $f8949-data   = './f8949.data';
my $f1040sd-data = './f1040sd.data';

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

my $debug = 0;
for @*ARGS {
    when /^d/ {
        $debug = 1;
    }
}

my $f8949   = get-boxes $f8949-data, :form-id<f8949>, :$debug;
#my $f1040sd = get-boxes $f1040sd-data, :form-id<f1040sd>, :$debug;

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
sub write-f8949-p1(:$debug) is export {
}

sub get-boxes($file, 
              :$form-id! where {$form-id ~~ /'f8949'|'f1040sd'/},
              :$debug,
             ) is export {
    # read box data for each form and page
    # current objects
    # return a Form object
    my $form = Form.new: :id($form-id);

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
            my $key = ~$0;
            my $id  = ~$1;
            my ($arg1, $arg2, $arg3, $arg4);
            $arg1 = ~$2 if $2;
            $arg2 = ~$3 if $3;
            $arg3 = ~$4 if $4;
            $arg4 = ~$5 if $5;
            given $key {
                when /form/ {
                    # the id MUST be the same as in $form
                    if $id ne $form.id {
                        die "FATAL: Internal form \$id ($id) and Form.id ({$form.id}) don't match";
                    }
                }
                when /page/  {
                    # a new page to add to the existing form
                    $page = Page.new: :$id;
                    $form.pages.push: $page;
                }
                when /row/   {
                    # a new row to add to the existing page
                    $row = Row.new: :$id;
                    $page.rows{$row.id} = $row;
                    # fill its attributes
                    # row: id lly ury|h:val  # key + 3 args
                }
                when /repeat/ {
                    #          tmpl times delta-y
                    # repeat: line1 r:13   dy:-24
                    if not $page.rows{$id}:exists {
                        die "FATAL: Repeat row '$id' not found (form x, page y)";
                    }
                    elsif $id ne 'line1' {
                        die "FATAL: Repeat row '$id' is not 'line1' as expected";
                    }
                    my $s = "$arg1 $arg2";
                    if $s ~~ /\h* 'r:' (\d+) \h+ 'dy:' (<[+-]>? \d+) / {
                        my $times = +$0;
                        my $dy    = +$1;
                        my $nf = $row.fields.elems;
                        my $y = $row.lly;
                        for 2..^$times -> $n {
                            $y += $dy; # currently we expect the dy value to be negative for succeeding rows
                            my $rid = "line$n";
                            my $nr = Row.new: :id($rid);
                            # update the new row's attributes
                            for $row.fields.keys.sort -> $k {
                                # the keys are 'a'..'h' (8 fields corresponding to the form column letters)
                                # get the master row's corresponding field's x values
                                my $llx = $row.fields{$k}.llx;
                                my $lrx = $row.fields{$k}.lrx;
                                my $f = Field.new: :id($k), :$llx, :$lrx;
                                $nr.fields{$k} = $f;
                                # update the new field's attributes
                            }
                        }

                    }
                    else {
                        die "FATAL: Unexpected format on a 'repeat' line: '$s'";
                    }

                }
                when /field/ {
                    # a new field to add to the existing row
                    $field = Field.new: :$id;
                    $row.fields{$field.id} = $field;
                    # fill its attributes
                    #   field: id llx urx|w:val # key + 3 args
                }
                when /box/   {
                    # a new box to add to the existing page
                    $box = Box.new: :$id;
                    $page.boxes{$box.id} = $box;
                    # fill its attributes
                    # box: id llx lly urx|w:val ury|h:val  # key + 5 args
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

    return $form;
}
