#!/bin/sh

make par-nbody

echo "------------------------------------------------------"
export OMP_NUM_THREADS=5 
echo "Number of threads used: $OMP_NUM_THREADS"
echo
make par-solar.out
echo
make par-random-100.out
echo
make par-random-1000.out
mv par-solar.out par-solar-5-threads.out
mv par-random-100.out par-random-100-5-threads.out
mv par-random-1000.out par-random-1000-5-threads.out

echo "------------------------------------------------------"
export OMP_NUM_THREADS=10
echo "Number of threads used: $OMP_NUM_THREADS"
echo
make par-solar.out
echo
make par-random-100.out
echo
make par-random-1000.out
mv par-solar.out par-solar-10-threads.out
mv par-random-100.out par-random-100-10-threads.out
mv par-random-1000.out par-random-1000-10-threads.out

echo "------------------------------------------------------"
export OMP_NUM_THREADS=15 
echo "Number of threads used: $OMP_NUM_THREADS"
echo
make par-solar.out
echo
make par-random-100.out
echo
make par-random-1000.out
mv par-solar.out par-solar-15-threads.out
mv par-random-100.out par-random-100-15-threads.out
mv par-random-1000.out par-random-1000-15-threads.out

