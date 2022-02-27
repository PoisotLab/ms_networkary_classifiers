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

# Drop the models with obviously borked classifiers
results.runid = hash.(results.connectance .* results.breadth .* results.bias)

todrop = unique(vcat([
    @subset(results, :measure .== "ACC", :value .== 0.0).runid,
    @subset(results, :measure .== "TPR", :value .== 0.0).runid,
    @subset(results, :measure .== "TNR", :value .== 0.0).runid,
    @subset(results, :measure .== "PRAUC", :value .<= 0.0).runid,
    @subset(results, :connectance .>= 0.25).runid,
    @subset(results, :connectance .<= 0.05).runid
]...))

tokeep(f) = !(f in todrop)
@subset!(results, tokeep.(:runid))

# Make bins for connectance to make the plotting more efficient
connectance_values = unique(select(results, [:runid, :connectance]))
connectance_values.midpoint = zeros(Float64, size(connectance_values,1))
n_connectance_bins = 5
bins_connectance = LinRange(0.05, 0.25, n_connectance_bins+1)
for i in 1:n_connectance_bins
    _idx = findall(bins_connectance[i] .<= connectance_values.connectance .< bins_connectance[i+1])
    connectance_values.midpoint[_idx] .= round((bins_connectance[i+1] + bins_connectance[i])/2.0; digits=4)
end

# Join the two dataframes
results = leftjoin(results, select(connectance_values, [:runid, :midpoint]), on=:runid)

# Dataviz
_keepval(f) = f in ["MCC", "INF"]
data(@subset(results, _keepval.(:measure))) *
    mapping(:bias => "Training set bias", :value => "Value", row=:midpoint => nonnumeric, col=:measure => "Measure", color=:model => "Model") *
    (smooth() * visual(linewidth=2.0)) |>
    plt -> draw(plt, facet=(;linkyaxes = :minimal)) |>
    plt -> save(joinpath(@__DIR__, "..", "figures", "bias_mcc_inf.png"), plt, px_per_unit = 3)

_keepval(f) = f in ["PRAUC", "ROCAUC"]
data(@subset(results, _keepval.(:measure))) *
    mapping(:bias => "Training set bias", :value => "Value", row=:midpoint => nonnumeric, col=:model, color=:measure => "Measure") *
    (AlgebraOfGraphics.density() * visual(Contour, color=:grey, alpha=0.3) + smooth() * visual(linewidth=2.0)) |>
    plt -> draw(plt, facet=(;linkyaxes = :minimal)) |>
    plt -> save(joinpath(@__DIR__, "..", "figures", "bias_roc_pr.png"), plt, px_per_unit = 3)

# Make bins for connectance to get the optimal bias
connectance_values = unique(select(results, [:runid, :connectance]))
connectance_values.conbin = zeros(Float64, size(connectance_values,1))
n_connectance_bins = 100
bins_connectance = LinRange(0.05, 0.25, n_connectance_bins+1)
for i in 1:n_connectance_bins
    _idx = findall(bins_connectance[i] .<= connectance_values.connectance .< bins_connectance[i+1])
    connectance_values.conbin[_idx] .= (bins_connectance[i+1] + bins_connectance[i])/2.0
end

results = leftjoin(results, select(connectance_values, [:runid, :conbin]), on=:runid)
bmm = groupby(results, [:model, :measure, :conbin])
function optival(v,b)
    idx = sortperm(v)[end-min(50, length(v))+1:end]
    return (bias=mean(b[idx]), value=mean(v[idx]))
end
opt = combine(bmm, [:value, :bias] => ((v,b) -> optival(v,b)) => AsTable)

_keepval(f) = f in ["MCC", "INF", "PRAUC", "ROCAUC"]
data(@subset(opt, _keepval.(:measure))) * 
    mapping(:conbin => "Network connectance", :bias => "Optimal training set bias", col=:model, row=:measure) *
    (AlgebraOfGraphics.density() * visual(Contour, color=:grey, alpha=0.3) + smooth() * visual(linewidth=2.0)) |>
    plt -> draw(plt, facet=(;linkyaxes = :minimal), axis = (xticks = LinearTicks(3),)) |>
    plt -> save(joinpath(@__DIR__, "..", "figures", "optim_bias.png"), plt, px_per_unit = 3)

_keepval(f) = f in ["MCC", "INF", "PRAUC", "ROCAUC"]
data(@subset(opt, _keepval.(:measure))) * 
    mapping(:conbin => "Network connectance", :value => "Validation measure value", col=:model, row=:measure) *
    (AlgebraOfGraphics.density() * visual(Contour, color=:grey, alpha=0.3) + smooth() * visual(linewidth=2.0)) |>
    plt -> draw(plt, facet=(;linkyaxes = :minimal), axis = (xticks = LinearTicks(3),)) |>
    plt -> save(joinpath(@__DIR__, "..", "figures", "optim_perf.png"), plt, px_per_unit = 3)
