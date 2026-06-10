# NeuroSymbolic AI for Rummikub

**A Comparative Study of DeepProbLog and NeurASP**

## Overview

This project implements and compares two neurosymbolic AI frameworks — **DeepProbLog** and **NeurASP** — for interpreting Rummikub board game states from real-world photographs. Both systems are used to identify Rummikub board game-tile combinations to determine whether tile combinations are valid or not. 
The system takes a photograph of a Rummikub board and outputs the valid runs and sets detected, along with per-image inference statistics.


## What It Does

Given a JPEG or PNG photograph of a Rummikub board:

1. **Tile Detection** — An SSD300 object detector locates every tile and produces bounding boxes.
2. **Tile Classification** — Two ResNet-18 classifiers predict the colour (black, blue, orange, red) and number (1–13, or joker) of each tile.
3. **Clustering & Ordering** — Detected tiles are grouped into rows/columns and ordered spatially using hierarchical agglomerative clustering.
4. **Symbolic Reasoning** — Consecutive triplets within each cluster are evaluated against Rummikub rules:
   - **DeepProbLog** uses Weighted Model Counting (WMC) via ProbLog to assign continuous probabilities to each triplet.
   - **NeurASP** uses Clingo-based Answer Set Programming to find stable models, producing binary valid/invalid output.

## Repository Structure

```
.
├── dataset/
│   └── images/                  # Rummikub board photographs (285 images)
├── model/
│   └── tile_detection.pth       # Trained SSD300 weights
├── classification/
│   ├── color_last.pth           # Trained ResNet-18 colour classifier
│   ├── number_last.pth          # Trained ResNet-18 number classifier
│   └── src/
│       └── models/model.py      # ResNet-18 model factory
├── rummikubexam.pl              # DeepProbLog Prolog rules (valid_run / valid_set)
├── Deepprolog_rummikub.ipynb    # DeepProbLog inference pipeline
├── Neuroasp_rummikub.ipynb      # NeurASP inference pipeline
├── compare_neurodeep.ipynb      # Comparison analysis and visualisations
├── modelSSD.py                  # SSD300 architecture
├── detect.py                    # SSD inference helper
├── utils.py                     # Bounding box sorting, orientation, clustering
├── deepproblog_results.json     # Output results — DeepProbLog
└── neurasp_results.json         # Output results — NeurASP
```

## Setup

### Requirements

- Python 3.10+
- PyTorch
- DeepProbLog (`deepproblog`, `problog`)
- NeurASP
- `torchvision`, `scipy`, `numpy`, `pandas`, `matplotlib`, `Pillow`

### Install dependencies

```bash
pip install torch torchvision scipy numpy pandas matplotlib Pillow
pip install deepproblog problog
# NeurASP: follow https://github.com/azreasoners/NeurASP
```

### Dataset

The dataset of 285 Rummikub board photographs is publicly available on Kaggle, introduced by Vandevelde et al. (2025). Place images in `dataset/images/`.

### Pretrained models

Place the following pretrained weights in the paths shown above:
- `model/tile_detection.pth` — SSD300 trained on Rummikub tiles
- `classification/color_last.pth` — ResNet-18 colour classifier (4 classes)
- `classification/number_last.pth` — ResNet-18 number classifier (14 classes: 1–13 + joker)

---

## Running the Pipelines

### DeepProbLog

Open and run `Deepprolog_rummikub.ipynb`.Results are saved to `deepproblog_results.json`. 

### NeurASP

Open and run `Neuroasp_rummikub.ipynb`.Results are saved to `neurasp_results.json`. 
### Comparison Analysis

Open and run `compare_neurodeep.ipynb` after both pipelines have completed. This notebook produces:
- Per-image triplet count scatter plot (agreement rate)
- Inference time comparison (per image, distribution, total)
- DeepProbLog probability distribution histogram
- Inference time vs. image complexity plots
  
## Rummikub Rules (Symbolic Layer)
Rules are encoded in `rummikubexam.pl` for DeepProbLog and as an equivalent dynamic ASP program for NeurASP.
**Valid run** — three tiles of the same colour with consecutive numbers (e.g. Red 3, Red 4, Red 5).  
**Valid set** — three tiles with the same number and all different colours (e.g. Red 7, Blue 7, Orange 7).  
**Joker** — substitutes any single tile; handled by dedicated rule variants in both frameworks.

