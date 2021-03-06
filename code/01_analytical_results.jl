using Statistics
using AlgebraOfGraphics, CairoMakie
using DataFrames
using DataFramesMeta
using CSV: CSV
using StatsFuns

# Confusion matrix utilities
include(joinpath(@__DIR__, "code", "confusionmatrix.jl"))

function ConfusionMatrix(; s=0.0, b=0.5, Ï=0.05)
    đ = [Ï^2 (1 - Ï)*Ï; (1 - Ï)*Ï (1 - Ï)^2]
    đ = [s 1-s; 1-s s]
    đ = [b b; 1-b 1-b]
    return ConfusionMatrix(đ .* đ .* đ)
end

# Calculations
results = DataFrame(Ï = Float64[], s = Float64[], b = Float64[], measure = Symbol[], value = Float64[])
for Ï in LinRange(0.0, 0.5, 251)
    if Ï > 0.0
        for ls in LinRange(-10, 10, 9)
            for lb in LinRange(-10, 10, 151)
                đ = ConfusionMatrix(Ï=Ï, s=logistic(ls), b=logistic(lb))
                #push!(results, (Ï, logistic(ls), logistic(lb), :Accuracy, accuracy(đ)))
                push!(results, (Ï, logistic(ls), logistic(lb), :F1, csi(đ)))
                #push!(results, (Ï, logistic(ls), logistic(lb), Symbol("Positive Predictive Value"), ppv(đ)))
                push!(results, (Ï, logistic(ls), logistic(lb), :MCC, mcc(đ)))
                push!(results, (Ï, logistic(ls), logistic(lb), Symbol("Îș"), Îș(đ)))
                push!(results, (Ï, logistic(ls), logistic(lb), :Informedness, informedness(đ)))
            end
        end
    end
end

_co = unique(results.Ï)[last(findmin(abs.(unique(results.Ï) .- 0.1)))]

data(@subset(results, :Ï .== _co)) *
    mapping(:b => logit => "logit(bias)", :value => "Measure value", layout=:measure => nonnumeric, color=:s => logit => "logit(skill)", group=:s => nonnumeric) *
    (visual(Lines, colormap=:tofino)) |> 
    plt -> draw(plt, facet=(;linkyaxes = :none)) |>
    plt -> save(joinpath(@__DIR__, "figures", "changing-bias.png"), plt, px_per_unit = 3)

data(@subset(results, :b .== 0.5)) *
    mapping(:Ï => "Connectance", :value => "Measure value", layout=:measure => nonnumeric, color=:s => logit => "logit(skill)", group=:s => nonnumeric) *
    (visual(Lines, colormap=:tofino)) |> 
    plt -> draw(plt, facet=(;linkyaxes = :none)) |>
    plt -> save(joinpath(@__DIR__, figures", "changing-connectance.png"), plt, px_per_unit = 3)
