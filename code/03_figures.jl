using AlgebraOfGraphics, CairoMakie
using DataFrames
using CSV: CSV
using DataFramesMeta
using StatsBase
using Statistics
using StatsFuns

results = DataFrame(CSV.File(joinpath(@__DIR__, "output.csv")))
allowmissing!(results, :value)
replace!(results.value, NaN => missing)
dropmissing!(results)

bmm = groupby(results, [:model, :measure, :links, :bias])
raw = combine(bmm, :value => mean => :value)

# Derived measure of connectance
raw.connectance = raw.links ./ (100*100)

# Show the core measures by connectance
_keepval(f) = f in ["ROC", "Y", "PR", "mcc"]
dt = data(@subset(raw, _keepval.(:measure)))
mp = mapping(
    :bias => "Training balance",
    :value => "Value";
    color = :connectance => "Network connectance",
    row = :measure => "Measure",
    col = :model => sorter("Decision tree", "kNN", "Random Forest", "BRT", "Ensemble") => "Model"
)
ly = visual(Scatter, colormap = :bamako, markersize = 4)
dt * mp * ly |>
    plt -> draw(plt, facet=(;linkyaxes = :minimal)) |>
    plt -> save(joinpath(@__DIR__, "..", "figures", "bias_by_connectance.png"), plt, px_per_unit = 3)

# Get the best bias for a given connectance
bmm = groupby(raw, [:model, :measure, :connectance])
function optival(v,b)
    idx = argmax(v)
    return (bias=b[idx], value=v[idx])
end
opt = combine(bmm, [:value, :bias] => ((v,b) -> optival(v,b)) => AsTable)

_keepval(f) = f in ["ROC", "Y", "PR", "mcc"]

dt = data(@subset(opt, _keepval.(:measure)))
mp = mapping(
    :connectance => "Connectance",
    :bias => "Optimal training balance";
    layout = :measure => "Measure",
    color = :model => sorter("Decision tree", "kNN", "Random Forest", "BRT", "Ensemble") => "Model"
)
ly = visual(ScatterLines, colormap = :deep, markersize = 4)
dt * mp * ly |>
    plt -> draw(plt, facet=(;linkyaxes = :minimal)) |>
    plt -> save(joinpath(@__DIR__, "..", "figures", "optimal_bias.png"), plt, px_per_unit = 3)

dt = data(@subset(opt, _keepval.(:measure)))
mp = mapping(
    :connectance => "Connectance",
    :value => "Value at optimal training balance";
    layout = :measure => "Measure",
    color = :model => sorter("Decision tree", "kNN", "Random Forest", "BRT", "Ensemble") => "Model"
)
ly = visual(ScatterLines, colormap = :deep, markersize = 4)
dt * mp * ly |>
    plt -> draw(plt, facet=(;linkyaxes = :minimal)) |>
    plt -> save(joinpath(@__DIR__, "..", "figures", "optimal_value.png"), plt, px_per_unit = 3)
