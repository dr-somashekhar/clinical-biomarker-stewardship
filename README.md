# 🧪 Procalcitonin (PCT) Stewardship for Resource-Limited Wards

This repository contains the clinical logic, implementation frameworks, and data simulation protocols based on our 2026 narrative review published in the *Indo American Journal of Pharmaceutical Sciences*. 📊

## 🔬 Project Overview
In tight resource settings, empirical antibiotic overuse accelerates antimicrobial resistance (AMR). This project digitizes a **Procalcitonin-Guided Antibiotic Stewardship Algorithm** designed to safely guide antibiotic de-escalation in secondary and tertiary care wards (such as ESI hospitals).

## 🎛️ Core Algorithmic Logic
The clinical decision support engine applies specific PCT cutoffs (ng/mL) to optimize prescribing:
* 🟢 **< 0.1 ng/mL:** Bacterial infection highly unlikely; strongly encourage withholding or stopping antibiotics.
* 🟡 **0.1 – 0.25 ng/mL:** Bacterial infection unlikely; discourage initiation.
* 🟠 **0.25 – 0.5 ng/mL:** Possible bacterial infection; use clinical discretion.
* 🔴 **> 0.5 ng/mL:** Bacterial infection highly likely; safely continue or escalate therapy.
* 🔄 **The 80% Rule:** Regardless of the absolute value, a drop of **≥80% from the peak PCT value** is a validated signal that the infection is resolving and antibiotics can be safely stopped.

## 🛠️ Repository Contents
* `README.md` - Project documentation and clinical frameworks.
* `pct_simulation.R` - *(Coming Next)* R script simulating patient PCT clearance curves.# clinical-biomarker-stewardship
Simulating kinetic clearance curves and clinical decision logic for procalcitonin-guided antibiotic de-escalation in resource-limited wards
