#!/bin/bash

cat $@ | sed -e "s/|\([JNV]\|RB\|PDT\)[^|]*|/|Content|/g;s/|CD|/|Number|/g;s/|FW|/|Foreign|/g;s/|\([^A-Z ]\+\|SENT\|SYM\)|/|Punct|/g;s/|[A-Z]\+|/|Aux|/g;s/|[WP]P\$|/|Aux|/g;s/|\(W.*\|TO\|UH\|DT\|EX\)|/|Aux|/g"
