# Bash script for the renumbering of equation tags and cross-references in plain TeX source code

## Using the script
```
  Syntax: ./texrenumber infile.tex outfile.tex
```

## Description
The `texrenumber.sh` script takes care of subsequent renumbering of equation
tags and cross-references in plain TeX source code (that is to say <em>real</em>
TeX, not LaTeX).

The input file is never modified by the `texrenumber.sh`script.  Equation tags
of the forms
```text
   \eqdef{eq:<tag>}
   \eqdefn{eq:<tag>}
   \eqsubdef{eq:<tag><suffix>}
```
are renumbered consecutively in increments of ten as `eq:10`, `eq:20`, `eq:30`,
... . The tags `\eqdef` as well as `\eqdefn` consume the next equation number,
whereas `\eqsubdef` does not: its number is instead inherited from the
preceding `\eqdefn`, along with its original suffix retained, e.g. `eq:20a`,
`eq:20b`, `eq:20c`, etc. All corresponding `\eqref{eq:<tag>}` cross-references
are changed to the new tags as well.

Internally, the `texrenumber.sh` script makes use of the `AWK` scripting
language as its primary engine of parsing and replacing tags and
cross-references, and the script makes two distinct passes over the input:

1. The first pass records every equation tag and constructs an
   old-tag -> new-tag mapping.
2. The second pass applies this mapping to both equation definitions
   and cross-references. This ensures that references are replaced
   consistently regardless of where they occur in the manuscript,
   and also allows several equation commands to occur on the same
   source line.

The script aborts if duplicate equation tags are encountered or if an
`\eqsubdef` cannot be associated with a preceding `\eqdefn`, rather than
risking ambiguous or inconsistent renumbering.

Example: `./texnumber example.tex example-renumbered.tex`

In this example, as included along with the script in the present repo, the
original TeX source `example.tex` is left unchanged and leaves it up to the
user to replace the original file with `example-renumbered.tex` or not (just
as a precaution, in case there are any nasty bugs lurking around in the present
bash script).

## Installation
In order to install the script including a symbolic link `texrenumber` to the
default directory `/usr/local/bin/`, just run the enclosed `Makefile` as
```
sudo make install
```

## Dependencies
As the `texrenumber.sh` script relies on `AWK` as its parsing engine, this
needs to be installed at your workstation (in virtually all cases installed
by default).
```
sudo apt-get install gawk
```

## Copyright
Copyright (C) 2026, Fredrik Jonsson, under GPLv3. See enclosed LICENSE.

## Location of master source code
The source and documentation can be found at https://github.com/hp35/texrenumber
