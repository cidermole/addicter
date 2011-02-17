#!/bin/bash

cat $@ | sed -e "s/|[^ ]\+//g"
