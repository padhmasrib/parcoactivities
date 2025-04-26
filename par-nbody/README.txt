

# To Compile and run in Centaurus:

cd /users/pbaskara/parcoactivities/par-nbody
make clean

# To submit the job in Centaurus

./queue-par-nbody.sh

# The above job runs run-par-nbody.sh in the above current directory
# It sets the number of threads and runs make for different targets like this
# export OMP_NUM_THREADS=5
# echo "Number of threads used: $OMP_NUM_THREADS"
# echo
# make par-solar.out
# echo
# make par-random-100.out
# echo
# make par-random-1000.out

# Used the sequential provided with the assignment.
# The sequential outputs are in:
#     /users/pbaskara/parcoactivities/par-nbody/sequential