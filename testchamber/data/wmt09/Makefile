all:
	# This is added by Ondrej to analyze the second set exactly the same
	# way as used in Bojar (2010) in PBML
	# Aside from tagging and lemmatization, this also does some plaintext
	# normalization, see for-info-the-Czech-normalization-performed.pm for
	# details.
	# Run the following goals:
	@for g in $(INPUTFILES:%=%.analyzed.gz); do \
	  echo "make $$g &" ; \
	done


TECTOMT=/home/bojar/diplomka/granty/emplus/mtmetrics/stopwords-reduction/tectomt
SRUNBLOCKS=$(TECTOMT)/tools/srunblocks_streaming/srunblocks
LOT2TMT=$(TECTOMT)/tools/format_convertors/line_oriented_tmt/lot_to_tmt.sh

INPUTFILES= \
  first.cu-bojar.hyp first.cu-tectomt.hyp first.google.hyp \
  first.pctrans.hyp first.ref \
  second.cu-bojar.hyp second.cu-tectomt.hyp second.google.hyp \
  second.pctrans.hyp second.ref

%.analyzed.gz: %
	qruncmd --join --jobs=2 " \
	   $(SRUNBLOCKS) --errorlevel=FATAL \
	     analyze-to-m.scen \
	     czech_source_sentence \
	     factored_output \
	 " $< \
	| gzip -c > $@
