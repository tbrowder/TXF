[![Actions Status](https://github.com/tbrowder/TXF/workflows/test-inline-perl5/badge.svg)](https://github.com/tbrowder/TXF/actions)

NAME
====

TXF - Provides tools to create TXF (tax exchange format) files for import into tax software

SYNOPSIS
========

```raku
$ zef install TXF
...
$ csv2txf /path/file.csv tax-year=2019 [toml=mycfg.toml] > /path/to/file.txf
Normal end.
Using default configuration file '$HOME/.TXF/config.toml'.
$
$ txt2csv /path/file2.txf tax-year=2019 [toml=mycfg.toml] > /path/to/file2.csv
Normal end.
Using default configuration file '$HOME/.TXF/config.toml'.
$
$ gen-tax-forms /path/to/file.csv tax-year=2019 [toml=myconfig.toml]
Normal end.
Using default configuration file './2019.toml'.
See new files:
  f8949-2019.csv
  f8949-2019.txf
  schedule-d-2019.csv
$
```

DESCRIPTION
===========

TXF is a module that provides three Raku programs to convert text files from/to CSV/TXF format and to specifically prepare files for US IRS requirements for tax reporting of stock sales. TXF files can be used to import US IRS-required data on stock sales into such tax software as *TurboTax* and *H\&R Block*.

The module may be able to help with other financial software if there is interest.

There are example account stock sale CSV output files from financial investment company *TD Ameritrade*, but the conversion programs should be able to handle any input format if the user can provide a text input file that maps the appropriate CSV file's field names (column headers) to the standard IRS Form 8949 fields as used in the sample *Form8949.csv* and *Form8949.xlsx* files. See the inputs required in file 'resources/config.toml'.

Planned capability
==================

Version 0.1.0
-------------

  * Situation 1

All short- and long-term stock sales are "covered" with bases reported to the IRS and no adjustments are needed.

Capability: Convert any investment company's tax year stock sales in CSV format to a TXF file for import into H \& R Block's individual tax return software for 2019.

  * Situation 2

One or more stock sales (1) need corrections to data previously reported to the IRS or (2) have missing data to be provided to the IRS.

Capability: Use an enhanced example Form 8949 xlsx file to provide the missing or erroneous data as a PDF file to be attached to a printed and mailed tax return.

CREDITS
=======

  * Thanks to fellow [GnuCash](https://gnucash.org) user **John Ralls** <jralls@ceridwen.us> who kindly found the included reference documents detailing the TXF file format specification.

  * Thanks to Github user **Misha Brukman** and the Github repository [https://github.com/mbrukman/csv2txf/](https://github.com/mbrukman/csv2txf/) for inspiration and some code (as well as the name of the driver program `csv2txf.raku`). See the code source in file `./lib/TXF/CSV2TXT.rakumod`

AUTHOR
======

Tom Browder <tom.browder@cpan.org>

COPYRIGHT AND LICENSE
=====================

Copyright &#x00A9; 2020 Tom Browder

This library is free software; you can redistribute it or modify it under the Artistic License 2.0.

Additional LICENSE
==================

One file is licensed under the Apache-2.0 license:

  * ./lib/TXF/CSV2TXF.rakumod

A copy of that license is found in directory `lib/TXF/`.

The original source of the content of that file came from Github repository [https://github.com/mbrukman/csv2txf](https://github.com/mbrukman/csv2txf) and was converted to its present form from Python to Raku.

