Data for analysis: source, reference and hypothesis texts (files 'src', 'ref', 'hyp')

first step: align the reference to the hypothesis, using lemmas;
script to do that: align.pl [-n factor_for_alignment] ref.file hyp.file
result -- alignment (file 'al')

second step: find and classify translation errors based on the texts and the alignment;
script to do that: finderrs.pl src.file ref.file hyp.file alignment.file > error.list.file
result -- error list for every sentence (file 'errs')

third step: summarize errors;
script to do that: errsummary.pl error.list.file
result -- summary (file 'summary')
