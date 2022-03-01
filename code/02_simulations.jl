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

# Simulation suffix
_jobid = get(ENV, "SLURM_ARRAY_TASK_ID", 1)
_jobcount = get(ENV, "SLURM_ARRAY_TASK_COUNT", 1)

# Confusion matrix utilities
include(joinpath(@__DIR__, "confusionmatrix.jl"))

# Network simulation utilities
include(joinpath(@__DIR__, "networksimulation.jl"))

# Choice of models
include(joinpath(@__DIR__, "modelchoice.jl"))

# Function to split the sets
include(joinpath(@__DIR__, "setsplitter.jl"))

# Prepare the results
results = [
    DataFrame(;
        links=Int64[], bias=Float64[], model=Symbol[], measure=Symbol[], value=Float64[]
    ) for _thr in 1:Threads.nthreads()
]

# Network size
S = (100, 100)

# Number of simulation blocks
grid_size = 35

# List of conditions
conditions = [(i, j) for i in 1:grid_size for j in 1:grid_size]

links = round.(Int64, LinRange(minimum(S) + 10, round(Int64, 0.5 * prod(S)), grid_size))
biases = LinRange(0.02, 0.98, grid_size)

# Prepare networks for the gridded simulations
nets = []
for link in links
    approx_conn = link / prod(S)
    candidates = [network(S, approx_conn) for i in 1:10_000]
    idx = last(findmin(n -> abs(approx_conn - mean(last(n))), candidates))
    push!(nets, candidates[idx])
end

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

# Simulations
Threads.@threads for i in 1:length(conditions)
    link = links[conditions[i][1]]
    bias = biases[conditions[i][2]]

    # Report
    @info "L: $(link)\tB: $(bias)\tThread:$(Threads.threadid())"

    # Get the network for this number of links
    𝐗, 𝐲 = nets[conditions[i][1]]

    # Indices to split the dataset
    Iₚ, Iₒ = split_indices(𝐲, bias)

    # Vector to store the predictions
    predictions = Dict()

    # Train the machines
    for model in candidate_models
        this_machine = machine(model.second, 𝐗, 𝐲)
        fit!(this_machine; rows=Iₚ)

        # Predict on the validation set
        prediction = R(MLJ.predict(this_machine; rows=Iₒ))

        # Thresholding analysis
        𝐌, ROC, PR, τ = threshold(𝐲[Iₒ] .> 0.0, prediction)

        # Write the outputs
        if !isnan(ROC)
            predictions[model.first] = R(prediction)
            push!(results[Threads.threadid()], (link, bias, model.first, :ROC, ROC))
            push!(results[Threads.threadid()], (link, bias, model.first, :PR, PR))
            push!(results[Threads.threadid()], (link, bias, model.first, :threshold, τ))
            for (mname, mfunc) in measures
                push!(
                    results[Threads.threadid()], (link, bias, model.first, mname, mfunc(𝐌))
                )
            end
        end
    end

    # Ensemble model
    if !isempty(predictions)
        predictions[:Ensemble] = R(mean(hcat(collect(values(predictions))...); dims=2))
        𝐌, ROC, PR, τ = threshold(𝐲[Iₒ] .> 0.0, predictions[:Ensemble])
        push!(results[Threads.threadid()], (link, bias, :Ensemble, :ROC, ROC))
        push!(results[Threads.threadid()], (link, bias, :Ensemble, :PR, PR))
        push!(results[Threads.threadid()], (link, bias, :Ensemble, :threshold, τ))
        for (mname, mfunc) in measures
            push!(results[Threads.threadid()], (link, bias, :Ensemble, mname, mfunc(𝐌)))
        end
    end
end

CSV.write(joinpath(@__DIR__, "output_$(_jobid).csv"), vcat(results...))
