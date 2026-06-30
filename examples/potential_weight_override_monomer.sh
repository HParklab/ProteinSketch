#!/usr/bin/env bash
set -euo pipefail

# Run against an RFdiffusion repository after applying px-rfdiffusion.patch.
# This one-step example is for ProteinSketch2AI .ps2ai input with volumes only.
# Example:
#   RFDIFFUSION_DIR=/path/to/RFdiffusion SKETCH_PS2AI=/path/to/MONOMER_VDB.ps2ai \
#     MONOMER_SHELL_WEIGHT=0.2 MONOMER_SHELL_D0=2 MONOMER_SHELL_R0=8 \
#     MONOMER_DISTANCE_MIN_DIST=1 bash examples/potential_weight_override_monomer.sh

: "${SKETCH_PS2AI:?Set SKETCH_PS2AI=/path/to/MONOMER_VDB.ps2ai}"

RFDIFFUSION_DIR="${RFDIFFUSION_DIR:-$(pwd)}"
OUTPUT_PREFIX="${OUTPUT_PREFIX:-outputs/examples/weight_override_monomer/design}"
NUM_DESIGNS="${NUM_DESIGNS:-2}"
MONOMER_SHELL_WEIGHT="${MONOMER_SHELL_WEIGHT:-0.1}"
MONOMER_SHELL_D0="${MONOMER_SHELL_D0:-1}"
MONOMER_SHELL_R0="${MONOMER_SHELL_R0:-10}"
MONOMER_DISTANCE_WEIGHT="${MONOMER_DISTANCE_WEIGHT:-0.001}"
MONOMER_DISTANCE_MIN_DIST="${MONOMER_DISTANCE_MIN_DIST:-0}"

if [[ ! -f "${RFDIFFUSION_DIR}/scripts/run_inference.py" ]]; then
  echo "RFDIFFUSION_DIR does not look like an RFdiffusion checkout: ${RFDIFFUSION_DIR}" >&2
  exit 2
fi

cd "${RFDIFFUSION_DIR}"

python scripts/run_inference.py --config-name voxel \
  "inference.sketch_input=${SKETCH_PS2AI}" \
  "inference.output_prefix=${OUTPUT_PREFIX}" \
  "inference.num_designs=${NUM_DESIGNS}" \
  "potentials.guiding_potentials=[\"type:volume_sketch_monomer_shell_ncontacts,weight:${MONOMER_SHELL_WEIGHT},d_0:${MONOMER_SHELL_D0},r_0:${MONOMER_SHELL_R0}\",\"type:volume_sketch_shell_nearest_monomer_distance,weight:${MONOMER_DISTANCE_WEIGHT},min_dist:${MONOMER_DISTANCE_MIN_DIST}\"]"
