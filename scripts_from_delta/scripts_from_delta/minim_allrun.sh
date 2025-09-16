#!/bin/bash
#SBATCH --job-name=minim.em
#SBATCH --nodes=1
#SBATCH --account=bfam-delta-cpu
#SBATCH --partition=cpu    
#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=32
#SBATCH --time=08:00:00
#SBATCH --mem=64G
#SBATCH --output=em.out
#SBATCH --error=em.err
#SBATCH --mail-user=lawlew2@rpi.edu
#SBATCH --mail-type="BEGIN,END"

module load openmpi
source /u/wlawler/gromacs-2025.2/install/bin/GMXRC

JOB1=$(srun gmx_mpi mdrun -v -deffnm "/projects/bfam/wlawler/${current_name}/em" )


srun --dependency=afterok:$JOB1 gmx_mpi make_ndx -f "/projects/bfam/wlawler/${current_name}/em.gro"  -o index.ndx
