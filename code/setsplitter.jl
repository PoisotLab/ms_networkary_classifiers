function split_indices(š², bias; split=0.5)
    # Get the training size
    training_size = round(Int64, split * length(š²))

    # Number of positive samples in the training set
    n_positive = round(Int64, training_size * bias)

    # Locate positive and negative cases
    idx_pos = sample(findall(iszero.(š²)), n_positive; replace=true)
    idx_neg = sample(findall(isone.(š²)), training_size - n_positive; replace=true)

    # Get the training set and the initial testing set
    Iā = shuffle(vcat(idx_neg, idx_pos))
    Iā = setdiff(eachindex(š²), Iā)

    # Correct the testing set to have it keep the connectance of the network
    _test_pos = sum(š²[Iā])
    _expected_neg = round(Int64, _test_pos/mean(š²) - _test_pos)
    _observed_neg = round(Int64, length(Iā)-sum(š²[Iā]))
    tst_neg = sample(findall(iszero.(š²[Iā])), max(_observed_neg - _expected_neg, 1); replace=true)
    deleteat!(Iā, sort(unique(tst_neg)))
    
    # Return the INDICES of the training and testing set, in that order
    return Iā, Iā
end
