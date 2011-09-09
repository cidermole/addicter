# Makefile written by Martin Popel, 2011
SHELL=bash
DATASET=de-en
DATADIR=data/$(DATASET)
H=jane
VARIANT=greedy
ALIGNER_CMD=perl -I.. ../align-$(VARIANT).pl
DETECTOR=addicter

# parameters for make all
#HYPS=jane pbt rpbt
HYPS=mix
ADDICTER_VARIANTS=hmm greedy berk berkwmt
HJERSON_VARIANTS=default lemmawer
VARIANTS=$(ADDICTER_VARIANTS) $(HJERSON_VARIANTS)
DETECTORS=addicter hjerson
DATASETS=de-en
DO=results
DOMORE=ranking

# for SGE cluster
QCMD = ${TMT_ROOT}/tools/cluster_utils/qruncmd
JOBS = 20


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

align: $(DATADIR)/$H.aligned-$(VARIANT)
$(DATADIR)/$H.aligned-$(VARIANT): $(DATADIR)/ref.factors $(DATADIR)/$H.factors
	case $(VARIANT) in\
	  berk | berkwmt) ../align-hmm.pl -x -a $(DATADIR)/non1to1align/$H.aligned-$(VARIANT)\
	                                  $(DATADIR)/ref.factors $(DATADIR)/$H.factors > $@;;\
	  hmm | greedy) $(ALIGNER_CMD) $(DATADIR)/ref.factors $(DATADIR)/$H.factors > $@;;\
	esac

errors: $(DATADIR)/$H.errors-$(VARIANT)-$(DETECTOR).dat
$(DATADIR)/%.errors-default-hjerson.dat: $(foreach x,ref $H,$(DATADIR)/$x.factors)
	hjerson/generic-wrapper.sh raw_hjerson.py $(foreach x,ref $H,$(DATADIR)/$x.factors) > $@
$(DATADIR)/%.errors-lemmawer-hjerson.dat: $(foreach x,ref $H,$(DATADIR)/$x.factors)
	hjerson/generic-wrapper.sh raw_hjerson_lemma-wer.py $(foreach x,ref $H,$(DATADIR)/$x.factors) > $@
$(DATADIR)/%.errors-$(VARIANT)-addicter.xml: $(foreach x,src $H ref,$(DATADIR)/$x.factors) $(DATADIR)/$H.aligned-$(VARIANT)
	../finderrs.pl $(foreach x,src $H ref,$(DATADIR)/$x.factors) $(DATADIR)/$H.aligned-$(VARIANT) > $@
$(DATADIR)/%.errors-$(VARIANT)-addicter.dat: $(DATADIR)/%.errors-$(VARIANT)-addicter.xml
	../err2hjerson.pl < $< > $@


results: $(DATADIR)/$H.$(VARIANT)-$(DETECTOR).results
$(DATADIR)/$H.$(VARIANT)-$(DETECTOR).results: $(DATADIR)/$H.errors-$(VARIANT)-$(DETECTOR).dat
	./eval-prec-rec.sh $(DATADIR)/$H.errors.gold.dat $(DATADIR)/$H.errors-$(VARIANT)-$(DETECTOR).dat > $@

ranking: $(DATADIR)/$H.$(VARIANT)-$(DETECTOR).ranking
$(DATADIR)/$H.$(VARIANT)-$(DETECTOR).ranking: $(DATADIR)/$H.errors-$(VARIANT)-$(DETECTOR).dat
	perl -e 'print "Ranking evaluation for $(DETECTOR), $(VARIANT) ($(DATADIR), $(H); manual/automatic counts)\n||border=1\n||! system || infl || reord || miss || ext || lex ||! rho ||\n"; for my $$idx (1..3) { \
		system "./eval-rank-parts.sh $(DATADIR)/$H.errors.gold.dat $(DATADIR)/$H.errors-$(VARIANT)-$(DETECTOR).dat $$idx"; }' > $@

info:
	@echo DETECTOR=$(DETECTOR) VARIANT=$(VARIANT) H=$H DATASET=$(DATASET)

all:
	perl -e 'for my $$e (qw($(DETECTORS))){for my $$v (qw($(VARIANTS))){#\
	 next if $$e eq "hjerson"  && index("$(HJERSON_VARIANTS)",$$v)==-1;#\
	 next if $$e eq "addicter" && index("$(ADDICTER_VARIANTS)",$$v)==-1;#\
	 for my $$h (qw($(HYPS))){for my $$d (qw($(DATASETS))){#\
	 system "make -s info $(DO) $(DOMORE) DETECTOR=$$e VARIANT=$$v H=$$h DATASET=$$d\n";}}}}'

# SGE cluster
qall:
	perl -e 'for my $$e (qw($(DETECTORS))){for my $$v (qw($(VARIANTS))){#\
	 next if $$e eq "hjerson"  && index("$(HJERSON_VARIANTS)",$$v)==-1;#\
	 next if $$e eq "addicter" && index("$(ADDICTER_VARIANTS)",$$v)==-1;#\
	 for my $$h (qw($(HYPS))){for my $$d (qw($(DATASETS))){#\
	 print "$(DO) DETECTOR=$$e VARIANT=$$v H=$$h DATASET=$$d\n";}}}}' | \
	$(QCMD) --jobs=$(JOBS) --jobname=addicter --join "while read params; do make -s pp \$$params; done"


clean:
	rm -rf $(DATADIR)/*.aligned-* $(DATADIR)/*.errors-*.dat $(DATADIR)/*.results $(DATADIR)/*.ranking

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
