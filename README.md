# UnitJuMP

[![Build Status](https://github.com/trulsf/UnitJuMP.jl/workflows/CI/badge.svg?branch=main)](https://github.com/trulsf/UnitJuMP.jl/actions?query=workflow%3ACI)
[![codecov](https://codecov.io/gh/trulsf/UnitJuMP.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/trulsf/UnitJuMP.jl)

This is an experimental and proof-of-concept package that allows JuMP to be
combined with units using Unitful.

Currently, the package only supports a limited set of modelling with linear and quadratic
constraints using the `@variable` and `@constraint` macros.

## Variables

Variables are defined with units using the `@variable` macro by adding the unit
as a separate argument:
```julia
@variable(m, speed, u"m/s")
@variable(m, length, u"cm")
```

## Constraints

Constraints are automatically created with units using the  `@constraint` macro
if any of the involved parameters or variables have units. It is possible to
specify the unit used for the constraint by adding it is an extra argument
(e.g., for consistent scaling):
```julia
period = 1.4u"s"
max_length = 1200u"ft"
@constraint(m, period * speed + length  <= max_length, u"km")
```

If no unit is provided, the unit of the first term is used. Note that it may
cause problems if using numerical parameters with units directly in the macro
expression. Instead, create a separate parameter to hold the value.

## Expressions and objective

Both the @expression and @objective macros will handle variables with units, but
it is not possible to specify units as part of the macro arguments. If one wants
to use a different unit for the objective, the best approach is to create the
objective as a separate expression and then convert it to the required unit
before setting the objective:
```julia
obj = Unitful.uconvert(u"km/hr", @expression(m, x + y))
@objective(m, Max, obj)
```

As an alternative the objective can also be built incrementally as a
`UnitExpression` of a given unit:
```julia
obj = UnitExpression(AffExpr(), u"km/hr")
obj += x + y
@objective(m, Max, obj)
```

## Usage

```julia
using UnitJuMP, HiGHS
m = Model(HiGHS.Optimizer)
@variable(m, x >= 0, u"m/s")
@variable(m, y >= 0, u"ft/s")
max_speed = 60u"km/hr"
@constraint(m, x + y <= max_speed, u"km/hr")
@constraint(m, x <= 0.5y)
obj = @objective(m, Max, x + y)
optimize!(m)
println("x = $(value(x))  y = $(value(y))")
println("objective value = $(value(obj))")

#output x = 5.555555555555556 m s^-1  y = 36.45377661125693 ft s^-1
#       objective value = 16.666666666666668 m s^-1
```
