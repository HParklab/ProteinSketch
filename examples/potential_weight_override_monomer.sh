#!/usr/bin/env bash
set -euo pipefail

# Run against an RFdiffusion repository after applying px-rfdiffusion.patch.
# This one-step example is for ProteinSketch JSON with volume only.
# Example:
#   RFDIFFUSION_DIR=/path/to/RFdiffusion SKETCH_JSON=/path/to/MONOMER_VDB.json MONOMER_SHELL_WEIGHT=0.2 bash examples/potential_weight_override_monomer.sh

: "${SKETCH_JSON:?Set SKETCH_JSON=/path/to/MONOMER_VDB.json}"

RFDIFFUSION_DIR="${RFDIFFUSION_DIR:-$(pwd)}"
OUTPUT_PREFIX="${OUTPUT_PREFIX:-outputs/examples/weight_override_monomer/design}"
NUM_DESIGNS="${NUM_DESIGNS:-2}"
MONOMER_SHELL_WEIGHT="${MONOMER_SHELL_WEIGHT:-0.1}"
MONOMER_DISTANCE_WEIGHT="${MONOMER_DISTANCE_WEIGHT:-0.001}"

if [[ ! -f "${RFDIFFUSION_DIR}/scripts/run_inference.py" ]]; then
  echo "RFDIFFUSION_DIR does not look like an RFdiffusion checkout: ${RFDIFFUSION_DIR}" >&2
  exit 2
fi

cd "${RFDIFFUSION_DIR}"

python scripts/run_inference.py --config-name voxel \
  "inference.sketch_json=${SKETCH_JSON}" \
  "inference.output_prefix=${OUTPUT_PREFIX}" \
  "inference.num_designs=${NUM_DESIGNS}" \
  "potentials.guiding_potentials=[\"type:volume_sketch_monomer_shell_ncontacts,weight:${MONOMER_SHELL_WEIGHT}\",\"type:volume_sketch_shell_nearest_monomer_distance,weight:${MONOMER_DISTANCE_WEIGHT}\"]"
