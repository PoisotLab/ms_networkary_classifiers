using EcologicalNetworks
using AlgebraOfGraphics, CairoMakie
using DataFrames
using CSV: CSV
using DataFramesMeta
using LinearAlgebra
using Statistics

N = simplify.(nz_stream_foodweb())

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


results = DataFrame(network=Int64[], connectance=Float64[], rank=Int64[], varexpl=Float64[], measure=Symbol[], value=Float64[])

for n in 1:length(N)
    for r in 1:45
        _svd = svd(N[n])
        varexpl = sum(_svd.S[1:r])/sum(_svd.S)
        prediction = prod(rdpg(N[n], r))
        thresholds = LinRange(minimum(vec(prediction)), maximum(vec(prediction)), 200)
        M = Vector{ConfusionMatrix}(undef, length(thresholds))
        binobs = adjacency(N[n])
        for (i, τ) in enumerate(thresholds)
            binpred = prediction .>= τ
            tp = sum(binobs .& binpred)
            tn = sum(.!binobs .& .!binpred)
            fp = sum(.!binobs .& binpred)
            fn = sum(binobs .& .!binpred)
            M[i] = ConfusionMatrix(tp, tn, fp, fn)
        end
        X = UnipartiteNetwork(prediction .>= thresholds[last(findmax(informedness.(M)))])
        ROCAUC = ∫(fpr.(M), tpr.(M))
        AUPRC = ∫(tpr.(M), ppv.(M))
        𝐌 = M[last(findmax(informedness.(M)))]
        push!(results, (n, connectance(N[n]), r, varexpl, :ROCAUC, ROCAUC))
        push!(results, (n, connectance(N[n]), r, varexpl, :PRAUC, AUPRC))
        push!(results, (n, connectance(N[n]), r, varexpl, :INF, informedness(𝐌)))
        push!(results, (n, connectance(N[n]), r, varexpl, :MCC, mcc(𝐌)))
        push!(results, (n, connectance(N[n]), r, varexpl, :Connectance, connectance(X)))
        push!(results, (n, connectance(N[n]), r, varexpl, Symbol("Spectral radius"), ρ(X)))
        push!(results, (n, connectance(N[n]), r, varexpl, :Entropy, entropy(X)))
    end
end

_keepval(f) = f in [:PRAUC, :ROCAUC, :INF, :MCC]
data(@subset(results, _keepval.(:measure))) *
    mapping(:varexpl => "Variance explained", :value => "Value", layout=:measure, color=:connectance => "Connectance", group=:network => nonnumeric) *
    (visual(Lines)) |>
    plt -> draw(plt, facet=(;linkyaxes = :minimal)) |>
    plt -> save(joinpath(@__DIR__, "..", "figures", "svd_perf.png"), plt, px_per_unit = 3)

_keepval(f) = f in [:Connectance, :Entropy, Symbol("Spectral radius")]
data(@subset(results, _keepval.(:measure))) *
    mapping(:varexpl => "Variance explained", :value => "Value", layout=:measure, color=:connectance => "Connectance", group=:network => nonnumeric) *
    (visual(Lines)) |>
    plt -> draw(plt, facet=(;linkyaxes = :none)) |>
    plt -> save(joinpath(@__DIR__, "..", "figures", "svd_ecol.png"), plt, px_per_unit = 3)
