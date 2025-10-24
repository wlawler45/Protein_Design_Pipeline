from vina import Vina
from openbabel import pybel 
import os
import subprocess

# ask user for receptor and ligand file names
receptor_file = input("Enter the receptor file name (PDB format): ")
ligand_file = input("Enter the ligand file name (PDB format): ")

# ask user for center and box size (box size is / 2)
center_x = float(input("Enter the center x coordinate: "))
center_y = float(input("Enter the center y coordinate: "))
center_z = float(input("Enter the center z coordinate: "))
box_size = float(input("Enter the box size (distance from center to one edge): "))

# Convert receptor to PDBQT
receptor_pdbqt = receptor_file.replace('.pdb', '.pdbqt')
os.system(f'obabel {receptor_file} -O {receptor_pdbqt} -xr -p 7.4 --partialcharge gasteiger')

# Convert ligand to PDBQT (add --gen3d to fix kekulize error)
ligand_pdbqt = ligand_file.replace('.pdb', '.pdbqt')
os.system(f'obabel {ligand_file} -O {ligand_pdbqt} --partialcharge gasteiger')

# Update file names 
receptor_file = receptor_pdbqt
ligand_file = ligand_pdbqt

# Init vina 
v = Vina(sf_name='vina')

# Load receptor and ligand
v.set_receptor(receptor_file)
v.set_ligand_from_file(ligand_file)

v.compute_vina_maps(center=[center_x, center_y, center_z], box_size=[box_size * 2, box_size * 2, box_size * 2])

# Score the current pose
energy = v.score()
print('Score before minimization: %.3f (kcal/mol)' % energy[0])

# Minimized locally the current pose
energy_minimized = v.optimize()
print('Score after minimization : %.3f (kcal/mol)' % energy_minimized[0])
v.write_pose('1iep_ligand_minimized.pdbqt', overwrite=True)

# Dock the ligand
v.dock(exhaustiveness=32, n_poses=20)
# Save the best scored pose, output file name is ${ligand_file}_vina_out.pdbqt 
v.write_poses(f'{ligand_file}_vina_out.pdbqt', n_poses=5, overwrite=True)

# Upload to slurm here 
slurm_script = f"""#!/bin/bash
#SBATCH --job-name=vina_dock
#SBATCH --output={ligand_file}_vina_slurm.out
#SBATCH --error={ligand_file}_vina_slurm.err
#SBATCH --time=01:00:00
#SBATCH --partition=cpu
#SBATCH --account=bfam-delta-cpu
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4

module load python
python {os.path.abspath(__file__)}
"""

slurm_filename = "vina_dock.slurm"
with open(slurm_filename, "w") as f:
    f.write(slurm_script)

subprocess.run(["sbatch", slurm_filename])
print(f"Submitted SLURM job with script {slurm_filename}")
