# Support the use of qudratic expressions during rewrite  
# with MutableArithmetics 

const UnitQuadExpr{U} = UnitExpression{QuadExpr,U}

UnitQuadExpr(quad::QuadExpr, unit::U) where {U} = UnitExpression(quad, unit)

# Zero handling

# Two arguments
function _create_expression(
    t::_AddSub,
    z::typeof(_MA.Zero()),
    x::UnitAffExpr,
    y::UnitAffExpr,
)
    xu = Unitful.Quantity(1, x.unit)
    yu = Unitful.Quantity(1, y.unit)
    return UnitQuadExpr(
        _MA.operate!!(t, z, x.expr, y.expr),
        Unitful.unit(xu * yu),
    )
end

function _create_expression(
    t::_AddSub,
    z::typeof(_MA.Zero()),
    x::UnitAffExpr,
    y::AffExpr,
)
    return UnitQuadExpr(_MA.operate!!(t, z, x.expr, y), x.unit)
end

# UnitVariableRef * UnitVariableRef
function _MA.operate!!(
    t::_AddSub,
    z::_MA.Zero,
    x::UnitVariableRef,
    y::UnitVariableRef,
)
    return _create_expression(
        t,
        z,
        convert(UnitAffExpr, x),
        convert(UnitAffExpr, y),
    )
end

# UnitVariableRef * VariableRef
function _MA.operate!!(
    t::_AddSub,
    z::_MA.Zero,
    x::UnitVariableRef,
    y::VariableRef,
)
    return _create_expression(
        t,
        z,
        convert(UnitAffExpr, x),
        convert(AffExpr, y),
    )
end

function _MA.operate!!(
    t::_AddSub,
    z::_MA.Zero,
    x::VariableRef,
    y::UnitVariableRef,
)
    return _create_expression(
        t,
        z,
        convert(UnitAffExpr, y),
        convert(AffExpr, x),
    )
end

# UnitVariableRef * UnitAffExpr
function _MA.operate!!(
    t::_AddSub,
    z::_MA.Zero,
    x::UnitVariableRef,
    y::UnitAffExpr,
)
    return _create_expression(t, z, convert(UnitAffExpr, x), y)
end

function _MA.operate!!(
    t::_AddSub,
    z::_MA.Zero,
    x::UnitAffExpr,
    y::UnitVariableRef,
)
    return _create_expression(t, z, convert(UnitAffExpr, y), x)
end

# UnitVariableRef * AffExpr
function _MA.operate!!(t::_AddSub, z::_MA.Zero, x::UnitVariableRef, y::AffExpr)
    return _create_expression(t, z, convert(UnitAffExpr, x), y)
end

function _MA.operate!!(t::_AddSub, z::_MA.Zero, x::AffExpr, y::UnitVariableRef)
    return _create_expression(t, z, convert(UnitAffExpr, y), x)
end

# UnitAffExpr * UnitAffExpr
function _MA.operate!!(t::_AddSub, z::_MA.Zero, x::UnitAffExpr, y::UnitAffExpr)
    return _create_expression(t, z, x, y)
end

# UnitAffExpr * AffExpr
function _MA.operate!!(t::_AddSub, z::_MA.Zero, x::UnitAffExpr, y::AffExpr)
    return _create_expression(t, z, x, y)
end

function _MA.operate!!(t::_AddSub, z::_MA.Zero, x::AffExpr, y::UnitAffExpr)
    return _create_expression(t, z, y, x)
end

# UnitAffExpr * VariableRef
function _MA.operate!!(t::_AddSub, z::_MA.Zero, x::UnitAffExpr, y::VariableRef)
    return _create_expression(t, z, x, convert(AffExpr, y))
end

function _MA.operate!!(t::_AddSub, z::_MA.Zero, x::VariableRef, y::UnitAffExpr)
    return _create_expression(t, z, y, convert(AffExpr, x))
end

# Quantity * QuadExpr
function _MA.operate!!(
    t::_AddSub,
    z::_MA.Zero,
    x::Unitful.Quantity,
    y::QuadExpr,
)
    return UnitQuadExpr(
        _MA.operate!!(t, z, Unitful.ustrip(x), y),
        Unitful.unit(x),
    )
end

function _MA.operate!!(
    t::_AddSub,
    z::_MA.Zero,
    x::QuadExpr,
    y::Unitful.Quantity,
)
    return UnitQuadExpr(
        _MA.operate!!(t, z, x, Unitful.ustrip(y)),
        Unitful.unit(y),
    )
end

# Update expressions

function _update_expression(uexpr::UnitQuadExpr, ux::UnitExpression)
    factor = Unitful.ustrip(
        Unitful.uconvert(uexpr.unit, Unitful.Quantity(1, ux.unit)),
    )
    return UnitQuadExpr(
        JuMP.add_to_expression!(uexpr.expr, factor * ux.expr),
        uexpr.unit,
    )
end

function _update_expression(uexpr::UnitAffExpr, ux::UnitQuadExpr)
    factor = Unitful.ustrip(
        Unitful.uconvert(uexpr.unit, Unitful.Quantity(1, ux.unit)),
    )
    return UnitQuadExpr(
        JuMP.add_to_expression!(factor * ux.expr, uexpr.expr),
        uexpr.unit,
    )
end

# UnitQuadExpr -- UnitVariableRef
function _MA.operate!!(
    _::typeof(_MA.add_mul),
    uqad::UnitQuadExpr,
    x::UnitVariableRef,
)
    return _update_expression(uqad, convert(UnitAffExpr, x))
end
function _MA.operate!!(
    _::typeof(_MA.sub_mul),
    uqad::UnitQuadExpr,
    x::UnitVariableRef,
)
    return _update_expression(uqad, -convert(UnitAffExpr, x))
end

# UnitQuadExpr -- UnitQuadExpr
function _MA.operate!!(
    ::typeof(_MA.add_mul),
    uqad::UnitQuadExpr,
    x::UnitQuadExpr,
)
    return _update_expression(uqad, x)
end
function _MA.operate!!(
    ::typeof(_MA.sub_mul),
    uqad::UnitQuadExpr,
    x::UnitQuadExpr,
)
    return _update_expression(uqad, -x)
end

# UnitQuadExpr -- UnitAffExpr
function _MA.operate!!(
    _::typeof(_MA.add_mul),
    uqad::UnitQuadExpr,
    x::UnitAffExpr,
)
    return _update_expression(uqad, x)
end
function _MA.operate!!(
    _::typeof(_MA.sub_mul),
    uqad::UnitQuadExpr,
    x::UnitAffExpr,
)
    return _update_expression(uqad, -x)
end
function _MA.operate!!(
    _::typeof(_MA.add_mul),
    x::UnitAffExpr,
    uquad::UnitQuadExpr,
)
    return _update_expression(x, uquad)
end
function _MA.operate!!(
    _::typeof(_MA.sub_mul),
    x::UnitAffExpr,
    uquad::UnitQuadExpr,
)
    return _update_expression(x, -uquad)
end

# UnitQuadExpr -- Quantity
function _MA.operate!!(::typeof(_MA.add_mul), uqad::UnitQuadExpr, a::Quantity)
    aval = Unitful.ustrip(Unitful.uconvert(uqad.unit, a))
    return UnitQuadExpr(JuMP.add_to_expression!(uqad.expr, aval), uqad.unit)
end
function _MA.operate!!(::typeof(_MA.sub_mul), uqad::UnitQuadExpr, a::Quantity)
    aval = Unitful.ustrip(Unitful.uconvert(uqad.unit, a))
    return UnitQuadExpr(JuMP.add_to_expression!(uqad.expr, -aval), uqad.unit)
end

# Three arguments

function _update_expression(
    uexpr::UnitQuadExpr,
    a::_NumQuant,
    ux::UnitExpression,
)
    aval = Unitful.ustrip(
        Unitful.uconvert(uexpr.unit, a * Unitful.Quantity(1, ux.unit)),
    )
    return UnitQuadExpr(
        JuMP.add_to_expression!(uexpr.expr, aval * ux.expr),
        uexpr.unit,
    )
end

_AffQuadExpr = Union{AffExpr,QuadExpr}

function _update_expression(
    uexpr::UnitQuadExpr,
    a::Unitful.Quantity,
    ux::_AffQuadExpr,
)
    aval = Unitful.ustrip(Unitful.uconvert(uexpr.unit, a))
    return UnitQuadExpr(
        JuMP.add_to_expression!(uexpr.expr, aval * ux),
        uexpr.unit,
    )
end

function _update_expression(
    uexpr::UnitAffExpr,
    a::_NumQuant,
    uquad::UnitQuadExpr,
)
    aval = Unitful.ustrip(
        Unitful.uconvert(uexpr.unit, a * Unitful.Quantity(1, uquad.unit)),
    )
    return UnitQuadExpr(
        JuMP.add_to_expression!(aval * uquad.expr, uexpr.expr),
        uexpr.unit,
    )
end

# UnitQuadExpr -- Quantity * VariableRef
function _MA.operate!!(
    _::typeof(_MA.add_mul),
    uquad::UnitQuadExpr,
    a::Quantity,
    x::VariableRef,
)
    return _update_expression(uquad, a, convert(AffExpr, x))
end
function _MA.operate!!(
    _::typeof(_MA.sub_mul),
    uquad::UnitQuadExpr,
    a::Quantity,
    x::VariableRef,
)
    return _update_expression(uquad, -a, convert(AffExpr, x))
end

# UnitQuadExpr -- Number/Quantity * UnitVariableRef
function _MA.operate!!(
    _::typeof(_MA.add_mul),
    uquad::UnitQuadExpr,
    a::_NumQuant,
    x::UnitVariableRef,
)
    return _update_expression(uquad, a, convert(UnitAffExpr, x))
end
function _MA.operate!!(
    _::typeof(_MA.sub_mul),
    uquad::UnitQuadExpr,
    a::_NumQuant,
    x::UnitVariableRef,
)
    return _update_expression(uquad, -a, convert(UnitAffExpr, x))
end

# UnitQuadExpr -- Quantity * AffExpr/QuadExpr
function _MA.operate!!(
    _::typeof(_MA.add_mul),
    uquad::UnitQuadExpr,
    a::Quantity,
    x::_AffQuadExpr,
)
    return _update_expression(uquad, a, x)
end
function _MA.operate!!(
    _::typeof(_MA.sub_mul),
    uquad::UnitQuadExpr,
    a::Quantity,
    x::_AffQuadExpr,
)
    return _update_expression(uquad, -a, x)
end

# UnitQuadExpr -- Number/Quantity * UnitExpression
function _MA.operate!!(
    _::typeof(_MA.add_mul),
    uquad::UnitQuadExpr,
    a::_NumQuant,
    x::UnitExpression,
)
    return _update_expression(uquad, a, x)
end
function _MA.operate!!(
    _::typeof(_MA.sub_mul),
    uquad::UnitQuadExpr,
    a::_NumQuant,
    x::UnitExpression,
)
    return _update_expression(uquad, -a, x)
end

# UnitAffExpr -- Number/Quantity * UnitQuadExpr
function _MA.operate!!(
    _::typeof(_MA.add_mul),
    uex::UnitAffExpr,
    a::_NumQuant,
    uquad::UnitQuadExpr,
)
    return _update_expression(uex, a, uquad)
end
function _MA.operate!!(
    _::typeof(_MA.sub_mul),
    uex::UnitAffExpr,
    a::_NumQuant,
    uquad::UnitQuadExpr,
)
    return _update_expression(uex, -a, uquad)
end

# UnitAffExpr -- UnitVariableRef * UnitVariableRef
function _MA.operate!!(
    _::typeof(_MA.add_mul),
    uex::UnitAffExpr,
    uvar1::UnitVariableRef,
    uvar2::UnitVariableRef,
)
    return _update_expression(uex, 1, uvar1 * uvar2)
end
function _MA.operate!!(
    _::typeof(_MA.sub_mul),
    uex::UnitAffExpr,
    uvar1::UnitVariableRef,
    uvar2::UnitVariableRef,
)
    return _update_expression(uex, -1, uvar1 * uvar2)
end

# UnitAffExpr -- VariableRef * UnitVariableRef
function _MA.operate!!(
    _::typeof(_MA.add_mul),
    uex::UnitAffExpr,
    var::VariableRef,
    uvar::UnitVariableRef,
)
    return _update_expression(uex, 1, var * uvar)
end
function _MA.operate!!(
    _::typeof(_MA.sub_mul),
    uex::UnitAffExpr,
    var::VariableRef,
    uvar::UnitVariableRef,
)
    return _update_expression(uex, -1, var * uvar)
end

# Multiple arguments
