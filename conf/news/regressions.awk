@namespace "regression"

# Does a weighted linear regression of a step function f(t) with a weight function of exp(r*t)

# The core regression formula used is:
# y = b1*x + b0
# b0 = (Σ[y]*Σ[x^2] - Σ[x]*Σ[x*y]) / (Σ[1]*Σ[x^2] - Σ[x]^2)
# b1 = (Σ[1]*Σ[x*y] - Σ[x]*Σ[y]) / (Σ[1]*Σ[x^2] - Σ[x]^2)
# where Σ[g(x,y)] = ∫[t₀ -> t] exp(r*x)*g(x,f(x))*dx

# Persistent variables used by the algorithm:
# r   = growth constant of the weight function
# irt = r*t of the first step's start time
# prt = r*t of the last step's end time
# sy  = (∫[irt/r -> prt/r] exp(r*x)  *f(x)*dx)*r  /exp(prt)
# sxy = (∫[irt/r -> prt/r] exp(r*x)*x*f(x)*dx)*r^2/exp(prt)

# Components of the formula in terms of those variables:
# with drt = irt - prt
# with ef = exp(drt)
# Σ[1]   = exp(prt)/r*(1-ef)
# Σ[y]   = exp(prt)/r*sy
# Σ[x]   = exp(prt)/r^2*(prt-1-ef*(irt-1))
# Σ[x*y] = exp(prt)/r^2*sxy
# Σ[x^2] = exp(prt)/r^3*(prt^2-2*prt+2-ef*(irt^2-2*irt+2))

# b0 = (Σ[y]*Σ[x^2] - Σ[x]*Σ[x*y]) / (Σ[1]*Σ[x^2] - Σ[x]^2)
#    = (exp(prt)/r*sy*exp(prt)/r^3*(prt^2-2*prt+2-ef*(irt^2-2*irt+2)) - exp(prt)/r^2*(prt-1-ef*(irt-1))*exp(prt)/r^2*sxy) /
#      (exp(prt)/r*(1-ef)*exp(prt)/r^3*(prt^2-2*prt+2-ef*(irt^2-2*irt+2)) - (exp(prt)/r^2*(prt-1-ef*(irt-1)))^2)
#    = (sy*(prt^2-2*prt+2-ef*(irt^2-2*irt+2)) - (prt-1-ef*(irt-1))*sxy) / ((1-ef)*(prt^2-2*prt+2-ef*(irt^2-2*irt+2)) - (prt-1-ef*(irt-1))^2)
#    = (sy*(prt^2-ef*irt^2)+(sxy+2*sy)*(1-prt-ef*(1-irt))) / (ef*(ef-drt^2-2)+1)
# b1 = (Σ[1]*Σ[x*y] - Σ[x]*Σ[y]) / (Σ[1]*Σ[x^2] - Σ[x]^2)
#    = (exp(prt)/r*(1-ef)*exp(prt)/r^2*sxy - exp(prt)/r^2*(prt-1-ef*(irt-1))*exp(prt)/r*sy) /
#      (exp(prt)/r*(1-ef)*exp(prt)/r^3*(prt^2-2*prt+2-ef*(irt^2-2*irt+2)) - (exp(prt)/r^2*(prt-1-ef*(irt-1)))^2)
#    = r*((1-ef)*sxy - (prt-1-ef*(irt-1))*sy)/((1-ef)*(prt^2-2*prt+2-ef*(irt^2-2*irt+2)) - ((prt-1-ef*(irt-1)))^2)
#    = r*((1-ef)*(sxy+sy)+(ef*irt-prt)*sy) / (ef*(ef-drt^2-2)+1)

# a version of exp() that doesn't warn about rounding to zero
BEGIN { exp_warn_breakpoint = -6554261109157969/8796093022208; }
function exp_no_warn(x) {
    if (x < exp_warn_breakpoint) return 0;
    return exp(x);
}

# configure the weight function
function config(dt) {
    # calculate the growth constant of the exponential growth of the weight function, in terms of the given doubling time
    r = log(2)/dt;
}

# initialize regression, with a given start time for the (not yet created) first step
function init(t) {
    irt = prt = r*t;
    sy = sxy = 0;
}

# add a step of the step function, ending at the given time, with the given value
function step(t, v) {
    rt = r*t;
    drt = prt-rt;
    if (drt > 0) {
        printf "Warning: Entries are not in time order! Skipping.\n" >>"/dev/stderr";
        return;
    }
    ef = exp_no_warn(drt);
    sy  = ef*(sy  - v          ) + v;
    sxy = ef*(sxy - v*(prt - 1)) + v*(rt - 1);
    prt = rt;
}

# calculate the reciprocal of the slope of the linear regression result
function recip_slope() {
    drt = irt - prt;
    ef = exp_no_warn(drt);
    divisor = r*((1 - ef)*(sxy + sy) + (ef*irt - prt)*sy);
    if (divisor == 0) return awk::strtonum("+inf");
    return (ef*(ef - drt^2 - 2) + 1)/divisor;
}

@namespace "awk"

function min(x, y) {
    if (x <= y)
        return x;
    else
        return y;
}

function max(x, y) {
    if (x >= y)
        return x;
    else
        return y;
}

BEGIN {
    regression::config(weightdoublingtime);
}

NR==1 {
    regression::init($1 - firststeplength);
    count = 0;
}

{
    regression::step($1, count);
    count += 1;
    lastentry = $1;
}

END {
    regression::step(lastchecked, count);

    # Regression-based estimator
    regressiondelay = regression::recip_slope()/regressiondiv;
    regressiondelay = max(regressiondelay,regressionmin);

    # Estimator based on time since last entry
    recentdelay = (lastchecked-lastentry)/recentdiv;
    recentdelay = max(recentdelay,recentmin);

    # Use the minimum of the 2 estimators
    checkdelay = min(regressiondelay,recentdelay);
    checkdelay = min(checkdelay,maxdelay);

    now = systime();
    srand(now + count); # Probably random enough for what we need.
    if (now >= max(lastchecked,lastfailed) + checkdelay || (lastfailed > lastchecked && (now-lastchecked)/(lastfailed-lastchecked) > backofffactor))
        exit (rand() > deferprobablility) # Fail, indicating it's time to re-check, but occasionally put it off, to break up cadence between feeds over time.
    else
        exit 0 # Succeed, indicating it can wait till later
}
