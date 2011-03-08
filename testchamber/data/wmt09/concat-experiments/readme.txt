Results of Addicter on ../../data/wmt09/concat-experiments

something.ali		alignment from align.pl -n=2 both.ref something.hyp
something.lcs.ali	alignment from align-lcs.pl -n=2 both.ref something.hyp
something.err		errors from finderrs.pl both.src both.ref something.hyp something.ali
something.lcs.err	errors from finderrs.pl both.src both.ref something.hyp something.lcs.ali
something.eval		error evaluation from evalerrs.pl something.hyp-man-tagged something.err both.ref
something.lcs.eval	error evaluation from evalerrs.pl something.hyp-man-tagged something.lcs.err both.ref
