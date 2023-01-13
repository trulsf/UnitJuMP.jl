using UnitJuMP
using Test
import Ipopt

function test_quad_example()
    model = Model(Ipopt.Optimizer)
    set_silent(model)

    @variable(model, x >= 0, u"m")
    @variable(model, y >= 0, u"s")

    a = 0.5u"ft"
    b = 250u"cm"
    v = 3u"m/s"
    d = 0.1u"hr"

    @constraint(model, (x - a)^2 <= b^2)
    @constraint(model, y - 1 / v * x <= d)
    obj = x^2 / v^2 + y^2
    @objective(model, Max, obj)
    optimize!(model)
    @test value(x) ≈ 2.6524u"m"
    @test value(y) ≈ 360.88414u"s"
    @test objective_value(model) ≈ 130238.14198
    @test value(obj) ≈ 130238.14198u"s^2"
    return
end

test_quad_example()
