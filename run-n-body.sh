#!/bin/sh
## need to create a Makefile and use the make command instead of the following
g++ n-body.cpp -o n-body

echo
echo "Time to simulate the solar system with dt = 200 and for 5000000 steps"
## How often to dump the state: 500000
./n-body 3 200 5000000 100000

echo
echo "How long does it take to simulate 100 particles dt=1 for 10000 steps?"
## How often to dump the state: 1000
./n-body 100 1 10000 1000

echo
echo "How long does it take to simulate 1000 particles dt=1 for 10000 steps?"
## How often to dump the state: 1000
./n-body 1000 1 10000 1000


