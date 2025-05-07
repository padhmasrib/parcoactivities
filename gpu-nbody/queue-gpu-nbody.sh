#!/bin/bash

#!/bin/sh
# sbatch --partition=Centaurus --chdir=`pwd` --time=3:52:00 --mem-per-cpu=16G --nodes=1 --tasks-per-node=1 --job-name=par-nbody run-par-nbody.sh
# sbatch --partition=Centaurus --chdir=`pwd` --time=3:52:00 --mem-per-cpu=16G --nodes=1 --tasks-per-node=1 --job-name=gpu-nbody run-gpu-nbody.sh

#SBATCH --job-name=cuda_add
#SBATCH --partition=GPU
#SBATCH --time=01:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --gres=gpu:1

sbatch --partition=GPU --chdir=`pwd` --time=01:00:00 --nodes=1 --ntasks-per-node=1 --gres=gpu:1 --job-name=gpu-nbody run-gpu-nbody.sh

