#!/usr/bin/env raku

use Text::Utils :strip-comment, :commify;
use PDF::API6;
use PDF::Page;
use PDF::Content::Page :PageSizes;
use PDF::Content::Font::CoreFont;
constant CoreFont = PDF::Content::Font::CoreFont;


constant $i8949   = "../irs-forms/f8949.pdf";   # two pages
constant $i1040sd = "../irs-forms/f1040sd.pdf"; # two pages
my $o8949   = "/tmp/f8949-overlay.pdf";
my $o1040sd = "/tmp/f1040sd-overlay.pdf";

# form description files
constant $f8949-data   = './f8949.data';
constant $f1040sd-data = './f1040sd.data';

use lib <../lib>;
use TXF::Forms;

if not @*ARGS.elems {
    say qq:to/HERE/;
    Usage: {$*PROGRAM.IO.basename} go | test [blank debug]

    Uses file 1 ($i8949)
      and
         file 2 ($i1040sd)
      plus data from
         file 3 ($f8949-data)
      and
         file 4 ($f1040sd-data)
    and generates filled forms.

    The 'test' mode outlines the target cells for
    tweaking cell dimensions.

    The 'blank' option uses blank paper instead of
    an existing form.
    HERE
    exit;
}

my $test  = 0;
my $blank = 0;
my $debug = 0;
for @*ARGS {
    when /^d/ {
        $debug = 1;
    }
    when /^t/ {
        $test = 1;
    }
    when /^b/ {
        $blank = 1;
    }
}

my $f8949   = get-form-data $f8949-data, :form-id<f8949>, :$debug;
my $f1040sd = get-form-data $f1040sd-data, :form-id<f1040sd>, :$debug;

if not $test {
    say "NOTE: The real data handling is not yet ready. Use the test mode.";
    exit;
}

my $name = "Thomas M. Jr. and Lauren L. Browder";
my $ssan = "999-99-9999";

write-form-test :form-data($f8949), :$blank, :$debug;

exit;

if 0 {
    # Open an existing PDF file
    my $pdf = PDF::API6.new;
    $pdf .= open($i8949);
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
    $pdf.save-as($o8949);
    say "See file '$o8949'";
}


#### SUBROUTINES ####
our constant %valid-keys is export = set <
    form
    page
    row
    field
    duprow
    copyrow
    copyrows
>;

sub get-form-data($file,
    :$form-id! where {$form-id ~~ /'f8949'|'f1040sd'/},
    :$debug,
    --> Form) is export {

    # read row data for each form and page

    # current objects
    # need a Form object to return
    my $form = Form.new: :id($form-id);

    # child objects of a form
    my $page;
    my $pageid; # for later ref
    # child objects of a page
    my $row;

    my $lnum = 0;
    LINE: for $file.IO.lines -> $line is copy {
        ++$lnum;
        $line = strip-comment $line;
        next if $line !~~ /\S/;
        # remove commas, replace with spaces
        $line ~~ s:g/','/ /;
        say "DEBUG: line: $line" if $debug;
        $line .= trim-leading;
        # get the mandatory key

        my $idx = index ':', $line;
        if not defined $idx {
            die "FATAL: Mandatory line leading key token 'xxx:' not found on line $lnum: $line";
        }
        my $key = substr $line, 0, $idx+1;
        # elim internal spaces
        $key  .= subst: ' ', '', :g;
        $line .= substr: $idx;
        my @args = $line.words;
        my $id = @args.shift;
        my $nargs = @args.elems;

        given $key {
            when $_ eq <form> {
                    # the id MUST be the same as in $form
                if $id ne $form.id {
                    die "FATAL: Internal form \$id ($id) and Form.id ({$form.id}) don't match";
                }
            }
            when /page/  {
                # a new page to add to the existing form
                $pageid = $id.Int; # for later ref
                $page   = Page.new: :id($pageid);
                $form.pages{$id} = $page;
            }
            when /^row/   {
                # a new row to add to the existing page
                =begin comment
                sub form-add-row(:$form!, :$key!, :$id!, :@args!, :$pageid!, :$line!,
                                 :$debug!,)
                =end comment

                # fill its attributes
                my ($nr-lly, $nr-ury, $nr-h);
                # row: id lly ury|h:val  # key + id + 2 args
                my $arg1 = @args[0];
                my $arg2 = @args[1];
                say "DEBUG: checking row lly ($arg1)" if $debug;
                $nr-lly = $arg1;
                if $arg2 ~~ /'h:' (\S+) / {
                    say "DEBUG: checking row h ($arg2)" if $debug;
                    $nr-h = ~$0;
                }
                else {
                    say "DEBUG: checking row ury ($arg2)" if $debug;
                    $nr-ury = $arg2;
                }
                # now get the new row
                $row = Row.new: :$id, :lly($nr-lly), :ury($nr-ury), :h($nr-h);
                $page.rows{$row.id} = $row;
                note "DEBUG: dumping row" if $debug;
                say $row.raku if $debug;
            }
            when /copyrows $/ {
                =begin comment
                sub form-copyrows(:$form!, :$key!, :$id!, :@args!, :$pageid!, :$line!,
                                  :$debug!,)
                =end comment

                # duplicate a row set on another page onto the current page:
                #    copyrows: pageN:rowid y:val # key + id + 1 args
                say "DEBUG: found key: $key";
            }
            when /duprow/ {
                =begin comment
                sub form-duprow(:$form!, :$key!, :$id!, :@args!, :$pageid!, :$line!,
                                :$debug!,)
                =end comment

                # duplicate a row on the same page N more times:
                #    copyrow: rowid       c:13    dy:-24       # key + id + 2 args
            }
            when /copyrow $/ {
                =begin comment
                sub form-copyrow(:$form!, :$key!, :$id!, :@args!, :$pageid!, :$line!,
                                 :$debug!,)
                =end comment
                my $arg1 = @args[0];
                my $arg2 = @args[1];

                # copy a single row on another page to the current page:
                #    copyrow: pageN:rowid y:val                # key + id + 1 args

                my $s;

                if $nargs == 1 and $id ~~ / page (\d+) ':' (\S+) / {
                    my $other-page-id  = +$0;
                    $id = ~$1;

                    note "DEBUG: line $lnum: $line" if 1;
                    if not $form.pages{$other-page-id}.rows{$id}:exists {
                        die "FATAL: Copy row '$id' not found (form x, page $other-page-id)";
                    }
                    # now parse $arg1

                }
                elsif $nargs == 2 {
                    if $id !~~ /'01'$/ {
                        die "FATAL: Copy row '$id' ends not in '01' as expected";
                    }
                    $s = "$arg1 $arg2";
                }

                # params to be used in the copy
                my $copies; # = +$0;
                my $dy;     # = +$1;
                my $nf;     # = $row.fields.elems;
                my $lly;    # = $row.lly;
                my $ury;    # = $row.ury;
                my $starty; #

                if $nargs == 2 and $s ~~ /\h* 'c:' (\d+)
                \h+ 'dy:' (<[+-]>? \d+ ['.'\d*]?)
                / {
                    # two-arg form
                    # duplicate a row on the same page N more times:
                    #    copyrow: rowid => c:13 dy:-24          # key + id + 2 args
                    # get the params to be copied
                    $copies = +$0;
                    $dy     = +$1;
                    $nf     = $row.fields.elems;
                    $lly    = $row.lly;
                    $ury    = $row.ury;
                }
                elsif $nargs == 3  {
                    # three-arg form
                    # duplicate a row on another page onto the current page N more times:
                    #    copyrow: pageN:rowid => c:13 dy:-24  y:val   # key + id + 3 args
                    # get the params to be copied
                    # must parse the $id first
                    if $id ~~ / page (\d+) ':' (\S+) / {
                        my $pn  = +$0;
                        my $rid = ~$1;
                    }
                    else {
                        die "FATAL: ";
                    }
                    # then the three args
                    if $s ~~ /\h* 'c:' (\d+)
                    \h+ 'dy:' (<[+-]>? \d+ ['.'\d*]?)
                    \h+ 'y:' (<[+-]>? \d+ ['.'\d*]?)
                    / {
                        $copies = +$0;
                        $dy     = +$1;
                        $starty = +$2;
                        $nf     = $row.fields.elems;
                        $lly    = $row.lly;
                        $ury    = $row.ury;
                    }
                    else {
                        die "FATAL: ";
                    }
                }
                else {
                    die "FATAL: Unexpected format on a 'copyrow' line: '$s'";
                }

                # dup each row
                for 1..$copies -> $n is copy {
                    ++$n; # make line num correct
                    #my $rowid = "line{$n+1}";
                    my $rowid = sprintf 'line%02d', $n;
                    $lly += $dy; # NOTE currently we expect the dy value to be negative for succeeding rows
                    $ury += $dy; # NOTE currently we expect the dy value to be negative for succeeding rows
                    my $newrow = Row.new: :id($rowid), :$lly, :$ury;
                    # add row to the page
                    $page.rows{$rowid} = $newrow;

                    # dup each field
                    for $row.fields.keys.sort -> $k {
                        # the keys are 'a'..'h' (8 fields corresponding to the form column letters)
                        # get the master row's corresponding field's x values
                        my $llx = $row.fields{$k}.llx;
                        my $urx = $row.fields{$k}.urx;
                        my $f = Field.new: :id($k), :$llx, :$urx;
                        $newrow.fields{$k} = $f;
                    } # end dup field
                } # end dup row
            }
            when /field/ {
                # a new field to add to the existing row
                =begin comment
                sub form-add-field(:$form!, :$key!, :$id!, :@args!, :$pageid!, :$line!,
                                   :$row!,
                                   :$debug!,)
                =end comment

                my $arg1 = @args[0];
                my $arg2 = @args[1];
                # fill its attributes
                #   field: id llx urx|w:val # key + 3 args
                my ($nf-llx, $nf-urx, $nf-w);
                $nf-llx = $arg1;
                if $arg2 ~~ /'w:' (\S+) / {
                    $nf-w = ~$0;
                }
                else {
                    $nf-w = $arg2;
                }
                my $field = Field.new: :$id, :llx($nf-llx), :urx($nf-urx), :w($nf-w);
                $row.fields{$field.id} = $field;
            }
            default {
                die "FATAL: Unknown key '$key'";
            }
        }
    }

    return $form;
} # sub get-form-data

# need some pdf subs for common tasks:
#   write text to a position x,y
#     with varied justification, font, font size
#   outline a cell with red lines
#   write text in a box
#   write a paragraph of text with justification
multi sub outline-box(
    $page, # a PDF page object
    $llx, $lly, $urx, $ury,
    :@color   = [1, 0, 0], # rgb decimal red
    :$linewidth = 1.0,
    :$debug,
    ) is export {

    use PDF::Content::Color :rgb;
    my $gfx = $page.gfx;
    $gfx.Save;
    $gfx.StrokeColor = rgb(@color[0..2]);
    $gfx.Rectangle($llx, $lly, $urx, $ury);
    $gfx.paint: :stroke;
    $gfx.Restore;
} # sub outline-box

multi sub fill-box(
    $page, # a PDF page object
    $llx, $lly, $urx, $ury,
    :@color   = [1, 0, 0], # rgb decimal red
    :$debug,
    ) is export {

    use PDF::Content::Color :rgb;
    my $gfx = $page.gfx;
    $gfx.Save;
    $gfx.FillColor = rgb(@color[0..2]);
    $gfx.Rectangle($llx, $lly, $urx, $ury);
    $gfx.paint: :fill;
    $gfx.Restore;
} # sub fill-box

multi sub write-text(
    $page, # a PDF page object
    $llx, $lly, $urx, $ury,
    :$text!,
    :$halign = 'left',
    :$valign = 'bottom',
    :$font-size = 9,
    :$font = 'Helvetica',
    :$debug,
    ) is export {



} # sub write-text

sub write-form-test(
    :$form-data!, # a Form desciption class object
    :$blank!,     # if true, use blank paper instead
    :$debug) is export {

    if $debug > 1 {
        say $form-data.gist;
        say "DEBUG EXIT";
        exit;
    }

    # Open an existing PDF file
    my $pdf = PDF::API6.new;
    # Set the default page size for all pages
    $pdf.media-box = Letter;
    # Use a standard PDF core font
    my $font = $pdf.core-font: :family<Helvetica>; #, :weight<Bold>;
    my $font-size = 9;

    # assumes two-page forms for now
    my ($page1, $page2);

    if $blank {
        # Add blank pages
        $page1 = $pdf.add-page();
        $page2 = $pdf.add-page();
    }
    else {
        # Retrieve existing pages
        $pdf .= open($i8949);
        $page1 = $pdf.page(1);
        $page2 = $pdf.page(2);
    }

    # step through $format pieces and outline the boxes
    my $f = $form-data.id;
    for $form-data.pages -> $page  {
        say "DEBUG: page {$page.id}";
        for $page.boxes.keys.sort -> $k {
            say "DEBUG: page boxes key: '$k'";
        }
        for $page.rows.keys.sort -> $k {
            say "DEBUG: page rows key: '$k'";
        }
    }

    =begin comment
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
    =end comment

    # Save the new PDF
    $o8949.IO.chmod: 0o667;
    $pdf.save-as($o8949);
    say "See file '$o8949'";

} # sub write-form-test

sub form-add-row() {
}

sub form-copyrow() {
}

sub form-copyrows() {
}

sub form-add-field() {
}
