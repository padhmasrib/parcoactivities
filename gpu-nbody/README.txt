# To Compile and run in Centaurus using GPU partition:

cd /users/pbaskara/parcoactivities/gpu-nbody
make clean

# To submit the job in Centaurus
./queue-gpu-nbody.sh

# The above job runs run-gpu-nbody.sh in the above current directory
# It runs the job for 1000 particles, 10,000 particles and 100,000 particles
and generates the corresponding .out files:

# echo "------------------------------------------------------"
# make gpu-random-1000.out
#
# echo "------------------------------------------------------"
# make gpu-random-10000.out
#
# echo "------------------------------------------------------"
# make gpu-random-100000.out

Ran the job two times and copied the outputs and log files to the directory ./run-01-out ./run-02-out

Execution time was so fast.

./run-01-out/slurm-15864.out
./run-02-out/slurm-15865.out

Found solar (planet) model faster with GPU than with CPU.
