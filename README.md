# ProteinSketch RFdiffusion Patch

<p align="center">
  <img src="figs/main_figure.png" alt="ProteinSketch RFdiffusion volume-conditioning overview" width="100%">
</p>

RFdiffusion patch for ProteinSketch, a VR-assisted protein design workflow that turns user-sketched backbone topologies and volumetric envelopes into diffusion-ready spatial constraints for de novo monomer and binder design. This repository adds ProteinSketch JSON input, embedded OpenVDB SDF volume support, volume-guided potentials, and partial-diffusion refinement utilities to the official RFdiffusion codebase.

Base RFdiffusion commit:

```text
2d0c003df46b9db41d119321f15403dec3716cd9
```

## Install

Install RFdiffusion, model weights, and dependencies from the official
RFdiffusion repository.

```text
https://github.com/RosettaCommons/RFdiffusion
```

Use RFdiffusion conda environment `SE3nv`; Install `pyopenvdb` so the
JSON-embedded OpenVDB grid can be decoded.

```bash
conda activate SE3nv
conda install conda-forge::openvdb
```

Apply this patch from the patch repository:

```bash
cd RFdiffusion
git checkout 2d0c003df46b9db41d119321f15403dec3716cd9

curl -fsSL -o /tmp/px-rfdiffusion.patch \
  https://raw.githubusercontent.com/supergermy/ProteinSketch/main/patches/px-rfdiffusion.patch

git apply --whitespace=nowarn --check /tmp/px-rfdiffusion.patch
git apply --whitespace=nowarn /tmp/px-rfdiffusion.patch
```

## ProteinSketch JSON/OpenVDB input

Use `inference.sketch_json` to point RFdiffusion at a ProteinSketch JSON file
that may contain a target PDB, a sketched backbone, and/or an embedded OpenVDB
SDF volume. JSON file looks like:

```json
{
    "format": "ProteinSketchOutput",
    "schemaVersion": 1,
    "createdAt": "2099-01-01T23:59:59.115+09:00",
    "target": [
        {
            "format": "PDB",
            "encoding": "utf-8",
            "data": "HELIX    1  H1 GLY A   70  GLY A   72  1 ...", # if exists, used as `inference.input_pdb` (i.e., target)
            "hotspots": [ # if exists, used as `ppi.hotspot_res`
                "A392",
                "A394",
                "A421",
                "A423"
            ]
        }
    ],
    "backbone": [], # if exists, used as `inference.input_pdb` (i.e., motif)
    "volume": [
        {
            "format": "OpenVDB",
            "encoding": "base64",
            "estimatedResidueCountRange": { # if exists, used as `contigmap.contigs`
                "min": 329,
                "max": 342
            },
            "data": "niuLyrzVXCazo/B6gKDBo3UMo+..." # hashed SDF values
        }
    ]
}
```

An empty list means null. Normally `volume` contains one dictionary. If an
example file contains multiple volume entries, treat them as independent
examples; the default uses `volume[0]`, and `inference.sketch_json_volume_index`
can select another entry.

Design mode is inferred from populated sections:

```text
# [] means empty. e.g., above JSON's backbone is empty
target=[]  backbone=[]  volume!=[]  -> monomer design with volume potential
target!=[] backbone=[]  volume!=[]  -> binder design with volume potential
target=[]  backbone!=[]             -> monomer partial diffusion without volume potential
target!=[] backbone!=[]             -> binder partial diffusion without volume potential
```

## Unified schema for monomer and binder design

As described above, `.json` defines which design to run (monomer or binder).

```bash
python scripts/run_inference.py --config-name voxel \
  inference.sketch_json=/path/to/PROTEINSKETCH_VDB.json \
  inference.output_prefix=outputs/json_vdb/design \
  inference.num_designs=2
```

Override `contigmap.contigs` when you want a custom design length.

## Two-step binder run

For binder design from JSON target + volume, two-step is recommended:

```bash
python scripts/two-step/run_inference_json_twostep.py \
  inference.sketch_json=/path/to/PROTEINSKETCH_VDB.json \
  inference.output_prefix=outputs/json_two_step/binder \
  inference.num_designs=2
```

The two-step workflow first samples monomer backbones with the VDB volume
potentials enabled. After the monomer stage, each generated monomer is moved
back into the original target coordinate frame and combined with the target PDB
from the JSON input. The binder stage then runs partial diffusion on that
target-frame complex, refining the generated binder while keeping the target in
its original position.

## Examples

Example scripts live in `examples/`. Set `RFDIFFUSION_DIR` to a patched
RFdiffusion checkout and `SKETCH_JSON` to a ProteinSketch JSON file.

- `examples/sdf_cutoff_override.sh` shows how to change the VDB SDF shell band
  with `inference.volume_sketch_cutoff`, `inference.volume_sketch_max_sdf`, and
  `inference.sketch_json_volume_index`.
- `examples/potential_weight_override_monomer.sh` runs one-step monomer design
  from volume-only JSON while overriding monomer volume potential weights.
- `examples/potential_weight_override_binder.sh` runs one-step binder design
  from target + volume JSON while overriding binder volume potential weights and
  interface weight.
- `examples/potential_weight_override_twostep.sh` runs the two-step target +
  volume workflow while overriding monomer volume weights, binder volume
  weights, and interface weight.
- `examples/contig_override.sh` shows how to override the automatically inferred
  `contigmap.contigs`, for example to set a custom design length or explicit
  target/binder contig.

## T=2 refinement (partial diffusion)

ProteinSketch supports T=2 RFdiffusion partial diffusion for fast backbone
regularization of sketch-derived inputs.

```bash
python scripts/run_inference.py \
  --config-name oneshot \
  inference.input_pdb=/path/to/input.pdb \
```

## Files

```text
patches/px-rfdiffusion.patch
tools/apply_px_patch.sh
examples/*.sh
figs/*.png
```
