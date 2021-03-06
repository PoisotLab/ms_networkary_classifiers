using Statistics
using StatsFuns
using StatsBase
using DataFramesMeta
using Random
using Statistics
using MLJ
using DataFrames
using CSV: CSV
using Distributions
using AlgebraOfGraphics, CairoMakie
using EcologicalNetworks
using Random
using Combinatorics

Random.seed!(3)

# AUC
function β«(x::Array{T}, y::Array{T}) where {T<:Number}
    S = zero(Float64)
    for i in 2:length(x)
        S += (x[i] - x[i - 1]) * (y[i] + y[i - 1]) * 0.5
    end
    return .-S
end

# Confusion matrix utilities
include(joinpath(@__DIR__, "confusionmatrix.jl"))

# Network generation function
function L(x::T, y::T; r::T=0.1) where {T<:Number}
    return (x - r / 2.0) β€ y β€ (x + r / 2.0) ? one(T) : zero(T)
end

function network(S, ΞΎ)
    infectivity = Beta(6.0, 8.0)
    resistance = Beta(2.0, 8.0)
    π±α΅₯ = sort(rand(infectivity, S[1]))
    π±β = sort(rand(resistance, S[2]))
    π±β = repeat(π±α΅₯; outer=length(π±β))
    π±β = repeat(π±β; inner=length(π±α΅₯))
    π² = [L(π±β[i], π±β[i]; r=ΞΎ) for i in 1:length(π±β)]
    π± = table(hcat(π±β, π±β))
    return (π±, π²)
end

function swaps!(π², s)
    p = findall(isone, π²)
    n = findall(iszero, π²)
    π²[rand(p, s)] .= 0.0
    π²[rand(n, s)] .= 1.0
    return π²
end

function R(x, m, M)
    x = x .- m
    x = x ./ (M - m)
    return x
end

R(x) = R(x, extrema(x)...)

DecisionTree = @load DecisionTreeRegressor pkg = DecisionTree verbosity=0
RandomForest = @load RandomForestRegressor pkg = DecisionTree verbosity=0
BoostedRegressor = @load EvoTreeRegressor pkg = EvoTrees verbosity=0
KNNRegressor = @load KNNRegressor pkg = NearestNeighborModels verbosity=0

candidate_models = [
    Symbol("Decision tree") => DecisionTree(),
    :BRT => BoostedRegressor(),
    Symbol("Random Forest") => RandomForest(),
    :kNN => KNNRegressor(),
]

S = (50,40)

results = DataFrame(
    run = Int64[],
    model = Symbol[],
    measure = Symbol[],
    value = Float64[]
)

function asymmetry(B::BipartiteNetwork)
    s1 = species(B; dims=1)
    s2 = species(B; dims=2)
    k1 = [degree(B)[s] for s in s1]
    k2 = [degree(B)[s] for s in s2]'
    C = abs.(k1 .- k2) ./ (k1 .+ k2) .* adjacency(B)
    return sum(C)/links(B)
end

function betadiv(n1, n2)
    return KGL08(Ξ²os(n1, n2))
end

for i in 1:300

    π, π² = network(S, 0.15)
    # swaps!(π², 15)

    net = BipartiteNetwork(reshape(Bool.(π²), S))
    realnet = copy(net)
    push!(results, (i, :data, :Co, connectance(net)))
    push!(results, (i, :data, :Nest, Ξ·(net)))
    push!(results, (i, :data, :Mod, Q(brim(lp(net)...)...)))
    push!(results, (i, :data, :Asymm, asymmetry(net)))
    bias = 0.5

    training_size = round(Int64, 0.7 * length(π²))
    n_positive = round(Int64, training_size * bias)
    idx_pos = sample(findall(iszero.(π²)), n_positive; replace=true)
    idx_neg = sample(findall(isone.(π²)), training_size - n_positive; replace=true)
    Iβ = shuffle(vcat(idx_neg, idx_pos))
    Iβ = setdiff(eachindex(π²), Iβ)

    m = Pair[] # Predictions (raw)
    Ms = [] # Best confmat

    for candidate_model in candidate_models
        this_machine = machine(candidate_model.second, π, π²)
        fit!(this_machine; rows=Iβ)
        prediction = mean.(MLJ.predict(this_machine; rows=Iβ))

        # The prediction isn't clamped because we threshold it so who gives a shit
        thresholds = LinRange(minimum(prediction), maximum(prediction), 500)

        # Confusion matrix
        binobs = Bool.(π²[Iβ])
        M = Vector{ConfusionMatrix}(undef, length(thresholds))
        for (i, Ο) in enumerate(thresholds)
            binpred = prediction .>= Ο
            tp = sum(binobs .& binpred)
            tn = sum(.!binobs .& .!binpred)
            fp = sum(.!binobs .& binpred)
            fn = sum(binobs .& .!binpred)
            M[i] = ConfusionMatrix(tp, tn, fp, fn)
        end
        ROCAUC = β«(fpr.(M), tpr.(M))
        AUPRC = β«(tpr.(M), ppv.(M))
        π = M[last(findmax(informedness.(M)))]

        push!(results, (i, candidate_model.first, :ROCAUC, ROCAUC))
        push!(results, (i, candidate_model.first, :PRAUC, AUPRC))
        push!(results, (i, candidate_model.first, :MCC, mcc(π)))
        push!(results, (i, candidate_model.first, :INF, informedness(π)))
        push!(results, (i, candidate_model.first, :F1, informedness(π)))
        push!(results, (i, candidate_model.first, :ACC, accuracy(π)))
        push!(results, (i, candidate_model.first, :BAC, balanced(π)))

        push!(Ms, π)
        push!(m, this_machine => thresholds[last(findmax(informedness.(M)))])

        # Network
        pr = MLJ.predict(this_machine)
        thr = thresholds[last(findmax(informedness.(M)))]
        net = BipartiteNetwork(reshape(pr .>= thr, S))
        push!(results, (i, candidate_model.first, :Co, connectance(net)))
        push!(results, (i, candidate_model.first, :Nest, Ξ·(net)))
        push!(results, (i, candidate_model.first, :Mod, Q(brim(lp(net)...)...)))
        push!(results, (i, candidate_model.first, :Asymm, asymmetry(net)))
        push!(results, (i, candidate_model.first, :Betadiv, betadiv(realnet, net)))

    end

    # Ensemble and thresholding
    ens_pred = mean(hcat([R(MLJ.predict(m[j].first)) for j in 1:length(m)]...); dims=2)
    binobs = Bool.(π²[Iβ])
    thresholds = LinRange(minimum(ens_pred), maximum(ens_pred), 500)
    M = Vector{ConfusionMatrix}(undef, length(thresholds))
    for (i, Ο) in enumerate(thresholds)
        binpred = ens_pred[Iβ] .>= Ο
        tp = sum(binobs .& binpred)
        tn = sum(.!binobs .& .!binpred)
        fp = sum(.!binobs .& binpred)
        fn = sum(binobs .& .!binpred)
        M[i] = ConfusionMatrix(tp, tn, fp, fn)
    end
    ROCAUC = β«(fpr.(M), tpr.(M))
    AUPRC = β«(tpr.(M), ppv.(M))
    π = M[last(findmax(informedness.(M)))]
    thr = thresholds[last(findmax(informedness.(M)))]
    push!(Ms, π)
    ens_thres = thresholds[last(findmax(informedness.(M)))]
    push!(results, (i, :ensemble, :ROCAUC, ROCAUC))
    push!(results, (i, :ensemble, :PRAUC, AUPRC))
    push!(results, (i, :ensemble, :MCC, mcc(π)))
    push!(results, (i, :ensemble, :INF, informedness(π)))
    push!(results, (i, :ensemble, :F1, f1(π)))
    push!(results, (i, :ensemble, :ACC, accuracy(π)))
    push!(results, (i, :ensemble, :BAC, balanced(π)))

    net = BipartiteNetwork(reshape(ens_pred .>= thr, S))
    push!(results, (i, :ensemble, :Co, connectance(net)))
    push!(results, (i, :ensemble, :Nest, Ξ·(net)))
    push!(results, (i, :ensemble, :Mod, Q(brim(lp(net)...)...)))
    push!(results, (i, :ensemble, :Asymm, asymmetry(net)))
    push!(results, (i, :ensemble, :Betadiv, betadiv(realnet, net)))

end

allowmissing!(results, :value)
replace!(results.value, NaN => missing)
dropmissing!(results)
bmm = groupby(results, [:model, :measure])
opt = combine(bmm, :value => (x -> round(mean(x); digits=2)) => :mean)
unstack(opt, :model, :measure, :mean)
