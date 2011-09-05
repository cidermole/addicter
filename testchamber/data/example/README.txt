Data for analysis: source, reference and hypothesis texts (files 'src.txt', 'ref.txt', 'hyp.txt')

first step: align the reference to the hypothesis, using lemmas;
./align-hmm.pl -n 2 ref.txt hyp.txt > ali.txt

second step: find and classify translation errors based on the texts and the alignment;
./finderrs.pl src.txt hyp.txt ref.txt ali.txt > errs.txt

third step: summarize errors;
./errsummary.pl errs.txt
