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
_suffix = get(ENV, "SLURM_ARRAY_TASK_ID", "global")

# AUC
function ∫(x::Array{T}, y::Array{T}) where {T<:Number}
    S = zero(Float64)
    for i in 2:length(x)
        S += (x[i] - x[i - 1]) * (y[i] + y[i - 1]) * 0.5
    end
    return .-S
end

# Confusion matrix utilities
include(joinpath(@__DIR__, "confusionmatrix.jl"))

# Network generation function
L(x::T, y::T; r::T=0.1) where {T<:Number} = (x-r/2.0) ≤ y ≤ (x+r/2.0)  ? one(T) : zero(T)
function network(S, ξ)
    infectivity = Beta(6.0, 8.0)
    resistance = Beta(2.0, 8.0)
    𝐱ᵥ = sort(rand(infectivity, S))
    𝐱ₕ = sort(rand(resistance, S))
    𝐱₁ = repeat(𝐱ᵥ; outer=length(𝐱ₕ))
    𝐱₂ = repeat(𝐱ₕ; inner=length(𝐱ᵥ))
    𝐱₃ = abs.(𝐱₁ .- 𝐱₂)
    𝐲 = [L(𝐱₁[i], 𝐱₂[i]; r=ξ) for i in 1:(S*S)]
    #𝐱 = table(hcat(𝐱₁, 𝐱₂, 𝐱₃))
    𝐱 = table(hcat(𝐱₁, 𝐱₂))
    return (𝐱, 𝐲)
end

# Prepare the results
results = [DataFrame(;
    breadth=Float64[],
    bias=Float64[],
    connectance=Float64[],
    model=Symbol[],
    measure=Symbol[],
    value=Float64[],
) for _thr in 1:Threads.nthreads()]

# these regression machines go brrr as f u c k
DecisionTree = @load DecisionTreeRegressor pkg = DecisionTree verbosity=0
RandomForest = @load RandomForestRegressor pkg = DecisionTree verbosity=0
BoostedRegressor = @load EvoTreeRegressor pkg = EvoTrees verbosity=0
KNNRegressor = @load KNNRegressor pkg = NearestNeighborModels verbosity=0

candidate_models = [
    Symbol("Decision tree") => DecisionTree(),
    :BRT => BoostedRegressor(),
    Symbol("Random Forest") => RandomForest(),
    :kNN => KNNRegressor(),
]

S = 100
_n_sims = 600
conditions_breadth = rand(_n_sims) .* 0.4 .+ 0.05
conditions_bias = rand(_n_sims) .* 0.98 .+ 0.01
conditions = hcat(conditions_breadth, conditions_bias)

Threads.@threads for i in 1:size(conditions, 1)
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
