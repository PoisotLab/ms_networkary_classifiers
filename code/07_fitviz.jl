using AlgebraOfGraphics, CairoMakie
using DataFrames
using CSV: CSV
using DataFramesMeta
using StatsBase
using Statistics
using StatsFuns

results = DataFrame(CSV.File(joinpath(@__DIR__, "overfit.csv")))
allowmissing!(results, :value)
replace!(results.value, NaN => missing)
dropmissing!(results)

bmm = groupby(results, [:model, :measure, :connectance, :set])
raw = combine(bmm, :value => mean => :value)

# Show the overfit
_keepval(f) = f in ["acc"]
dt = data(@subset(raw, _keepval.(:measure)))
mp = mapping(
    :connectance => "Connectance",
    :value => "Value";
    color = :set => nonnumeric => "Dataset",
    layout = :model => sorter("Decision tree", "kNN", "Random Forest", "BRT", "Ensemble") => "Model"
)
ly = visual(Lines)
dt * mp * ly |>
    plt -> draw(plt, facet=(;linkyaxes = :all)) |>
    plt -> save(joinpath(@__DIR__, "..", "figures", "overfit.png"), plt, px_per_unit = 3)
