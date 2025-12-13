#!/usr/bin/env bash
set -euo pipefail

# Minimize selected chains in GROMACS, freezing everything else.
# Examples:
#   ./gromacs_minimize_chains.sh -c A,B,C -f input.pdb -o minimized
#   ./gromacs_minimize_chains.sh -c A -ff amber99sb-ildn -water spce
#   ./gromacs_minimize_chains.sh -c A,B --no-freeze

GMX_BIN="${GMX_BIN:-gmx_mpi}"   # allow override: GMX_BIN=gmx ./script.sh ...

usage() {
  cat <<'EOF'
Usage:
  gromacs_minimize_chains.sh -c A,B,C [options]

Required:
  -c CHAINS        Comma-separated chain IDs (e.g., A,B,C)

Options:
  -f FILE          Input structure (default: input.pdb)
  -o PREFIX        Output prefix (default: minimized)
  -ff FORCEFIELD   pdb2gmx force field (passed to -ff if provided)
  -water MODEL     Water model (default: spce)
  -maxwarn N       grompp -maxwarn (default: 1)
  -ntmpi N         mdrun -ntmpi N (optional)
  -ntomp N         mdrun -ntomp N (optional)
  -gpu_id ID       mdrun -gpu_id ID (optional)
  --no-freeze      Do NOT freeze other atoms (minimize whole system)
  --keep-workdir   Do not delete intermediate files
  -h               Show help

Environment:
  GMX_BIN          GROMACS binary (default: gmx_mpi)

EOF
}

STRUCTURE="input.pdb"
OUTPUT_PREFIX="minimized"
CHAINS=""
WATER_MODEL="spce"
FORCEFIELD=""
MAXWARN="1"
NTMPI=""
NTOMP=""
GPU_ID=""
DO_FREEZE="1"
KEEP_WORKDIR="0"

# --- arg parsing (supports long opts) ---
while [[ $# -gt 0 ]]; do
  case "$1" in
    -c) CHAINS="${2:-}"; shift 2;;
    -f) STRUCTURE="${2:-}"; shift 2;;
    -o) OUTPUT_PREFIX="${2:-}"; shift 2;;
    -ff) FORCEFIELD="${2:-}"; shift 2;;
    -water) WATER_MODEL="${2:-}"; shift 2;;
    -maxwarn) MAXWARN="${2:-}"; shift 2;;
    -ntmpi) NTMPI="${2:-}"; shift 2;;
    -ntomp) NTOMP="${2:-}"; shift 2;;
    -gpu_id) GPU_ID="${2:-}"; shift 2;;
    --no-freeze) DO_FREEZE="0"; shift 1;;
    --keep-workdir) KEEP_WORKDIR="1"; shift 1;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown option: $1" >&2; usage; exit 1;;
  esac
done

if [[ -z "$CHAINS" ]]; then
  echo "Error: -c CHAINS is required (e.g., -c A,B,C)" >&2
  usage
  exit 1
fi

if [[ ! -f "$STRUCTURE" ]]; then
  echo "Error: input structure not found: $STRUCTURE" >&2
  exit 1
fi

if ! command -v "$GMX_BIN" >/dev/null 2>&1; then
  echo "Error: GROMACS binary not found: $GMX_BIN" >&2
  echo "Tip: set GMX_BIN=gmx or GMX_BIN=gmx_mpi" >&2
  exit 1
fi

# --- workdir & logging ---
WORKDIR="work_${OUTPUT_PREFIX}_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$WORKDIR"
LOG="$WORKDIR/run.log"
exec > >(tee -a "$LOG") 2>&1

cleanup() {
  if [[ "$KEEP_WORKDIR" == "0" ]]; then
    # keep the final output files in the original directory
    rm -rf "$WORKDIR"
  else
    echo "Keeping workdir: $WORKDIR"
  fi
}
trap cleanup EXIT

echo "== Settings =="
echo "GMX_BIN        : $GMX_BIN"
echo "Input          : $STRUCTURE"
echo "Chains         : $CHAINS"
echo "Output prefix  : $OUTPUT_PREFIX"
echo "Force field    : ${FORCEFIELD:-'(default prompt)'}"
echo "Water model    : $WATER_MODEL"
echo "Freeze others  : $([[ "$DO_FREEZE" == "1" ]] && echo yes || echo no)"
echo "Workdir        : $WORKDIR"
echo "Log            : $LOG"
echo

cp "$STRUCTURE" "$WORKDIR/input.pdb"
cd "$WORKDIR"

# --- topology generation ---
echo "== pdb2gmx =="
PDB2GMX_ARGS=(-f input.pdb -o processed.gro -water "$WATER_MODEL" -ignh)
if [[ -n "$FORCEFIELD" ]]; then
  PDB2GMX_ARGS+=(-ff "$FORCEFIELD")
fi
"$GMX_BIN" pdb2gmx "${PDB2GMX_ARGS[@]}"

# --- index creation (SELECTED + FROZEN) ---
echo "== make_ndx (SELECTED/FROZEN) =="
IFS=',' read -r -a CHAIN_ARR <<< "$CHAINS"

NDX_IN="ndx.in"
{
  echo "keep 0"  # keep only System as group 0 so numbering is deterministic
  idx=1
  for ch in "${CHAIN_ARR[@]}"; do
    ch="$(echo "$ch" | tr -d '[:space:]')"
    if [[ -z "$ch" ]]; then continue; fi
    echo "chain $ch"
    echo "name $idx CH_$ch"
    idx=$((idx+1))
  done

  n_chains=$((idx-1))
  if [[ "$n_chains" -lt 1 ]]; then
    echo "q"
  else
    # Union: 1 | 2 | ... | n_chains  --> group (n_chains+1)
    union_expr="1"
    for ((i=2; i<=n_chains; i++)); do
      union_expr="$union_expr | $i"
    done
    echo "$union_expr"
    sel_grp=$((n_chains+1))
    echo "name $sel_grp SELECTED"

    # Complement: System & !SELECTED --> group (n_chains+2)
    frz_grp=$((n_chains+2))
    echo "0 & !$sel_grp"
    echo "name $frz_grp FROZEN"
    echo "q"
  fi
} > "$NDX_IN"

"$GMX_BIN" make_ndx -f processed.gro -o index.ndx < "$NDX_IN"

# --- mdp creation ---
echo "== Writing minim.mdp =="
cat > minim.mdp <<'EOF'
integrator      = steep
emtol           = 1000.0
emstep          = 0.01
nsteps          = 50000

; neighbor searching
cutoff-scheme   = Verlet
nstlist         = 10
ns_type         = grid

; electrostatics / vdw
coulombtype     = PME
rcoulomb        = 1.0
rvdw            = 1.0

pbc             = xyz
EOF

if [[ "$DO_FREEZE" == "1" ]]; then
  cat >> minim.mdp <<'EOF'

; Freeze everything in group "FROZEN" (i.e., all except selected chains)
freezegrps      = FROZEN
freezedim       = Y Y Y
EOF
fi

# --- grompp + mdrun ---
echo "== grompp =="
"$GMX_BIN" grompp -f minim.mdp -c processed.gro -p topol.top -n index.ndx -o em.tpr -maxwarn "$MAXWARN"

echo "== mdrun =="
MDRUN_ARGS=(-v -deffnm em)
[[ -n "$NTMPI" ]] && MDRUN_ARGS+=(-ntmpi "$NTMPI")
[[ -n "$NTOMP" ]] && MDRUN_ARGS+=(-ntomp "$NTOMP")
[[ -n "$GPU_ID" ]] && MDRUN_ARGS+=(-gpu_id "$GPU_ID")
"$GMX_BIN" mdrun "${MDRUN_ARGS[@]}"

# --- outputs ---
echo "== Converting output =="
"$GMX_BIN" editconf -f em.gro -o "${OUTPUT_PREFIX}.pdb"
cp "${OUTPUT_PREFIX}.pdb" "../${OUTPUT_PREFIX}.pdb"
cp em.gro "../${OUTPUT_PREFIX}.gro"
cp em.log "../${OUTPUT_PREFIX}_em.log"
cp "$LOG" "../${OUTPUT_PREFIX}_run.log"

echo
echo "Done!"
echo "  Output PDB : ${OUTPUT_PREFIX}.pdb"
echo "  Output GRO : ${OUTPUT_PREFIX}.gro"
echo "  Logs       : ${OUTPUT_PREFIX}_em.log, ${OUTPUT_PREFIX}_run.log"
