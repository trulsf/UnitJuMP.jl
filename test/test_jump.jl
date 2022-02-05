@testset "Variables" begin

    m = Model()
    
    @variable(m, x ≥ 0, u"m/s")
    @test x == UnitJuMP.UnitVariableRef(x.vref, u"m/s")
    @test unit(x) == u"m/s"
    @test owner_model(x) === m

    @variable(m, y[1:4], u"km/hr")
    @test y[1] == UnitJuMP.UnitVariableRef(y[1].vref, u"km/hr")

end

@testset "Constraints" begin

    m = Model()
    
    @variable(m, u[1:2] ≥ 0, u"m")
    @variable(m, v[1:4], u"km/hr")
    @variable(m, w, Bin)
    @variable(m, y)

    maxspeed = 4u"ft/s"
    speed = 2.3u"m/s"

    # Various combination of coefficient and variables with and without units
    @constraint(m, 2v[1] ≤ maxspeed)
    @test num_constraints(m, AffExpr, MOI.LessThan{Float64}) == 1
    
    @constraint(m, 2.3v[1] ≤ maxspeed)
    @test num_constraints(m, AffExpr, MOI.LessThan{Float64}) == 2
    
    @constraint(m, c1a, speed * w ≤ maxspeed)
    @test num_constraints(m, AffExpr, MOI.LessThan{Float64}) == 3
    @test unit(c1a) == u"m/s"
    
    @constraint(m, c1b, 40u"km/hr" * w ≤ 15u"m/s")
    @test num_constraints(m, AffExpr, MOI.LessThan{Float64}) == 4
    @test unit(c1b) == u"km/hr"

    @constraint(m, c1c, w * speed  ≤ maxspeed)
    @test num_constraints(m, AffExpr, MOI.LessThan{Float64}) == 5
    @test unit(c1c) == u"m/s"

    @constraint(m, c1d, sum(v[i] for i in 1:4)   ≤ maxspeed)
    @test num_constraints(m, AffExpr, MOI.LessThan{Float64}) == 6
    @test unit(c1d) == u"km/hr"

    @constraint(m, c1, 2v[1] + 4v[2] ≤ maxspeed) 
    @test typeof(c1) <: UnitJuMP.UnitConstraintRef
    @test unit(c1) == u"km/hr"

    @constraint(m, c2, 2v[1] + 4v[2] ≤ maxspeed, u"m/s")
    @test unit(c2) == u"m/s"
    @test normalized_rhs(c2.cref) == convert(Float64, uconvert(u"m/s", maxspeed).val)

    @variable(m, z, Bin)

    maxlength = 1000u"yd"
    period = 1.5u"hr"
    @constraint(m, c3, u[2] + period * v[2] ≤ maxlength * z, u"cm")
    @test unit(c3) == u"cm"

    @constraint(m, c3b, u[2] + 1.5u"hr" * v[2] ≤ 1000u"yd" * z, u"cm")
    @test unit(c3b) == u"cm"

end