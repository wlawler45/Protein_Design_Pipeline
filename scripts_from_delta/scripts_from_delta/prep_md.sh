#!/bin/bash


gmx_mpi grompp -f mdout.mdp -c /projects/bfam/wlawler/npt.gro -p topol.top -o /projects/bfam/wlawler/md_0_1.tpr -n index2.ndx   
