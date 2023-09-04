# Multi-objective example with units based on example from JuMP docs.

using UnitJuMP
using Unitful
using UnitfulAssets
import HiGHS
import MultiObjectiveAlgorithms as MOA

function test_multiobj_knapsack()
    profit =
        [77, 94, 71, 63, 96, 82, 85, 75, 72, 91, 99, 63, 84, 87, 79, 94, 90] *
        u"NOK"
    desire =
        [65, 90, 90, 77, 95, 84, 70, 94, 66, 92, 74, 97, 60, 60, 65, 97, 93] *
        u"NOK"
    weight =
        [80, 87, 68, 72, 66, 77, 99, 85, 70, 93, 98, 72, 100, 89, 67, 86, 91] *
        u"kg"
    capacity = 900u"kg"
    N = length(profit)

    model = Model()
    @variable(model, x[1:N], Bin)
    @constraint(model, sum(weight[i] * x[i] for i in 1:N) <= capacity)
    @expression(model, profit_expr, sum(profit[i] * x[i] for i in 1:N))
    @expression(model, desire_expr, sum(desire[i] * x[i] for i in 1:N))
    obj = @objective(model, Max, [profit_expr, desire_expr])

    set_optimizer(model, () -> MOA.Optimizer(HiGHS.Optimizer))
    set_silent(model)
    set_attribute(model, MOA.Algorithm(), MOA.EpsilonConstraint())
    optimize!(model)

    res = value(obj; result = 5)
    @test res[1] ≈ 936.0u"NOK"
    @test res[2] ≈ 942.0u"NOK"
end

test_multiobj_knapsack()
