%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LOAN KB – Global + Ghana, with safe numeric guards, no instantiation_error
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- DYNAMIC PREDICATES ---
:- dynamic
    income/1,
    credit_score/1,
    employment_years/1,
    debt_to_income/1,
    requested_amount/1.

% --- Suppress singleton warnings (optional) ---
:- style_check(-singleton).

% --- Advice clauses can be non‑contiguous ---
:- discontiguous advice/1.

% === SAFE COMPARISON GUARDS (Best Practice) ===
safe_ge(X, Y) :- nonvar(X), X >= Y.
safe_ge(_, _) :- fail.

safe_le(X, Y) :- nonvar(X), X =< Y.
safe_le(_, _) :- fail.

safe_gt(X, Y) :- nonvar(X), X > Y.
safe_gt(_, _) :- fail.

safe_lt(X, Y) :- nonvar(X), X < Y.
safe_lt(_, _) :- fail.

% === GLOBAL LEVELS (using safe‑guards) ===
risk_level(Score, low)    :- safe_ge(Score, 700).
risk_level(Score, medium) :- safe_ge(Score, 550), safe_lt(Score, 700).
risk_level(Score, high)   :- safe_lt(Score, 550).

dti_level(Dti, low)    :- safe_lt(Dti, 0.3).
dti_level(Dti, medium) :- safe_ge(Dti, 0.3), safe_lt(Dti, 0.5).
dti_level(Dti, high)   :- safe_ge(Dti, 0.5).

income_level(I, low)    :- safe_le(I, 1999).
income_level(I, medium) :- safe_ge(I, 2000), safe_le(I, 4999).
income_level(I, high)   :- safe_ge(I, 5000).

% === GLOBAL ELIGIBILITY (all numeric checks guarded) ===
eligible(strong) :-
    income(I),
    income_level(I, high),
    credit_score(Cs),
    risk_level(Cs, low),
    debt_to_income(Dti),
    dti_level(Dti, low),
    employment_years(Emp),
    safe_ge(Emp, 2).

eligible(medium) :-
    income(I),
    income_level(I, medium),
    credit_score(Cs),
    risk_level(Cs, medium),
    debt_to_income(Dti),
    dti_level(Dti, medium),
    employment_years(Emp),
    safe_ge(Emp, 1).

eligible(weak) :-
    income(I),
    credit_score(Cs),
    debt_to_income(Dti),
    dti_level(Dti, high),
    employment_years(Emp),
    safe_ge(Emp, 0.5),
    (income_level(I, low) ; risk_level(Cs, high)).

% === GLOBAL LOAN TYPES (guarded numeric checks) ===
loan_type(safe) :-
    eligible(strong),
    requested_amount(Amt),
    safe_le(Amt, 20000).

loan_type(conditional) :-
    eligible(medium),
    requested_amount(Amt),
    safe_gt(Amt, 20000),
    safe_le(Amt, 50000).

loan_type(risky) :-
    eligible(weak),
    requested_amount(Amt),
    safe_gt(Amt, 10000).

loan_type(test_loan) :-
    income(I),
    safe_ge(I, 1000),
    requested_amount(Amt),
    safe_le(Amt, 3000),
    (eligible(weak) ; \+ (eligible(_))).

% === DEFAULTS FOR MISSING DATA (no numeric checks here) ===
income(I) :-
    \+ current_predicate(income/1),
    I = 0.

credit_score(Cs) :-
    \+ current_predicate(credit_score/1),
    Cs = 500.

debt_to_income(Dti) :-
    \+ current_predicate(debt_to_income/1),
    Dti = 0.4.

employment_years(Emp) :-
    \+ current_predicate(employment_years/1),
    Emp = 1.

requested_amount(Amt) :-
    \+ current_predicate(requested_amount/1),
    Amt = 5000.

% === GLOBAL DECISION WITH CONFIDENCE ===
decision_with_confidence(Result, Conf) :-
    loan_type(safe),
    Result = approve,
    Conf = high.

decision_with_confidence(Result, Conf) :-
    loan_type(conditional),
    Result = conditional,
    Conf = medium.

decision_with_confidence(Result, Conf) :-
    loan_type(risky),
    Result = reject,
    Conf = low.

decision_with_confidence(Result, Conf) :-
    loan_type(test_loan),
    Result = approve_with_test,
    Conf = medium.

decision_with_confidence(Result, Conf) :-
    \+ (loan_type(safe) ; loan_type(conditional) ;
        loan_type(risky) ; loan_type(test_loan)),
    Result = unknown,
    Conf = low.

% === GLOBAL ADVICE ===
advice(approve) :-
    write('Loan approved with high confidence. Standard terms apply.').

advice(conditional) :-
    write('Loan may be approved under conditions (e.g., higher interest, lower amount). Further review recommended.').

advice(reject) :-
    write('Loan rejected due to high risk. Re‑apply after improving credit score or reducing debts.').

advice(approve_with_test) :-
    write('Loan approved as a small test loan to assess repayment behavior. Expect close monitoring.').

advice(unknown) :-
    write('Insufficient data or unclear risk. Manual review required to decide.').

% === GHANA‑SPECIFIC LAYERS (using safe‑guards) ===
ghana_income_level(I, low)    :- safe_lt(I, 1000).
ghana_income_level(I, medium) :- safe_ge(I, 1000), safe_lt(I, 3000).
ghana_income_level(I, high)   :- safe_ge(I, 3000).

loan_sector(informal) :-
    employment_years(Emp),
    safe_lt(Emp, 1).

loan_sector(formal) :-
    employment_years(Emp),
    safe_ge(Emp, 1),
    requested_amount(Amt),
    safe_ge(Amt, 5000).

loan_sector(sacco) :-
    requested_amount(Amt),
    safe_le(Amt, 10000),
    credit_score(Cs),
    safe_ge(Cs, 500),
    income(I),
    safe_ge(I, 800).

loan_sector(microloan) :-
    requested_amount(Amt),
    safe_le(Amt, 3000),
    income(I),
    safe_ge(I, 500).

% === GHANA‑RULES (all numeric guarded) ===
ghana_sacco_strong :-
    loan_sector(sacco),
    income(I),
    ghana_income_level(I, medium),
    requested_amount(Amt),
    safe_le(Amt, 7000),
    debt_to_income(Dti),
    dti_level(Dti, low).

ghana_sacco_medium :-
    loan_sector(sacco),
    income(I),
    (ghana_income_level(I, low) ; employment_years(Emp), safe_lt(Emp, 2)),
    requested_amount(Amt),
    safe_le(Amt, 5000),
    debt_to_income(Dti),
    dti_level(Dti, medium).

ghana_sacco_risky :-
    loan_sector(sacco),
    requested_amount(Amt),
    safe_gt(Amt, 7000),
    debt_to_income(Dti),
    dti_level(Dti, high).

ghana_microloan_safe :-
    loan_sector(microloan),
    requested_amount(Amt),
    safe_le(Amt, 2000),
    debt_to_income(Dti),
    dti_level(Dti, low),
    employment_years(Emp),
    safe_ge(Emp, 0.25).

ghana_microloan_risky :-
    loan_sector(microloan),
    requested_amount(Amt),
    safe_gt(Amt, 2000),
    debt_to_income(Dti),
    dti_level(Dti, medium),
    income(I),
    ghana_income_level(I, low).

ghana_informal_test :-
    loan_sector(informal),
    requested_amount(Amt),
    safe_le(Amt, 1500),
    income(I),
    safe_ge(I, 300),
    debt_to_income(Dti),
    dti_level(Dti, low).

% === GHANA DECISIONS (no arithmetic checks here) ===
ghana_decision(sacco_safe, high) :-
    ghana_sacco_strong.

ghana_decision(sacco_conditional, medium) :-
    ghana_sacco_medium.

ghana_decision(sacco_reject, low) :-
    ghana_sacco_risky.

ghana_decision(microloan_safe, high) :-
    ghana_microloan_safe.

ghana_decision(microloan_conditional, medium) :-
    ghana_microloan_risky.

ghana_decision(informal_test, medium) :-
    ghana_informal_test.

ghana_decision(legacy, unknown_conf) :-
    \+ (ghana_sacco_strong ; ghana_sacco_medium ; ghana_sacco_risky ;
        ghana_microloan_safe ; ghana_microloan_risky ; ghana_informal_test).

% === GHANA‑AUGMENTED DECISION (no arithmetic, just logic + safe guards) ===
ghana_augmented_decision(Result, Conf) :-
    income(I),
    credit_score(Cs),
    employment_years(Emp),
    debt_to_income(Dti),
    requested_amount(Amt),
    safe_ge(I, 0),      % sanity check (non‑var, numeric)
    safe_ge(Cs, 0),
    safe_ge(Emp, 0),
    safe_ge(Dti, 0),
    safe_ge(Amt, 0),
    (   ghana_sacco_strong
    ->  Result = sacco_safe,
        Conf = high
    ;   ghana_sacco_medium
    ->  Result = sacco_conditional,
        Conf = medium
    ;   ghana_sacco_risky
    ->  Result = sacco_reject,
        Conf = low
    ;   ghana_microloan_safe
    ->  Result = microloan_safe,
        Conf = high
    ;   ghana_microloan_risky
    ->  Result = microloan_conditional,
        Conf = medium
    ;   ghana_informal_test
    ->  Result = informal_test,
        Conf = medium
    ;   decision_with_confidence(Result, Conf)
    ).

% === GHANA‑SPECIFIC ADVICE ===
advice(sacco_safe) :-
    write('Loan approved as a SACCO‑style loan with high confidence. Regular group meetings and savings are required.').

advice(sacco_conditional) :-
    write('SACCO loan may be approved with smaller amount or higher interest. Close monitoring and savings requirement apply.').

advice(sacco_reject) :-
    write('SACCO loan rejected due to high risk or high DTI. Re‑apply after reducing debts or increasing savings history.').

advice(microloan_safe) :-
    write('Microloan approved with high confidence. Typical 3–6 month term and weekly repayments.').

advice(microloan_conditional) :-
    write('Microloan may be approved only for a smaller amount. Expect intensive repayment monitoring.').

advice(informal_test) :-
    write('Small informal‑sector test loan approved. Repayment history will be tracked to qualify for larger amounts.').

