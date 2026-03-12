"""
Loan Expert System – Python Agent (pyswip)
- Collects perceptions (user inputs)
- Queries Prolog knowledge base
- Prints actions (decision + explanations + advice)
- Saves run history for your report
"""

from __future__ import annotations

import json
import sys
from dataclasses import dataclass, asdict
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List

from pyswip import Prolog

from datetime import datetime, timezone  # <-- add timezone here if not already

def _to_text(v):
    """Normalize Prolog terms (bytes/atoms) to clean Python str."""
    if isinstance(v, (bytes, bytearray)):
        return v.decode("utf-8", errors="replace")
    return str(v)

# ---------- Configuration ----------
PROJECT_ROOT = Path(__file__).resolve().parent.parent
KB_PATH = PROJECT_ROOT / "knowledge_base" / "loan_rules.pl"
HISTORY_PATH = PROJECT_ROOT / "history.json"


# ---------- Data Model ----------
@dataclass
class LoanApplication:
    income: int                # monthly income
    credit_score: int          # typical 300..850
    debt_ratio: float          # 0.0 .. 1.0
    employment_years: int      # >= 0
    loan_amount: int           # absolute currency amount

    def validate(self) -> None:
        errors = []
        if self.income <= 0:
            errors.append("Income must be a positive integer.")
        if not (300 <= self.credit_score <= 900):
            errors.append("Credit score must be between 300 and 900.")
        if not (0.0 <= self.debt_ratio <= 1.0):
            errors.append("Debt ratio must be in the range 0.0 to 1.0.")
        if self.employment_years < 0:
            errors.append("Employment years cannot be negative.")
        if self.loan_amount <= 0:
            errors.append("Loan amount must be a positive integer.")
        if errors:
            raise ValueError("\n".join(errors))


# ---------- Agent ----------
class LoanExpertAgent:
    def __init__(self, kb_path: Path):
        self.prolog = Prolog()
        if not kb_path.exists():
            raise FileNotFoundError(f"Knowledge base not found at: {kb_path}")
        # Use a raw string path so SWI-Prolog can consult it on Windows
        self.prolog.consult(str(kb_path))

    def evaluate(self, app: LoanApplication) -> Dict[str, Any]:
        """
        Calls Prolog evaluate/8:
            evaluate(I, C, D, E, L, Decision, Risk, Reasons, AdviceList)
        Returns a Python dict with normalized types.
        """
        app.validate()

        query = (
            "evaluate("
            f"{app.income}, {app.credit_score}, {float(app.debt_ratio):.4f}, "
            f"{app.employment_years}, {app.loan_amount}, "
            "Decision, Risk, Reasons, Advice)"
        )

        results = list(self.prolog.query(query, maxresult=1))
        if not results:
            # This should never happen given our KB, but be defensive
            return {
                "decision": "unknown",
                "risk_score": None,
                "reasons": [],
                "advice": ["Unable to evaluate with the given inputs."]
            }

        row = results[0]

        # Normalize outputs
        decision = str(row.get("Decision"))
        risk = int(row.get("Risk"))
        # pyswip returns Prolog atoms as Python strings; lists map naturally
        reasons = [str(r) for r in row.get("Reasons", [])]
        advice = [str(a) for a in row.get("Advice", [])]

        return {
            "decision": decision,
            "risk_score": risk,
            "reasons": reasons,
            "advice": advice,
        }

    def save_history(self, app: LoanApplication, result: Dict[str, Any]) -> None:
        HISTORY_PATH.parent.mkdir(parents=True, exist_ok=True)
        history: List[Dict[str, Any]] = []
        if HISTORY_PATH.exists():
            try:
                history = json.loads(HISTORY_PATH.read_text(encoding="utf-8"))
            except Exception:
                # If the file is corrupt, start fresh (but don't crash in demo)
                history = []

        entry = {
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "input": asdict(app),
            "output": result,
        }
        history.append(entry)
        HISTORY_PATH.write_text(json.dumps(history, indent=2), encoding="utf-8")


# ---------- CLI Utilities ----------
def prompt_int(prompt: str, min_val: int | None = None, max_val: int | None = None) -> int:
    while True:
        try:
            val = int(input(prompt).strip())
            if min_val is not None and val < min_val:
                print(f"  • Value must be ≥ {min_val}")
                continue
            if max_val is not None and val > max_val:
                print(f"  • Value must be ≤ {max_val}")
                continue
            return val
        except ValueError:
            print("  • Enter a valid integer.")


def prompt_float(prompt: str, min_val: float | None = None, max_val: float | None = None) -> float:
    while True:
        try:
            txt = input(prompt).strip().replace(",", ".")
            val = float(txt)
            if min_val is not None and val < min_val:
                print(f"  • Value must be ≥ {min_val}")
                continue
            if max_val is not None and val > max_val:
                print(f"  • Value must be ≤ {max_val}")
                continue
            return val
        except ValueError:
            print("  • Enter a valid number (e.g., 0.35).")


def pretty_print(app: LoanApplication, result: Dict[str, Any]) -> None:
    print("\n================= RESULT =================")
    print(f"Decision     : {result['decision'].upper()}")
    print(f"Risk Score   : {result['risk_score']} / 100")
    if result["reasons"]:
        print("Reasons      :")
        for r in result["reasons"]:
            print(f"  - {r}")
    if result["advice"]:
        print("Advice       :")
        for a in result["advice"]:
            print(f"  - {a}")
    print("Inputs       :")
    print(f"  • Income            = {app.income}")
    print(f"  • Credit Score      = {app.credit_score}")
    print(f"  • Debt Ratio        = {app.debt_ratio}")
    print(f"  • Employment Years  = {app.employment_years}")
    print(f"  • Loan Amount       = {app.loan_amount}")
    print("==========================================\n")


def main() -> int:
    print("=== Loan Expert System (Python + Prolog) ===")
    print(f"Loading KB: {KB_PATH}")
    try:
        agent = LoanExpertAgent(KB_PATH)
    except Exception as ex:
        print(f"Error loading knowledge base: {ex}")
        return 1

    # Interactive single evaluation (MVP)
    income = prompt_int("Enter monthly income (e.g., 2500): ", min_val=1)
    credit = prompt_int("Enter credit score (300..900): ", min_val=300, max_val=900)
    debt = prompt_float("Enter debt ratio (0.0..1.0), e.g., 0.38: ", min_val=0.0, max_val=1.0)
    employment = prompt_int("Enter employment years (>=0): ", min_val=0)
    loan_amt = prompt_int("Enter requested loan amount (e.g., 15000): ", min_val=1)

    app = LoanApplication(
        income=income,
        credit_score=credit,
        debt_ratio=debt,
        employment_years=employment,
        loan_amount=loan_amt,
    )

    try:
        result = agent.evaluate(app)
    except Exception as ex:
        print(f"\nEvaluation error: {ex}\n")
        return 2

    pretty_print(app, result)

    # Persist to history for your report & demo evidence
    try:
        agent.save_history(app, result)
        print(f"Saved to history: {HISTORY_PATH}")
    except Exception as ex:
        print(f"Warning: could not save history ({ex})")

    return 0


if __name__ == "__main__":
    sys.exit(main())
    