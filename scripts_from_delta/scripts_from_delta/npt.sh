#!/bin/bash
#SBATCH --job-name=npt.em
#SBATCH --output="NPT.out"
#SBATCH --account=bfam-delta-cpu
#SBATCH --ntasks=2
#SBATCH --partition=cpu   
#SBATCH --ntasks-per-node=64
#SBATCH --mem=64G
#SBATCH --time=06:00:00             # Time limit hrs:min:sec
#SBATCH --export=ALL
#SBATCH --error=em.err
#SBATCH --mail-user=lawlew2@rpi.edu
#SBATCH --mail-type="BEGIN,END"
# load GNU compiler libraries
#%Module module load gcc/8.4.0/1
#%Module module load cmake
#%Module module load spectrum-mpi

# Set the number of threads per task(Default=1)
#export OMP_NUM_THREADS=64

module load openmpi
source /u/wlawler/gromacs-2025.2/install/bin/GMXRC

srun gmx_mpi mdrun -deffnm /projects/bfam/wlawler/npt


