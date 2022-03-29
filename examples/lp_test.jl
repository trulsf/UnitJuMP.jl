using UnitJuMP
using Test
import HiGHS

function test_simple_example()
    model = Model(HiGHS.Optimizer)
    max_speed = 2u"m/s"
    a = 9.8u"ft/s^2"
    M = 0.5u"m/s"
    no_speed = 0.0u"m/s"
    data = 4
    @variables(model, begin
        x >= 0, u"m/s"
        y >= 0, u"s"
        z >= 0, u"km/s"
        v[1:4], u"m/s"
        w, Bin
    end)
    @constraints(model, begin
        x + a * y <= max_speed
        z + x <= max_speed
        x + 0.5 * a * y <= max_speed
        x <= M * w
        -3x + 2z <= no_speed
        x == 0.15 * max_speed
        con7[i = 1:4], v[i] <= max_speed
        con8, sum(v[i] for i in 1:3) <= max_speed, u"ft/s"
        -3 * data * x + 2z <= no_speed
    end)
    @objective(model, Max, x + 0.2 * z)
    optimize!(model)
    @test value(x) == 0.3u"m/s"
    @test value(y) == 0.0u"s"
    @test value(z) ≈ 0.00045u"km/s"
    return
end

test_simple_example()
