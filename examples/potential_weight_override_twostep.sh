#!/usr/bin/env bash
set -euo pipefail

# Run against an RFdiffusion repository after applying px-rfdiffusion.patch.
# This two-step example is for ProteinSketch2AI .ps2ai input with targets and volumes.
# Example:
#   RFDIFFUSION_DIR=/path/to/RFdiffusion SKETCH_PS2AI=/path/to/BINDER_VDB.ps2ai \
#     MONOMER_SHELL_D0=2 MONOMER_SHELL_R0=8 BINDER_SHELL_D0=2 BINDER_SHELL_R0=8 \
#     BINDER_DISTANCE_MIN_DIST=1 bash examples/potential_weight_override_twostep.sh

: "${SKETCH_PS2AI:?Set SKETCH_PS2AI=/path/to/BINDER_VDB.ps2ai}"

RFDIFFUSION_DIR="${RFDIFFUSION_DIR:-$(pwd)}"
OUTPUT_PREFIX="${OUTPUT_PREFIX:-outputs/examples/weight_override_twostep/binder}"
NUM_DESIGNS="${NUM_DESIGNS:-2}"
MONOMER_SHELL_WEIGHT="${MONOMER_SHELL_WEIGHT:-0.1}"
MONOMER_SHELL_D0="${MONOMER_SHELL_D0:-1}"
MONOMER_SHELL_R0="${MONOMER_SHELL_R0:-10}"
MONOMER_DISTANCE_WEIGHT="${MONOMER_DISTANCE_WEIGHT:-0.001}"
MONOMER_DISTANCE_MIN_DIST="${MONOMER_DISTANCE_MIN_DIST:-0}"
BINDER_SHELL_WEIGHT="${BINDER_SHELL_WEIGHT:-0.1}"
BINDER_SHELL_D0="${BINDER_SHELL_D0:-1}"
BINDER_SHELL_R0="${BINDER_SHELL_R0:-10}"
BINDER_DISTANCE_WEIGHT="${BINDER_DISTANCE_WEIGHT:-0.001}"
BINDER_DISTANCE_MIN_DIST="${BINDER_DISTANCE_MIN_DIST:-0}"
INTERFACE_WEIGHT="${INTERFACE_WEIGHT:-1.0}"

if [[ ! -f "${RFDIFFUSION_DIR}/scripts/two-step/run_inference_json_twostep.py" ]]; then
  echo "RFDIFFUSION_DIR does not look like a patched RFdiffusion checkout: ${RFDIFFUSION_DIR}" >&2
  exit 2
fi

cd "${RFDIFFUSION_DIR}"

python scripts/two-step/run_inference_json_twostep.py \
  "inference.sketch_input=${SKETCH_PS2AI}" \
  "inference.output_prefix=${OUTPUT_PREFIX}" \
  "inference.num_designs=${NUM_DESIGNS}" \
  "--monomer-shell-weight=${MONOMER_SHELL_WEIGHT}" \
  "--monomer-shell-d0=${MONOMER_SHELL_D0}" \
  "--monomer-shell-r0=${MONOMER_SHELL_R0}" \
  "--monomer-distance-weight=${MONOMER_DISTANCE_WEIGHT}" \
  "--monomer-distance-min-dist=${MONOMER_DISTANCE_MIN_DIST}" \
  "--binder-shell-weight=${BINDER_SHELL_WEIGHT}" \
  "--binder-shell-d0=${BINDER_SHELL_D0}" \
  "--binder-shell-r0=${BINDER_SHELL_R0}" \
  "--binder-distance-weight=${BINDER_DISTANCE_WEIGHT}" \
  "--binder-distance-min-dist=${BINDER_DISTANCE_MIN_DIST}" \
  "--interface-weight=${INTERFACE_WEIGHT}"
