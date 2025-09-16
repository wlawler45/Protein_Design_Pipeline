#!/bin/bash


dir=`pwd`
inputs=$dir/inputs

#for i in combo
#do
#    cd $dir/$i
#    cp $inputs/nvt.mdp . 
#    gmx grompp -f nvt.mdp -c em.gro -r em.gro -p topol_ions.top -o nvt.tpr -n index.ndx
#    cd $dir 
#
#done 

gmx_mpi grompp -f nvt.mdp -c /projects/bfam/wlawler/em.gro -r /projects/bfam/wlawler/em.gro -p topol.top -o nvt.tpr -n index2.ndx