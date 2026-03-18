import numpy as np
import skfuzzy as fuzz
from skfuzzy import control as ctrl

# Inputs
income = ctrl.Antecedent(np.arange(0, 10001, 1), 'income')
credit = ctrl.Antecedent(np.arange(300, 851, 1), 'credit')
debt = ctrl.Antecedent(np.arange(0, 1.1, 0.01), 'debt')

# Output
risk = ctrl.Consequent(np.arange(0, 101, 1), 'risk')

# Membership functions
income['low'] = fuzz.trimf(income.universe, [0, 0, 3000])
income['medium'] = fuzz.trimf(income.universe, [2000, 5000, 8000])
income['high'] = fuzz.trimf(income.universe, [6000, 10000, 10000])

credit['poor'] = fuzz.trimf(credit.universe, [300, 300, 550])
credit['fair'] = fuzz.trimf(credit.universe, [500, 650, 700])
credit['good'] = fuzz.trimf(credit.universe, [650, 750, 850])

debt['low'] = fuzz.trimf(debt.universe, [0, 0, 0.3])
debt['medium'] = fuzz.trimf(debt.universe, [0.2, 0.5, 0.7])
debt['high'] = fuzz.trimf(debt.universe, [0.6, 1, 1])

risk['low'] = fuzz.trimf(risk.universe, [0, 0, 40])
risk['medium'] = fuzz.trimf(risk.universe, [30, 50, 70])
risk['high'] = fuzz.trimf(risk.universe, [60, 100, 100])
