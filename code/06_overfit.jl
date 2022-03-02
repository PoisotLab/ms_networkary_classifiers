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
using UUIDs
using ProgressMeter

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
        id=UUID[],
        connectance=Float64[],
        model=Symbol[],
        set=Symbol[],
        measure=Symbol[],
        value=Float64[],
    ) for _thr in 1:Threads.nthreads()
]

# Network size
S = (40, 50)

# List of conditions
links = sort(floor.(Int, repeat(LinRange(45, 0.5*(40*50), 10), 60)))

# Prepare networks for the gridded simulations
nets = []
@showprogress for i in 1:length(links)
    link = links[i]
    approx_conn = link / prod(S)
    candidates = [network(S, approx_conn) for i in 1:1_000]
    idx = last(findmin(n -> abs(approx_conn - mean(last(n))), candidates))
    push!(nets, candidates[idx])
end

# Function to range the predictions
R = (v) -> (v .- minimum(v)) ./ (maximum(v) - minimum(v))

# Dictionary of measures
measures = Dict(:acc => accuracy, :bac => balanced, :mcc => mcc, :Y => informedness)

# Simulations
Threads.@threads for i in 1:length(links)
    bias = 0.5

    runid = uuid4()

    𝐗, 𝐲 = nets[i]

    # Indices to split the dataset
    Iₚ, Iₒ = split_indices(𝐲, bias)

    # Vector to store the predictions

    for current_set in [(:training, Iₚ), (:testing, Iₒ), (:full, 1:prod(S))]
        setname, setrow = current_set
        predictions = Dict()

        # Train the machines
        for model in candidate_models
            this_machine = machine(model.second, 𝐗, 𝐲)
            fit!(this_machine; rows=Iₚ)

            # Predict on the validation set
            prediction = R(MLJ.predict(this_machine; rows=setrow))
            𝐌, ROC, PR, τ = threshold(𝐲[setrow] .> 0.0, prediction)

            # Write the outputs
            if !isnan(ROC)
                predictions[model.first] = R(prediction)
                push!(
                    results[Threads.threadid()],
                    (runid, links[i]/prod(S), model.first, setname, :ROC, ROC),
                )
                push!(
                    results[Threads.threadid()],
                    (runid, links[i]/prod(S), model.first, setname, :PR, PR),
                )
                push!(
                    results[Threads.threadid()],
                    (runid, links[i]/prod(S), model.first, setname, :threshold, τ),
                )
                for (mname, mfunc) in measures
                    push!(
                        results[Threads.threadid()],
                        (runid, links[i]/prod(S), model.first, setname, mname, mfunc(𝐌)),
                    )
                end
            end

            # Ensemble model
            if !isempty(predictions)
                predictions[:Ensemble] = R(
                    mean(hcat(collect(values(predictions))...); dims=2)
                )
                𝐌, ROC, PR, τ = threshold(𝐲[setrow] .> 0.0, predictions[:Ensemble])
                push!(
                    results[Threads.threadid()],
                    (runid, links[i]/prod(S), :Ensemble, setname, :ROC, ROC),
                )
                push!(
                    results[Threads.threadid()], (runid, links[i]/prod(S), :Ensemble, setname, :PR, PR)
                )
                push!(
                    results[Threads.threadid()],
                    (runid, links[i]/prod(S), :Ensemble, setname, :threshold, τ),
                )
                for (mname, mfunc) in measures
                    push!(
                        results[Threads.threadid()],
                        (runid, links[i]/prod(S), :Ensemble, setname, mname, mfunc(𝐌)),
                    )
                end
            end
        end
    end
end

CSV.write(joinpath(@__DIR__, "overfit.csv"), vcat(results...))
