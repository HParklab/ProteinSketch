#!/usr/bin/env bash
set -euo pipefail

# Run against an RFdiffusion repository after applying px-rfdiffusion.patch.
# Example:
#   RFDIFFUSION_DIR=/path/to/RFdiffusion SKETCH_JSON=/path/to/PROTEINSKETCH_VDB.json CONTIG='120-140' bash examples/contig_override.sh
# For binder JSON, CONTIG can include the target side, for example:
#   CONTIG='A1-90/0 80-110'

: "${SKETCH_JSON:?Set SKETCH_JSON=/path/to/PROTEINSKETCH_VDB.json}"
: "${CONTIG:?Set CONTIG, for example CONTIG='120-140'}"

RFDIFFUSION_DIR="${RFDIFFUSION_DIR:-$(pwd)}"
OUTPUT_PREFIX="${OUTPUT_PREFIX:-outputs/examples/contig_override/design}"
NUM_DESIGNS="${NUM_DESIGNS:-2}"

if [[ ! -f "${RFDIFFUSION_DIR}/scripts/run_inference.py" ]]; then
  echo "RFDIFFUSION_DIR does not look like an RFdiffusion checkout: ${RFDIFFUSION_DIR}" >&2
  exit 2
fi

cd "${RFDIFFUSION_DIR}"

python scripts/run_inference.py --config-name voxel \
  "inference.sketch_json=${SKETCH_JSON}" \
  "inference.output_prefix=${OUTPUT_PREFIX}" \
  "inference.num_designs=${NUM_DESIGNS}" \
  "contigmap.contigs=[${CONTIG}]"
