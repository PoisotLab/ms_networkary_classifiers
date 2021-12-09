using Statistics
using StatsFuns
using StatsBase
using DataFramesMeta
using Random
using Statistics
using MLJ
using DataFrames
using CSV: CSV

# AUC
function ∫(x::Array{T}, y::Array{T}) where {T<:Number}
    S = zero(Float64)
    for i in 2:length(x)
        S += (x[i] - x[i - 1]) * (y[i] + y[i - 1]) * 0.5
    end
    return .-S
end

# Confusion matrix utilities
include("confusionmatrix.jl")

# Network generation function
function network(S, breadth)
    # Get the network
    x = sort(rand(S))
    y = sort(rand(S))
    𝐱 = repeat(x; inner=length(y))
    𝐲 = repeat(y; outer=length(x))
    𝐳 =
        clamp.(𝐱 .- 0.8 .* 𝐱 .- breadth, 0, 1) .<=
        𝐲 .<=
        clamp.(𝐱 .- 0.8 .* 𝐱 .+ breadth, 0, 1)

    # Features / labels matrix
    return (table(hcat(𝐱, 𝐲)), Float64.(𝐳))
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

# Pick possible models based on a network
_mock = network(10, 0.2)
_mods = models() do model
    matching(model, _mock...) &&
        model.prediction_type == :deterministic &&
        model.is_supervised &&
        model.is_pure_julia
end

# these regression machines go brrr as f u c k
DecisionTree = @load DecisionTreeRegressor pkg = DecisionTree
RandomForest = @load RandomForestRegressor pkg = DecisionTree
BoostedRegressor = @load EvoTreeRegressor pkg = EvoTrees
RidgeRegressor = @load RidgeRegressor pkg = MLJLinearModels

candidate_models = [
    :DecTree => DecisionTree(),
    :BRT => BoostedRegressor(),
    :RF => RandomForest(),
    :RR => RidgeRegressor()
]

S = 200

_n_sims = 20000
conditions_breadth = rand(_n_sims) .* 0.1 .+ 0.005
conditions_bias = rand(_n_sims) .* 0.98 .+ 0.01
conditions = hcat(conditions_breadth, conditions_bias)

Threads.@threads for i in 1:size(conditions, 1)
    breadth, bias = conditions[i, :]
    @info i, Threads.threadid(), breadth, bias

    𝐗, 𝐲 = network(S, breadth)

    # Training and testing sets
    training_size = round(Int64, 0.3 * length(𝐲))
    n_positive = round(Int64, training_size * bias)
    idx_pos = sample(findall(iszero.(𝐲)), n_positive; replace=true)
    idx_neg = sample(findall(isone.(𝐲)), training_size - n_positive; replace=true)
    Iₚ = shuffle(vcat(idx_neg, idx_pos))
    Iₒ = setdiff(eachindex(𝐲), Iₚ)
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
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), :ensemble, :ROCAUC, ROCAUC))
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), :ensemble, :PRAUC, AUPRC))
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), :ensemble, :CSI, csi(𝐌)))
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), :ensemble, :BA, balanced(𝐌)))
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), :ensemble, :ACC, accuracy(𝐌)))
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), :ensemble, :INF, informedness(𝐌)))
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), :ensemble, :PT, pt(𝐌)))
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), :ensemble, :FDR, fdir(𝐌)))
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), :ensemble, :FOR, fomr(𝐌)))
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), :ensemble, :KAPPA, κ(𝐌)))
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), :ensemble, :TPR, tpr(𝐌)))
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), :ensemble, :TNR, tnr(𝐌)))
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), :ensemble, :FPR, fpr(𝐌)))
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), :ensemble, :FNR, fnr(𝐌)))
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), :ensemble, :PPV, ppv(𝐌)))
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), :ensemble, :NPV, npv(𝐌)))
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), :ensemble, :MKD, markedness(𝐌)))
        push!(results[Threads.threadid()], (breadth, bias, mean(𝐲), :ensemble, :F1, f1(𝐌)))
    end
end

CSV.write("output.csv", vcat(results...))
