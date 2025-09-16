#!/bin/bash
source /u/wlawler/gromacs-2025.2/install/bin/GMXRC
current_name="losingitnoviral"
export current_name
/u/wlawler/scripts/prep_sim_vac.sh
JOBminim=$(sbatch /u/wlawler/scripts/minim_allrun.sh)

