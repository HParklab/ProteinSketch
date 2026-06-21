#!/usr/bin/env bash
set -euo pipefail

# Run against an RFdiffusion repository after applying px-rfdiffusion.patch.
# This two-step example is for ProteinSketch JSON with target and volume.
# Example:
#   RFDIFFUSION_DIR=/path/to/RFdiffusion SKETCH_JSON=/path/to/BINDER_VDB.json BINDER_SHELL_WEIGHT=0.2 bash examples/potential_weight_override_twostep.sh

: "${SKETCH_JSON:?Set SKETCH_JSON=/path/to/BINDER_VDB.json}"

RFDIFFUSION_DIR="${RFDIFFUSION_DIR:-$(pwd)}"
OUTPUT_PREFIX="${OUTPUT_PREFIX:-outputs/examples/weight_override_twostep/binder}"
NUM_DESIGNS="${NUM_DESIGNS:-2}"
MONOMER_SHELL_WEIGHT="${MONOMER_SHELL_WEIGHT:-0.1}"
MONOMER_DISTANCE_WEIGHT="${MONOMER_DISTANCE_WEIGHT:-0.001}"
BINDER_SHELL_WEIGHT="${BINDER_SHELL_WEIGHT:-0.1}"
BINDER_DISTANCE_WEIGHT="${BINDER_DISTANCE_WEIGHT:-0.001}"
INTERFACE_WEIGHT="${INTERFACE_WEIGHT:-1.0}"

if [[ ! -f "${RFDIFFUSION_DIR}/scripts/two-step/run_inference_json_twostep.py" ]]; then
  echo "RFDIFFUSION_DIR does not look like a patched RFdiffusion checkout: ${RFDIFFUSION_DIR}" >&2
  exit 2
fi

cd "${RFDIFFUSION_DIR}"

python scripts/two-step/run_inference_json_twostep.py \
  "inference.sketch_json=${SKETCH_JSON}" \
  "inference.output_prefix=${OUTPUT_PREFIX}" \
  "inference.num_designs=${NUM_DESIGNS}" \
  "--monomer-shell-weight=${MONOMER_SHELL_WEIGHT}" \
  "--monomer-distance-weight=${MONOMER_DISTANCE_WEIGHT}" \
  "--binder-shell-weight=${BINDER_SHELL_WEIGHT}" \
  "--binder-distance-weight=${BINDER_DISTANCE_WEIGHT}" \
  "--interface-weight=${INTERFACE_WEIGHT}"
