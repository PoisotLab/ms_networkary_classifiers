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

