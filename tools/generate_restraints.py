from Bio.PDB.MMCIFParser import MMCIFParser
import Bio.PDB as PDB
import sys
import json

## Modify create_pair_json to change TBL output ##
def create_pair_json(tbl_id, chain, active, target, file, radius):
    return {
    'id': tbl_id, 
    'chain': chain,
    'active': active,
    'passive': [],
    'target': [target],
    'structure': file,
    'target_distance': radius,
    'lower_margin': radius,
    'upper_margin' : 0,
    # Could add
    }

# Way too many arguments 
DESIGNFILE="designer.pdb"
LIGANDFILE="ligand.pdb"
COMPLEXFILE="complex.pbd"
cif_file = sys.argv[1]
ligand_chain = sys.argv[2]
ligand_bond_sites = sys.argv[3].split(",")
radius = float(sys.argv[4])
# Make sure ligand and designer chain are set by argument
design_chain = "A"
if ligand_chain == "A":
    design_chain = "B"

parser = MMCIFParser()
structure = parser.get_structure("full", cif_file)
# 

pcomplex = structure[0]
# SAVE AS PDB
io=PDB.PDBIO()
io.set_structure(pcomplex[design_chain])
io.save(DESIGNFILE)
io.set_structure(pcomplex[ligand_chain])
io.save(LIGANDFILE)
io.set_structure(pcomplex)
io.save(COMPLEXFILE)

# Lets get each target 
site_residues=[pcomplex[ligand_chain][int(i)] for i in ligand_bond_sites]
# Get atoms
site_atoms=PDB.Selection.unfold_entities(site_residues, "A")
protien_atoms=PDB.Selection.unfold_entities(pcomplex[design_chain],"A")
# Get all pairs, not just some.
ns_pairs =PDB.NeighborSearch(site_atoms+protien_atoms)
pairs = ns_pairs.search_all(radius,'R')
# Key as ligand residue, value as designer residue array
restrain_pairs = {}
for pair in pairs:
    # Check if it is between designer and ligand
    if pair[0].get_parent().id != pair[1].get_parent().id:
        # Its between a designer and ligand
        # Use quick assignment
        if pair[0].get_parent().id == ligand_chain:
            ligand_pair, design_pair =  pair[0], pair[1]
        else: 
            ligand_pair, design_pair =  pair[1], pair[0]
        if ligand_pair.id[1] in restrain_pairs.keys():
            restrain_pairs[ligand_pair.id[1]].append(design_pair.id[1])
        else: restrain_pairs[ligand_pair.id[1]]=[design_pair.id[1]]
jsonout = []
tbl_id = 1
for ligand_target in restrain_pairs.keys():
    tbl_ligand = create_pair_json(tbl_id=tbl_id, 
                                  chain=ligand_chain, 
                                  active=[ligand_target],
                                  target=tbl_id+1,
                                  file=LIGANDFILE,
                                  radius=radius)
    tbl_designer = create_pair_json(tbl_id=tbl_id+1, 
                                  chain=design_chain, 
                                  active=restrain_pairs[ligand_target],
                                  target=tbl_id,
                                  file=DESIGNFILE,
                                  radius=radius)
    jsonout.append(tbl_ligand)
    jsonout.append(tbl_designer)
    tbl_id += 2
fulljson = json.dumps(jsonout, indent=4)
print(fulljson)