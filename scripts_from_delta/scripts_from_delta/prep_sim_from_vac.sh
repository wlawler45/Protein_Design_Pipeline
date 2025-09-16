#!/bin/bash

#what should have been done before this script: 
# Converting each of the structures into GRO files by either 
# forcefield or editconf (if manual parameters have been created)
#




gmx_mpi solvate -cp /projects/bfam/wlawler/${current_name}/em.gro -cs /u/wlawler/scripts/tip3p -o /projects/bfam/wlawler/${current_name}/solv.gro -p topol.top
read
cp topol.top topol_solv.top
#mv ./#topol.top.1# topol_proc.top
#IF YOU ERROR HERE WITH MISMATCH ATOM NUMBERS IN TOPOL.TOP, See if there are multiple SOL lines at the end and erase any copies
#also choose option 14 SOL not WATER
gmx_mpi grompp -f /u/wlawler/scripts/ions.mdp -c /projects/bfam/wlawler/${current_name}/solv.gro -p topol.top -o /projects/bfam/wlawler/${current_name}/ions.tpr -maxwarn 1

#adding ions, Potassium and Chlorine at 0.1 M concentration 

gmx_mpi genion -s /projects/bfam/wlawler/${current_name}/ions.tpr -o /projects/bfam/wlawler/${current_name}/neutral.gro -p topol.top -pname NA -nname CL -conc 0.15 -neutral
#       select 3
#renaming the topology files to stay up to date 
mv topol_solv.top topol_ions.top
#mv ./#topol_solv.top.1# topol_solv.top

#energy minimization
gmx_mpi grompp -f /u/wlawler/scripts/minim.mdp -c /projects/bfam/wlawler/${current_name}/neutral.gro -p topol.top -o /projects/bfam/wlawler/${current_name}/em_vac.tpr -maxwarn 1
#gmx_mpi mdrun -v -deffnm em 
#sbatch /u/wlawler/scripts/minim.sh

# creating an index file, should create an object that refers all the structures a part of the complex 
#gmx_mpi make_ndx -f em.gro -o index.ndx

echo setup is complete, next script to run is nvt.sh to prepare for nvt step
