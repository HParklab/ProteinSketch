#!/usr/bin/env bash
set -euo pipefail

# Run against an RFdiffusion repository after applying px-rfdiffusion.patch.
# This one-step example is for ProteinSketch2AI .ps2ai input with targets and volumes.
# Example:
#   RFDIFFUSION_DIR=/path/to/RFdiffusion SKETCH_PS2AI=/path/to/BINDER_VDB.ps2ai \
#     BINDER_SHELL_WEIGHT=0.2 BINDER_SHELL_D0=2 BINDER_SHELL_R0=8 \
#     BINDER_DISTANCE_MIN_DIST=1 bash examples/potential_weight_override_binder.sh

: "${SKETCH_PS2AI:?Set SKETCH_PS2AI=/path/to/BINDER_VDB.ps2ai}"

RFDIFFUSION_DIR="${RFDIFFUSION_DIR:-$(pwd)}"
OUTPUT_PREFIX="${OUTPUT_PREFIX:-outputs/examples/weight_override_binder/design}"
NUM_DESIGNS="${NUM_DESIGNS:-2}"
BINDER_SHELL_WEIGHT="${BINDER_SHELL_WEIGHT:-0.1}"
BINDER_SHELL_D0="${BINDER_SHELL_D0:-1}"
BINDER_SHELL_R0="${BINDER_SHELL_R0:-10}"
BINDER_DISTANCE_WEIGHT="${BINDER_DISTANCE_WEIGHT:-0.001}"
BINDER_DISTANCE_MIN_DIST="${BINDER_DISTANCE_MIN_DIST:-0}"
INTERFACE_WEIGHT="${INTERFACE_WEIGHT:-1.0}"

if [[ ! -f "${RFDIFFUSION_DIR}/scripts/run_inference.py" ]]; then
  echo "RFDIFFUSION_DIR does not look like an RFdiffusion checkout: ${RFDIFFUSION_DIR}" >&2
  exit 2
fi

cd "${RFDIFFUSION_DIR}"

python scripts/run_inference.py --config-name voxel \
  "inference.sketch_input=${SKETCH_PS2AI}" \
  "inference.output_prefix=${OUTPUT_PREFIX}" \
  "inference.num_designs=${NUM_DESIGNS}" \
  "potentials.guiding_potentials=[\"type:volume_sketch_binder_shell_ncontacts,weight:${BINDER_SHELL_WEIGHT},d_0:${BINDER_SHELL_D0},r_0:${BINDER_SHELL_R0}\",\"type:volume_sketch_shell_nearest_binder_distance,weight:${BINDER_DISTANCE_WEIGHT},min_dist:${BINDER_DISTANCE_MIN_DIST}\",\"type:interface_ncontacts,weight:${INTERFACE_WEIGHT}\"]"
