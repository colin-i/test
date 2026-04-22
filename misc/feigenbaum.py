
#http://www.harald-hofstaetter.at/Math/Feigenbaum.html
#-2.50290787509589282228390287321821578638127137672714997733619205677923546317959020670329964974643383412959523186999585472394218237778544517927286331499337257811216359487950374478126099738059867123971173732892766540440103066983138346000941393223644906578899512205843172507873377463087853424285351988587500042358246918740820428170090171482305182162161941319985606612938274264970984408447010080545496779367608881264464068851815527093240075425064971570470475419932831783645332562415378693957125097066387979492654623137
#4.66920160910299067185320382046620161725818557747576863274565134300413433021131473713868974402394801381716598485518981513440862714202793252231244298889089085994493546323671341153248171421994745564436582379320200956105833057545861765222207038541064674949428498145339172620056875566595233987560382563722564800409510712838906118447027758542854198011134401750024285853824983357155220522360872502916788603626745272133990571316068753450834339344461037063094520191158769724322735898389037949462572512890979489867683346116

import numpy as np
from decimal import Decimal, getcontext
import math

# set precision (similar to BigFloat)
getcontext().prec = 100


# -----------------------------
# eval_g
# -----------------------------
def eval_g(x, g, n):
    x2 = x * x
    y = g[n - 1]
    for j in range(n - 2, -1, -1):
        y = y * x2 + g[j]
    y = y * x2 + 1
    return y


# -----------------------------
# eval_diff_g
# -----------------------------
def eval_diff_g(x, g, n):
    x2 = x * x
    y = 2 * n * g[n - 1]
    for j in range(n - 2, -1, -1):
        y = y * x2 + 2 * (j + 1) * g[j]
    y = y * x
    return y


# -----------------------------
# generate_F_J
# -----------------------------
def generate_F_J(g, x, n):
    F = np.zeros(n, dtype=float)
    J = np.zeros((n, n), dtype=float)

    g1 = eval_g(1.0, g, n)

    gx = np.array([eval_g(x[j], g, n) for j in range(n)])
    gdax = np.array([eval_diff_g(g1 * x[j], g, n) for j in range(n)])
    gax = np.array([eval_g(g1 * x[j], g, n) for j in range(n)])
    gdgax = np.array([eval_diff_g(gax[j], g, n) for j in range(n)])
    ggax = np.array([eval_g(gax[j], g, n) for j in range(n)])

    g12 = g1 * g1
    x2 = x * x
    gax2 = gax * gax

    F[:] = g1 * gx - ggax

    x2j = np.ones(n)
    gax2j = np.ones(n)
    g12j = 1.0

    for j in range(n):
        if j == 0:
            x2j = x2.copy()
            gax2j = gax2.copy()
            g12j = g12
        else:
            x2j *= x2
            gax2j *= gax2
            g12j *= g12

        J[:, j] = gx + g1 * x2j - gax2j - gdgax * (g12j * x2j + gdax * x)

    return F, J


# -----------------------------
# Newton iteration for alpha
# -----------------------------
def newton_iteration_for_alpha_g(g, x, n, maxit):
    alpha = 1 / eval_g(1.0, g, n)
    alpha_old = alpha
    diff = 1000
    diff_old = diff

    for k in range(maxit):
        F, J = generate_F_J(g, x, n)

        # solve J * delta = F
        delta = np.linalg.solve(J, F)
        g = g - delta

        res = np.max(np.abs(F))
        alpha = 1 / eval_g(1.0, g, n)

        diff = abs(alpha - alpha_old)
        print(alpha, f"{res:.3e} {diff:.3e}")

        if res < 1e-14 or diff > 0.1 * diff_old:
            break

        alpha_old = alpha
        diff_old = diff

    return alpha, g


# -----------------------------
# generate_L
# -----------------------------
def generate_L(g, x, n):
    L = np.zeros((n, n), dtype=float)

    g1 = eval_g(1.0, g, n)
    ax = g1 * x

    gax = np.array([eval_g(ax[k], g, n) for k in range(n)])
    gdgax = np.array([eval_diff_g(gax[k], g, n) for k in range(n)])

    ax2 = ax ** 2
    gax2 = gax ** 2
    alpha = 1 / g1

    ax2j = np.ones(n)
    gax2j = np.ones(n)

    for j in range(n):
        if j == 1:
            ax2j = ax2.copy()
            gax2j = gax2.copy()
        elif j > 1:
            ax2j *= ax2
            gax2j *= gax2

        L[:, j] = alpha * (gax2j + gdgax * ax2j)

    return L


# -----------------------------
# solve_vander
# -----------------------------
def solve_vander(x, f, n):
    f = f.copy()

    for k in range(n - 1):
        for i in range(n - 1, k, -1):
            f[i] = (f[i] - f[i - 1]) / (x[i] - x[i - k - 1])

    for k in range(n - 2, -1, -1):
        for i in range(k, n - 1):
            f[i] = f[i] - f[i + 1] * x[k]

    return f


# -----------------------------
# power method for delta
# -----------------------------
def power_method_for_delta_h(h, g, x, n, maxit):
    L = generate_L(g, x, n)
    x2 = x ** 2

    delta = 4.669
    delta_old = delta
    diff = 100
    diff_old = diff

    for k in range(maxit):
        h = L @ h
        h = solve_vander(x2, h, n)

        delta = h[0]

        if k % 20 == 0:
            diff = abs(delta - delta_old)
            print(k, delta, f"{diff:.3e}")

            if diff > 0.9 * diff_old:
                break

            delta_old = delta
            diff_old = diff

        h = h / delta

    return delta


# -----------------------------
# MAIN
# -----------------------------
if __name__ == "__main__":
    n = 20
    x = np.sqrt(np.arange(1, n + 1) / n)

    g = np.zeros(n)
    g[:3] = [-1.5218, 1.0481e-1, 2.67076e-2]

    alpha, g = newton_iteration_for_alpha_g(g, x, n, 30)

    h = np.zeros(n)
    h[:3] = [1.0, -3.2565e-1, -5.05539e-2]

    delta = power_method_for_delta_h(h, g, x, n, 1000)

    print("\nFinal results:")
    print("alpha =", alpha)
    print("delta =", delta)
