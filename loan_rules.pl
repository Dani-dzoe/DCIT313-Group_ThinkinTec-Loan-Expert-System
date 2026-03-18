% Applicant data

income(_).
credit_score(_).
age(_).
employment_years(_).
loan_amount(_).
debt_ratio(_).
collateral_value(_).
existing_loans(_).
marital_status(_).
dependents(_).

% Income Categories

low_income :-
    income(X),
    X < 2000.

medium_income :-
    income(X),
    X >= 2000,
    X < 5000.

high_income :-
    income(X),
    X >= 5000.

% Credit Categories

poor_credit :-
    credit_score(X),
    X < 500.

fair_credit :-
    credit_score(X),
    X >= 500,
    X < 650.

good_credit :-
    credit_score(X),
    X >= 650,
    X < 750.

excellent_credit :-
    credit_score(X),
    X >= 750.
    

% Debt Ratio Rules

low_debt :-
    debt_ratio(X),
    X < 0.30.

medium_debt :-
    debt_ratio(X),
    X >= 0.30,
    X < 0.50.

high_debt :-
    debt_ratio(X),
    X >= 0.50.
    

% Employment Stability Rules

stable_job :-
    employment_years(Y),
    Y >= 3.

moderate_job :-
    employment_years(Y),
    Y >= 1,
    Y < 3.

unstable_job :-
    employment_years(Y),
    Y < 1.
    
% Age Risks Rules

young_applicant :-
    age(X),
    X < 21.

working_age :-
    age(X),
    X >= 21,
    X =< 60.

retirement_risk :-
    age(X),
    X > 60.


% Loan Size Rules

small_loan :-
    loan_amount(X),
    X < 5000.

medium_loan :-
    loan_amount(X),
    X >= 5000,
    X < 20000.

large_loan :-
    loan_amount(X),
    X >= 20000.

% Collatoral Rules

good_collateral :-
    collateral_value(X),
    loan_amount(L),
    X >= L.

partial_collateral :-
    collateral_value(X),
    loan_amount(L),
    X > L * 0.5,
    X < L.

no_collateral :-
    collateral_value(X),
    X =< 0.

% Family Responsibility

high_dependency :-
    dependents(X),
    X >= 4.

medium_dependency :-
    dependents(X),
    X >= 2,
    X < 4.

low_dependency :-
    dependents(X),
    X < 2.

% High Scoring Rules
% High Risks
high_risk :-
    poor_credit.

high_risk :-
    high_debt.

high_risk :-
    unstable_job.

% Medium Risks

medium_risk :-
    fair_credit.

medium_risk :-
    medium_debt.

medium_risk :-
    moderate_job.

% Low Risks

low_risk :-
    excellent_credit,
    low_debt,
    stable_job.


% Approval Rules

% Full Approval

approve_loan :-
    excellent_credit,
    high_income,
    low_debt,
    stable_job,
    working_age.


% Approval With Collatoral

approve_loan :-
    good_credit,
    medium_income,
    stable_job,
    good_collateral.

% Conditional Approval

conditional_approval :-
    fair_credit,
    medium_income,
    medium_debt
    
conditional_approval :-
    good_credit,
    moderate_job.
    
conditional_approval :-
    medium_income,
    partial_collateral.
    
    
% Rejection Rules

reject_loan :-
    poor_credit.
    
reject_loan :-
    unstable_job,
    large_loan.
    
reject_loan :-
    young_applicant.
    
    
% High Value Customer

premium_customer :-
    excellent_credit,
    high_income,
    low_debt,
    stable_job.
    
approve_loan :-
    premium_customer.



% Risky Large Loan

reject_loan :-
    large_loan,
    medium_debt.


% Explanation Rules

reason(approved) :-
    excellent_credit,
    stable_job,
    low_debt.

reason(rejected) :-
    poor_credit.
    
reason(conditional) :-
    fair_credit,
    medium_income.


