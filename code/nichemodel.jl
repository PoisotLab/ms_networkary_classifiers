using Distributions

function nichemodel(; C=0.2, S=100)
    # Beta distribution parameter
    β = 1.0 / (2.0 * C) - 1.0
    # Generate body size
    n = sort(rand(Uniform(0.0, 1.0), S))
    # Generate random ranges
    r = n .* rand(Beta(1.0, β), S)
    # Generate random centroids
    c = [rand(Uniform(r[i] / 2, n[i])) for i in 1:S]
    # Smallest species is an obligate producer
    n[1] = c[1] = 0.0
    # Fill
    predictors = zeros(Float64, (S * S, 6))
    response = zeros(Float64, S * S)
    for i in 1:S
        for j in 1:S
            idx = S * (i - 1) + j
            predictors[idx, :] = [n[i], r[i], c[i], n[j], r[j], c[j]]
            response[idx] = c[i] - r[i] / 2 <= n[j] <= c[i] + r[j] / 2
        end
    end
    # Return
    return table(predictors), response
end
