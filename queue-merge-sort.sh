#!/bin/sh
sbatch --partition=Centaurus --chdir=`pwd` --time=00:10:00 --nodes=1 --tasks-per-node=1 --job-name=mod1mergesort run-merge-sort.sh

