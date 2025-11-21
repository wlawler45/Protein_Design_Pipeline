import Bio.PDB as PDB
import sys,re,json
from pathlib import Path
from typing import List, Dict, Tuple
"""
Usage:
  python parse_args.py input_complex {
      [radius=VALUE] 
      [design=VALUE] 
      [sites=VALUE,VALUE...] 
      [folder=VALUE]
      [files=VALUE,VALUE...]}
"""


VALID_PREFIXES = ("radius=", "design=", "sites=", "folder=", "files=")
def parse_args(argv: List[str]) -> Dict:
    if len(argv) < 2:
        raise SystemExit("Error: missing cif/pdb File")
    elif argv[1] == "-h":
        raise SystemExit("python parse_args.py path/to/file.cif/pdb {[radius=VALUE] [design=CHAIN] [sites=RESID,RESID...], [folder=DIR], [files=CHAIN_A,CHAIN_B...,[COMPLEX]]}")
    input_file = argv[1]
    parsed = {"input_file": input_file,"folder": ".", "radius": None, "design": None, "sites": None, "files": ""}
    for raw in argv[2:]:
        matched = False
        # handle small arguments
        for p in VALID_PREFIXES:
            if raw.startswith(p):
                val = raw[len(p):]
                key = p[:-1]  # e.g., "radius"
                parsed[key] = val
                matched = True
                break
        if not matched:
            raise SystemExit(f"Error: unrecognized argument '{raw}'. Must start with one of {VALID_PREFIXES}")
    return parsed
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
# AI func
def get_id_chain(s: str) -> Tuple[int, str]:
    m = re.match(r'^([A-Za-z]+)(\d+)$', s)
    if m:
        letters, nums = m.group(1), m.group(2)
        return (int(nums), letters)
    m = re.match(r'^(\d+)([A-Za-z]+)$', s)
    if m:
        nums, letters = m.group(1), m.group(2)
        return (int(nums), letters)
    raise Exception(f"Could not parse chain site {s}")
# Complex is prased complex
# files is none or comma seperated string of values
def save_pdbs(complex, folder: str, file_names: str):
    chain_files = {}
    base_folder=Path(folder)
    base_folder.mkdir(parents=True, exist_ok=True)
    if file_names != "": 
        files = file_names.split(",")
    else: files = []
    chain_number = 0
    io=PDB.PDBIO()
    for chain in complex:
        save_as = f"chain_{chain.id}.pdb"
        if chain_number < len(files):
            save_as = files[chain_number]
            if not save_as.endswith(".pdb"):
                save_as += ".pdb"
        # Perform io
        io.set_structure(chain)
        io.save(str(base_folder / save_as))
        chain_files[chain.id]=str((base_folder / save_as).resolve)
        chain_number += 1
    save_as = f"complex.pdb"
    if chain_number < len(files):
        save_as = files[chain_number]
        if not save_as.endswith(".pdb"):
            save_as += ".pdb"
    # Perform io
    io.set_structure(complex)
    io.save(str(base_folder / save_as))
    return chain_files
def getrestraints(complex, design_chain, sites, radius):
    residue_sites = []
    for site in sites.split(","):
        sitenum, sitechain = get_id_chain(site)
        residue_sites.append(complex[sitechain][sitenum])
    site_atoms=PDB.Selection.unfold_entities(residue_sites, "A")
    design_atoms=PDB.Selection.unfold_entities(complex[design_chain])
    ns_pairs =PDB.NeighborSearch(site_atoms+design_atoms)
    pairs = ns_pairs.search_all(radius,'R')
    restraints = {}
    for pair in pairs:
        # Ligand: any binding biomolecule
        ligand_site, design_site = sorted(pair, 
            key = lambda a: a.get_parent().id==design_chain)
        # Check if both are from the design chain
        if ligand_site.get_parent().id == design_chain:
            continue
        ligand_chain, ligand_res, design_res = (
            ligand_site.get_parent().id, 
            ligand_site.id[1],
            design_site.id[1]
        )
        if ligand_chain not in restraints:
            restraints[ligand_chain] = {}
        if ligand_res not in restraints[ligand_chain]:
            restraints[ligand_chain][ligand_res] = []
        restraints[ligand_chain][ligand_res].append(design_res)
    return restraints
def main():
    args = parse_args(sys.argv)
    # Load input file
    if args["input_file"].endswith("pdb"):
        parser = PDB.PDBParser()
    else: # if args["input_file"].endswith("cif")
        parser = PDB.MMCIFParser()

    complex = parser.get_structure("full", args["input_file"])[0]
    chain_file = save_pdbs(complex, args["folder"],args["files"])
    restraints = getrestraints(complex, args["design"], args["sites"],
                  radius=float(args["radius"]))
    jsonout = []
    tbl_id = 1
    for outer_chain in restraints.keys():
        for outer_res in outer_chain.keys():
            # outer (ligand) json:
            outer_json = create_pair_json(tbl_id = tbl_id,
                chain=outer_chain,
                active=[outer_res],
                target=tbl_id+1,
                file=chain_file[outer_chain],
                radius=float(args["radius"])
            )
            designer_json = create_pair_json(tbl_id = tbl_id+1, 
                chain=args["design"],
                active=[outer_chain[outer_res]],
                target=tbl_id,
                file=chain_file[args["design"]],
                radius=float(args["radius"])
            )
            jsonout.append(outer_json,designer_json)
    fulljson = json.dumps(jsonout, indent=4)
    print(fulljson)
if __name__ == "__main__":
    main()