#!/bin/bash
# source $(dirname $0)/prepall.sh 

bash $(dirname $0)/prepall.sh $1 $2 $3 $4 1>>output.log 2>>error.log
receptor=$(readlink -e "$1")
ligand=$(readlink -e "$2")
supplydir=$(readlink -e "$3")
workspace=$(readlink -e "$4")
# Copy ligand and Receptor, and mpd files to workspace
receptor=$(basename -- "$receptor")
ligand=$(basename -- "$ligand")
receptorname="${receptor%.*}"
ligandname="${ligand%.*}"
# Path of final output: "${workspace}/${receptorname}.tpr"
fullarg="${workspace}/${receptorname}"
echo "${fullarg} for SBATCH"
sbatch <<EOT
#!/bin/bash
#SBATCH --job-name=minim.em
#SBATCH --nodes=1
#SBATCH --account=bfam-delta-cpu
#SBATCH --partition=cpu    
#SBATCH --ntasks=32
#SBATCH --ntasks-per-node=32
#SBATCH --time=08:00:00
#SBATCH --mem=64G
#SBATCH --output=ev.out
#SBATCH --error=ev.err
#SBATCH --mail-user=wallaa3@rpi.edu
#SBATCH --mail-type="BEGIN,END"
srun gmx_mpi mdrun -v -deffnm ${fullarg}
echo "Done" >> ev.err

EOT