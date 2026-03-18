%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LOAN KB – Global + Ghana, no UNKNOWN, detailed advice, approved/rejected labels
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

:- dynamic
    income/1,
    credit_score/1,
    employment_years/1,
    debt_to_income/1,
    requested_amount/1.

% Suppress singleton warnings (optional, removes the messages)
:- style_check(-singleton).

% Advice clauses can be non‑contiguous
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
    dti_level(Dti, low),
    employment_years(Emp),
    safe_ge(Emp, 2).

eligible(medium) :-
    income(I),
    income_level(I, medium),
    credit_score(Cs),
    risk_level(Cs, medium),
    dti_level(Dti, medium),
    employment_years(Emp),
    safe_ge(Emp, 1).

eligible(weak) :-
    income(I),
    credit_score(Cs),
    dti_level(Dti, high),
    employment_years(Emp),
    safe_ge(Emp, 0.5),
    (income_level(I, low) ; risk_level(Cs, high)).

% === GLOBAL LOAN TYPES (guarded numeric checks) ===
loan_type(safe) :-
    eligible(strong),
    requested_amount(Amt),
    safe_ge(I, 3000),
    safe_ge(Cs, 550),
    dti_level(Dti, low),
    safe_le(Amt, 20000).

loan_type(conditional) :-
    income(I),
    safe_ge(I, 2000),
    credit_score(Cs),
    safe_ge(Cs, 500),
    dti_level(Dti, low),
    requested_amount(Amt),
    safe_ge(Amt, 10000),
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

loan_type(legacy_unknown) :-
    \+ (loan_type(safe) ; loan_type(conditional) ;
        loan_type(risky) ; loan_type(test_loan)).

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

% === GLOBAL DECISION WITH CONFIDENCE (no UNKNOWN) ===
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

% Fallback: always gives at least a decision (conditional)
decision_with_confidence(conditional, medium) :-
    loan_type(legacy_unknown).

% === RECOMMENDED AMOUNT TO GIVE ===
amount_to_give(Amt, Given) :-
    income(I),
    debt_to_income(Dti),
    requested_amount(Amt),
    dti_level(Dti, Level),
    (   safe_ge(I, 5000) ->
        % High income, can handle larger loans
        (   safe_le(Dti, 0.3) ->
            safe_le(Given, Amt),
            Given = Amt
        ;   safe_ge(Dti, 0.5) ->
            safe_le(Given, 0.8 * Amt),
            safe_ge(Given, 0.5 * Amt)
        ;   % medium DTI
            safe_le(Given, 0.95 * Amt),
            safe_ge(Given, 0.7 * Amt)
        )
    ;   safe_ge(I, 2000) ->
        % Medium income
        (   safe_ge(Dti, 0.5) ->
            safe_le(Given, 0.6 * Amt),
            safe_ge(Given, 0.3 * Amt)
        ;   safe_le(Given, 0.8 * Amt),
            safe_ge(Given, 0.5 * Amt)
        )
    ;   % Low income
        safe_le(Given, 0.5 * Amt),
        safe_ge(Given, 0.2 * Amt)
    ).

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

% === GHANA DECISIONS (no arithmetic checks) ===
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

ghana_decision(legacy, low) :-
    \+ (ghana_sacco_strong ; ghana_sacco_medium ; ghana_sacco_risky ;
        ghana_microloan_safe ; ghana_microloan_risky ; ghana_informal_test).

% === GHANA‑AUGMENTED DECISION (no UNKNOWN, includes amount) ===
ghana_augmented_decision(Result, Conf, Given) :-
    income(I),
    credit_score(Cs),
    employment_years(Emp),
    debt_to_income(Dti),
    requested_amount(Amt),
    safe_ge(I, 0),
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
    ),
    amount_to_give(Amt, Given).

% === ADVICE WITH DETAILED REASONS ===

advice(Result) :-
    income(I),
    credit_score(Cs),
    employment_years(Emp),
    debt_to_income(Dti),
    requested_amount(Amt),

    write_decision_header(Result),
    nl,
    nl,
    write('Reasons for this decision:'),
    nl,

    % 1. Income criteria
    (   safe_ge(I, 2000) ->
        write('  - Income meets minimum requirement (>= 2000 GHS).'),
        nl
    ;   write('  - Income too low (below 2000 GHS). Consider increasing income or applying for a smaller amount.'),
        nl
    ),

    % 2. Credit score
    (   safe_ge(Cs, 550) ->
        write('  - Credit score acceptable (>= 550).'),
        nl
    ;   write('  - Credit score too low (below 550). Improve score by paying bills on time and reducing credit utilization.'),
        nl
    ),

    % 3. Employment
    (   safe_ge(Emp, 1) ->
        write('  - Employment history is sufficient (1+ years).'),
        nl
    ;   write('  - Employment history too short (less than 1 year). Build longer work history.'),
        nl
    ),

    % 4. DTI
    (   safe_ge(Dti, 0.5) ->
        write('  - Debt‑to‑income ratio too high (DTI >= 0.5). Reduce debts or increase income before re‑applying.'),
        nl
    ;   write('  - Debt‑to‑income ratio is acceptable (DTI < 0.5).'),
        nl
    ),

    % 5. Amount size
    (   safe_ge(Amt, 30000) ->
        write('  - Requested amount is large; consider a smaller amount to improve chances.'),
        nl
    ;   write('  - Requested amount is reasonable for your profile.'),
        nl
    ),

    % 6. General advice line
    (   Result = approve ; Result = sacco_safe ; Result = microloan_safe ->
        write('  - Overall profile is strong; no major weaknesses detected.'),
        nl
    ;   Result = conditional ; Result = sacco_conditional ; Result = microloan_conditional ->
        write('  - Application conditionally approved; minor weaknesses but overall acceptable.'),
        nl
    ;   Result = reject ; Result = sacco_reject ->
        write('  - Application rejected due to multiple weaknesses. Improve income, credit, or DTI.'),
        nl
    ;   true
    ).

% --- Decision header: "Loan Approved", "Loan Rejected", etc. ---
write_decision_header(approve) :-
    write('Loan Approved').

write_decision_header(conditional) :-
    write('Loan Conditionally Approved (with conditions)').

write_decision_header(reject) :-
    write('Loan Rejected').

write_decision_header(sacco_safe) :-
    write('Loan Approved (SACCO Safe)').

write_decision_header(sacco_conditional) :-
    write('Loan Conditionally Approved (SACCO, with conditions)').

write_decision_header(sacco_reject) :-
    write('Loan Rejected (SACCO)').

write_decision_header(microloan_safe) :-
    write('Loan Approved (Microloan, Safe)').

write_decision_header(microloan_conditional) :-
    write('Loan Conditionally Approved (Microloan, with conditions)').

write_decision_header(informal_test) :-
    write('Loan Approved (Informal‑sector Test Loan)').

write_decision_header(conditional_multi_co) :-
    write('Loan Conditionally Approved (with co‑signers)').

write_decision_header(approve_multi_co) :-
    write('Loan Approved (with multiple co‑signers)').

write_decision_header(_) :-
    write('Loan Decision Review Required').

