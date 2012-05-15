This folder contains parts of cgi/addicter/cu-bojar that cannot be used currently
because the alignments are not 1-1 and detecter.pl cannot use them. We may want to
re-introduce them in future.

===============================================================================
Pro některá zarovnání nám chybí analýza chyb.
Zkusil jsem ji doplnit a zjistil jsem, že Mark stále neumí pracovat se zarovnáními, která nejsou 1-1 (viz níže).
Proto zatím tato zarovnání úplně odstraním, aby je prohlížeč nenabízel.

C:\Users\Dan\Documents\Web\cgi\addicter\cu-bojar\GizaDiag>perl C:\Users\Dan\Documents\Lingvistika\Projekty\statmt\addict
er\prepare\detecter.pl -s C:\Users\Dan\Documents\Lingvistika\Projekty\statmt\addicter-experiments\en-cs-wmt09\concat-exp
eriments\corps\src -r C:\Users\Dan\Documents\Lingvistika\Projekty\statmt\addicter-experiments\en-cs-wmt09\concat-experim
ents\corps\ref -h C:\Users\Dan\Documents\Lingvistika\Projekty\statmt\addicter-experiments\en-cs-wmt09\concat-experiments
\corps\cu-bojar -a test.refhyp.ali -w .
Alignment has to be 1-to-1, duplicate hyp point 0 '0-0 4-1 0-2 0-3 3-3 1-4 2-4 4-4 5-5 6-6 7-7 8-8 9-9 9-10 10-10 11-11
12-12 13-13 19-14 20-15 21-16 18-17 21-17 14-18 21-18 15-19 16-20 17-21 22-22' at C:\Users\Dan\Documents\Lingvistika\Pro
jekty\statmt\addicter\testchamber/parse.pm line 48, <$fh> line 1.
Command C:/Users/Dan/Documents/Lingvistika/Projekty/statmt/addicter/testchamber/finderrs.pl C:\Users\Dan\Documents\Lingv
istika\Projekty\statmt\addicter-experiments\en-cs-wmt09\concat-experiments\corps\src C:\Users\Dan\Documents\Lingvistika\
Projekty\statmt\addicter-experiments\en-cs-wmt09\concat-experiments\corps\cu-bojar C:\Users\Dan\Documents\Lingvistika\Pr
ojekty\statmt\addicter-experiments\en-cs-wmt09\concat-experiments\corps\ref ./tcali.txt > ./tcerr.txt returned a non-zer
o status at C:\Users\Dan\Documents\Lingvistika\Projekty\statmt\addicter\prepare\detecter.pl line 19.
