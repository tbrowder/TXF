#!/usr/bin/env raku

use PDF::API6;
use PDF::Page;
use PDF::Content::Page :PageSizes;
use PDF::Content::Font::CoreFont;
constant CoreFont = PDF::Content::Font::CoreFont;

my $pdf = PDF::API6.new;

my $ifil = "../irs-forms/f8949.pdf"; # two pages
my $ofil = "/tmp/f8949-mods.pdf";

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
