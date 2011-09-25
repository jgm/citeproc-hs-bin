#!/bin/sh
for style in chicago-author-date.csl mhra.csl; do
echo $style
echo
( cat | ./citeproc $style biblio.bib ) <<EOF
[[{"id":"item1","suffix":"test"}, {"id":"item2", "label":"chapter", "locator":"15", "suffix":["et ",["EMPH","passim"]]}],[{"id":"item3","author_in_text":true}]]
EOF
echo
done
