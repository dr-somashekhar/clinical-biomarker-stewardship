# Contributing to this Clinical Bioinformatics Engine

First, thank you for considering contributing to this project! Open-source collaboration is the foundation of reproducible translational research.

## 🔬 Scope of Contributions
We welcome contributions that improve the clinical accuracy, statistical rigor, or usability of this package. This includes:
* New renal dosing protocols (rows in `renal_dose_rules`) with a cited source.
* Refinements to the PCT algorithm (`R/pct_algorithm.R`) backed by published evidence.
* Improvements to the synthetic cohort generator, visualisations and documentation.
* Bug fixes in clinical formulas, with a test that reproduces the bug.

## 🛠️ Pull Request (PR) Process
1. **Fork** the repository and create your feature branch (`git checkout -b feature/Advanced-Imputation`).
2. **Commit** your changes with descriptive messages (`git commit -m 'Added Random Forest imputation method'`).
3. **Test** your code. Run `devtools::document()`, `devtools::test()`, `devtools::check()` and `lintr::lint_package()` from the repo root; all must pass without errors, warnings or lints (CI enforces this, plus 90% test coverage). Ensure any added statistical models converge properly and do not introduce data leakage.
4. **Push** to the branch (`git push origin feature/Advanced-Imputation`).
5. **Open a Pull Request** against the `main` branch. 

## ⚖️ Clinical Data Standards
If your contribution involves simulated or sample patient datasets:
* **No PHI:** Ensure absolute compliance with HIPAA and GDPR. Never upload Protected Health Information.
* **Reproducibility:** Set seeds (e.g., `set.seed(2026)`) for any stochastic processes, Monte Carlo simulations, or ML training splits.

## 💊 Dosing Rules
* New drugs are added as rows in `renal_dose_rules` (`R/renal.R`), not as new `if` branches.
* Every new or changed breakpoint must cite its source (product label or guideline) in the PR description and come with tests covering each band boundary.
