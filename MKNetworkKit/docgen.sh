rm -rf /Documentation
mkdir Documentation
headerdoc2html -u -t -o /Documentation
gatherheaderdoc /Documentation index.html

