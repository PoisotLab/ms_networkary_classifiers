function split_indices(𝐲, bias; split=0.5)
    # Get the training size
    training_size = round(Int64, split * length(𝐲))

    # Number of positive samples in the training set
    n_positive = round(Int64, training_size * bias)

    # Locate positive and negative cases
    idx_pos = sample(findall(iszero.(𝐲)), n_positive; replace=true)
    idx_neg = sample(findall(isone.(𝐲)), training_size - n_positive; replace=true)

    # Get the training set and the initial testing set
    Iₚ = shuffle(vcat(idx_neg, idx_pos))
    Iₒ = setdiff(eachindex(𝐲), Iₚ)

    # Correct the testing set to have it keep the connectance of the network
    _test_pos = sum(𝐲[Iₒ])
    _expected_neg = round(Int64, _test_pos/mean(𝐲) - _test_pos)
    _observed_neg = round(Int64, length(Iₒ)-sum(𝐲[Iₒ]))
    tst_neg = sample(findall(iszero.(𝐲[Iₒ])), max(_observed_neg - _expected_neg, 1); replace=true)
    deleteat!(Iₒ, sort(unique(tst_neg)))
    
    # Return the INDICES of the training and testing set, in that order
    return Iₚ, Iₒ
end
