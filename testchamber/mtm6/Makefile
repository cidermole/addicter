SHELL=bash
DATASET=de-en
DATADIR=data/$(DATASET)
H=jane
FACTORS=full pos base
ALIGNER=greedy
ALIGNER_CMD=perl -I.. ../align-$(ALIGNER).pl

# parameters for make all
HYPS=jane pbt rpbt
ALIGNERS=hmm greedy
DATASETS=de-en


define HELP_MESSAGE
# To run the experiments
make errors_by_addicter
# Additional parameters
# H (hypothesis, MT-system name) = jane pbt rpbt
# ALIGNER = hmm greedy
# For more details see the Makefile

# To delete all generated files
make clean
endef
export HELP_MESSAGE

help:
	@echo "$$HELP_MESSAGE" | egrep --color '^(make.*|)'

prepare_data: $(DATADIR)/$h.hyp.factors $(DATADIR)/ref.factors $(DATADIR)/src.factors

$(DATADIR)/$H.hyp.factors: $(foreach f,$(FACTORS),$(DATADIR)/$H.hyp.$f)
	auxx/joinfactors.pl $(foreach f,$(FACTORS),$(DATADIR)/$H.hyp.$f) > $@ 

$(DATADIR)/ref.factors: $(foreach f,$(FACTORS),$(DATADIR)/ref.$f)
	auxx/joinfactors.pl $(foreach f,$(FACTORS),$(DATADIR)/ref.$f) > $@ 

$(DATADIR)/src.factors:
	[ -f $(DATADIR)/src.full ] &&\
	auxx/joinfactors.pl $(foreach f,$(FACTORS),$(DATADIR)/src.$f) > $@ ||\
	cat $(DATADIR)/ref.full | sed -e "s/^.*/(dummy text)/g" > $@

align: $(DATADIR)/$H.aligned-$(ALIGNER)
$(DATADIR)/$H.aligned-$(ALIGNER): $(DATADIR)/ref.factors $(DATADIR)/$H.hyp.factors
	$(ALIGNER_CMD) $(DATADIR)/ref.factors $(DATADIR)/$H.hyp.factors > $@

errors_by_addicter: $(DATADIR)/$H.errors-$(ALIGNER)-addicter.dat
$(DATADIR)/%.errors-$(ALIGNER)-addicter.xml: $(foreach x,src $H.hyp ref,$(DATADIR)/$x.factors) $(DATADIR)/$H.aligned-$(ALIGNER)
	../finderrs.pl $(foreach x,src $H.hyp ref,$(DATADIR)/$x.factors) $(DATADIR)/$H.aligned-$(ALIGNER) > $@

$(DATADIR)/%.errors-$(ALIGNER)-addicter.dat: $(DATADIR)/%.errors-$(ALIGNER)-addicter.xml
	../err2hjerson.pl < $< > $@

results: $(DATADIR)/$H.$(ALIGNER)-addicter.results
$(DATADIR)/$H.$(ALIGNER)-addicter.results: $(DATADIR)/$H.errors-$(ALIGNER)-addicter.dat
	./eval-prec-rec.sh $(DATADIR)/$H.hum-all.dat $(DATADIR)/$H.errors-$(ALIGNER)-addicter.dat > $@

all:
	# TODO execute all $(HYPS) with both ALIGNERs, add Hjerson's flags, make summary tables
	perl -e 'for my $$a (qw($(ALIGNERS))){for my $$h (qw($(HYPS))){for my $$d (qw($(DATASETS))){\
	 system "make -s results ALIGNER=$a H=$$h DATASET=$$d\n";}}}' #>> $(RESULTS)

clean:
	rm -rf $(DATADIR)/*.{factors,aligned-greedy,aligned-hmm}