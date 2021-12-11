using Statistics
using AlgebraOfGraphics, CairoMakie
using DataFrames
using DataFramesMeta
using CSV: CSV
using StatsFuns

# Confusion matrix utilities
include(joinpath(@__DIR__, "code", "confusionmatrix.jl"))

function ConfusionMatrix(; s=0.0, b=0.5, ρ=0.05)
    𝐂 = [ρ^2 (1 - ρ)*ρ; (1 - ρ)*ρ (1 - ρ)^2]
    𝐒 = [s 1-s; 1-s s]
    𝐁 = [b b; 1-b 1-b]
    return ConfusionMatrix(𝐂 .* 𝐒 .* 𝐁)
end

# Calculations
results = DataFrame(ρ = Float64[], s = Float64[], b = Float64[], measure = Symbol[], value = Float64[])
for ρ in LinRange(0.0, 0.5, 251)
    if ρ > 0.0
        for ls in LinRange(-10, 10, 9)
            for lb in LinRange(-10, 10, 151)
                𝐌 = ConfusionMatrix(ρ=ρ, s=logistic(ls), b=logistic(lb))
                #push!(results, (ρ, logistic(ls), logistic(lb), :Accuracy, accuracy(𝐌)))
                push!(results, (ρ, logistic(ls), logistic(lb), :F1, csi(𝐌)))
                #push!(results, (ρ, logistic(ls), logistic(lb), Symbol("Positive Predictive Value"), ppv(𝐌)))
                push!(results, (ρ, logistic(ls), logistic(lb), :MCC, mcc(𝐌)))
                push!(results, (ρ, logistic(ls), logistic(lb), Symbol("κ"), κ(𝐌)))
                push!(results, (ρ, logistic(ls), logistic(lb), :Informedness, informedness(𝐌)))
            end
        end
    end
end

_co = unique(results.ρ)[last(findmin(abs.(unique(results.ρ) .- 0.1)))]

data(@subset(results, :ρ .== _co)) *
    mapping(:b => logit => "logit(bias)", :value => "Measure value", layout=:measure => nonnumeric, color=:s => logit => "logit(skill)", group=:s => nonnumeric) *
    (visual(Lines, colormap=:tofino)) |> 
    plt -> draw(plt, facet=(;linkyaxes = :none)) |>
    plt -> save(joinpath(@__DIR__, "..", "figures", "changing-bias.png"), plt, px_per_unit = 3)

data(@subset(results, :b .== 0.5)) *
    mapping(:ρ => "Connectance", :value => "Measure value", layout=:measure => nonnumeric, color=:s => logit => "logit(skill)", group=:s => nonnumeric) *
    (visual(Lines, colormap=:tofino)) |> 
    plt -> draw(plt, facet=(;linkyaxes = :none)) |>
    plt -> save(joinpath(@__DIR__, "..", "figures", "changing-connectance.png"), plt, px_per_unit = 3)
