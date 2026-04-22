# Loan Expert System

A Knowledge‑Based System (KBS) that acts as an Intelligent Agent for loan eligibility decisions. The system reasons under uncertainty and includes Ghana‑specific lending rules (e.g., SACCO loans, microloans, informal‑sector loans).

---

## Objective

Design and implement an Intelligent Agent that:
- Maps **perceptions** (applicant data: income, credit score, employment, DTI, loan amount) to **actions** (decision + advice).
- Uses **symbolic AI** (SWI‑Prolog) for inference.
- Provides a **Python user interface** (via `pyswip`) for interaction.
- Handles **uncertainty** (missing data, fuzzy thresholds, and confidence‑weighted decisions).

---

## Architecture Overview

The project follows this directory layout:

| Directory            | Content                                                                |
|----------------------|------------------------------------------------------------------------|
| `knowledge_base/`    | Prolog knowledge base `.pl` files with facts and rules.                |
| `interface/`         | Python scripts that query SWI‑Prolog (the inference interface).        |
| `docs/`              | Documentation, including this `README.md`.                             |

---

## Tech Stack

- **Logic engine**: SWI‑Prolog (for symbolic reasoning and inference).
- **User interface**: Python + `pyswip` (bridge between Python and Prolog).
- **Uncertainty handling**: Safe numeric guards (`safe_ge/2`, `safe_le/2`), defaults, and fuzzy thresholds.
- **Version control**: GitHub for collaboration and submission.

---

## Features

- **Global loan eligibility** for safe, conditional, risky, and test loans.
- **Uncertainty‑aware decisions** with safe arithmetic and default values.
- **Ghana‑specific rules** for:
  - SACCO‑style loans.
  - Microloans for low‑income borrowers.
  - Informal‑sector test loans.
- **User‑friendly output** with clear decision, confidence level, and English advice.

---

## How to Run

### 1. Prerequisites

- Install **SWI‑Prolog**.
- Install Python dependencies:

```bash
pip install pyswip
```

### Team Tetteh
- [Daniel Mawutor Dzotepe-[Dani-dzoe]- 22028361]
- [Philip Marfo Amoako -[amoakophilip] -22078203]
- [Irene Tetteh-[Abeikah]-22013982]
- [Jerry Kaborni-[jerry-kaborni]-22141090
- [Eric Ananga-[Survival77]- 22059600]
