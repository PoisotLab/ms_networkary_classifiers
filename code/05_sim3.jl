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

Random.seed!(1)

# AUC
function ∫(x::Array{T}, y::Array{T}) where {T<:Number}
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
    return (x - r / 2.0) ≤ y ≤ (x + r / 2.0) ? one(T) : zero(T)
end
function network(S, ξ)
    infectivity = Beta(6.0, 8.0)
    resistance = Beta(2.0, 8.0)
    𝐱ᵥ = sort(rand(infectivity, S[1]))
    𝐱ₕ = sort(rand(resistance, S[2]))
    𝐱₁ = repeat(𝐱ᵥ; outer=length(𝐱ₕ))
    𝐱₂ = repeat(𝐱ₕ; inner=length(𝐱ᵥ))
    𝐱₃ = abs.(𝐱₁ .- 𝐱₂)
    𝐲 = [L(𝐱₁[i], 𝐱₂[i]; r=ξ) for i in 1:length(𝐱₁)]
    #𝐱 = table(hcat(𝐱₁, 𝐱₂, 𝐱₃))
    𝐱 = table(hcat(𝐱₁, 𝐱₂))
    return (𝐱, 𝐲)
end

function R(x, m, M)
    x = x .- m
    x = x ./ (M - m)
    return x
end

R(x) = R(x, extrema(x)...)


DecisionTree = @load DecisionTreeRegressor pkg = DecisionTree
RandomForest = @load RandomForestRegressor pkg = DecisionTree
BoostedRegressor = @load EvoTreeRegressor pkg = EvoTrees
RidgeRegressor = @load RidgeRegressor pkg = MLJLinearModels

candidate_models = [
    :DecTree => DecisionTree(),
    :BRT => BoostedRegressor(),
    :RF => RandomForest(),
    :RR => RidgeRegressor(),
]

S = (50,80)

results = DataFrame(
    run = Int64[],
    model = Symbol[],
    measure = Symbol[],
    value = Float64[]
)

for i in 1:250

    𝐗, 𝐲 = network(S, 0.19)

    net = BipartiteNetwork(reshape(Bool.(𝐲), S))
    push!(results, (i, :data, :Connectance, connectance(net)))
    push!(results, (i, :data, :Nestedness, η(net)))
    push!(results, (i, :data, :Modularity, Q(brim(lp(net)...)...)))

    bias = 0.7

    training_size = round(Int64, 0.3 * length(𝐲))
    n_positive = round(Int64, training_size * bias)
    idx_pos = sample(findall(iszero.(𝐲)), n_positive; replace=true)
    idx_neg = sample(findall(isone.(𝐲)), training_size - n_positive; replace=true)
    Iₚ = shuffle(vcat(idx_neg, idx_pos))
    Iₒ = setdiff(eachindex(𝐲), Iₚ)

    m = Pair[] # Predictions (raw)
    Ms = [] # Best confmat

    for candidate_model in candidate_models
        this_machine = machine(candidate_model.second, 𝐗, 𝐲)
        fit!(this_machine; rows=Iₚ)
        prediction = mean.(MLJ.predict(this_machine; rows=Iₒ))

        # The prediction isn't clamped because we threshold it so who gives a shit
        thresholds = LinRange(minimum(prediction), maximum(prediction), 500)

        # Confusion matrix
        binobs = Bool.(𝐲[Iₒ])
        M = Vector{ConfusionMatrix}(undef, length(thresholds))
        for (i, τ) in enumerate(thresholds)
            binpred = prediction .>= τ
            tp = sum(binobs .& binpred)
            tn = sum(.!binobs .& .!binpred)
            fp = sum(.!binobs .& binpred)
            fn = sum(binobs .& .!binpred)
            M[i] = ConfusionMatrix(tp, tn, fp, fn)
        end
        ROCAUC = ∫(fpr.(M), tpr.(M))
        AUPRC = ∫(tpr.(M), ppv.(M))
        𝐌 = M[last(findmax(informedness.(M)))]

        push!(results, (i, candidate_model.first, :ROCAUC, ROCAUC))
        push!(results, (i, candidate_model.first, :PRAUC, AUPRC))
        push!(results, (i, candidate_model.first, :MCC, mcc(𝐌)))
        push!(results, (i, candidate_model.first, :INF, informedness(𝐌)))

        push!(Ms, 𝐌)
        push!(m, this_machine => thresholds[last(findmax(informedness.(M)))])

        # Network
        pr = MLJ.predict(this_machine)
        thr = thresholds[last(findmax(informedness.(M)))]
        net = BipartiteNetwork(reshape(pr .>= thr, S))
        push!(results, (i, candidate_model.first, :Connectance, connectance(net)))
        push!(results, (i, candidate_model.first, :Nestedness, η(net)))
        push!(results, (i, candidate_model.first, :Modularity, Q(brim(lp(net)...)...)))

    end


    # Ensemble and thresholding
    ens_pred = mean(hcat([R(MLJ.predict(m[j].first)) for j in 1:length(m)]...); dims=2)
    binobs = Bool.(𝐲[Iₒ])
    thresholds = LinRange(minimum(ens_pred), maximum(ens_pred), 500)
    M = Vector{ConfusionMatrix}(undef, length(thresholds))
    for (i, τ) in enumerate(thresholds)
        binpred = ens_pred[Iₒ] .>= τ
        tp = sum(binobs .& binpred)
        tn = sum(.!binobs .& .!binpred)
        fp = sum(.!binobs .& binpred)
        fn = sum(binobs .& .!binpred)
        M[i] = ConfusionMatrix(tp, tn, fp, fn)
    end
    ROCAUC = ∫(fpr.(M), tpr.(M))
    AUPRC = ∫(tpr.(M), ppv.(M))
    𝐌 = M[last(findmax(informedness.(M)))]
    thr = thresholds[last(findmax(informedness.(M)))]
    push!(Ms, 𝐌)
    ens_thres = thresholds[last(findmax(informedness.(M)))]
    push!(results, (i, :ensemble, :ROCAUC, ROCAUC))
    push!(results, (i, :ensemble, :PRAUC, AUPRC))
    push!(results, (i, :ensemble, :MCC, mcc(𝐌)))
    push!(results, (i, :ensemble, :INF, informedness(𝐌)))

    net = BipartiteNetwork(reshape(ens_pred .>= thr, S))
    push!(results, (i, :ensemble, :Connectance, connectance(net)))
    push!(results, (i, :ensemble, :Nestedness, η(net)))
    push!(results, (i, :ensemble, :Modularity, Q(brim(lp(net)...)...)))

end

allowmissing!(results, :value)
replace!(results.value, NaN => missing)
dropmissing!(results)
bmm = groupby(results, [:model, :measure])
opt = combine(bmm, :value => (x -> round(mean(x); digits=2)) => :mean)
unstack(opt, :model, :measure, :mean)