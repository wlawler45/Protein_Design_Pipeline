#!/bin/bash
#!/bin/bash
#!/bin/bash
#SBATCH --job-name=
#SBATCH --output="processTraj.%j.%N.out"
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=2
#SBATCH --cpus-per-task=64
#SBATCH --time=06:00:00             # Time limit hrs:min:sec
#SBATCH --export=ALL
# load GNU compiler libraries
#%Module module load gcc/8.4.0/1
#%Module module load cmake
#%Module module load spectrum-mpi
#%Module module load cuda/11.2
# Set the number of threads per task(Default=1)
#export OMP_NUM_THREADS=64

#gromacs post simulation processing - for processing Bulk Magnesium and DNA 
dir=`pwd`
inputs=$dir/inputs  #input folder 
#read -p 'XTC file name: ' xtcname
#gmx make_ndx -f md_0_1.gro -o analysis.ndx
#read
#Ignoring Mg ions, subset trajectory with 50ns data
echo 1 | gmx trjconv -f md_0_1.xtc -o subset.xtc -n analysis.ndx 
#read
#fitting the trajectory and putting any atoms that jump across the box back into their corect location
#read
echo 1 1 | gmx trjconv -f subset.xtc -s md_0_1.tpr -o nojump.xtc -pbc nojump -n analysis.ndx
#fitting the group (either just duplex or duplex and ligand) to the reference structure by rotating and translating
echo 1 1 | gmx trjconv -f nojump.xtc -s md_0_1.tpr -o fit.xtc -fit rot+trans -n analysis.ndx 
#read
#creating a snap shot from the first frame 
echo 1 1 | gmx trjconv -f fit.xtc -b 0 -e 0 -o protein_complex.pdb -s md_0_1.tpr -n analysis.ndx








