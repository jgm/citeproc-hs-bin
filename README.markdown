# citeproc

citeproc is a standalone program that uses Andrea Rossato's [citeproc-hs]
to generate citations and a bibliography, given a database of bibliographic
references and a [CSL] stylesheet.  The idea is to make it possible for
non-Haskell programs to use this excellent tool.

[citeproc-hs]: http://gorgias.mine.nu/repos/citeproc-hs/
[CSL]: http://citationstyles.org/

## Usage

    citeproc stylefile.csl bibliofile.bib

- The bibliography file can be in any of the formats that bibutils
  supports.
- The program reads JSON from stdin and writes JSON to stdout.

## Input

The input is a JSON array of citations.
A citation is a JSON array of cites.
A cite is a JSON object describing one source.  Fields can include:

- `id` (string)
- `prefix` (string or array)
- `suffix` (string or array)
- `label` (string)
- `locator` (string)
- `position` (string)
- `near_note` (boolean)
- `suppress_author` (boolean)
- `author_in_text` (boolean)

`id` must be included; the rest are optional.

Sample input:

     [[{"id":"item1","suffix":"test"}, {"id":"item2", "label":"chapter", "locator":"15", "suffix":["et ",["EMPH","passim"]]}],[{"id":"item3","author_in_text":true}]]

Note that `prefix` and `suffix` can be either plain strings or formatting text--a JSON
array consisting of plain strings or arrays in which the first string is a formatting
instruction:  `EMPH`, `STRONG`, `SMALLCAPS`, `STRIKEOUT`, `SUPERSCRIPT`, `SUBSCRIPT`, `NOTE`.

## Output

The output is a JSON object with three fields:

- `citations` is a JSON array consisting of a list of citations. Each citation is
  a JSON array representing formatted text as described above.

- `bibliography` is a JSON array consisting of a list of bibliographic items.
  Each item is a JSON array representing formatted text as described above.

Sample output:

    {"citations":[["(Doe 2005 test; Doe 2006, 15et ",["EMPH",["passim"]],")"],["Doe and Roe(2007)"]],"bibliography":[["Doe, John. 2005. ",["EMPH",["First Book"]],". Cambridge: Cambridge University Press."],["———. 2006. Article. ",["EMPH",["Journal of Generic Studies"]]," ","6: 33-34."],["Doe, John, and Jenny Roe. 2007. Why Water Is Wet. In ",["EMPH",["Third Book"]],", ed. Sam Smith. Oxford: Oxford University Press."]],"citation_type":"in-text"}

## Installing citeproc

Change to the source directory and:

    cabal install

