#!/bin/bash

cat $@ | sed -e "s/|[ACDGHSUVXY]|/|Content|/g;s/|\(Z\|SENT\)|/|Punct|/g;s/N/Number/g;s/|T|/|Foreign|/g;s/|[A-Z]|/|Aux|/g"
