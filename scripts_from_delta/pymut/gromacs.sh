#!/bin/bash

# Script to minimize specific chains in GROMACS
# Usage: ./gromacs.sh chain1,chain2,chain3

# Check if chains parameter is provided. if not show usage and exit
if [ -z "$1" ]; then
    echo "Usage: $0 <chains>"
    echo "Example: $0 A,B,C"
    exit 1
fi

CHAINS="$1"
STRUCTURE="input.pdb"
OUTPUT_PREFIX="minimized"

# Create index file for specified chains
echo "Creating index file for chains: $CHAINS"
gmx_mpi make_ndx -f "$STRUCTURE" -o index.ndx << EOF
chain $CHAINS
q
EOF

# Generate topology
echo "Generating topology..."
gmx_mpi pdb2gmx -f "$STRUCTURE" -o processed.gro -water spce -ignh

# Create energy minimization parameter file
cat > minim.mdp << 'EOF'
integrator  = steep
emtol       = 1000.0
emstep      = 0.01
nsteps      = 50000
nstlist     = 10
cutoff-scheme = Verlet
ns_type     = grid
coulombtype = PME
rcoulomb    = 1.0
rvdw        = 1.0
pbc         = xyz
EOF

# Prepare minimization with frozen atoms (all except selected chains)
gmx_mpi grompp -f minim.mdp -c processed.gro -p topol.top -n index.ndx -o em.tpr -maxwarn 1


# Run energy minimization
echo "Running energy minimization on chains: $CHAINS"
gmx_mpi mdrun -v -deffnm em


# Convert output
gmx_mpi editconf -f em.gro -o "${OUTPUT_PREFIX}.pdb"

echo "Minimization complete: ${OUTPUT_PREFIX}.pdb"
