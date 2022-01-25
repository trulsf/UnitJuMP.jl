using UnitJuMP
using Test

import MutableArithmetics
const _MA = MutableArithmetics

@testset "Operators" begin
    include("test_operators.jl")
end

@testset "MutableArithmetics" begin
    include("test_ma.jl")
end

@testset "JuMP" begin
    include("test_jump.jl")
end



