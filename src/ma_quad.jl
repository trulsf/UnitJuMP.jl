# Implement the MutableArithmetics API for UnitQuadExpr

const UnitQuadExpr{U} = UnitExpression{QuadExpr,U}

UnitQuadExpr(quad::QuadExpr, unit::U) where {U} = UnitExpression(quad, unit)

function _MA.operate!!(t::typeof(_MA.add_mul), z::_MA.Zero, x::UnitVariableRef, y::UnitVariableRef)
    xu = Unitful.Quantity(1, x.unit)
    yu = Unitful.Quantity(1, y.unit)
    return UnitQuadExpr(
        _MA.operate!!(t, z, x.variable, y.variable),
        Unitful.unit(xu*yu),
    )
end

function _MA.operate!!(::typeof(_MA.sub_mul), uqad::UnitQuadExpr, a::_NumQuant)
    aval = Unitful.ustrip(Unitful.uconvert(uqad.unit, a))
    return UnitQuadExpr(JuMP.add_to_expression!(uqad.expr, -aval), uqad.unit)
end