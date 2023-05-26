module RunTests

using UnitJuMP
using Test
using SparseVariables

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

    set_name(c3, "constraint")
    @test name(c3) == "constraint"
    return
end

function test_objective()
    m = Model()
    @variable(m, x[1:4] ≥ 0, u"m/s")
    @variable(m, y[1:4] ≥ 0, u"km/hr")

    # Single objective
    obj = @objective(m, Min, x[1] + 2y[4])
    @test typeof(obj) <: UnitExpression   
    @test unit(obj) == u"m/s"

    # Multi objective
    mobj = @objective(m, Min, [x[1] + 2y[4], 2y[2] - 4x[4]])
    @test typeof(mobj) <: Vector{<:UnitExpression}   
    @test unit(mobj[1]) == u"m/s"
    @test unit(mobj[2]) == u"km/hr"

end

function test_sum()
    m = Model()
    @variable(m, x[1:10] ≥ 0, u"m/s")

    sx = sum(x)
    sxx = sum(x[i] for i in 1:10)
    @test sx == sxx

    empty = sum(filter(el -> false, x))
    @test typeof(empty) <: UnitJuMP.UnitAffExpr
    period = 10u"s"
    empty2 = sum(period .* filter(el -> false, x))
    @test unit(empty2) == u"m"
    @test typeof(empty2) <: UnitJuMP.UnitAffExpr

    @variable(m, y[1:5] ≥ 0, u"m")
    @constraint(m, sum(y) == sum(period * x[i] for i in 1:4))
end

function test_zero_one()
    m = Model()
    @variable(m, x ≥ 0, u"m/s")
    z = zero(x)
    @test unit(z) == unit(x)

    o = one(x)
    @test unit(o) == unit(x)
end

function test_containers()
    cars = ["A", "B", "C"]
    years = collect(1980:2000)

    m = Model()
    @variable(
        m,
        x[cars = cars, years = years],
        u"km";
        container = DenseAxisArray
    )
    @test length(x) == 63
    @test unit(first(x)) == u"km"

    @variable(
        m,
        z[cars = cars, years = years],
        u"m/s";
        container = SparseAxisArray
    )
    @test length(z) == 63
    @test unit(first(z)) == u"m/s"
end

function test_sparsevariables()
    cars = ["A", "B", "C"]
    years = collect(1980:2000)

    m = Model()
    @variable(
        m,
        x[cars = cars, years = years],
        u"km";
        container = IndexedVarArray
    )
    for i in 1980:1990
        insertvar!(x, "A", i)
        insertvar!(x, "B", i + 3)
    end

    @test unit(x["A", 1980]) == u"km"

    @variable(m, z[cars = cars, years = years]; container = IndexedVarArray)
    for i in 1980:1990
        insertvar!(z, "A", i)
        insertvar!(z, "B", i + 3)
    end

    @variable(m, y[cars = cars], u"m"; container = IndexedVarArray)
    insertvar!(y, "A")
    insertvar!(y, "C")

    sy = sum(y)
    syy = sum(y[:])
    @test sy == syy

    @constraint(m, con[c in cars], sum(x[c, :]) == y[c])
    @test unit(con["A"]) == u"km"

    emit = SparseArray(Dict(("A", 1980) => 10u"kg", ("A", 1982) => 20u"kg"))
    obj = @objective(
        m,
        Min,
        sum(emit[c, y] * z[c, y] for c in cars for y in years)
    )

    @test typeof(obj) <: UnitJuMP.UnitAffExpr
    @test unit(obj) == u"kg"
    @test obj.expr == 10z["A", 1980] + 20z["A", 1982]
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
    @test _MA.@rewrite(speed * x) == UnitJuMP.UnitExpression(10x, u"m/s")
    @test _MA.@rewrite(x * speed) == UnitJuMP.UnitExpression(10x, u"m/s")
    @test _MA.@rewrite(xu * 10) == UnitJuMP.UnitExpression(10x, u"m/s")
    @test _MA.@rewrite(speed * xu) == UnitJuMP.UnitExpression(10x, u"m^2/s^2")
    @test _MA.@rewrite(xu * speed) == UnitJuMP.UnitExpression(10x, u"m^2/s^2")
    @test _MA.@rewrite(x / speed) == UnitJuMP.UnitExpression(0.1x, u"s/m")
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

function test_ma_quad()
    m = Model()
    @variable(m, x ≥ 0)
    @variable(m, y)
    @variable(m, z)
    @variable(m, w)

    xu = UnitJuMP.UnitVariableRef(x, u"m")
    yu = UnitJuMP.UnitVariableRef(y, u"km")
    zu = UnitJuMP.UnitVariableRef(z, u"km^2")
    wu = UnitJuMP.UnitVariableRef(w, u"s")

    expr = x + 1
    uexpr = xu + 10u"m"
    qexpr = (x + 1)^2
    quexpr = (xu + 1u"m")^2
    quadex = (wu + 4u"s")^2
    qex = zu + 100u"m^2"
    a = 10u"m"
    b = 5
    c = 0.01u"km^2"
    d = 3u"m^2/s^2"
    q = 10u"m^2"

    @test _MA.@rewrite(xu * xu) == UnitJuMP.UnitExpression(x * x, u"m^2")
    @test _MA.@rewrite(xu * yu) == UnitJuMP.UnitExpression(x * y, u"m*km")
    @test _MA.@rewrite(-xu * xu) == UnitJuMP.UnitExpression(-x * x, u"m^2")

    @test _MA.@rewrite(x * xu) == UnitJuMP.UnitExpression(x * x, u"m")
    @test _MA.@rewrite(xu * x) == UnitJuMP.UnitExpression(x * x, u"m")

    @test _MA.@rewrite(-x * xu) == UnitJuMP.UnitExpression(-x * x, u"m")

    @test _MA.@rewrite(xu * uexpr) ==
          UnitJuMP.UnitExpression(x * x + 10x, u"m^2")
    @test _MA.@rewrite(uexpr * xu) ==
          UnitJuMP.UnitExpression(x * x + 10x, u"m^2")

    @test _MA.@rewrite(xu * expr) == UnitJuMP.UnitExpression(x * x + x, u"m")
    @test _MA.@rewrite(expr * xu) == UnitJuMP.UnitExpression(x * x + x, u"m")

    @test _MA.@rewrite(uexpr * uexpr) ==
          UnitJuMP.UnitExpression(x * x + 20x + 100, u"m^2")

    @test _MA.@rewrite(uexpr * expr) ==
          UnitJuMP.UnitExpression(x * x + 11x + 10, u"m")
    @test _MA.@rewrite(expr * uexpr) ==
          UnitJuMP.UnitExpression(x * x + 11x + 10, u"m")

    @test _MA.@rewrite(uexpr * x) == UnitJuMP.UnitExpression(x * x + 10x, u"m")
    @test _MA.@rewrite(x * uexpr) == UnitJuMP.UnitExpression(x * x + 10x, u"m")

    @test _MA.@rewrite(uexpr^2) ==
          UnitJuMP.UnitExpression(x * x + 20x + 100, u"m^2")

    @test _MA.@rewrite(a * qexpr) ==
          UnitJuMP.UnitExpression(10x * x + 20x + 10, u"m")
    @test _MA.@rewrite(qexpr * a) ==
          UnitJuMP.UnitExpression(10x * x + 20x + 10, u"m")

    @test _MA.@rewrite(a * b * x^2) == UnitJuMP.UnitExpression(50x^2, u"m")
    @test _MA.@rewrite(a * b * xu^2) == UnitJuMP.UnitExpression(50x^2, u"m^3")
    @test _MA.@rewrite(a * b * qexpr) ==
          UnitJuMP.UnitExpression(50x^2 + 100x + 50, u"m")
    @test _MA.@rewrite(a * b * quexpr) ==
          UnitJuMP.UnitExpression(50x^2 + 100x + 50, u"m^3")

    @test _MA.@rewrite(xu^2 + zu) == UnitJuMP.UnitExpression(x^2 + 1e6z, u"m^2")
    @test _MA.@rewrite(zu + xu^2) ==
          UnitJuMP.UnitExpression(z + 1e-6x^2, u"km^2")
    @test _MA.@rewrite(xu^2 - zu) == UnitJuMP.UnitExpression(x^2 - 1e6z, u"m^2")
    @test _MA.@rewrite(zu - xu^2) ==
          UnitJuMP.UnitExpression(z - 1e-6x^2, u"km^2")

    @test _MA.@rewrite(xu^2 + qex) ==
          UnitJuMP.UnitExpression(x^2 + 1e6z + 100, u"m^2")
    @test _MA.@rewrite(qex + xu^2) ==
          UnitJuMP.UnitExpression(z + 1e-6x^2 + 1e-4, u"km^2")
    @test _MA.@rewrite(xu^2 - qex) ==
          UnitJuMP.UnitExpression(x^2 - 1e6z - 100, u"m^2")
    @test _MA.@rewrite(qex - xu^2) ==
          UnitJuMP.UnitExpression(z - 1e-6x^2 + 1e-4, u"km^2")

    @test _MA.@rewrite(xu^2 + yu^2) ==
          UnitJuMP.UnitExpression(x^2 + 1e6y^2, u"m^2")
    @test _MA.@rewrite(xu^2 - yu^2) ==
          UnitJuMP.UnitExpression(x^2 - 1e6y^2, u"m^2")

    @test _MA.@rewrite(xu^2 + c) == UnitJuMP.UnitExpression(x^2 + 1e4, u"m^2")
    @test _MA.@rewrite(xu^2 - c) == UnitJuMP.UnitExpression(x^2 - 1e4, u"m^2")
    @test _MA.@rewrite(c + xu^2) ==
          UnitJuMP.UnitExpression(1e-6x^2 + 1e-2, u"km^2")
    @test _MA.@rewrite(c - xu^2) ==
          UnitJuMP.UnitExpression(-1e-6x^2 + 1e-2, u"km^2")

    # Three arguments
    @test _MA.@rewrite(xu^2 + c * z) ==
          UnitJuMP.UnitExpression(x^2 + 1e4z, u"m^2")
    @test _MA.@rewrite(xu^2 - c * z) ==
          UnitJuMP.UnitExpression(x^2 - 1e4z, u"m^2")

    @test _MA.@rewrite(xu^2 + b * zu) ==
          UnitJuMP.UnitExpression(x^2 + 5e6z, u"m^2")
    @test _MA.@rewrite(xu^2 - b * zu) ==
          UnitJuMP.UnitExpression(x^2 - 5e6z, u"m^2")

    @test _MA.@rewrite(xu^2 + a * yu) ==
          UnitJuMP.UnitExpression(x^2 + 1e4y, u"m^2")
    @test _MA.@rewrite(xu^2 - a * yu) ==
          UnitJuMP.UnitExpression(x^2 - 1e4y, u"m^2")

    @test _MA.@rewrite(yu^2 + c * qexpr) ==
          UnitJuMP.UnitExpression(y^2 + 0.01x^2 + 0.02x + 0.01, u"km^2")
    @test _MA.@rewrite(yu^2 - c * qexpr) ==
          UnitJuMP.UnitExpression(y^2 - 0.01x^2 - 0.02x - 0.01, u"km^2")

    @test _MA.@rewrite(xu^2 + b * quexpr) ==
          UnitJuMP.UnitExpression(6x^2 + 10x + 5, u"m^2")
    @test _MA.@rewrite(xu^2 - b * quexpr) ==
          UnitJuMP.UnitExpression(-4x^2 - 10x - 5, u"m^2")

    @test _MA.@rewrite(q + d * quadex) ==
          UnitJuMP.UnitExpression(3w^2 + 24w + 58, u"m^2")
    @test _MA.@rewrite(q - d * quadex) ==
          UnitJuMP.UnitExpression(-3w^2 - 24w - 38, u"m^2")
    @test _MA.@rewrite(q + xu * yu) ==
          UnitJuMP.UnitExpression(10 + 1000x * y, u"m^2")
    @test _MA.@rewrite(q - xu * yu) ==
          UnitJuMP.UnitExpression(10 - 1000x * y, u"m^2")

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

function test_operators_quad()
    m = Model()

    @variable(m, x)
    @variable(m, y)
    @variable(m, z)

    xu = UnitJuMP.UnitVariableRef(x, u"km")
    zu = UnitJuMP.UnitVariableRef(z, u"s")

    @test xu * xu == UnitJuMP.UnitExpression(x * x, u"km^2")
    @test xu * zu == UnitJuMP.UnitExpression(x * z, u"km*s")
    @test y * xu == UnitJuMP.UnitExpression(y * x, u"km")
    @test xu * y == UnitJuMP.UnitExpression(y * x, u"km")

    a = 1000u"m"
    @test xu * (xu + a) == UnitJuMP.UnitExpression(x^2 + x, u"km^2")
    @test (xu + a) * xu == UnitJuMP.UnitExpression(x^2 + x, u"km^2")
    @test (xu + a) * (xu + a) == UnitJuMP.UnitExpression(x^2 + 2x + 1, u"km^2")

    @test (x + 1) * (xu + a) == UnitJuMP.UnitExpression(x^2 + 2x + 1, u"km")
    @test (xu + a) * (x + 1) == UnitJuMP.UnitExpression(x^2 + 2x + 1, u"km")

    @test (x + 1) * xu == UnitJuMP.UnitExpression(x^2 + x, u"km")
    @test xu * (x + 1) == UnitJuMP.UnitExpression(x^2 + x, u"km")

    @test x * (xu + a) == UnitJuMP.UnitExpression(x^2 + x, u"km")
    @test (xu + a) * x == UnitJuMP.UnitExpression(x^2 + x, u"km")

    b = 1u"km^2"
    @test xu * xu + b == UnitJuMP.UnitExpression(x^2 + 1, u"km^2")
    @test b + xu * xu == UnitJuMP.UnitExpression(x^2 + 1, u"km^2")

    @test xu^2 == UnitJuMP.UnitExpression(x^2, u"km^2")
    @test xu^1 == xu
    @test xu^0 == 1
    @test_throws ErrorException xu^4

    @test (xu + a)^2 == UnitJuMP.UnitExpression(x^2 + 2x + 1, u"km^2")
    @test (xu + a)^1 == UnitJuMP.UnitExpression(x + 1, u"km")
    @test (xu + a)^0 == 1
    @test_throws ErrorException (xu + a)^4

    @test b * x^2 == UnitJuMP.UnitExpression(x^2, u"km^2")
    @test x^2 * b == UnitJuMP.UnitExpression(x^2, u"km^2")
    @test b * (x + 1)^2 == UnitJuMP.UnitExpression(x^2 + 2x + 1, u"km^2")
    @test (x + 1)^2 * b == UnitJuMP.UnitExpression(x^2 + 2x + 1, u"km^2")

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
