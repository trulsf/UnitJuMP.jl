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

function test_examples()
    examples = joinpath(@__DIR__, "..", "examples")
    for filename in filter(f -> endswith(f, ".jl"), readdir(examples))
        include(joinpath(examples, filename))
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

    @test _MA.@rewrite(xu) == UnitJuMP.UnitExpression(1x, u"m/s")
    @test _MA.@rewrite(-xu) == UnitJuMP.UnitExpression(-x, u"m/s")
    @test _MA.@rewrite(5xu) == UnitJuMP.UnitExpression(5x, u"m/s")
    @test _MA.@rewrite(xu * 5) == UnitJuMP.UnitExpression(5x, u"m/s")
    @test _MA.@rewrite(xu / 5) == UnitJuMP.UnitExpression(0.2x, u"m/s")

    @test _MA.@rewrite(xu + yu) == UnitJuMP.UnitExpression(x + y / 3.6, u"m/s")
    @test _MA.@rewrite(xu - yu) == UnitJuMP.UnitExpression(x - y / 3.6, u"m/s")
    @test _MA.@rewrite(-xu + yu) ==
          UnitJuMP.UnitExpression(-x + y / 3.6, u"m/s")

    speed = 10u"m/s"
    length = 10u"m"
    freq = 1u"1/s"
    @test _MA.@rewrite(speed * x) == UnitJuMP.UnitExpression(10x, u"m/s")
    @test _MA.@rewrite(x * speed) == UnitJuMP.UnitExpression(10x, u"m/s")
    @test _MA.@rewrite(xu * 10) == UnitJuMP.UnitExpression(10x, u"m/s")
    @test _MA.@rewrite(speed * xu) == UnitJuMP.UnitExpression(10x, u"m^2/s^2")
    @test _MA.@rewrite(xu * speed) == UnitJuMP.UnitExpression(10x, u"m^2/s^2")
    @test _MA.@rewrite(x / speed) == UnitJuMP.UnitExpression(0.1x, u"s/m")
    @test _MA.@rewrite(speed + 2xu) == UnitJuMP.UnitExpression(10 + 2x, u"m/s")
    @test _MA.@rewrite(-speed + xu) == UnitJuMP.UnitExpression(-10 + x, u"m/s")
    @test _MA.@rewrite(2xu - speed) == UnitJuMP.UnitExpression(2x - 10, u"m/s")

    @test _MA.@rewrite(xu + 0.5 * speed) ==
          UnitJuMP.UnitExpression(x + 5, u"m/s")
    @test _MA.@rewrite(xu - 0.5 * speed) ==
          UnitJuMP.UnitExpression(x - 5, u"m/s")
    @test _MA.@rewrite(xu + speed * 0.5) ==
          UnitJuMP.UnitExpression(x + 5, u"m/s")
    @test _MA.@rewrite(xu - speed * 0.5) ==
          UnitJuMP.UnitExpression(x - 5, u"m/s")
    @test _MA.@rewrite(xu + length * freq) ==
          UnitJuMP.UnitExpression(x + 10, u"m/s")
    @test _MA.@rewrite(xu - length * freq) ==
          UnitJuMP.UnitExpression(x - 10, u"m/s")
    @test _MA.@rewrite(0.5 * speed + xu) ==
          UnitJuMP.UnitExpression(x + 5, u"m/s")

    @test _MA.@rewrite(4xu + 2yu - speed) ==
          UnitJuMP.UnitExpression(4x + 2y / 3.6 - 10, u"m/s")
    @test _MA.@rewrite(4xu - 2yu + speed) ==
          UnitJuMP.UnitExpression(4x - 2y / 3.6 + 10, u"m/s")

    ex = xu + yu
    @test _MA.@rewrite(ex + yu + speed) ==
          UnitJuMP.UnitExpression(x + 2y / 3.6 + 10, u"m/s")
    ex = xu + yu
    @test _MA.@rewrite(yu + ex) == UnitJuMP.UnitExpression(3.6x + 2y, u"km/hr")
    ex = xu + yu
    @test _MA.@rewrite(yu - 2ex) == UnitJuMP.UnitExpression(-7.2x - y, u"km/hr")

    @test_throws ErrorException _MA.@rewrite(xu + y)
    @test_throws ErrorException _MA.@rewrite(xu - y)
    @test_throws ErrorException _MA.@rewrite(xu + 5y)
    @test_throws ErrorException _MA.@rewrite(xu - 3y)
    @test_throws ErrorException _MA.@rewrite(y + xu)
    @test_throws ErrorException _MA.@rewrite(y - xu)
    @test_throws ErrorException _MA.@rewrite(y + 5xu)
    @test_throws ErrorException _MA.@rewrite(y - 4xu)
    @test_throws ErrorException _MA.@rewrite(xu + 4)
    @test_throws ErrorException _MA.@rewrite(xu - 4)

    @test_throws ErrorException @constraint(m, x <= xu)
    @test_throws ErrorException @constraint(m, xu <= y)

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

    @test -xu == UnitJuMP.UnitExpression(-x, u"km")
    @test xu + 200u"m" == UnitJuMP.UnitExpression(x + 0.2, u"km")
    @test 200u"m" + xu == UnitJuMP.UnitExpression(1000x + 200, u"m")
    @test xu - 400u"m" == UnitJuMP.UnitExpression(x - 0.4, u"km")
    @test 400u"m" - xu == UnitJuMP.UnitExpression(-1000x + 400, u"m")

    @test 200u"km" * x == UnitJuMP.UnitExpression(200 * x, u"km")
    @test x * 200u"km" == UnitJuMP.UnitExpression(200 * x, u"km")
    @test 200 * xu == UnitJuMP.UnitExpression(200 * x, u"km")
    @test xu * 200 == UnitJuMP.UnitExpression(200 * x, u"km")
    @test 1.5u"s" * xu == UnitJuMP.UnitExpression(1.5 * x, u"s*km")
    @test xu * 1.5u"s" == UnitJuMP.UnitExpression(1.5 * x, u"s*km")

    @test xu / 0.5 == UnitJuMP.UnitExpression(2 * x, u"km")
    @test x / 0.5u"s" == UnitJuMP.UnitExpression(2 * x, u"s^-1")
    @test xu / 0.5u"s" == UnitJuMP.UnitExpression(2 * x, u"km/s")

    @test yu + zu == UnitJuMP.UnitExpression(y + z / 3600, u"hr")
    @test yu - zu == UnitJuMP.UnitExpression(y - z / 3600, u"hr")

    expr = yu + 1800 * zu

    @test expr + 3600u"s" == UnitJuMP.UnitExpression(y + 0.5z + 1, u"hr")
    @test expr - 1800u"s" == UnitJuMP.UnitExpression(y + 0.5z - 0.5, u"hr")
    @test 2u"s" + expr == UnitJuMP.UnitExpression(3600y + 1800z + 2, u"s")
    @test 3600u"s" - expr ==
          UnitJuMP.UnitExpression(-3600y - 1800z + 3600, u"s")

    @test 2 * expr == UnitJuMP.UnitExpression(2y + z, u"hr")
    @test expr * 2 == UnitJuMP.UnitExpression(2y + z, u"hr")
    @test expr / 0.5 == UnitJuMP.UnitExpression(2y + z, u"hr")
    @test 2u"kW" * expr == UnitJuMP.UnitExpression(2y + z, u"kW*hr")
    @test expr * 2u"kW" == UnitJuMP.UnitExpression(2y + z, u"kW*hr")
    @test expr / 0.5u"km" == UnitJuMP.UnitExpression(2y + z, u"hr/km")

    @variable(m, w)
    wu = UnitJuMP.UnitVariableRef(w, u"minute")

    @test expr + wu == UnitJuMP.UnitExpression(y + 0.5z + w / 60, u"hr")
    @test expr - wu == UnitJuMP.UnitExpression(y + 0.5z - w / 60, u"hr")
    @test wu + expr == UnitJuMP.UnitExpression(60y + 30z + w, u"minute")
    @test wu - expr == UnitJuMP.UnitExpression(-60y - 30z + w, u"minute")
    @test expr + yu == UnitJuMP.UnitExpression(2y + 0.5z, u"hr")

    expr2 = 30wu + yu

    @test expr + expr2 == UnitJuMP.UnitExpression(2y + 0.5z + 0.5w, u"hr")
    @test expr2 + expr == UnitJuMP.UnitExpression(120y + 30z + 30w, u"minute")
    @test 2 * expr - expr2 == UnitJuMP.UnitExpression(y + z - 0.5w, u"hr")

    # Combination of unit expression with unitless variables/expressions
    # should throw error
    @test_throws ErrorException w + wu
    @test_throws ErrorException w - wu
    @test_throws ErrorException 4w - wu
    @test_throws ErrorException wu - 4w
    @test_throws ErrorException 4 - wu
    @test_throws ErrorException wu + 4
    @test_throws ErrorException wu - 4
    @test_throws ErrorException x + 2y - wu
    @test_throws ErrorException xu + 2y - wu

    return
end

function test_number_times_quantity_times_variable()
    a = 9.81u"m/s^2"
    model = Model()
    @variable(model, y, u"s")
    expr = @expression(model, 0.5 * a * y)
    @test Unitful.unit(expr) == u"m/s"
    return
end

function test_number_times_quantity_times_variable_to_existing()
    a = 9.81u"m/s^2"
    model = Model()
    @variable(model, x, u"m/s")
    @variable(model, y, u"s")
    expr = @expression(model, x + 0.5 * a * y)
    @test Unitful.unit(expr) == u"m/s"
    return
end

function test_unit_variable()
    model = Model()
    @variable(model, x, u"kW*hr")
    @variable(model, y, u"s")

    # Start values
    set_start_value(x, 1u"MW*hr")
    @test start_value(x) == 1000u"kW*hr"
    @test_throws ErrorException set_start_value(x, 13.2)

    # Lower bounds
    set_lower_bound(x, 10u"MJ")
    @test has_lower_bound(x)
    @test lower_bound(x) == (10 / 3.6)u"kW*hr"
    lref = LowerBoundRef(x)
    @test typeof(lref) <: ConstraintRef
    delete_lower_bound(x)
    @test !has_lower_bound(x)
    @test_throws ErrorException set_lower_bound(x, -4.0)

    # Upper bounds
    set_upper_bound(y, 10u"hr")
    @test has_upper_bound(y)
    @test upper_bound(y) == 36000u"s"
    uref = UpperBoundRef(y)
    @test typeof(uref) <: ConstraintRef
    delete_upper_bound(y)
    @test !has_lower_bound(y)
    @test_throws ErrorException set_upper_bound(y, 42)

    # Fix values
    fix(y, 1u"hr")
    @test is_fixed(y)
    @test fix_value(y) == 3600u"s"
    fref = FixRef(y)
    @test typeof(fref) <: ConstraintRef
    unfix(y)
    @test !is_fixed(y)
    @test_throws ErrorException fix(y, 10)

    # Integer and binary
    set_integer(x)
    @test is_integer(x)
    iref = IntegerRef(x)
    @test typeof(iref) <: ConstraintRef
    unset_integer(x)
    @test !is_integer(x)
    set_binary(y)
    @test is_binary(y)
    bref = BinaryRef(y)
    @test typeof(bref) <: ConstraintRef
    unset_binary(y)
    @test !is_binary(y)

    # Naming
    set_name(x, "xvar")
    @test name(x) == "xvar"

    return
end

end

RunTests.runtests()
