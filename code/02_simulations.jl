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

# Prepare the results
results = [DataFrame(;
    breadth=Float64[],
    bias=Float64[],
    connectance=Float64[],
    model=Symbol[],
    measure=Symbol[],
    value=Float64[],
) for _thr in 1:Threads.nthreads()]

# Block for the gridded simulations
S = (100, 100)

grid_size = 80
links = LinRange(minimum(S)+10, round(Int64, 0.5*prod(S)), grid_size)
biases = LinRange(0.02, 0.98, grid_size)

conditions = hcat(conditions_breadth, conditions_bias)

Threads.@threads for connectance in connectances
    # Get the network for this connectance run
    for bias in biases
    end
end
    breadth, bias = conditions[i, :]
    @info i, Threads.threadid(), breadth, bias

    𝐗, 𝐲 = network(S, breadth)
    _real_co = mean(𝐲)

    training_size = round(Int64, 0.5 * length(𝐲))
    n_positive = round(Int64, training_size * bias)
    idx_pos = sample(findall(iszero.(𝐲)), n_positive; replace=true)
    idx_neg = sample(findall(isone.(𝐲)), training_size - n_positive; replace=true)
    Iₚ = shuffle(vcat(idx_neg, idx_pos))
    Iₒ = setdiff(eachindex(𝐲), Iₚ)

    # Tweak the testing set to have the correct connectance - this results in a SMALLER testing set
    _test_pos = sum(𝐲[Iₒ])
    _expected_neg = round(Int64, _test_pos/_real_co - _test_pos)
    _observed_neg = round(Int64, length(Iₒ)-sum(𝐲[Iₒ]))
    tst_neg = sample(findall(iszero.(𝐲[Iₒ])), max(_observed_neg - _expected_neg, 1); replace=true)
    deleteat!(Iₒ, sort(unique(tst_neg)))
    #

    m = []
    for candidate_model in candidate_models
        this_machine = machine(candidate_model.second, 𝐗, 𝐲)
        fit!(this_machine; rows=Iₚ)
        prediction = mean.(MLJ.predict(this_machine; rows=Iₒ))
        pr = prediction .- minimum(prediction)
        pr = pr ./ maximum(pr)
        push!(m, pr)

        # The prediction isn't clamped because we threshold it so who gives a shit
        thresholds = LinRange(minimum(prediction), maximum(prediction), 500)

        # Confusion matrix
        binobs = Bool.(𝐲[Iₒ])
        M = Vector{ConfusionMatrix}(undef, length(thresholds))
        for (i, τ) in enumerate(thresholds)
            binpred = prediction .>= τ
            tp = sum(binobs .& binpred)
            tn = sum(.!binobs .& .!binpred)
            fp = sum(.!binobs .& binpred)
            fn = sum(binobs .& .!binpred)
            M[i] = ConfusionMatrix(tp, tn, fp, fn)
        end
        ROCAUC = ∫(fpr.(M), tpr.(M))
        AUPRC = ∫(tpr.(M), ppv.(M))
        𝐌 = M[last(findmax(informedness.(M)))]
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), candidate_model.first, :ROCAUC, ROCAUC))
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), candidate_model.first, :PRAUC, AUPRC))
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), candidate_model.first, :CSI, csi(𝐌)))
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), candidate_model.first, :BA, balanced(𝐌)))
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), candidate_model.first, :ACC, accuracy(𝐌)))
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), candidate_model.first, :INF, informedness(𝐌)))
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), candidate_model.first, :PT, pt(𝐌)))
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), candidate_model.first, :FDR, fdir(𝐌)))
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), candidate_model.first, :FOR, fomr(𝐌)))
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), candidate_model.first, :KAPPA, κ(𝐌)))
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), candidate_model.first, :TPR, tpr(𝐌)))
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), candidate_model.first, :TNR, tnr(𝐌)))
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), candidate_model.first, :FPR, fpr(𝐌)))
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), candidate_model.first, :FNR, fnr(𝐌)))
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), candidate_model.first, :PPV, ppv(𝐌)))
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), candidate_model.first, :NPV, npv(𝐌)))
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), candidate_model.first, :MKD, markedness(𝐌)))
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), candidate_model.first, :F1, f1(𝐌)))
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), candidate_model.first, :MCC, mcc(𝐌)))
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), candidate_model.first, :postbias, (𝐌.tp+𝐌.fp)/(𝐌.tp+𝐌.fn)))
    end

    # Ensemble model
    begin
        prediction = mean(hcat(m...); dims=2)
        thresholds = LinRange(minimum(prediction), maximum(prediction), 500)


        # Confusion matrix
        binobs = Bool.(𝐲[Iₒ])
        M = Vector{ConfusionMatrix}(undef, length(thresholds))
        for (i, τ) in enumerate(thresholds)
            binpred = prediction .>= τ
            tp = sum(binobs .& binpred)
            tn = sum(.!binobs .& .!binpred)
            fp = sum(.!binobs .& binpred)
            fn = sum(binobs .& .!binpred)
            M[i] = ConfusionMatrix(tp, tn, fp, fn)
        end
        ROCAUC = ∫(fpr.(M), tpr.(M))
        AUPRC = ∫(tpr.(M), ppv.(M))
        𝐌 = M[last(findmax(informedness.(M)))]
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), :Ensemble, :ROCAUC, ROCAUC))
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), :Ensemble, :PRAUC, AUPRC))
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), :Ensemble, :CSI, csi(𝐌)))
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), :Ensemble, :BA, balanced(𝐌)))
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), :Ensemble, :ACC, accuracy(𝐌)))
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), :Ensemble, :INF, informedness(𝐌)))
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), :Ensemble, :PT, pt(𝐌)))
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), :Ensemble, :FDR, fdir(𝐌)))
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), :Ensemble, :FOR, fomr(𝐌)))
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), :Ensemble, :KAPPA, κ(𝐌)))
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), :Ensemble, :TPR, tpr(𝐌)))
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), :Ensemble, :TNR, tnr(𝐌)))
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), :Ensemble, :FPR, fpr(𝐌)))
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), :Ensemble, :FNR, fnr(𝐌)))
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), :Ensemble, :PPV, ppv(𝐌)))
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), :Ensemble, :NPV, npv(𝐌)))
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), :Ensemble, :MKD, markedness(𝐌)))
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), :Ensemble, :F1, f1(𝐌)))
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), :Ensemble, :MCC, mcc(𝐌)))
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), :Ensemble, :postbias, (𝐌.tp+𝐌.fp)/(𝐌.tp+𝐌.fn)))
    end
end

CSV.write(joinpath(@__DIR__, "output_$(_suffix).csv"), vcat(results...))
