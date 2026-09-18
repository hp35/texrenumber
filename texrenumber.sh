#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# texrenumber.sh -- Bash script for the renumbering of equation tags and
#                   cross-references in plain TeX source code (not LaTeX).
#
# Location of source at GitHub: https://github.com/hp35/texrenumber
#
# Usage:
#     ./texnumber infile.tex outfile.tex
#
# The input file is never modified.  Equation tags of the forms
#
# \eqdef{eq:<tag>}
# \eqdefn{eq:<tag>}
# \eqsubdef{eq:<tag><suffix>}
#
# are renumbered consecutively as eq:10, eq:20, eq:30, ... .  Both "\eqdef"
# and "\eqdefn" consume the next equation number, whereas "\eqsubdef" does
# not: its number is instead inherited from the preceding "\eqdefn", along
# with its original suffix retained, e.g. eq:20a, eq:20b, eq:20c, etc.
# All corresponding "\eqref{eq:<tag>}" cross-references are changed to the
# new tags as well.
#
# Internally, the script makes use of AWK as the primary engine of parsing
# and replacing tags and cross-references, and the script makes two distinct
# passes over the input:
#
#     1. The first pass records every equation tag and constructs an
#        old-tag -> new-tag mapping.
#     2. The second pass applies this mapping to both equation definitions
#        and cross-references. This ensures that references are replaced
#        consistently regardless of where they occur in the manuscript,
#        and also allows several equation commands to occur on the same
#        source line.
#
# The script aborts if duplicate equation tags are encountered or if a
# "\eqsubdef" cannot be associated with a preceding "\eqdefn", rather than
# risking ambiguous or inconsistent renumbering.
#
# Example:
#     ./texnumber opatheory.tex opatheory-numbered.tex
#
# In this example, the original opatheory.tex is left unchanged and leaves
# it up to the user to replace the original file or not (just as a safety,
# just in case there are any nasty bugs lurking around in the present bash
# script).
#
#     Copyright (C) 2026, Fredrik Jonsson
#
#     This program is free software: you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation, either version 3 of the License, or
#     (at your option) any later version.
#
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
#
#     You should have received a copy of the GNU General Public License
#     along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# ---------------------------------------------------------------------------

set -e  # Exit directly on non-zero status

PROGRAM="${0##*/}"

if [ "$#" -eq 0 ]; then
    echo "Usage: $PROGRAM infile.tex outfile.tex"
    echo
    echo "Renumber equation tags and cross-references."
    echo "Equation numbers become 10, 20, 30, ..."
    echo "Sub-equation suffixes are preserved."
    echo
    echo "The input file is not modified."
    exit 1
fi

if [ "$#" -ne 2 ]; then
    echo "Usage: $PROGRAM infile.tex outfile.tex" >&2
    exit 1
fi

INFILE="$1"
OUTFILE="$2"

if [ ! -f "$INFILE" ]; then
    echo "$PROGRAM: file not found: $INFILE" >&2
    exit 1
fi

if [ "$INFILE" = "$OUTFILE" ]; then
    echo "$PROGRAM: input and output files must be different." >&2
    exit 1
fi

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

TMPFILE="$TMPDIR/output"

awk '
BEGIN {
    number = 0
    group = ""
    group_number = 0
    bad = 0
}

{
    lines[NR] = $0
    text = $0

    while (match(text, /\\(eqdefn|eqsubdef|eqdef)\{eq:[^}]+\}/)) {
        command = substr(text, RSTART, RLENGTH)
        kind = command
        sub(/^\\/, "", kind)
        sub(/\{.*$/, "", kind)
        tag = command
        sub(/^\\(eqdefn|eqsubdef|eqdef)\{/, "", tag)
        sub(/}$/, "", tag)

        if (tag in newtag) {
            printf "ERROR: duplicate equation tag \"%s\" (line %d)\n",
                   tag, NR > "/dev/stderr"
            bad = 1
        }
        else if (kind == "eqdef") {
            number++
            newtag[tag] = "eq:" (10 * number)

            group = ""
            group_number = 0
        }
        else if (kind == "eqdefn") {
            number++
            group = tag
            group_number = 10 * number
            newtag[tag] = "eq:" group_number
        }
        else if (kind == "eqsubdef") {
            if (group == "") {
                printf "ERROR: eqsubdef without preceding eqdefn: \"%s\" (line %d)\n",
                       tag, NR > "/dev/stderr"
                bad = 1
            }
            else if (index(tag, group) != 1) {
                printf "ERROR: sub-equation \"%s\" does not belong to \"%s\" (line %d)\n",
                       tag, group, NR > "/dev/stderr"
                bad = 1
            }
            else {
                suffix = substr(tag, length(group) + 1)
                if (suffix == "") {
                    printf "ERROR: empty sub-equation suffix: \"%s\" (line %d)\n",
                           tag, NR > "/dev/stderr"
                    bad = 1
                }
                else {
                    newtag[tag] = "eq:" group_number suffix
                }
            }
        }
        text = substr(text, RSTART + RLENGTH)
    }
}

END {
    if (bad)
        exit 1

    if (number == 0) {
        print "ERROR: no equation definitions found." > "/dev/stderr"
        exit 1
    }

    for (n = 1; n <= NR; n++) {
        line = lines[n]
        result = ""
        rest = line
        while (match(rest, /\\(eqdefn|eqsubdef|eqdef|eqref)\{eq:[^}]+\}/)) {
            result = result substr(rest, 1, RSTART - 1)
            command = substr(rest, RSTART, RLENGTH)
            tag = command
            sub(/^\\(eqdefn|eqsubdef|eqdef|eqref)\{/, "", tag)
            sub(/}$/, "", tag)
            brace = index(command, "{")
            if (tag in newtag)
                result = result substr(command, 1, brace) newtag[tag] "}"
            else
                result = result command
            rest = substr(rest, RSTART + RLENGTH)
        }
        print result rest
    }

    printf "Found %d numbered equations.\n", number > "/dev/stderr"
    printf "Last equation number: eq:%d\n", 10 * number > "/dev/stderr"
}
' "$INFILE" > "$TMPFILE"

mv "$TMPFILE" "$OUTFILE"

echo "Successfully wrote: $OUTFILE"
