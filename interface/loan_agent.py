from pyswip import Prolog

prolog = Prolog()
prolog.consult("../knowledge_base/loan_kb.pl")


def clear_kb():
    prolog.retractall("income(_)")
    prolog.retractall("credit_score(_)")
    prolog.retractall("employment_years(_)")
    prolog.retractall("debt_to_income(_)")
    prolog.retractall("requested_amount(_)")


def set_applicant_data():
    print("Loan Expert System – Ghana Edition (press Enter for unknown)")
    try:
        income_val = float(input("Monthly income (GHS, 0 if unknown): ") or 0)
    except (ValueError, TypeError):
        income_val = 0
    try:
        credit = int(input("Credit score (0–850, 0 if unknown): ") or 0)
    except (ValueError, TypeError):
        credit = 0
    try:
        emp_years = float(input("Years of employment (0 if unknown): ") or 0)
    except (ValueError, TypeError):
        emp_years = 0
    try:
        dti = float(input("Debt‑to‑income ratio (e.g., 0.3, 0 if unknown): ") or 0)
    except (ValueError, TypeError):
        dti = 0.5   # high‑risk default

    while True:
        try:
            amount = float(input("Requested loan amount (GHS): "))
            break
        except (ValueError, TypeError):
            print("Please enter a valid number.")

    clear_kb()
    prolog.assertz(f"income({income_val})")
    prolog.assertz(f"credit_score({credit})")
    prolog.assertz(f"employment_years({emp_years})")
    prolog.assertz(f"debt_to_income({dti})")
    prolog.assertz(f"requested_amount({amount})")


def get_ghana_decision():
    query = "ghana_augmented_decision(Result, Confidence)."
    results = list(prolog.query(query))
    if results:
        r = results[0]
        result = r["Result"]
        conf = r["Confidence"]
        return result, conf
    else:
        global_query = "decision_with_confidence(Result, Confidence)."
        global_results = list(prolog.query(global_query))
        if global_results:
            r = global_results[0]
            result = r["Result"]
            conf = r["Confidence"]
            return result, conf
        else:
            return "unknown", "low"


def main():
    print("=== Loan Expert Agent (Ghana Edition) ===")
    while True:
        print("\n--- New applicant ---")
        set_applicant_data()

        result, conf = get_ghana_decision()
        print(f"\nDecision:     {result.upper()}")
        print(f"Confidence:   {conf.upper()}")

        advice_query = f"advice({result})."
        advice_results = list(prolog.query(advice_query))
        if not advice_results:
            print("(No explicit advice rule defined for this result.)")

        repeat = input("\nCheck another applicant? (y/n): ").strip().lower()
        if repeat != "y":
            print("Goodbye!")
            break


if __name__ == "__main__":
    main()

