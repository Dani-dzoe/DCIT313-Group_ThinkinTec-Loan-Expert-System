% =========================
% Loan Expert System (KBS)
% Knowledge Base + Inference
% DCIT 313 – Final Project
% =========================

% ---- Threshold Facts (easy to tune) ----
min_income(1500).
min_credit(600).
max_debt_ratio(0.55).
min_employment_years(1).

good_income(3000).
good_credit(700).
good_debt_ratio(0.40).
good_employment_years(2).

% Upper anchors for normalization (for risk scoring)
anchor_income_high(6000).        % >= this → very safe income
anchor_credit_high(850).         % plausible upper bound
anchor_employment_high(10).      % years
anchor_debt_ratio_high(1.0).     % 100% debt ratio
anchor_lti_max(2.0).             % loan-to-(annual)-income cap for risk

% ---- Utility & math helpers ----
clamp(Min, Max, X, Y) :-
    ( X < Min -> Y = Min
    ; X > Max -> Y = Max
    ; Y = X
    ).

% Linear risk for income: higher income → lower risk [0..100]
income_risk(Income, Risk) :-
    anchor_income_high(H),
    ( Income >= H -> Risk = 0
    ; Gap is H - Income,
      Risk0 is (Gap / H) * 100,
      clamp(0, 100, Risk0, Risk)
    ).

% Linear risk for credit: higher credit → lower risk [0..100]
credit_risk(Credit, Risk) :-
    anchor_credit_high(Top),
    Bottom = 300,
    clamp(Bottom, Top, Credit, Cc),
    Range is Top - Bottom,
    Risk0 is ((Top - Cc) / Range) * 100,
    clamp(0, 100, Risk0, Risk).

% Linear risk for debt ratio: more debt → higher risk [0..100]
debt_risk(DebtRatio, Risk) :-
    anchor_debt_ratio_high(MaxR),
    clamp(0.0, MaxR, DebtRatio, Dr),
    Risk0 is (Dr / MaxR) * 100,
    clamp(0, 100, Risk0, Risk).

% Linear risk for employment: longer employment → lower risk [0..100]
employment_risk(Years, Risk) :-
    anchor_employment_high(MaxY),
    ( Years >= MaxY -> Risk = 0
    ; Gap is MaxY - Years,
      Risk0 is (Gap / MaxY) * 100,
      clamp(0, 100, Risk0, Risk)
    ).

% Loan-to-(annual)-income ratio component: higher ratio → higher risk [0..100]
loan_amount_risk(LoanAmount, Income, Risk) :-
    AnnualIncome is max(Income * 12, 1),  % avoid division by zero
    Ratio0 is LoanAmount / AnnualIncome,
    anchor_lti_max(MaxRatio),
    clamp(0.0, MaxRatio, Ratio0, Ratio),
    Risk0 is (Ratio / MaxRatio) * 100,
    clamp(0, 100, Risk0, Risk).

% ---- Composite risk score with weights (sum to 1.0) ----
% Weights reflect domain intuition: debt & credit dominate risk.
risk_score(Income, Credit, DebtRatio, EmploymentYears, LoanAmount, Score) :-
    income_risk(Income, Rinc),
    credit_risk(Credit, Rcred),
    debt_risk(DebtRatio, Rdebt),
    employment_risk(EmploymentYears, Remp),
    loan_amount_risk(LoanAmount, Income, Rloan),
    Wdebt = 0.35, Wcred = 0.30, Winc = 0.15, Wemp = 0.10, Wloan = 0.10,
    Score0 is Rdebt*Wdebt + Rcred*Wcred + Rinc*Winc + Remp*Wemp + Rloan*Wloan,
    clamp(0, 100, Score0, Score).

% ---- Hard eligibility gates (policy rules) ----
% IMPORTANT: bind thresholds FIRST, then compare (prevents instantiation_error)
fails_hard_gate(Income, Credit, DebtRatio, EmploymentYears, Reason) :-
    ( min_income(MinI),             Income      <  MinI, Reason = low_income )
 ;  ( min_credit(MinC),             Credit      <  MinC, Reason = low_credit )
 ;  ( max_debt_ratio(MaxD),         DebtRatio   >  MaxD, Reason = high_debt )
 ;  ( min_employment_years(MinE),   EmploymentYears < MinE, Reason = short_employment ).

% Collect all failing hard-gate reasons into a list
collect_gate_failures(I, C, D, E, Reasons) :-
    findall(R, fails_hard_gate(I, C, D, E, R), Reasons).

% Soft reasons (for explanations) based on “good” thresholds + high LTI
soft_short_employment(E, R) :- good_employment_years(G), E < G, R = moderate_employment.
soft_income(I, R)           :- good_income(G),           I < G, R = moderate_income.
soft_credit(C, R)           :- good_credit(G),           C < G, R = moderate_credit.
soft_debt(D, R)             :- good_debt_ratio(G),       D > G, R = moderate_debt.

collect_soft_reasons(I, C, D, E, L, SoftReasons) :-
    AnnualIncome is max(I*12, 1),
    LR is L / AnnualIncome,
    findall(R, (
        soft_income(I, R)
      ; soft_credit(C, R)
      ; soft_debt(D, R)
      ; soft_short_employment(E, R)
      ; (LR > 1.0, R = high_loan_to_income)
    ), SoftReasons).

% ---- Decision policy from risk score (if no hard-gate failure) ----
% Tunable cutoffs:
%   <=45 → approved ; 45..65 → conditional ; >65 → rejected.
decision_from_score(Score, approved)    :- Score =< 45, !.
decision_from_score(Score, conditional) :- Score  > 45, Score =< 65, !.
decision_from_score(_Score, rejected).   % underscore avoids singleton warning

% Map reason atoms to human-readable advice
advice_for(low_income,            "Increase monthly income or apply with a guarantor/collateral.").
advice_for(low_credit,            "Improve credit behavior for 3–6 months; pay bills on time and reduce outstanding balances.").
advice_for(high_debt,             "Lower your debt ratio: pay off existing loans/credit before reapplying.").
advice_for(short_employment,      "Maintain stable employment for at least 12 months before reapplying.").
advice_for(moderate_income,       "Income is below the preferred level; consider a smaller loan or add a co-signer.").
advice_for(moderate_credit,       "Credit is fair; reduce hard inquiries and keep utilization under 30%.").
advice_for(moderate_debt,         "Debt ratio is moderate; paying down balances will improve your decision.").
advice_for(moderate_employment,   "Employment length is moderate; longer stability improves the outcome.").
advice_for(high_loan_to_income,   "Requested amount is high relative to income; consider reducing the loan amount.").

reasons_to_advice([], []).
reasons_to_advice([R|Rs], [T|Ts]) :-
    advice_for(R, T), !,
    reasons_to_advice(Rs, Ts).
reasons_to_advice([_|Rs], Ts) :-    % ignore unmapped reason codes
    reasons_to_advice(Rs, Ts).

% ---- Public entry point: evaluate/9 ----
% evaluate(+Income,+Credit,+DebtRatio,+EmploymentYears,+LoanAmount,
%          -Decision,-RiskScore,-Reasons,-AdviceList)
evaluate(I, C, D, E, L, Decision, RiskRounded, Reasons, AdviceList) :-
    % 1) Hard-gate failures → immediate reject
    collect_gate_failures(I, C, D, E, GateReasons),
    (   GateReasons \= []
    ->  Decision = rejected,
        RiskRounded = 100,
        Reasons = GateReasons,
        reasons_to_advice(GateReasons, AdviceList)
    ;   % 2) Compute risk score and policy decision
        risk_score(I, C, D, E, L, RiskScore),
        decision_from_score(RiskScore, Decision),
        % 3) Soft reasons (for explanations)
        collect_soft_reasons(I, C, D, E, L, SoftRs),
        Reasons = SoftRs,
        reasons_to_advice(SoftRs, AdviceList),
        RiskRounded is round(RiskScore)
    ).