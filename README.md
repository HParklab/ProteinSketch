# Protein*Sketch*

<p align="center">
  <img src="figs/thumbnail.png" alt="ProteinSketch overview" width="1100px" align="middle"/>
</p>

## Description

ProteinSketch is a VR-assisted protein design workflow for translating a designer's spatial intent into protein with RFdiffusion. Designers can sketch backbone topologies and volumetric envelopes in 3D, then use those sketches to guide *de novo* monomer design, binder design, and partial-diffusion refinement.

This repository provides the RFdiffusion-side patch for ProteinSketch. It adds support for ProteinSketch `.ps2ai` input (it's just a JSON file) , embedded OpenVDB SDF volumes, volume-guided potentials, inferred contig lengths from sketched envelopes, and sketch-derived partial diffusion.

`.ps2ai` can be made from https://proteinsketch.app or https://proteinsketch.com with VR headset (non-VR version is coming soon).

## Documentation

This patch builds on the official [RFdiffusion](https://github.com/RosettaCommons/RFdiffusion) codebase.

For general RFdiffusion usage, model weights, and installation details, see the official RFdiffusion repository and documentation. This README only documents the ProteinSketch-specific patch and `.ps2ai`/OpenVDB input workflow.

----

# Table of contents

- [Protein*Sketch*](#proteinsketch)
  - [Description](#description)
  - [Documentation](#documentation)
- [Getting started / installation](#getting-started--installation)
  - [Base RFdiffusion version](#base-rfdiffusion-version)
  - [Install OpenVDB support](#install-openvdb-support)
  - [Apply the ProteinSketch patch](#apply-the-proteinsketch-patch)
- [Usage](#usage)
  - [ProteinSketch input](#proteinsketch-input)
  - [Running volume-conditioned monomer or binder design](#running-volume-conditioned-monomer-or-binder-design)
  - [Two-step binder design](#two-step-binder-design)
  - [Partial diffusion for sketch refinement](#partial-diffusion-for-sketch-refinement)
  - [Examples](#examples)
- [Files](#files)

----

# Getting started / installation

ProteinSketch is distributed as a patch to RFdiffusion. First install RFdiffusion, model weights, and dependencies from the official repository:

```text
https://github.com/RosettaCommons/RFdiffusion
```

## Base RFdiffusion version

This patch is intended for the following RFdiffusion commit:

```text
2d0c003df46b9db41d119321f15403dec3716cd9
```

Start from a clean RFdiffusion checkout:

```bash
git clone https://github.com/RosettaCommons/RFdiffusion.git
cd RFdiffusion
git checkout 2d0c003df46b9db41d119321f15403dec3716cd9
```

## Install OpenVDB support

ProteinSketch stores volumetric envelopes as OpenVDB SDF grids embedded in `.ps2ai` files. Use the RFdiffusion conda environment and install OpenVDB support:

```bash
conda activate SE3nv
conda install conda-forge::openvdb
```

## Apply the ProteinSketch patch

Apply the patch from this repository:

```bash
curl -fsSL -o proteinsketch-rfdiffusion.patch \
  https://raw.githubusercontent.com/supergermy/ProteinSketch/main/patches/px-rfdiffusion.patch

git apply --whitespace=nowarn --check proteinsketch-rfdiffusion.patch
git apply --whitespace=nowarn proteinsketch-rfdiffusion.patch
rm proteinsketch-rfdiffusion.patch
```

----

# Usage

The `.ps2ai` file is JSON-formatted internally. The main entry point is still RFdiffusion's inference script, and designs are conditioned through the existing `inference.sketch_input` option.

## ProteinSketch input

The input file `.ps2ai` contains three major sections in JSON format:

- `targets`: target PDB and optional hotspot residues for binder design
- `backbones`: sketched backbone PDB for partial diffusion
- `volumes`: OpenVDB SDF envelope for volume-conditioned generation

A typical `.ps2ai` payload looks like this:

```json
{
    "format": "ProteinSketch2AI",
    "schemaVersion": 1.0,
    "exportTime": "2099-01-01T23:59:59.115+09:00",
    "targets": [
        {
            "format": "PDB",
            "encoding": "utf-8",
            "data": "HELIX    1  H1 GLY A   70  GLY A   72  1 ...",
            "hotspots": [
                "A392",
                "A394",
                "A421",
                "A423"
            ]
        }
    ],
    "backbones": [],
    "volumes": [
        {
            "format": "OpenVDB",
            "encoding": "base64",
            "estimatedMinResidueLength": 329,
            "estimatedMaxResidueLength": 342,
            "data": "niuLyrzVXCazo/B6gKDBo3UMo+..."
        }
    ]
}
```

Empty lists are treated as null values. The design mode is inferred from the populated sections:

```text
targets=[]  backbones=[]  volumes!=[]  -> monomer design with volume potential
targets!=[] backbones=[]  volumes!=[]  -> binder design with volume potential
targets=[]  backbones!=[]              -> monomer partial diffusion
targets!=[] backbones!=[]              -> binder partial diffusion
```

Currently, if a `.ps2ai` file contains multiple volume entries, ProteinSketch uses `volumes[0]` by default. Another entry can be selected with:

```text
inference.sketch_input_volume_index=<index>
```

## Running volume-conditioned monomer or binder design

To run RFdiffusion with a `.ps2ai` file:

```bash
python scripts/run_inference.py --config-name voxel \
  inference.sketch_input=/path/to/PROTEINSKETCH_VDB.ps2ai \
  inference.output_prefix=outputs/ps2ai_vdb/design \
  inference.num_designs=2
```

If the `.ps2ai` file contains only a volume, RFdiffusion runs monomer design with volume conditioning. If it contains both a target and a volume, RFdiffusion runs binder design with volume conditioning.

ProteinSketch can infer `contigmap.contigs` from `estimatedMinResidueLength` and `estimatedMaxResidueLength` stored in the `.ps2ai` volume. You can override the inferred length manually (see [Examples](#examples)):

```bash
python scripts/run_inference.py --config-name voxel \
  inference.sketch_input=/path/to/PROTEINSKETCH_VDB.ps2ai \
  'contigmap.contigs=[150-170]' \
  inference.output_prefix=outputs/ps2ai_vdb/custom_length \
  inference.num_designs=2
```

## Two-step binder design

For target + volume binder design, the two-step workflow is recommended:

```bash
python scripts/two-step/run_inference_json_twostep.py \
  inference.sketch_input=/path/to/PROTEINSKETCH_VDB.ps2ai \
  inference.output_prefix=outputs/ps2ai_two_step/binder \
  inference.num_designs=2
```

The first stage samples monomer backbones under the sketched volume potential. The generated backbones are then transformed and combined with the target PDB from the `.ps2ai` input. The second stage runs partial diffusion on the monomer-target complex to design the binder.

## Partial diffusion for sketch refinement

ProteinSketch also supports sketch-derived backbone refinement with RFdiffusion partial diffusion. This is useful for regularizing manually sketched backbones while preserving the intended topology.

```bash
python scripts/run_inference.py \
  --config-name oneshot \
  inference.input_pdb=/path/to/input.pdb
```

The `oneshot` configuration is intended for fast partial-diffusion refinement of sketch-derived structures (you can do this with the original RFdiffusion, too).

## Examples

Example scripts are provided in `examples/`. Set `RFDIFFUSION_DIR` to a patched RFdiffusion checkout and `SKETCH_PS2AI` to a ProteinSketch `.ps2ai` file before running them.

```text
examples/sdf_cutoff_override.sh
examples/potential_weight_override_monomer.sh
examples/potential_weight_override_binder.sh
examples/potential_weight_override_twostep.sh
examples/contig_override.sh
```

These examples show how to:

- change the VDB SDF shell band with `inference.volume_sketch_cutoff`
- select a volume entry with `inference.sketch_input_volume_index`
- override monomer and binder volume-potential weights
- override volume-potential parameters such as `d_0`, `r_0`, and `min_dist`
- override interface weights for binder design
- manually override inferred `contigmap.contigs`

----

# Files

```text
patches/px-rfdiffusion.patch
tools/apply_px_patch.sh
examples/*.sh
figs/*.png
```
