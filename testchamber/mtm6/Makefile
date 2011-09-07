SHELL=bash
LANGPAIR=de-en
DATADIR=data/$(LANGPAIR)
#HYPS=jane pbt rpbt
H=jane
FACTORS=full pos base
ALIGNER=greedy
ALIGNER=hmm
ALIGNER_CMD=perl -I.. ../align-$(ALIGNER).pl

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

errors_by_addicter: $(DATADIR)/$H.errors-$(ALIGNER)-addicter
$(DATADIR)/%.errors-$(ALIGNER)-addicter: $(foreach x,src $H.hyp ref,$(DATADIR)/$x.factors) $(DATADIR)/$H.aligned-$(ALIGNER)
	../finderrs.pl $(foreach x,src $H.hyp ref,$(DATADIR)/$x.factors) $(DATADIR)/$H.aligned-$(ALIGNER) > $@

all:
	# TODO execute all $(HYPS) with both ALIGNERs, add Hjerson's flags, make summary tables 

clean:
	rm -rf $(DATADIR)/*.{factors,aligned-greedy,aligned-hmm}