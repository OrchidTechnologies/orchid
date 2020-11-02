#
# Calculate the survival probability for Orchid accounts given:
#
# n -- number of nanopayments sent
# p -- winrate of a nanopayment
# F -- face value backing a nanopayment
# E -- initial payment escrow (lottery pot balance)
#
import numpy as np

def D(p, q):
    """Relative entropy of p and q."""
    result = p * np.log(p / q) + (1 - p) * np.log((1 - p) / (1 - q))
    if np.isnan(result):
        return 0
    return result

def pbust(n, p, F, E):
    """
    This expression is derived from the Chernoff bound of the tail of the binomial distribution.
    """
    return np.exp(-n * D(E / (n * F), p))


#
# Find n for various ratios of E/F.  
# (This won't work because the function does not behave well)
#
#import numpy as np
#from scipy.optimize import minimize
#for E in range(1, 25):
    #target_n = 0.2; F=1; p=1e-5;
    #x0 = np.array([1e3])
    #result = minimize(lambda n: abs(target_n - pbust(n=n, F=F, E=E, p=p)), x0, method='Nelder-Mead')
    #print(E, result.x)

#
# Find n for various ratios of E/F by brute force in the appropriate range
#
target_survival = 0.8 # target survival rate
for E in range(1, 25):
    for n in range(int(1e3), int(1e8)):
        pbustv = pbust(n=n, F=1, E=E, p=1e-5); 
        #print(1-pbustv)
        if (1-pbustv) < target_survival:
            print(E, n)
            break

# 80% survival rate: E/F, n
# 1 7969
# 2 40238
# 3 85956
# 4 139457
# 5 198151
# 6 260619
# 7 325989
# 8 393678
# 9 463275
# 10 534480
# 11 607060
# 12 680837
# 13 755667
# 14 831432
# 15 908034
# 16 985394
# 17 1063442
# 18 1142119
# 19 1221373
# 20 1301161
# 21 1381442
# 22 1462184
# 23 1543354
# 24 1624926

