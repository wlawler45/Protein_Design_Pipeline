#!/bin/bash
# source $(dirname $0)/prepall.sh 
bash $(dirname $0)/prepall.sh $1 $2 $3 $4
receptor=$(readlink -e "$1")
ligand=$(readlink -e "$2")
supplydir=$(readlink -e "$3")
workspace=$(readlink -e "$4")
# Copy ligand and Receptor, and mpd files to workspace
receptor=$(basename -- "$receptor")
ligand=$(basename -- "$ligand")
receptorname="${receptor%.*}"
ligandname="${ligand%.*}"
echo "Running SBATCH"
# Path of final output: "${workspace}/${receptorname}.tpr"
fullarg="${workspace}/${receptorname}"
sbatch $(dirname $0)/minimize.sh $fullarg