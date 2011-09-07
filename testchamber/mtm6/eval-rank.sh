#!/bin/bash

#
# given a manually annotated file and an automatically annotaged one (Hjerson's or Addicter's),
# print a table of counts and rank correlations 
#
# input: manual_file automatic_file; both in Hjerson's output format (with flags reversed):
# 
# 1::ref-err-cats: the reord~~total reord~~amount miss~~designated for assistance to reord~~the reord~~system is to be divided into two parts .  
# 1::hyp-err-cats: the for reord~~the reord~~system to help ext~~certain reord~~total reord~~amount will be divided into two parts .  
# 
# 2::ref-err-cats: lex~~there infl~~are price lex~~and qualitative categories here reord~~as reord~~well .  
# 2::hyp-err-cats: lex~~here too there infl~~is price and quality categories .  
# ...
#
