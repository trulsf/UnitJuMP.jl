# UnitJuMP

This is an experimental and proof-of-concept package that allows JuMP to be combined with units using Unitful.

Currently, the package only supports a limited set of modelling with linear constraints using the ```@variable``` and ```@constraint``` macros.

## Variables

Variables are defined with units using the ```@variable``` macro by adding the unit as a separate
argument
```julia
    @variable(m, speed, u"m/s")
    @variable(m, length, u"cm")
```

## Constraints

Constraints are automatically created with units using the  ```@constraint``` macro if any of the involved parameters or variables have units. It is possible to specify the unit used for the constraint through the optional argument _unit_ (e.g. for consistent scaling)
```julia
    period = 1.4u"s"
    max_length = 1200u"ft"
    @constraint(m, period * speed + length  <= max_length, unit=u"km")
```
If no unit is provided, the unit of the first term is used. Note that it is not possible to use 
numerical parameters with units directly in the macro expression. Instead, create a separate parameter to hold the value


## Usage

```julia
using UnitJuMP, GLPK

m = Model(GLPK.Optimizer)

@variable(m, x >= 0, u"m/s")
@variable(m, y >= 0, u"ft/s")

max_speed = 60u"km/hr"

@constraint(m, x + y <= max_speed)
@constraint(m, x <= 0.5y)
obj = @objective(m, Max, x + y)

optimize!(m)

println("x = $(value(x))  y = $(value(y))")

#output x = 5.555555555555556 m s^-1  y = 36.45377661125693 ft s^-1
```