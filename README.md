# L1_vs_L2_depth_correction

A minimal, reproducible MATLAB demo that illustrates the difference between an **L2 (least-squares / mean)** global shift and an **L1 (least-absolute / median)** global shift when correcting seismic-predicted horizon depths with well measurements.

---

## What this repo contains

- `L1_vs_L2_clean_documented.m` — single, self-contained MATLAB script (copy/paste ready).  
  The script creates a synthetic true depth surface, generates a seismic-derived estimate, samples wells, injects measurement noise + a small fraction of large outliers, computes residuals, computes/apply L2 and L1 global shifts, and produces comparison figures and metrics.

---

## Quick summary (one line to use in your post)
> A compact MATLAB demo showing that the L2 (mean) global shift minimizes RMSE but is pulled by outliers, while the L1 (median) shift minimizes MAE and is robust to a few bad wells.

---

## Requirements

- MATLAB R2018 or later.  
- No special toolboxes required (the script uses base MATLAB functions).  
- Optional: change `rng(...)` seed for different realizations.

---

## How to run

1. Download or copy `L1_vs_L2_clean_documented.m` into a folder.  
2. Open MATLAB and set the folder as the current folder.  
3. Run the script:
```matlab
>> L1_vs_L2_clean_documented
```
4. Outputs:
   - Console printout with summary statistics (mean, median, std, MAE, RMSE).  
   - A PNG figure `L1_vs_L2_clean_documented.png` saved in the current folder (maps + histogram + metrics).

---

## Main script parameters (easy to edit)

Open the script and modify these variables near the top:

- `Nwells` — number of well samples (default: `20`).  
- `measurement_noise_std` — standard deviation of typical well noise (meters, default: `4`).  
- `outlier_fraction` — fraction of wells that receive large errors (default: `0.08`).  
- `noise_amplitude` — amplitude of small perturbation added to seismic estimate (meters, default: `0.8`).  
- `rng(2025)` — random seed for reproducibility (change or remove to get other random draws).

---

## What the script shows / Interpretation guidance

- The script computes two single-number corrections:
  - **L2 shift** = mean(residuals) — minimizes sum of squares (RMSE).  
  - **L1 shift** = median(residuals) — minimizes sum of absolute residuals (MAE).
- Use the printed metrics and the histogram to see that:
  - When you have a few large outliers, **L2** will move toward those outliers (smaller RMSE but larger sensitivity).
  - **L1** remains closer to the central cluster (smaller MAE, more robust).
- The demonstration is intentionally simple (global single-number shifts) so the effect is isolated and easy to explain.

---

## Recommended use in a Medium post

- Show the three small maps (wells colored by residual: original, after L2, after L1) and the histogram.  
- Paste the one-line summary (above) as the figure caption.  
- Mention the printed MAE / RMSE numbers in the script output to support your conclusions.

---

## License
MIT — feel free to adapt and reuse the script in your tutorials or blog.

---

## Contact / reproducibility note
If you want the notebook version (Python + Jupyter) or an extended demo with cross-validation or spatial kriging, open an issue or message me — I can provide a converted notebook that reproduces the same figures.

