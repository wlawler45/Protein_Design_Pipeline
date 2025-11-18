# This script reads a PDB file and a position file, categorizes residues at specified positions, and prints the results
# Eventually to be integrated with mutation functionality

import argparse
from pymut import mutate
from Bio.PDB.PDBIO import PDBIO
from Bio.PDB import PDBParser

Positive = {"R", "H", "K"}
Negative = {"D", "E"}
Polar = {"S", "T", "N", "Q"}
NonPolar = {"G", "A", "V", "I", "L", "M", "F", "W", "P", "C"}
Aromatic = {"F", "Y", "W", "H"} # Bulky 
Hydrophobic = {"A", "V", "I", "L", "M", "F", "Y", "W"}

positions = {}

def categorize_residue(residue):
    res_name = residue.get_resname().strip().upper()
    if res_name in Positive:
        return "Positive"
    elif res_name in Negative:
        return "Negative"
    elif res_name in Polar:
        return "Polar"
    elif res_name in NonPolar:
        return "NonPolar"
    elif res_name in Aromatic:
        return "Aromatic"
    elif res_name in Hydrophobic:
        return "Hydrophobic"
    else:
        return "Unknown"

posfilename = input("Enter the position file name: ")
with open(posfilename, 'r') as posfile:
    for line in posfile:
        parts = line.split()
        if len(parts) >= 3:
            chain_id = parts[0]
            res_num = int(parts[1])
            positions[(chain_id, res_num)] = parts[2]  # Store additional info if needed

# debug 
for pos in positions:
    print(f"Position to analyze: Chain {pos[0]}, Residue Number {pos[1]}")

pdbfilename = input("Enter the PDB file name: ")
parser = PDBParser(QUIET=1)
structure = parser.get_structure("my_structure", pdbfilename)

# analyze + categorize the residues at positions from the position file 
for model in structure:
    for chain in model:
        for residue in chain:
            res_id = residue.get_id()
            if res_id[0] == ' ':
                res_num = res_id[1]
                chain_id = chain.get_id()
                if (chain_id, res_num) in positions:
                    category = categorize_residue(residue)
                    print(f"Chain: {chain_id}, Residue Number: {res_num}, Category: {category}")

