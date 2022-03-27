m = Model()

@variable(m, x ≥ 0)
@variable(m, y)

xu = UnitJuMP.UnitVariableRef(x, u"m/s")
yu = UnitJuMP.UnitVariableRef(y, u"km/hr")

@test _MA.@rewrite(xu) == UnitJuMP.UnitAffExpr(1x, u"m/s")
@test _MA.@rewrite(-xu) == UnitJuMP.UnitAffExpr(-x, u"m/s")
@test _MA.@rewrite(5xu) == UnitJuMP.UnitAffExpr(5x, u"m/s")
@test _MA.@rewrite(xu / 5) == UnitJuMP.UnitAffExpr(0.2x, u"m/s")

@test _MA.@rewrite(xu + yu) == UnitJuMP.UnitAffExpr(x + y / 3.6, u"m/s")
@test _MA.@rewrite(xu - yu) == UnitJuMP.UnitAffExpr(x - y / 3.6, u"m/s")
@test _MA.@rewrite(-xu + yu) == UnitJuMP.UnitAffExpr(-x + y / 3.6, u"m/s")

speed = 10u"m/s"
@test _MA.@rewrite(speed * x) == UnitJuMP.UnitAffExpr(10x, u"m/s")
@test _MA.@rewrite(x * speed) == UnitJuMP.UnitAffExpr(10x, u"m/s")
@test _MA.@rewrite(speed * xu) == UnitJuMP.UnitAffExpr(10x, u"m^2/s^2")
@test _MA.@rewrite(xu * speed) == UnitJuMP.UnitAffExpr(10x, u"m^2/s^2")
@test _MA.@rewrite(x / speed) == UnitJuMP.UnitAffExpr(0.1x, u"s/m")
