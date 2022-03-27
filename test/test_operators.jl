m = Model()

@variable(m, x)
@variable(m, y)
@variable(m, z)

xu = UnitJuMP.UnitVariableRef(x, u"km")
yu = UnitJuMP.UnitVariableRef(y, u"hr")
zu = UnitJuMP.UnitVariableRef(z, u"s")

@test -xu == UnitJuMP.UnitAffExpr(-x, u"km")
@test xu + 200u"m" == UnitJuMP.UnitAffExpr(x + 0.2, u"km")
@test 200u"m" + xu == UnitJuMP.UnitAffExpr(1000x + 200, u"m")
@test xu - 400u"m" == UnitJuMP.UnitAffExpr(x - 0.4, u"km")
@test 400u"m" - xu == UnitJuMP.UnitAffExpr(-1000x + 400, u"m")

@test 200u"km" * x == UnitJuMP.UnitAffExpr(200 * x, u"km")
@test 200 * xu == UnitJuMP.UnitAffExpr(200 * x, u"km")
@test 1.5u"s" * xu == UnitJuMP.UnitAffExpr(1.5 * x, u"s*km")

@test xu / 0.5 == UnitJuMP.UnitAffExpr(2 * x, u"km")
@test x / 0.5u"s" == UnitJuMP.UnitAffExpr(2 * x, u"s^-1")
@test xu / 0.5u"s" == UnitJuMP.UnitAffExpr(2 * x, u"km/s")

@test yu + zu == UnitJuMP.UnitAffExpr(y + z / 3600, u"hr")
@test yu - zu == UnitJuMP.UnitAffExpr(y - z / 3600, u"hr")

expr = yu + 1800 * zu

@test expr + 3600u"s" == UnitJuMP.UnitAffExpr(y + 0.5z + 1, u"hr")
@test expr - 1800u"s" == UnitJuMP.UnitAffExpr(y + 0.5z - 0.5, u"hr")
@test 2u"s" + expr == UnitJuMP.UnitAffExpr(3600y + 1800z + 2, u"s")
@test 3600u"s" - expr == UnitJuMP.UnitAffExpr(-3600y - 1800z + 3600, u"s")

@test 2 * expr == UnitJuMP.UnitAffExpr(2y + z, u"hr")
@test expr / 0.5 == UnitJuMP.UnitAffExpr(2y + z, u"hr")
@test 2u"kW" * expr == UnitJuMP.UnitAffExpr(2y + z, u"kW*hr")
@test expr / 0.5u"km" == UnitJuMP.UnitAffExpr(2y + z, u"hr/km")

@variable(m, w)
wu = UnitJuMP.UnitVariableRef(w, u"minute")

@test expr + wu == UnitJuMP.UnitAffExpr(y + 0.5z + w / 60, u"hr")
@test expr - wu == UnitJuMP.UnitAffExpr(y + 0.5z - w / 60, u"hr")
@test wu + expr == UnitJuMP.UnitAffExpr(60y + 30z + w, u"minute")
@test wu - expr == UnitJuMP.UnitAffExpr(-60y - 30z + w, u"minute")
@test expr + yu == UnitJuMP.UnitAffExpr(2y + 0.5z, u"hr")

expr2 = 30wu + yu

@test expr + expr2 == UnitJuMP.UnitAffExpr(2y + 0.5z + 0.5w, u"hr")
@test expr2 + expr == UnitJuMP.UnitAffExpr(120y + 30z + 30w, u"minute")
@test 2 * expr - expr2 == UnitJuMP.UnitAffExpr(y + z - 0.5w, u"hr")
