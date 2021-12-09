using Statistics
using StatsPlots
using StatsFuns
using StatsBase
using Random
using Statistics
using MLJ

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

# Simple network-generating function with traits

x = sort(rand(200))
y = sort(rand(200))

# Trait elements

Tree = @load EvoTreeGaussian

breadth = rand(250).*0.15

𝐌 = Vector{ConfusionMatrix}(undef, length(breadth))
ROCAUC = zeros(Float64, length(breadth))
AUPRC = zeros(Float64, length(breadth))

training_size = round(Int64, 0.3*length(𝐳))

for (connectance_index, ρ) in enumerate(breadth)
    
    𝐱 = repeat(x; inner=length(y))
    𝐲 = repeat(y; outer=length(x))
    𝐳 = clamp.(𝐱 .- 0.8.*𝐱 .- ρ, 0, 1) .<= 𝐲 .<= clamp.(𝐱 .- 0.8.*𝐱 .+ ρ, 0, 1)
    𝐗 = hcat(𝐱, 𝐲)
    𝐘 = Float64.(𝐳)

    n_positive = round(Int64, training_size*ρ)
    idx_pos = sample(findall(iszero.(𝐘)), n_positive; replace=true)
    idx_neg = sample(findall(isone.(𝐘)), training_size-n_positive; replace=true)

    Iₚ = shuffle(vcat(idx_neg, idx_pos))
    Iₒ = setdiff(eachindex(𝐘), Iₚ)
    
    for (midx,m) in enumerate(candidate_models)
        this_machine = machine(m, table(𝐗), 𝐘)
        fit!(this_machine, rows=Iₚ) 
        prediction = mean.(MLJ.predict(this_machine, rows=Iₒ))
        thresholds = LinRange(minimum(prediction), maximum(prediction), 500)
        binobs = Bool.(𝐘[Iₒ])
        M = Vector{ConfusionMatrix}(undef, length(thresholds))
        for (i, τ) in enumerate(thresholds)
            binpred = prediction .>= τ
            tp = sum(binobs .& binpred)
            tn = sum(.!binobs .& .!binpred)
            fp = sum(.!binobs .& binpred)
            fn = sum(binobs .& .!binpred)
            M[i] = ConfusionMatrix(tp, tn, fp, fn)
        end
        ROCAUC[midx,prevalence_index] = ∫(fpr.(M), tpr.(M))
        AUPRC[midx,prevalence_index] = ∫(tpr.(M), ppv.(M))
        𝐌[midx,prevalence_index] = M[last(findmax(informedness.(M)))]
    end
end

# Critical Success Index
scatter(target_prevalence, csi.(𝐌)', labels=["Lin. reg." "BRT" "RF"], legend=:outertopright, frame=:box)
vline!([mean(𝐳)], lab="", ls=:dash, c=:black, lw=1.5)
xaxis!("Training set prevalence")
yaxis!("Critical Success Index")

scatter(target_prevalence, balanced.(𝐌)', labels=["Lin. reg." "BRT" "RF"], legend=:outertopright, frame=:box)
vline!([mean(𝐳)], lab="", ls=:dash, c=:black, lw=1.5)
xaxis!("Training set prevalence")
yaxis!("Balanced accurracy")

scatter(target_prevalence, accuracy.(𝐌)', labels=["Lin. reg." "BRT" "RF"], legend=:outertopright, frame=:box)
vline!([mean(𝐳)], lab="", ls=:dash, c=:black, lw=1.5)
xaxis!("Training set prevalence")
yaxis!("Accurracy")

scatter(target_prevalence, informedness.(𝐌)', labels=["Lin. reg." "BRT" "RF"], legend=:outertopright, frame=:box)
vline!([mean(𝐳)], lab="", ls=:dash, c=:black, lw=1.5)
xaxis!("Training set prevalence")
yaxis!("Informedness")

# Prevalence required to see improvements in PPV
scatter(target_prevalence, pt.(𝐌)', labels=["Lin. reg." "BRT" "RF"], legend=:outertopright, frame=:box)
vline!([mean(𝐳)], lab="", ls=:dash, c=:black, lw=1.5)
hline!([mean(𝐳)], lab="", ls=:dash, c=:black, lw=1.5)
xaxis!("Training set prevalence")
yaxis!("Prevalence threshold")

scatter(target_prevalence, fdir.(𝐌)', labels=["Lin. reg." "BRT" "RF"], legend=:outertopright, frame=:box)
vline!([mean(𝐳)], lab="", ls=:dash, c=:black, lw=1.5)
xaxis!("Training set prevalence")
yaxis!("False discovery rate")

scatter(target_prevalence, κ.(𝐌)', labels=["Lin. reg." "BRT" "RF"], legend=:outertopright, frame=:box)
vline!([mean(𝐳)], lab="", ls=:dash, c=:black, lw=1.5)
xaxis!("Training set prevalence")
yaxis!("Cohen's κ")

scatter(target_prevalence, ROCAUC', labels=["Lin. reg." "BRT" "RF"], legend=:outertopright, frame=:box)
vline!([mean(𝐳)], lab="", ls=:dash, c=:black, lw=1.5)
xaxis!("Training data prevalence", (0,1))
yaxis!("ROC-AUC")

scatter(target_prevalence, AUPRC', labels=["Lin. reg." "BRT" "RF"], legend=:outertopright, frame=:box)
vline!([mean(𝐳)], lab="", ls=:dash, c=:black, lw=1.5)
xaxis!("Training data prevalence", (0,1))
yaxis!("PR-AUC", (0,1))