using DataFrames
using CSV: CSV

function main()::Int64
    try
        simulations = readdir(joinpath(@__DIR__, "simulations"))
        all_data = [
            DataFrame(CSV.File(joinpath(@__DIR__, "simulations", file))) for
            file in simulations
        ]
        CSV.write(joinpath(@__DIR__, "output.csv"), reduce(vcat, all_data))
    catch err
        @info err
        return 1
    end
    return 0
end

main()

