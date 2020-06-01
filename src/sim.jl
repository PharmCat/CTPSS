
"""
    ctsim(t::CTask{T, D, Bioequivalence, Power}; nsim = 100, seed=0)  where T where D

Bioequivalence power simulation.

"""
function ctsim(t::CTask{T, D, Bioequivalence, Power}; nsim = 100, rsabe = false, rsabeconst = 0.760, seed = 0)  where T where D
    if seed != 0  Random.seed!(seed) end
    df      = t.design.df(t.objective.val)
    sef     = sediv(t.design, t.objective.val)
    CHSQ    = Chisq(df)
    tval    = quantile(TDist(df), 1 - t.alpha)
    σ̵ₓ      = sef * t.param.a.sd
    pow     = 0
    for i = 1:nsim
        smean   = rand(ZDIST) * σ̵ₓ + (t.param.a.m - t.param.b.m)
        σ²      = rand(CHSQ)  * t.param.a.sd  ^ 2 / df
        σ       = sqrt(σ²)
        hw      = tval * σ * sef
        θ₁      = smean - hw
        θ₂      = smean + hw
        if rsabe
            cv = cvfromsd(σ)
            if cv > 0.30
                if θ₁ > (- rsabeconst * σ) && θ₂ < (rsabeconst * σ) pow += 1 end
            else
                if θ₁ > t.hyp.llim && θ₂ < t.hyp.ulim pow += 1 end
            end
        else
            if θ₁ > t.hyp.llim && θ₂ < t.hyp.ulim pow += 1 end
        end
    end
    return pow/nsim
end

# Proportion, Superiority, Power
"""
    ctsim(t::CTask{DiffProportion{P, P}, D, H, Power}; nsim = 100, seed=0, method = :default, dropout = 0.0)  where P <: Proportion where D where H <: Superiority

Proportion difference power simulation.

"""
function ctsim(t::CTask{DiffProportion{P, P}, D, H, Power}; nsim = 100, seed=0, method = :default, dropout = 0.0)  where P <: Proportion where D where H <: Superiority
    if seed != 0  Random.seed!(seed) end
    n₁      = getval(t.objective)
    n₂      = Int(ceil(getval(t.objective) / t.k))
    pow     = 0
    D₁      = Binomial(n₁, getval(t.param.a))
    D₂      = Binomial(n₂, getval(t.param.b))
    for i = 1:nsim
        n1      = rand(D₁)
        n2      = rand(D₂)
        ci      = confint(DiffProportion(Proportion(n1, getval(t.objective)), Proportion(n2, getval(t.objective))); level = 1.0 - t.alpha * 2, method = method)
        if  checkhyp(t.hyp, ci) pow += 1 end
    end
    return pow/nsim
end
