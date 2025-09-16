#!/bin/bash


#TODO change input paths
gmx_mpi grompp -f npt.mdp -c nvt.gro -r nvt.gro -t nvt.cpt -p topol.top -o /projects/bfam/wlawler/npt.tpr -n index2.ndx
