#!/bin/bash
# Inputs: Receptor, Ligand, mdp Directory, Directory
# Make output workspace
FORCEFEILD=charmm27
WATER=tip3p
receptor=$(readlink -e "$1")
ligand=$(readlink -e "$2")
supplydir=$(readlink -e "$3")
workspace=$(readlink -e "$4")
# Copy ligand and Receptor, and mpd files to workspace
module load openmpi gromacs

cp -a $supplydir/. "$workspace"

cp "$ligand" "$workspace"

cp "$receptor" "$workspace"

cd "$workspace"
receptor=$(basename -- "$receptor")
ligand=$(basename -- "$ligand")
receptorname="${receptor%.*}"
ligandname="${ligand%.*}"
# From anywhere, make 
gmx_mpi pdb2gmx -f "$receptor" -o "${receptorname}.gro" -ff ${FORCEFEILD} -water ${WATER} -merge all -ignh

gmx_mpi editconf -f "$ligand" -o "${ligandname}.gro"

gmx_mpi editconf -f "${receptorname}.gro" -o combo_box.gro -c -d 5.0 -bt cubic

#adding water  - tip3p model 
#gmx_mpi editconf -f spc216.gro -o empty.gro -box 3 3 3
#gmx_mpi solvate -cs tip3p -o tip3p.gro -box 3 3 3
gmx_mpi solvate -cp combo_box.gro -cs tip3p -o solv.gro -p topol.top
cp topol.top topol_solv.top
#mv ./#topol.top.1# topol_proc.top
gmx_mpi grompp -f ions.mdp -c solv.gro -p topol.top -o ions.tpr -maxwarn 1

#adding ions, Potassium and Chlorine at 0.1 M concentration 
echo 13 | gmx_mpi genion -s ions.tpr -o neutral.gro -p topol.top -pname NA -nname CL -conc 0.1 -neutral
#       select 3
#renaming the topology files to stay up to date 
mv topol_solv.top topol_ions.top
#mv ./#topol_solv.top.1# topol_solv.top

gmx_mpi grompp -f minim.mdp -c neutral.gro -p topol.top -o "${receptorname}.tpr" -maxwarn 1 && exit
#gmx_mpi mdrun -v -deffnm em 
#sbatch /u/wlawler/scripts/minim.sh

# creating an index file, should create an object that refers all the structures a part of the complex 
#gmx_mpi make_ndx -f em.gro -o index.ndx
