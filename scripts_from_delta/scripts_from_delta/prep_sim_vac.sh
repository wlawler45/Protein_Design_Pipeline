#!/bin/bash

#what should have been done before this script: 
# Converting each of the structures into GRO files by either 
# forcefield or editconf (if manual parameters have been created)
#

dir=`pwd`
inputs=$dir/inputs
source /u/wlawler/gromacs-2025.2/install/bin/GMXRC
#creating the box 
gmx_mpi editconf -f attempthiwithHana.gro -o combo_box.gro -c -d 5.0 -bt cubic
#adding water  - tip3p model 
#gmx_mpi editconf -f spc216.gro -o empty.gro -box 3 3 3
mkdir "/projects/bfam/wlawler/${current_name}"

gmx_mpi grompp -f /u/wlawler/scripts/minim.mdp -c combo_box.gro -p topol.top -o "/projects/bfam/wlawler/${current_name}/em.tpr" -maxwarn 2