using UnitJuMP
using Test

import MutableArithmetics
const _MA = MutableArithmetics

@testset "Operators" begin
    include("test_operators.jl")
end

@testset "Variables" begin

    m = Model()
    
    @variable(m, x ≥ 0, u"m/s")
    @test unit(x) == u"m/s"

    @variable(m, y[1:4], u"km/hr")
    @test  unit(y[2]) == u"km/hr"

end

@testset "Rewrite" begin
    m = Model()
    
    @variable(m, x ≥ 0, u"m/s")
    @variable(m, y[1:4], u"km/hr")
 
    uexpr = _MA.@rewrite(x + 3y[1])
    @test uexpr.u == u"m/s"
    @test length(uexpr.expr.terms) == 2
    
end


@testset "Constraints" begin

    m = Model()
    
    @variable(m, u[1:2] ≥ 0, u"m")
    @variable(m, v[1:4], u"km/hr")
    @variable(m, w)

    maxspeed = 4u"ft/s"

    # Various combination of coefficient and variables with and without units
    @constraint(m, 2v[1] ≤ maxspeed)
    @test num_constraints(m, AffExpr, MOI.LessThan{Float64}) == 1
    
    @constraint(m, 2.3v[1] ≤ maxspeed)
    @test num_constraints(m, AffExpr, MOI.LessThan{Float64}) == 2
    speed = 2.3u"m/s"
    
    @constraint(m, c1a, speed * w ≤ maxspeed)
    @test num_constraints(m, AffExpr, MOI.LessThan{Float64}) == 3
    @test UnitJuMP.unit(c1a) == u"m/s"
    
    @constraint(m, c1b, w * speed  ≤ maxspeed)
    @test num_constraints(m, AffExpr, MOI.LessThan{Float64}) == 4
    @test UnitJuMP.unit(c1b) == u"m/s"

    @constraint(m, c1c, sum(v[i] for i in 1:4)   ≤ maxspeed)
    @test num_constraints(m, AffExpr, MOI.LessThan{Float64}) == 5
    
    


    @constraint(m, c1, 2v[1] + 4v[2] ≤ maxspeed) 
    @test typeof(c1) == UnitJuMP.UnitConstraintRef
    @test UnitJuMP.unit(c1) == u"km/hr"

    @constraint(m, c2, 2v[1] + 4v[2] ≤ maxspeed, unit=u"m/s")
    @test UnitJuMP.unit(c2) == u"m/s"
    @test normalized_rhs(c2.cref) == convert(Float64, uconvert(u"m/s", maxspeed).val)

    @variable(m, z, Bin)

    maxlength = 1000u"yd"
    period = 1.5u"hr"
    @constraint(m, c3, u[2] + period * v[2] ≤ maxlength * z, unit=u"cm")
    @test UnitJuMP.unit(c3) == u"cm"

end

