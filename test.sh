#!/bin/sh
PROG=./dist/build/citeproc/citeproc
for style in chicago-author-date.csl mhra.csl; do
echo $style
echo
( cat | $PROG $style biblio.bib ) <<EOF
[[{"id":"item1","suffix":"test"}, {"id":"item2", "label":"chapter", "locator":"15", "suffix":["et ",["EMPH","passim"]]}],[{"id":"item3","author_in_text":true}]]
EOF
echo
done
