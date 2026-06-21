#!/usr/bin/env bash
set -euo pipefail

# Run against an RFdiffusion repository after applying px-rfdiffusion.patch.
# Example:
#   RFDIFFUSION_DIR=/path/to/RFdiffusion SKETCH_JSON=/path/to/PROTEINSKETCH_VDB.json SDF_CUTOFF=-2.0 bash examples/sdf_cutoff_override.sh

: "${SKETCH_JSON:?Set SKETCH_JSON=/path/to/PROTEINSKETCH_VDB.json}"

RFDIFFUSION_DIR="${RFDIFFUSION_DIR:-$(pwd)}"
OUTPUT_PREFIX="${OUTPUT_PREFIX:-outputs/examples/sdf_cutoff/design}"
NUM_DESIGNS="${NUM_DESIGNS:-2}"
SDF_CUTOFF="${SDF_CUTOFF:--1.0}"
SDF_MAX_SDF="${SDF_MAX_SDF:-0.0}"
VOLUME_INDEX="${VOLUME_INDEX:-0}"

if [[ ! -f "${RFDIFFUSION_DIR}/scripts/run_inference.py" ]]; then
  echo "RFDIFFUSION_DIR does not look like an RFdiffusion checkout: ${RFDIFFUSION_DIR}" >&2
  exit 2
fi

cd "${RFDIFFUSION_DIR}"

python scripts/run_inference.py --config-name voxel \
  "inference.sketch_json=${SKETCH_JSON}" \
  "inference.output_prefix=${OUTPUT_PREFIX}" \
  "inference.num_designs=${NUM_DESIGNS}" \
  "inference.volume_sketch_cutoff=${SDF_CUTOFF}" \
  "inference.volume_sketch_max_sdf=${SDF_MAX_SDF}" \
  "inference.sketch_json_volume_index=${VOLUME_INDEX}"
