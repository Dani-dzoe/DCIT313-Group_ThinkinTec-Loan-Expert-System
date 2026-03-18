from pyswip import Prolog

prolog = Prolog()
prolog.consult("../knowledge_base/loan_kb.pl")


def clear_kb():
    """Clear all applicant facts that Python asserts."""
    prolog.retractall("income(_)")
    prolog.retractall("credit_score(_)")
    prolog.retractall("employment_years(_)")
    prolog.retractall("debt_to_income(_)")
    prolog.retractall("requested_amount(_)")


def set_applicant_data():
    """Ask user for applicant data and assert into Prolog."""
    print("Loan Expert System – Ghana Edition (press Enter for unknown)")
    try:
        income_val = float(input("Monthly income (GHS, 0 if unknown): ") or 0)
    except (ValueError, TypeError):
        income_val = 0
    try:
        credit = int(input("Credit score (0–850, 0 if unknown): ") or 0)
    except (ValueError, TypeError):
        credit = 500
    try:
        emp_years = float(input("Years of employment (0 if unknown): ") or 0)
    except (ValueError, TypeError):
        emp_years = 1
    try:
        dti = float(input("Debt‑to‑income ratio (e.g., 0.3, 0 if unknown): ") or 0)
    except (ValueError, TypeError):
        dti = 0.4

    while True:
        try:
            amount = float(input("Requested loan amount (GHS): "))
            if amount <= 0:
                print("Please enter a positive number.")
            else:
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
    """Get Ghana‑augmented decision, confidence, and recommended amount."""
    query = "ghana_augmented_decision(Result, Confidence, Given)."
    results = list(prolog.query(query))
    if not results:
        # Fallback: use global decision only
        global_query = "decision_with_confidence(Result, Confidence)."
        global_results = list(prolog.query(global_query))
        if global_results:
            r = global_results[0]
            result = r["Result"]
            conf = r["Confidence"]
            given = 0  # no explicit given amount in global fallback
            return result, conf, given
        else:
            return "unknown", "low", 0
    else:
        r = results[0]
        result = r["Result"]
        conf = r["Confidence"]
        given = r["Given"]
        return result, conf, given


def main():
    print("=== Loan Expert Agent (Ghana Edition) ===")
    while True:
        print("\n--- New applicant ---")
        set_applicant_data()

        result, conf, given = get_ghana_decision()
        print(f"\nDecision:          {result.upper()}")
        print(f"Confidence:        {conf.upper()}")

        if given > 0:
            print(f"Amount to give:    {given:.2f} GHS")

        print()  # blank line before advice

        # Run Prolog advice; it prints all the detailed reasons
        advice_query = f"advice({result})."
        advice_results = list(prolog.query(advice_query))
        if not advice_results:
            print("(No explicit advice rule defined for this result.)")

        print()  # extra blank line after advice

        repeat = input("Check another applicant? (y/n): ").strip().lower()
        if repeat != "y":
            print("Goodbye!")
            break


if __name__ == "__main__":
    main()

