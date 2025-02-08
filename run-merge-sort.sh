#!/bin/sh
## need to create a Makefile and use the make command instead of the following
g++ merge-sort.cpp -o merge-sort

## redirects time output also to merge-sort-answer for various array sizes
{ 
    (time ./merge-sort 10)
    (time ./merge-sort 100)
    (time ./merge-sort 1000)
    (time ./merge-sort 10000)
    (time ./merge-sort 100000)
    (time ./merge-sort 1000000)
    (time ./merge-sort 10000000)
    (time ./merge-sort 100000000)
    (time ./merge-sort 1000000000)
} > merge-sort-answer 2>&1

