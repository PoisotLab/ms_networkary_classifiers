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

Random.seed!(5)

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
    # 𝐱 = table(hcat(𝐱₁, 𝐱₂, 𝐱₃))
    𝐱 = table(hcat(𝐱₁, 𝐱₂))
    return (𝐱, 𝐲)
end

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

S = (50,50)

𝐗, 𝐲 = network(S, 0.20)
bias = 0.5

training_size = round(Int64, 0.3 * length(𝐲))
n_positive = round(Int64, training_size * bias)
idx_pos = sample(findall(iszero.(𝐲)), n_positive; replace=true)
idx_neg = sample(findall(isone.(𝐲)), training_size - n_positive; replace=true)
Iₚ = shuffle(vcat(idx_neg, idx_pos))
Iₒ = setdiff(eachindex(𝐲), Iₚ)

m = Pair[]

Ms = []

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
    @info ROCAUC = ∫(fpr.(M), tpr.(M))
    @info AUPRC = ∫(tpr.(M), ppv.(M))
    𝐌 = M[last(findmax(informedness.(M)))]
    push!(Ms, 𝐌)

    push!(m, this_machine => thresholds[last(findmax(informedness.(M)))])
end

function R(x, m, M)
    x = x .- m
    x = x ./ (M - m)
    return x
end

R(x) = R(x, extrema(x)...)

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
push!(Ms, 𝐌)
ens_thres = thresholds[last(findmax(informedness.(M)))]

mnames = [String(p.first) for p in candidate_models]
results = DataFrame(;
    infectivity=Float64[],
    resistance=Float64[],
    model=String[],
    prediction=Float64[],
    guess=Float64[],
    truth = Float64[]
)
for j in 1:length(m)
    pr = MLJ.predict(m[j].first)
    prr = R(pr)
    thr = R(m[j].second, extrema(pr)...)
    for i in 1:length(𝐲)
        push!(results, (𝐗.x1[i], 𝐗.x2[i], mnames[j], prr[i], prr[i] >= thr, 𝐲[i]))
    end
end
for i in 1:length(𝐲)
    push!(results, (𝐗.x1[i], 𝐗.x2[i], "Ensemble", ens_pred[i], ens_pred[i] >= ens_thres, 𝐲[i]))
end
for i in 1:length(𝐲)
    push!(results, (𝐗.x1[i], 𝐗.x2[i], "Dataset", 𝐲[i], 𝐲[i], 𝐲[i]))
end

data(results) *
    mapping(:infectivity => "Infectivity trait", :resistance => "Resistance trait", :prediction => "Prediction score"; layout=:model => sorter("BRT", "Random Forest", "Decision tree", "kNN", "Ensemble", "Dataset")) *
    visual(Heatmap, colormap=Reverse(:deep)) |>
    plt -> draw(plt, facet=(;linkyaxes = :minimal), axis = (xticks = LinearTicks(3),)) |>
    plt -> save(joinpath(@__DIR__, "..", "figures", "valid_ensemble.png"), plt, px_per_unit = 3)
