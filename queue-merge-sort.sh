#!/bin/sh
sbatch --partition=Centaurus --chdir=`pwd` --time=0:52:00 --mem-per-cpu=16G --nodes=1 --tasks-per-node=1 --job-name=mod1mergesort run-merge-sort.sh

