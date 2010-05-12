Dan's ADDICTER
(automatic detection and display of common translation errors)

===============================================================================
PLEASE NOTE: As of 22-Feb-2010, there is a new, more detailed on-line
installation guide at https://wiki.ufal.ms.mff.cuni.cz/user:zeman:addicter
===============================================================================

So far limited to:
- quick lookup of word examples in context
-- in training data
-- in test data (source + reference translation)
-- in test data (source + system-generated hypothesis)
- with alignment
-- for every word shows an overview of words it has been aligned to

Preparation:
- run Giza++ in both directions on training data + test data (reference) + test data (hypothesis)
- split the resulting alignment file to training + test + test
- now you have all input files needed:
-- training.src
-- training.tgt
-- training.ali
-- test.src
-- test.ref
-- test.hyp
-- test.ref.ali
-- test.hyp.ali
- run the word indexer (see the "prepare" folder)
-- creates a number of index files, currently they should be in the cgi folder

addictindex.pl -trs train.en -trt train.hi -tra train.ali -s test.en -r test.hi -h test.joshua.hi -ra test.ali -ha test.joshua.ali -o ../../../Web/cgi/addicter

Viewing:
- use your local web server (:-)) with the cgi scripts in the cgi folder
- e.g. the URL "cgi/example.pl?word=city" shows the example sentences with the word "city"