L(x::T, y::T; r::T=0.1) where {T<:Number} = (x-r/2.0) β€ y β€ (x+r/2.0)  ? one(T) : zero(T)

function network(S, ΞΎ)
    infectivity = Beta(6.0, 8.0)
    resistance = Beta(2.0, 8.0)
    π±α΅₯ = sort(rand(infectivity, S[1]))
    π±β = sort(rand(resistance, S[2]))
    π±β = repeat(π±α΅₯; outer=length(π±β))
    π±β = repeat(π±β; inner=length(π±α΅₯))
    π² = [L(π±β[i], π±β[i]; r=ΞΎ) for i in 1:prod(S)]
    π± = table(hcat(π±β, π±β))
    return (π±, π²)
end

