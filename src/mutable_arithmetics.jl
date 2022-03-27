# Implemment the mutable arithmetics interface for UnitAffExpr

_MA.mutability(::Type{UnitAffExpr}) = _MA.IsMutable()

#  Minimal support of operate!! to allow @rewrite macro to work on linear
# constraints

_UnitAffOrVar = Union{UnitVariableRef,UnitAffExpr}
_AddSub = Union{typeof(_MA.add_mul),typeof(_MA.sub_mul)}
_NumQuant = Union{Number,Unitful.Quantity}

function Base.convert(::Type{UnitAffExpr}, uv::UnitVariableRef)
    return UnitAffExpr(convert(AffExpr, uv.vref), uv.u)
end

function _update_expression(ua::UnitAffExpr, a::_NumQuant, x::UnitVariableRef)
    aval = Unitful.ustrip(Unitful.uconvert(ua.u, a * Unitful.Quantity(1, x.u)))
    return UnitAffExpr(JuMP.add_to_expression!(ua.expr, aval, x.vref), ua.u)
end

function _update_expression(
    ua::UnitAffExpr,
    a::Unitful.Quantity,
    x::VariableRef,
)
    aval = Unitful.ustrip(Unitful.uconvert(ua.u, a))
    return UnitAffExpr(JuMP.add_to_expression!(ua.expr, aval, x), ua.u)
end

function _update_expression(ua::UnitAffExpr, a::Unitful.Quantity)
    aval = Unitful.ustrip(Unitful.uconvert(ua.u, a))
    return UnitAffExpr(JuMP.add_to_expression!(ua.expr, aval), ua.u)
end

function _update_expression(ua::UnitAffExpr, x::UnitAffExpr)
    factor = Unitful.ustrip(Unitful.uconvert(ua.u, Unitful.Quantity(1, x.u)))
    return UnitAffExpr(JuMP.add_to_expression!(ua.expr, factor, x.expr), ua.u)
end

function _update_expression(ua::UnitAffExpr, a::_NumQuant, b::_NumQuant)
    aval = Unitful.ustrip(Unitful.uconvert(ua.u, a * b))
    return UnitAffExpr(JuMP.add_to_expression!(ua.expr, aval), ua.u)
end

function _create_expression(
    t::_AddSub,
    z::typeof(_MA.Zero()),
    a::_NumQuant,
    x::UnitVariableRef,
)
    val = a * Unitful.Quantity(1, x.u)
    return UnitAffExpr(
        _MA.operate!!(t, z, Unitful.ustrip(val), x.vref),
        Unitful.Unitful.unit(val),
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
        Unitful.Unitful.unit(a),
    )
end

function _create_expression(
    t::_AddSub,
    z::typeof(_MA.Zero()),
    a::Unitful.Quantity,
)
    return UnitAffExpr(
        _MA.operate!!(t, z, Unitful.ustrip(a)),
        Unitful.Unitful.unit(a),
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
    return _update_expression(convert(UnitAffExpr, uav), x)
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

# Three arguments
function _MA.operate!!(
    ::typeof(_MA.add_mul),
    uav::_UnitAffOrVar,
    a::_NumQuant,
    x::UnitVariableRef,
)
    return _update_expression(convert(UnitAffExpr, uav), a, x)
end

function _MA.operate!!(
    ::typeof(_MA.sub_mul),
    uav::_UnitAffOrVar,
    a::_NumQuant,
    x::UnitVariableRef,
)
    return _update_expression(convert(UnitAffExpr, uav), -a, x)
end

function _MA.operate!!(
    ::typeof(_MA.add_mul),
    uav::_UnitAffOrVar,
    a::Unitful.Quantity,
    x::VariableRef,
)
    return _update_expression(convert(UnitAffExpr, uav), a, x)
end

function _MA.operate!!(
    ::typeof(_MA.sub_mul),
    uav::_UnitAffOrVar,
    a::Unitful.Quantity,
    x::VariableRef,
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

# Multiple arguments
function _MA.operate!!(t::_AddSub, uav::_UnitAffOrVar, x, y, z, other_args...)
    args = [x, y, z, other_args...]
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

_MA.operate!!(::_AddSub, ::_MA.Zero, ua::UnitAffExpr) = ua

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
    args = [x, y, z, other_args...]
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
    return _MA.operate!!(t, zero, val, var)
end
