using AlgebraOfGraphics, CairoMakie
using DataFrames
using CSV: CSV
using DataFramesMeta
using StatsBase
using Statistics

results = DataFrame(CSV.File("output.csv"))
allowmissing!(results, :value)
replace!(results.value, NaN => missing)
dropmissing!(results)

# Drop the models with obviously borked classifiers
results.runid = hash.(results.connectance .* results.breadth .* results.bias)

todrop = unique(vcat([
    @subset(results, :measure .== "ACC", :value .== 0.0).runid,
    @subset(results, :measure .== "TPR", :value .== 0.0).runid,
    @subset(results, :measure .== "TNR", :value .== 0.0).runid,
    @subset(results, :measure .== "FPR", :value .== 1.0).runid,
    @subset(results, :measure .== "FNR", :value .== 1.0).runid,
    @subset(results, :connectance .>= 0.2).runid
]...))

tokeep(f) = !(f in todrop)
@subset!(results, tokeep.(:runid))

# Make bins for connectance to make the plotting more efficient
connectance_values = unique(select(results, [:runid, :connectance]))
connectance_values.midpoint = zeros(Float64, size(connectance_values,1))
n_connectance_bins = 4
bins_connectance = LinRange(0.0, 0.2, n_connectance_bins+1)
for i in 1:n_connectance_bins
    _idx = findall(bins_connectance[i] .<= connectance_values.connectance .< bins_connectance[i+1])
    connectance_values.midpoint[_idx] .= (bins_connectance[i+1] + bins_connectance[i])/2.0
end

# Join the two dataframes
results = leftjoin(results, select(connectance_values, [:runid, :midpoint]), on=:runid)

# Dataviz
data(@subset(results, :measure .== "F1")) *
    mapping(:bias, :value, row=:midpoint => nonnumeric, col=:model) *
    (AlgebraOfGraphics.density() * visual(Contour, color=:grey, alpha=0.3) + smooth() * visual(linewidth=2.0)) |>
    draw

# Make bins for connectance to get the optimal bias
connectance_values = unique(select(results, [:runid, :connectance]))
connectance_values.conbin = zeros(Float64, size(connectance_values,1))
n_connectance_bins = 100
bins_connectance = LinRange(0.0, 0.2, n_connectance_bins+1)
for i in 1:n_connectance_bins
    _idx = findall(bins_connectance[i] .<= connectance_values.connectance .< bins_connectance[i+1])
    connectance_values.conbin[_idx] .= (bins_connectance[i+1] + bins_connectance[i])/2.0
end

results = leftjoin(results, select(connectance_values, [:runid, :conbin]), on=:runid)
bmm = groupby(results, [:model, :measure, :conbin])
opt = combine(bmm, [:value, :bias] => ((v,b) -> median(b[sortperm(v)[end-min(20, length(v))+1:end]])) => :optimalbias)

_keepval(f) = f in ["PRAUC", "F1", "INF"]
@subset!(opt, _keepval.(:measure))

data(opt) * 
    mapping(:conbin, :optimalbias, col=:model, row=:measure) *
    (AlgebraOfGraphics.density() * visual(Contour, color=:grey, alpha=0.3) + smooth() * visual(linewidth=2.0)) |>
    draw