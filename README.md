# NeuroSymbolic AI for Rummikub

**A Comparative Study of DeepProbLog and NeurASP**

## Overview

This project implements and compares two neurosymbolic AI frameworks — **DeepProbLog** and **NeurASP** — for interpreting Rummikub board game states from real-world photographs. Both systems combine a neural vision backbone (SSD + ResNet-18) with symbolic rule engines to detect and validate tile combinations without any hand-labeled symbolic input.

The system takes a photograph of a Rummikub board and outputs the valid runs and sets detected, along with per-image inference statistics.
---

## What It Does

Given a JPEG or PNG photograph of a Rummikub board:

1. **Tile Detection** — An SSD300 object detector locates every tile and produces bounding boxes.
2. **Tile Classification** — Two ResNet-18 classifiers predict the colour (black, blue, orange, red) and number (1–13, or joker) of each tile.
3. **Clustering & Ordering** — Detected tiles are grouped into rows/columns and ordered spatially using hierarchical agglomerative clustering.
4. **Symbolic Reasoning** — Consecutive triplets within each cluster are evaluated against Rummikub rules:
   - **DeepProbLog** uses Weighted Model Counting (WMC) via ProbLog to assign continuous probabilities to each triplet.
   - **NeurASP** uses Clingo-based Answer Set Programming to find stable models, producing binary valid/invalid output.

---

## Key Results (285 Images)

| Metric | DeepProbLog | NeurASP |
|---|---|---|
| Valid runs detected | 430 | 431 |
| Valid sets detected | 273 | 274 |
| **Total valid triplets** | **703** | **705** |
| Total inference time | 3006.3 s (≈50 min) | 407.8 s (≈7 min) |
| Speed ratio | — | **~7.4× faster** |
| Output type | Continuous probability [0, 1] | Binary (valid / invalid) |

Both frameworks converge on nearly identical detection counts despite fundamentally different inference architectures.

---

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

---

## Architecture

```
Photo
  │
  ▼
SSD300 (tile detection)
  │  bounding boxes
  ▼
ResNet-18 × 2 (colour + number classifiers)
  │  probability tensors  [T = 2.0 temperature scaling]
  ▼
Tile Clustering & Ordering
  │  consecutive triplets
  ├──────────────────────────────────┐
  ▼                                  ▼
DeepProbLog                        NeurASP
ExactEngine (WMC)                  Clingo (ASP solver)
rummikubexam.pl                    Dynamic ASP program
  │                                  │
  ▼                                  ▼
P(valid_run), P(valid_set)         Binary: in stable model?
```

---

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

Both notebooks support **checkpoint resumption** — if interrupted, already-processed images are skipped automatically.

### DeepProbLog

Open and run `Deepprolog_rummikub.ipynb`.

Results are saved to `deepproblog_results.json`. Intermediate progress is saved to `checkpoint.json`.

### NeurASP

Open and run `Neuroasp_rummikub.ipynb`.

Results are saved to `neurasp_results.json`. Intermediate progress is saved to `checkpoint_neurasp.json`.

### Comparison Analysis

Open and run `compare_neurodeep.ipynb` after both pipelines have completed. This notebook produces:
- Per-image triplet count scatter plot (agreement rate)
- Inference time comparison (per image, distribution, total)
- DeepProbLog probability distribution histogram
- Inference time vs. image complexity plots

---

## Rummikub Rules (Symbolic Layer)

Rules are encoded in `rummikubexam.pl` for DeepProbLog and as an equivalent dynamic ASP program for NeurASP.

**Valid run** — three tiles of the same colour with consecutive numbers (e.g. Red 3, Red 4, Red 5).  
**Valid set** — three tiles with the same number and all different colours (e.g. Red 7, Blue 7, Orange 7).  
**Joker** — substitutes any single tile; handled by dedicated rule variants in both frameworks.

---

## Design Decisions

**Temperature scaling (T = 2.0)** is applied to both classifiers. Raw softmax is typically ~99% overconfident. Scaling to T = 2.0 broadens the distribution to 70–80% peak confidence, which is essential for meaningful probabilistic inference in both DeepProbLog and NeurASP.

**Threshold (DeepProbLog only)** is set at 0.10. Because DeepProbLog internally multiplies three tile probabilities together, the joint probability is inherently low. A standard 0.5 threshold would reject nearly all valid triplets.

**SSD hyperparameters**: `min_score=0.7`, `max_overlap=0.3`, `top_k=200`. These were selected empirically to balance false positives and missed detections across the dataset's varying lighting and zoom levels.

---

## Framework Comparison

| Aspect | DeepProbLog | NeurASP |
|---|---|---|
| Reasoning paradigm | Probabilistic logic (ProbLog) | Answer Set Programming |
| Inference engine | ExactEngine — Weighted Model Counting | Clingo ASP solver |
| Output | Continuous probability [0, 1] | Binary (stable model membership) |
| Queries per image | 2 per triplet (run + set) | 1 global solve per image |
| Scales with tile count? | Poorly (exponential WMC calls) | Yes (bounded per image) |
| Uncertainty quantification | ✅ Native | ❌ Binary only |
| End-to-end learning | ✅ Supported | ✅ Supported |
| Used in this study | Inference only | Inference only |

---

## Limitations

- **No ground truth annotations** — precision, recall, and F1 cannot be computed. The study relies on inter-system agreement and aggregate counts.
- **Inference-only evaluation** — end-to-end joint training of neural and symbolic layers was not performed.
- **Threshold sensitivity** — DeepProbLog's 0.10 threshold was chosen heuristically and has not been systematically tuned.

---

## Future Work

- Expert annotation of valid runs/sets per image to enable precision/recall evaluation.
- Full end-to-end joint training for both frameworks.
- Continuous probability output for NeurASP to enable a fair head-to-head comparison.
- Adding [Scallop](https://arxiv.org/abs/2304.04812) as a third framework for a three-way comparison.
- Batching triplet queries in DeepProbLog to reduce WMC overhead and close the speed gap with NeurASP.
- Mobile deployment using NeurASP's speed advantage for a real-time game assistant.

---

## References

- Manhaeve et al. (2019). *Neural Probabilistic Logic Programming in DeepProbLog.* [arXiv:1907.08194](https://arxiv.org/abs/1907.08194)
- Yang et al. (2023). *NeurASP: Embracing Neural Networks into Answer Set Programming.* [arXiv:2307.07700](https://arxiv.org/abs/2307.07700)
- Vandevelde et al. (2025). *Enhancing Computer Vision with Knowledge: A Rummikub Case Study.* ESANN 2025.
- He et al. (2016). *Deep Residual Learning for Image Recognition.* CVPR 2016.
- Liu et al. (2015). *SSD: Single Shot MultiBox Detector.* [arXiv:1512.02325](https://arxiv.org/abs/1512.02325)
- Garcez & Lamb (2023). *Neurosymbolic AI: The 3rd wave.* Artificial Intelligence Review.

## License

This project was developed for academic research purposes. Please refer to the individual framework licenses for DeepProbLog and NeurASP before any other use.
