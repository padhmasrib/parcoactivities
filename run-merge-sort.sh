#!/bin/sh
## need to create a Makefile and use the make command instead of the following
g++ merge-sort.cpp -o merge-sort

## redirects time output also to merge-sort-answer
(time ./merge-sort 12) > merge-sort-answer 2>&1

