module RunTests

using UnitJuMP
using Test

import MutableArithmetics
const _MA = MutableArithmetics

function runtests()
    for name in names(@__MODULE__; all = true)
        if startswith("$(name)", "test_")
            @testset "$(name)" begin
                getfield(@__MODULE__, name)()
            end
        end
    end
    return
end

function test_jump_variables()
    m = Model()

    @variable(m, x ≥ 0, u"m/s")
    @test x == UnitJuMP.UnitVariableRef(x.variable, u"m/s")
    @test unit(x) == u"m/s"
    @test owner_model(x) === m

    @variable(m, y[1:4], u"km/hr")
    @test y[1] == UnitJuMP.UnitVariableRef(y[1].variable, u"km/hr")
    return
end

function test_jump_constraints()
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

    @constraint(m, c1c, w * speed ≤ maxspeed)
    @test num_constraints(m, AffExpr, MOI.LessThan{Float64}) == 5
    @test unit(c1c) == u"m/s"

    @constraint(m, c1d, sum(v[i] for i in 1:4) ≤ maxspeed)
    @test num_constraints(m, AffExpr, MOI.LessThan{Float64}) == 6
    @test unit(c1d) == u"km/hr"

    @constraint(m, c1, 2v[1] + 4v[2] ≤ maxspeed)
    @test typeof(c1) <: UnitJuMP.UnitConstraintRef
    @test unit(c1) == u"km/hr"

    @constraint(m, c2, 2v[1] + 4v[2] ≤ maxspeed, u"m/s")
    @test unit(c2) == u"m/s"
    @test normalized_rhs(c2.constraint) ==
          convert(Float64, Unitful.uconvert(u"m/s", maxspeed).val)

    @variable(m, z, Bin)

    maxlength = 1000u"yd"
    period = 1.5u"hr"
    @constraint(m, c3, u[2] + period * v[2] ≤ maxlength * z, u"cm")
    @test unit(c3) == u"cm"

    @constraint(m, c3b, u[2] + 1.5u"hr" * v[2] ≤ 1000u"yd" * z, u"cm")
    @test unit(c3b) == u"cm"
    return
end

function test_mutable_arithmetics()
    m = Model()
    @variable(m, x ≥ 0)
    @variable(m, y)

    xu = UnitJuMP.UnitVariableRef(x, u"m/s")
    yu = UnitJuMP.UnitVariableRef(y, u"km/hr")

    @test _MA.@rewrite(xu) == UnitJuMP.UnitAffExpr(1x, u"m/s")
    @test _MA.@rewrite(-xu) == UnitJuMP.UnitAffExpr(-x, u"m/s")
    @test _MA.@rewrite(5xu) == UnitJuMP.UnitAffExpr(5x, u"m/s")
    @test _MA.@rewrite(xu / 5) == UnitJuMP.UnitAffExpr(0.2x, u"m/s")

    @test _MA.@rewrite(xu + yu) == UnitJuMP.UnitAffExpr(x + y / 3.6, u"m/s")
    @test _MA.@rewrite(xu - yu) == UnitJuMP.UnitAffExpr(x - y / 3.6, u"m/s")
    @test _MA.@rewrite(-xu + yu) == UnitJuMP.UnitAffExpr(-x + y / 3.6, u"m/s")

    speed = 10u"m/s"
    @test _MA.@rewrite(speed * x) == UnitJuMP.UnitAffExpr(10x, u"m/s")
    @test _MA.@rewrite(x * speed) == UnitJuMP.UnitAffExpr(10x, u"m/s")
    @test _MA.@rewrite(speed * xu) == UnitJuMP.UnitAffExpr(10x, u"m^2/s^2")
    @test _MA.@rewrite(xu * speed) == UnitJuMP.UnitAffExpr(10x, u"m^2/s^2")
    @test _MA.@rewrite(x / speed) == UnitJuMP.UnitAffExpr(0.1x, u"s/m")
    return
end

function test_operators()
    m = Model()

    @variable(m, x)
    @variable(m, y)
    @variable(m, z)

    xu = UnitJuMP.UnitVariableRef(x, u"km")
    yu = UnitJuMP.UnitVariableRef(y, u"hr")
    zu = UnitJuMP.UnitVariableRef(z, u"s")

    @test -xu == UnitJuMP.UnitAffExpr(-x, u"km")
    @test xu + 200u"m" == UnitJuMP.UnitAffExpr(x + 0.2, u"km")
    @test 200u"m" + xu == UnitJuMP.UnitAffExpr(1000x + 200, u"m")
    @test xu - 400u"m" == UnitJuMP.UnitAffExpr(x - 0.4, u"km")
    @test 400u"m" - xu == UnitJuMP.UnitAffExpr(-1000x + 400, u"m")

    @test 200u"km" * x == UnitJuMP.UnitAffExpr(200 * x, u"km")
    @test 200 * xu == UnitJuMP.UnitAffExpr(200 * x, u"km")
    @test 1.5u"s" * xu == UnitJuMP.UnitAffExpr(1.5 * x, u"s*km")

    @test xu / 0.5 == UnitJuMP.UnitAffExpr(2 * x, u"km")
    @test x / 0.5u"s" == UnitJuMP.UnitAffExpr(2 * x, u"s^-1")
    @test xu / 0.5u"s" == UnitJuMP.UnitAffExpr(2 * x, u"km/s")

    @test yu + zu == UnitJuMP.UnitAffExpr(y + z / 3600, u"hr")
    @test yu - zu == UnitJuMP.UnitAffExpr(y - z / 3600, u"hr")

    expr = yu + 1800 * zu

    @test expr + 3600u"s" == UnitJuMP.UnitAffExpr(y + 0.5z + 1, u"hr")
    @test expr - 1800u"s" == UnitJuMP.UnitAffExpr(y + 0.5z - 0.5, u"hr")
    @test 2u"s" + expr == UnitJuMP.UnitAffExpr(3600y + 1800z + 2, u"s")
    @test 3600u"s" - expr == UnitJuMP.UnitAffExpr(-3600y - 1800z + 3600, u"s")

    @test 2 * expr == UnitJuMP.UnitAffExpr(2y + z, u"hr")
    @test expr / 0.5 == UnitJuMP.UnitAffExpr(2y + z, u"hr")
    @test 2u"kW" * expr == UnitJuMP.UnitAffExpr(2y + z, u"kW*hr")
    @test expr / 0.5u"km" == UnitJuMP.UnitAffExpr(2y + z, u"hr/km")

    @variable(m, w)
    wu = UnitJuMP.UnitVariableRef(w, u"minute")

    @test expr + wu == UnitJuMP.UnitAffExpr(y + 0.5z + w / 60, u"hr")
    @test expr - wu == UnitJuMP.UnitAffExpr(y + 0.5z - w / 60, u"hr")
    @test wu + expr == UnitJuMP.UnitAffExpr(60y + 30z + w, u"minute")
    @test wu - expr == UnitJuMP.UnitAffExpr(-60y - 30z + w, u"minute")
    @test expr + yu == UnitJuMP.UnitAffExpr(2y + 0.5z, u"hr")

    expr2 = 30wu + yu

    @test expr + expr2 == UnitJuMP.UnitAffExpr(2y + 0.5z + 0.5w, u"hr")
    @test expr2 + expr == UnitJuMP.UnitAffExpr(120y + 30z + 30w, u"minute")
    @test 2 * expr - expr2 == UnitJuMP.UnitAffExpr(y + z - 0.5w, u"hr")
    return
end

end

RunTests.runtests()
