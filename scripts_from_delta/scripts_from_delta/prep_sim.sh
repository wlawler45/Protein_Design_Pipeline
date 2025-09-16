#!/bin/bash

#what should have been done before this script: 
# Converting each of the structures into GRO files by either 
# forcefield or editconf (if manual parameters have been created)
#

dir=`pwd`
inputs=$dir/inputs

#creating the box 
gmx_mpi editconf -f conf.gro -o combo_box.gro -c -d 5.0 -bt cubic
#adding water  - tip3p model 
#gmx_mpi editconf -f spc216.gro -o empty.gro -box 3 3 3
#gmx_mpi solvate -cs tip3p -o tip3p.gro -box 3 3 3
gmx_mpi solvate -cp combo_box.gro -cs tip3p -o solv.gro -p topol.top
read
cp topol.top topol_solv.top
#mv ./#topol.top.1# topol_proc.top
gmx_mpi grompp -f ions.mdp -c solv.gro -p topol.top -o ions.tpr -maxwarn 1

#adding ions, Potassium and Chlorine at 0.1 M concentration 
gmx_mpi genion -s ions.tpr -o neutral.gro -p topol.top -pname NA -nname CL -conc 0.1 -neutral
#       select 3
#renaming the topology files to stay up to date 
mv topol_solv.top topol_ions.top
#mv ./#topol_solv.top.1# topol_solv.top

#energy minimization
gmx_mpi grompp -f minim.mdp -c neutral.gro -p topol.top -o /projects/bfam/wlawler/em.tpr -maxwarn 1
#gmx_mpi mdrun -v -deffnm em 
#sbatch /u/wlawler/scripts/minim.sh

# creating an index file, should create an object that refers all the structures a part of the complex 
#gmx_mpi make_ndx -f em.gro -o index.ndx

echo setup is complete, next script to run is nvt.sh to prepare for nvt step
