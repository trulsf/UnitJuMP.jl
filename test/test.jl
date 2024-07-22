using UnitJuMP

m = Model()

@variable(m, x <= 2, u"m/s")
@variable(m, y <= 1, u"ft/s")


ex1 = x + y

@expression(m, ex2, x + y)

b1 = 5u"m/s"
b2 = 5.0u"m/s"

ex3 = x + b1
ex4 = x + b2

@constraint(m, x + y ≤ b1) # Fails due to zero not having dimensions

@objective(m, Max, x + y)

using HiGHS

set_optimizer(m, HiGHS.Optimizer)
optimize!(m)
