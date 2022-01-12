# UnitJuMP

This is an experimental and proof-of-concept module that allows JuMP to be combined with units using Unitful.

Currently, only supports a limited set of modelling with linear constraints.


## Usage

```julia
using UnitJuMP, GLPK

m = Model(GLPK.Optimizer)

@variable(m, x >= 0, u"m/s")
@variable(m, y >= 0, u"ft/s")

max_speed = 60u"km/hr"

@constraint(m, x + y <= max_speed)
obj = @objective(m, Max, x + y)

optimize!(m)



```

[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)