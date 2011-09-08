# Makefile written by Martin Popel, 2011
SHELL=bash
DATASET=de-en
DATADIR=data/$(DATASET)
H=jane
ALIGNER=greedy
ALIGNER_CMD=perl -I.. ../align-$(ALIGNER).pl
DETECTOR=addicter

# parameters for make all
#HYPS=jane pbt rpbt
HYPS=mix
ALIGNERS=hmm greedy berk berkwmt
DETECTORS=addicter hjerson hjersonlemma
DATASETS=de-en
DO=results

define HELP_MESSAGE
# To run all the experiments
make all
# For more details see the Makefile

# To delete all generated files
make clean
endef
export HELP_MESSAGE

help:
	@echo "$$HELP_MESSAGE" | egrep --color '^(make.*|)'

align: $(DATADIR)/$H.aligned-$(ALIGNER)

$(DATADIR)/$H.aligned-$(ALIGNER): $(DATADIR)/ref.factors $(DATADIR)/$H.factors
	case $(ALIGNER) in\
	  berk | berkwmt) ../align-hmm.pl -x -a $(DATADIR)/non1to1align/$H.aligned-$(ALIGNER)\
	                                  $(DATADIR)/ref.factors $(DATADIR)/$H.factors > $@;;\
	  *) $(ALIGNER_CMD) $(DATADIR)/ref.factors $(DATADIR)/$H.factors > $@;;\
	esac

errors_by_addicter: $(DATADIR)/$H.errors-$(ALIGNER)-addicter.dat
$(DATADIR)/%.errors-$(ALIGNER)-addicter.xml: $(foreach x,src $H ref,$(DATADIR)/$x.factors) $(DATADIR)/$H.aligned-$(ALIGNER)
	../finderrs.pl $(foreach x,src $H ref,$(DATADIR)/$x.factors) $(DATADIR)/$H.aligned-$(ALIGNER) > $@

$(DATADIR)/%.errors-$(ALIGNER)-addicter.dat: $(DATADIR)/%.errors-$(ALIGNER)-addicter.xml
	../err2hjerson.pl < $< > $@

errors_by_hjerson: $(DATADIR)/$H.errors-hjerson.dat
$(DATADIR)/%.errors-hjerson.dat: $(foreach x,ref $H,$(DATADIR)/$x.factors)
	../hjerson/generic-wrapper.sh raw_hjerson.py $(foreach x,ref $H,$(DATADIR)/$x.factors) > $@

results: $(DATADIR)/$H.$(ALIGNER)-addicter.results
$(DATADIR)/$H.$(ALIGNER)-addicter.results: $(DATADIR)/$H.errors-$(ALIGNER)-addicter.dat
	./eval-prec-rec.sh $(DATADIR)/$H.errors.gold.dat $(DATADIR)/$H.errors-$(ALIGNER)-addicter.dat > $@

all:
	# TODO execute all $(HYPS) with both ALIGNERs, add Hjerson's flags, make summary tables
	perl -e 'for my $$a (qw($(ALIGNERS))){for my $$h (qw($(HYPS))){for my $$d (qw($(DATASETS))){\
	 system "make $(DO) ALIGNER=$$a H=$$h DATASET=$$d\n";}}}'

clean:
	rm -rf $(DATADIR)/*.aligned-* $(DATADIR)/*.errors-{results,dat}
#*.factors files are now in the svn repository, so this is not needed (but may be useful in future)
#FACTORS=full pos base
#prepare_data: $(DATADIR)/$H.factors $(DATADIR)/ref.factors $(DATADIR)/src.factors
#
#$(DATADIR)/$H.factors: $(foreach f,$(FACTORS),$(DATADIR)/$H.hyp.$f)
#	auxx/joinfactors.pl $(foreach f,$(FACTORS),$(DATADIR)/$H.hyp.$f) > $@ 
#
#$(DATADIR)/ref.factors: $(foreach f,$(FACTORS),$(DATADIR)/ref.$f)
# 	auxx/joinfactors.pl $(foreach f,$(FACTORS),$(DATADIR)/ref.$f) > $@ 
# 
# $(DATADIR)/src.factors:
# 	[ -f $(DATADIR)/src.full ] &&\
# 	auxx/joinfactors.pl $(foreach f,$(FACTORS),$(DATADIR)/src.$f) > $@ ||\
# 	cat $(DATADIR)/ref.full | sed -e "s/^.*/(dummy text)/g" > $@
