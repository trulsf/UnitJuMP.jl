# Implement the MutableArithmetics API for UnitAffExpr

const UnitAffExpr{U} = UnitExpression{AffExpr,U}

UnitAffExpr(aff::AffExpr, unit::U) where {U} = UnitExpression(aff, unit)

_MA.mutability(::Type{UnitAffExpr}) = _MA.IsMutable()

#  Minimal support of operate!! to allow @rewrite macro to work on linear
# constraints

_UnitAffOrVar = Union{UnitVariableRef,UnitAffExpr}
_AffOrVar = Union{AffExpr,VariableRef}
_AddSub = Union{typeof(_MA.add_mul),typeof(_MA.sub_mul)}
_NumQuant = Union{Number,Unitful.Quantity}

function Base.convert(::Type{UnitAffExpr}, uv::UnitVariableRef)
    return UnitAffExpr(convert(AffExpr, uv.variable), uv.unit)
end

function _update_expression(ua::UnitAffExpr, a::_NumQuant, x::UnitVariableRef)
    aval = Unitful.ustrip(
        Unitful.uconvert(ua.unit, a * Unitful.Quantity(1, x.unit)),
    )
    return UnitAffExpr(
        JuMP.add_to_expression!(ua.expr, aval, x.variable),
        ua.unit,
    )
end

function _update_expression(ua::UnitAffExpr, a::Unitful.Quantity, x::_AffOrVar)
    aval = Unitful.ustrip(Unitful.uconvert(ua.unit, a))
    return UnitAffExpr(JuMP.add_to_expression!(ua.expr, aval, x), ua.unit)
end

function _update_expression(ua::UnitAffExpr, a::Unitful.Quantity)
    aval = Unitful.ustrip(Unitful.uconvert(ua.unit, a))
    return UnitAffExpr(JuMP.add_to_expression!(ua.expr, aval), ua.unit)
end

function _update_expression(ua::UnitAffExpr, a::_NumQuant, x::UnitAffExpr)
    factor = Unitful.ustrip(
        Unitful.uconvert(ua.unit, a * Unitful.Quantity(1, x.unit)),
    )
    return UnitAffExpr(
        JuMP.add_to_expression!(ua.expr, factor, x.expr),
        ua.unit,
    )
end

function _update_expression(ua::UnitAffExpr, a::_NumQuant, b::_NumQuant)
    aval = Unitful.ustrip(Unitful.uconvert(ua.unit, a * b))
    return UnitAffExpr(JuMP.add_to_expression!(ua.expr, aval), ua.unit)
end

function _create_expression(
    t::_AddSub,
    z::typeof(_MA.Zero()),
    a::_NumQuant,
    x::UnitVariableRef,
)
    val = a * Unitful.Quantity(1, x.unit)
    return UnitAffExpr(
        _MA.operate!!(t, z, Unitful.ustrip(val), x.variable),
        Unitful.unit(val),
    )
end

function _create_expression(
    t::_AddSub,
    z::typeof(_MA.Zero()),
    a::Unitful.Quantity,
    x::VariableRef,
)
    return UnitAffExpr(
        _MA.operate!!(t, z, Unitful.ustrip(a), x),
        Unitful.unit(a),
    )
end

function _create_expression(
    t::_AddSub,
    z::typeof(_MA.Zero()),
    a::Unitful.Quantity,
)
    return UnitAffExpr(
        convert(AffExpr, _MA.operate!!(t, z, Unitful.ustrip(a))),
        Unitful.unit(a),
    )
end

# Two arguments
function _MA.operate!!(
    ::typeof(_MA.add_mul),
    uav::_UnitAffOrVar,
    x::UnitVariableRef,
)
    return _update_expression(convert(UnitAffExpr, uav), 1, x)
end

function _MA.operate!!(
    ::typeof(_MA.sub_mul),
    uav::_UnitAffOrVar,
    x::UnitVariableRef,
)
    return _update_expression(convert(UnitAffExpr, uav), -1, x)
end

function _MA.operate!!(
    ::typeof(_MA.add_mul),
    uav::_UnitAffOrVar,
    x::UnitAffExpr,
)
    return _update_expression(convert(UnitAffExpr, uav), 1, x)
end

function _MA.operate!!(
    ::typeof(_MA.sub_mul),
    uav::_UnitAffOrVar,
    x::UnitAffExpr,
)
    return _update_expression(convert(UnitAffExpr, uav), -1, x)
end

function _MA.operate!!(
    ::typeof(_MA.add_mul),
    uav::_UnitAffOrVar,
    a::Unitful.Quantity,
)
    return _update_expression(convert(UnitAffExpr, uav), a)
end

function _MA.operate!!(
    ::typeof(_MA.sub_mul),
    uav::_UnitAffOrVar,
    a::Unitful.Quantity,
)
    return _update_expression(convert(UnitAffExpr, uav), -a)
end

function _MA.operate!!(::_AddSub, ::_UnitAffOrVar, ::_AffOrVar)
    return error(
        "Can not combine variables with and without units in the samme expression",
    )
end

function _MA.operate!!(::_AddSub, ::_AffOrVar, ::_UnitAffOrVar)
    return error(
        "Can not combine variables with and without units in the samme expression",
    )
end

function _MA.operate!!(::_AddSub, ::_UnitAffOrVar, ::Real)
    return error("Can not combine unit expression with numbers without units")
end

function _MA.operate!!(::_AddSub, ::_AffOrVar, ::Unitful.Quantity)
    return error("Can not combine unit parameters with variables without units")
end

# Three arguments
function _MA.operate!!(
    ::typeof(_MA.add_mul),
    uav::_UnitAffOrVar,
    a::_NumQuant,
    x::_UnitAffOrVar,
)
    return _update_expression(
        convert(UnitAffExpr, uav),
        a,
        convert(UnitAffExpr, x),
    )
end

function _MA.operate!!(
    ::typeof(_MA.sub_mul),
    uav::_UnitAffOrVar,
    a::_NumQuant,
    x::_UnitAffOrVar,
)
    return _update_expression(
        convert(UnitAffExpr, uav),
        -a,
        convert(UnitAffExpr, x),
    )
end

function _MA.operate!!(
    ::typeof(_MA.add_mul),
    uav::_UnitAffOrVar,
    a::Unitful.Quantity,
    x::_AffOrVar,
)
    return _update_expression(convert(UnitAffExpr, uav), a, x)
end

function _MA.operate!!(
    ::typeof(_MA.sub_mul),
    uav::_UnitAffOrVar,
    a::Unitful.Quantity,
    x::_AffOrVar,
)
    return _update_expression(convert(UnitAffExpr, uav), -a, x)
end

function _MA.operate!!(
    ::typeof(_MA.add_mul),
    uav::_UnitAffOrVar,
    a::_NumQuant,
    b::_NumQuant,
)
    return _update_expression(convert(UnitAffExpr, uav), a, b)
end

function _MA.operate!!(
    ::typeof(_MA.sub_mul),
    uav::_UnitAffOrVar,
    a::_NumQuant,
    b::_NumQuant,
)
    return _update_expression(convert(UnitAffExpr, uav), -a, b)
end

function _MA.operate!!(
    ::typeof(_MA.add_mul),
    uav::_UnitAffOrVar,
    a::Number,
    b::Unitful.Units,
)
    return _update_expression(
        convert(UnitAffExpr, uav),
        a * Unitful.Quantity(1.0, b),
    )
end

function _MA.operate!!(
    ::typeof(_MA.sub_mul),
    uav::_UnitAffOrVar,
    a::Number,
    b::Unitful.Units,
)
    return _update_expression(
        convert(UnitAffExpr, uav),
        -a * Unitful.Quantity(1.0, b),
    )
end

function _MA.operate!!(::_AddSub, ::_UnitAffOrVar, ::Real, ::VariableRef)
    return error(
        "Can not combine variables with and without units in the samme expression",
    )
end

function _MA.operate!!(::_AddSub, ::_AffOrVar, ::_NumQuant, ::UnitVariableRef)
    return error(
        "Can not combine variables with and without units in the samme expression",
    )
end

function _MA.operate!!(
    ::_AddSub,
    ::_AffOrVar,
    ::Unitful.Quantity,
    ::VariableRef,
)
    return error(
        "Can not combine variables with and without units in the samme expression",
    )
end

# Multiple arguments
function _MA.operate!!(t::_AddSub, uav::_UnitAffOrVar, x, y, z, other_args...)
    args = (x, y, z, other_args...)
    n = length(args)
    varidx = findall(
        t ->
            (typeof(t) <: UnitAffExpr) ||
                (typeof(t) <: UnitVariableRef) ||
                (typeof(t) <: VariableRef),
        args,
    )
    var = args[varidx[1]]
    val = prod(args[i] for i in setdiff(1:n, varidx))
    return _MA.operate!!(t, uav, val, var)
end

# Zero handling
function _MA.operate!!(t::_AddSub, z::_MA.Zero, a::Unitful.Quantity)
    return _create_expression(t, z, a)
end

function _MA.operate!!(t::_AddSub, z::_MA.Zero, x::UnitVariableRef)
    return _create_expression(t, z, 1, x)
end

_MA.operate!!(::_AddSub, ::_MA.Zero, ua::UnitExpression) = ua

function _MA.operate!!(
    t::_AddSub,
    z::_MA.Zero,
    a::_NumQuant,
    x::UnitVariableRef,
)
    return _create_expression(t, z, a, x)
end

function _MA.operate!!(
    t::_AddSub,
    z::_MA.Zero,
    x::UnitVariableRef,
    a::_NumQuant,
)
    return _create_expression(t, z, a, x)
end

function _MA.operate!!(
    t::_AddSub,
    z::_MA.Zero,
    a::Unitful.Quantity,
    x::VariableRef,
)
    return _create_expression(t, z, a, x)
end

function _MA.operate!!(
    t::_AddSub,
    z::_MA.Zero,
    x::VariableRef,
    a::Unitful.Quantity,
)
    return _create_expression(t, z, a, x)
end

function _MA.operate!!(t::_AddSub, zero::_MA.Zero, x, y, z, other_args...)
    args = (x, y, z, other_args...)
    n = length(args)
    varidx = findall(
        t ->
            (typeof(t) <: UnitExpression) ||
                (typeof(t) <: UnitVariableRef) ||
                (typeof(t) <: VariableRef) ||
                (typeof(t) <: QuadExpr),
        args,
    )
    var = args[varidx[1]]
    val = prod(args[i] for i in setdiff(1:n, varidx))
    return _MA.operate!!(t, zero, val, var)
end
