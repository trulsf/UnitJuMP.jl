using UnitJuMP

m = Model()

@variable(m, x, u"m/s")
@variable(m, y, u"ft/s")


#ex1 = x + y
#@expression(m, ex2, x + y)

b1 = 5u"m/s"
b2 = 1.5u"m/s"

#ex3 = x + b1
#ex4 = x + b2

@constraint(m, x + y ≤ b1)
@constraint(m, x ≤ b2)


@objective(m, Max, x + y)

using HiGHS
set_optimizer(m, HiGHS.Optimizer)

JuMP.add_bridge(m, UnitJuMP.UnitLessThanBridge)
JuMP.add_bridge(m, UnitJuMP.UnitObjectiveBridge)

optimize!(m)

value(x)
value(y)
