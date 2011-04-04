Results of Addicter on ../../data/wmt09/concat-experiments

ali/X.Y		alignment of translation hypothesis X (cu-bojar/cu-tectomt/google/pctrans) with the alignment method Y
	(LCS/HMM/GIZA++/Berkeley/etc.)
corps/X		source text, reference and hypothesis translations
errs/X.Y		errors tagged in translation hypothesis X based on alignment method Y (or manually tagged for Y=man)
eval/all.Y	comparison of manually and automatically (based on alignment Y) tagged errors

(old:
something.ali		alignment from align.pl -n=2 both.ref something.hyp
something.lcs.ali	alignment from align-lcs.pl -n=2 both.ref something.hyp
something.err		errors from finderrs.pl both.src both.ref something.hyp something.ali
something.lcs.err	errors from finderrs.pl both.src both.ref something.hyp something.lcs.ali
something.eval		error evaluation from evalerrs.pl something.hyp-man-tagged something.err both.ref
something.lcs.eval	error evaluation from evalerrs.pl something.hyp-man-tagged something.lcs.err both.ref)
