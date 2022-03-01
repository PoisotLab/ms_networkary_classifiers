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

# Confusion matrix utilities
include(joinpath(@__DIR__, "confusionmatrix.jl"))

# Network simulation utilities
include(joinpath(@__DIR__, "networksimulation.jl"))

# Choice of models
include(joinpath(@__DIR__, "modelchoice.jl"))

# Function to split the sets
include(joinpath(@__DIR__, "setsplitter.jl"))

# Generate a network for the test
S = (30,70)
_co = 0.18
candidates = [network(S, _co) for i in 1:10_000]
idx = last(findmin(n -> abs(_co - mean(last(n))), candidates))
𝐗, 𝐲 = candidates[idx]
training_balance = 0.5

# Function to range the predictions
R = (v) -> (v .- minimum(v)) ./ (maximum(v) - minimum(v))

# Dictionary of measures
measures = Dict(
    :tpr => tpr,
    :tnr => tnr,
    :ppv => ppv,
    :npv => npv,
    :fnr => fnr,
    :fpr => fpr,
    :acc => accuracy,
    :bac => balanced,
    :f1 => f1,
    :mcc => mcc,
    :fm => fm,
    :Y => informedness,
    :mkd => markedness,
    :κ => κ,
    :mcc => mcc,
)

# Indices to split the dataset
Iₚ, Iₒ = split_indices(𝐲, training_balance)

# Vector to store the predictions
machines = Dict()

# Train the machines
for model in candidate_models
    this_machine = machine(model.second, 𝐗, 𝐲)
    fit!(this_machine; rows=Iₚ)

    # Predict on the entire set
    prediction = MLJ.predict(this_machine; rows=Iₒ)

    # Thresholding analysis
    𝐌, ROC, PR, τ = threshold(𝐲[Iₒ] .> 0.0, R(prediction))

    # Write the outputs
    machines[model.first] = (this_machine, τ)
end

# Ensemble model
predictions = [R(MLJ.predict(first(machines[k]))) for k in keys(machines)]
ensemble_predictions = vec(R(mean(hcat(predictions...); dims=2)))
𝐌, ROC, PR, τ = threshold(𝐲[Iₒ] .> 0.0, ensemble_predictions[Iₒ])

results = DataFrame(;
    infectivity=Float64[],
    resistance=Float64[],
    model=Symbol[],
    prediction=Float64[],
    guess=Float64[],
    truth = Float64[]
)
for k in keys(machines)
    mc, th = machines[k]
    for (i,p) in enumerate(MLJ.predict(mc))
        push!(results, (𝐗.x1[i], 𝐗.x2[i], k, p, p>=th, 𝐲[i]))
    end
end

for (i,p) in enumerate(ensemble_predictions)
    push!(results, (𝐗.x1[i], 𝐗.x2[i], :Ensemble, p, p>=τ, 𝐲[i]))
end

for (i,p) in enumerate(𝐲)
    push!(results, (𝐗.x1[i], 𝐗.x2[i], :Dataset, p, p, p))
end

dt = data(results)
dt = data(results)
mp = mapping(
    :infectivity => "Infectivity trait",
    :resistance => "Resistance trait",
    :prediction => "Prediction score";
    layout=:model => sorter(
        Symbol("Decision tree"), :kNN, Symbol("Random Forest"), :BRT, :Ensemble, :Dataset
    )
)
ly = visual(Heatmap; colormap=Reverse(:deep))
dt * mp * ly |>
    plt -> draw(plt, facet=(;linkyaxes = :minimal), axis = (xticks = LinearTicks(3),)) |>
    plt -> save(joinpath(@__DIR__, "..", "figures", "valid_ensemble.png"), plt, px_per_unit = 3)
