#!/usr/bin/env bash
set -euo pipefail

# Run against an RFdiffusion repository after applying px-rfdiffusion.patch.
# This one-step example is for ProteinSketch JSON with target and volume.
# Example:
#   RFDIFFUSION_DIR=/path/to/RFdiffusion SKETCH_JSON=/path/to/BINDER_VDB.json BINDER_SHELL_WEIGHT=0.2 bash examples/potential_weight_override_binder.sh

: "${SKETCH_JSON:?Set SKETCH_JSON=/path/to/BINDER_VDB.json}"

RFDIFFUSION_DIR="${RFDIFFUSION_DIR:-$(pwd)}"
OUTPUT_PREFIX="${OUTPUT_PREFIX:-outputs/examples/weight_override_binder/design}"
NUM_DESIGNS="${NUM_DESIGNS:-2}"
BINDER_SHELL_WEIGHT="${BINDER_SHELL_WEIGHT:-0.1}"
BINDER_DISTANCE_WEIGHT="${BINDER_DISTANCE_WEIGHT:-0.001}"
INTERFACE_WEIGHT="${INTERFACE_WEIGHT:-1.0}"

if [[ ! -f "${RFDIFFUSION_DIR}/scripts/run_inference.py" ]]; then
  echo "RFDIFFUSION_DIR does not look like an RFdiffusion checkout: ${RFDIFFUSION_DIR}" >&2
  exit 2
fi

cd "${RFDIFFUSION_DIR}"

python scripts/run_inference.py --config-name voxel \
  "inference.sketch_json=${SKETCH_JSON}" \
  "inference.output_prefix=${OUTPUT_PREFIX}" \
  "inference.num_designs=${NUM_DESIGNS}" \
  "potentials.guiding_potentials=[\"type:volume_sketch_binder_shell_ncontacts,weight:${BINDER_SHELL_WEIGHT}\",\"type:volume_sketch_shell_nearest_binder_distance,weight:${BINDER_DISTANCE_WEIGHT}\",\"type:interface_ncontacts,weight:${INTERFACE_WEIGHT}\"]"
