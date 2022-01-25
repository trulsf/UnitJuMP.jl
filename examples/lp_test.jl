using UnitJuMP
using GLPK

m = Model(GLPK.Optimizer)

const speedunit = u"m/s"
const timeunit = u"s"

@variable(m, x >= 0, speedunit)
@variable(m, y >= 0, timeunit)
@variable(m, z >= 0, u"km/s")

@variable(m, v[1:4], speedunit)


@variable(m, w, Bin)

max_speed = 2u"m/s"
a = 9.8u"ft/s^2"

con = @constraint(m, x + a * y <= max_speed)
@constraint(m, z + x <= max_speed)
@constraint(m, x + 0.5 * a * y  <= max_speed)

M = 0.5u"m/s"
@constraint(m, x <= M * w)

no_speed = 0.0u"m/s"
@constraint(m, -3x  + 2z <= no_speed)

@constraint(m, x == 0.15 * max_speed)

@constraint(m, con7[i=1:4], v[i] <= max_speed)

@constraint(m, con8, sum(v[i] for i=1:3) <= max_speed, u"ft/s")


@objective(m, Max, x + 0.2*z)

data = 4
@constraint(m, -3*data*x  + 2z <= no_speed)

optimize!(m)

value(m[:x])
value(m[:y])
value(m[:z])