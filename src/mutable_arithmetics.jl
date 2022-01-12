import MathOptInterface
MOI = MathOptInterface

import MutableArithmetics
_MA = MutableArithmetics


# Implemment the mutable arithmetics interface for UnitAffExpr

_MA.mutability(::Type{UnitAffExpr}) = _MA.IsMutable()


#  Minimal support of operate!! to allow @rewrite macro to work on linear constraints

UnitAffOrVar = Union{UnitVariableRef, UnitAffExpr}
AddSub = Union{typeof(_MA.add_mul), typeof(_MA.sub_mul)}
NumQuant = Union{Number, Quantity}

function Base.convert(::Type{UnitAffExpr}, uv::UnitVariableRef)
    return UnitAffExpr(convert(AffExpr, uv.vref), uv.u)
end

function update_expression!(ua::UnitAffExpr, a::NumQuant, x::UnitVariableRef)
    aval = ustrip(uconvert(ua.u, a * Quantity(1, x.u)))
    return UnitAffExpr(add_to_expression!(ua.expr, aval, x.vref), ua.u)
end

function update_expression!(ua::UnitAffExpr, a::Quantity, x::VariableRef)
    aval = ustrip(uconvert(ua.u, a))
    return UnitAffExpr(add_to_expression!(ua.expr, aval, x), ua.u)
end

function update_expression!(ua::UnitAffExpr, a::Quantity)
    aval = ustrip(uconvert(ua.u, a))
    return UnitAffExpr(add_to_expression!(ua.expr, aval), ua.u)
end

function update_expression!(ua::UnitAffExpr, x::UnitAffExpr)
    factor = ustrip(uconvert(ua.u, Quantity(1, x.u)))
    return UnitAffExpr(add_to_expression!(ua.expr, factor, x.expr), ua.u)
end

function update_expression!(ua::UnitAffExpr, a::NumQuant, b::NumQuant)
    aval = ustrip(uconvert(ua.u, a * b))
    return UnitAffExpr(add_to_expression!(ua.expr, aval), ua.u)
end

function create_expression(t::AddSub, z::typeof(_MA.Zero()), a::NumQuant, x::UnitVariableRef)
    val = a * Quantity(1, x.u)
    return UnitAffExpr(_MA.operate!!(t, z, ustrip(val), x.vref), Unitful.unit(val))
end

function create_expression(t::AddSub, z::typeof(_MA.Zero()), a::Quantity, x::VariableRef)
    return UnitAffExpr(_MA.operate!!(t, z, ustrip(a), x), Unitful.unit(a))
end

function create_expression(t::AddSub, z::typeof(_MA.Zero()), a::Quantity)
    return UnitAffExpr(_MA.operate!!(t, z, ustrip(a)), Unitful.unit(a))
end

# Two arguments
_MA.operate!!(::typeof(_MA.add_mul), uav::UnitAffOrVar, x::UnitVariableRef) = update_expression!(Base.convert(UnitAffExpr, uav), 1, x)
_MA.operate!!(::typeof(_MA.sub_mul), uav::UnitAffOrVar, x::UnitVariableRef) = update_expression!(Base.convert(UnitAffExpr, uav), -1, x)

_MA.operate!!(::typeof(_MA.add_mul), uav::UnitAffOrVar, x::UnitAffExpr) = update_expression!(Base.convert(UnitAffExpr, uav), x)
_MA.operate!!(::typeof(_MA.sub_mul), uav::UnitAffOrVar, x::UnitAffExpr) = update_expression!(Base.convert(UnitAffExpr, uav), -1, x)

_MA.operate!!(::typeof(_MA.add_mul), uav::UnitAffOrVar, a::Quantity) = update_expression!(Base.convert(UnitAffExpr, uav), a)
_MA.operate!!(::typeof(_MA.sub_mul), uav::UnitAffOrVar, a::Quantity) = update_expression!(Base.convert(UnitAffExpr, uav), -a)

# Three arguments
_MA.operate!!(::typeof(_MA.add_mul), uav::UnitAffOrVar, a::NumQuant, x::UnitVariableRef) = update_expression!(Base.convert(UnitAffExpr, uav), a, x)
_MA.operate!!(::typeof(_MA.sub_mul), uav::UnitAffOrVar, a::NumQuant, x::UnitVariableRef) = update_expression!(Base.convert(UnitAffExpr, uav), -a, x)

_MA.operate!!(::typeof(_MA.add_mul), uav::UnitAffOrVar, a::Quantity, x::VariableRef) = update_expression!(Base.convert(UnitAffExpr, uav), a, x)
_MA.operate!!(::typeof(_MA.sub_mul), uav::UnitAffOrVar, a::Quantity, x::VariableRef) = update_expression!(Base.convert(UnitAffExpr, uav), -a, x)

_MA.operate!!(::typeof(_MA.add_mul), uav::UnitAffOrVar, a::NumQuant, b::NumQuant) = update_expression!(Base.convert(UnitAffExpr, uav), a, b)
_MA.operate!!(::typeof(_MA.sub_mul), uav::UnitAffOrVar, a::NumQuant, b::NumQuant) = update_expression!(Base.convert(UnitAffExpr, uav), a, b)

# Multiple arguments
function _MA.operate!!(t::AddSub, uav::UnitAffOrVar, x, y, z, other_args...) 
    args = [x, y, z, other_args...]
    n = length(args)
    varidx = findall(t -> (typeof(t) <: UnitAffExpr) || (typeof(t) <: UnitVariableRef) || (typeof(t) <: VariableRef), args)
    var = args[varidx[1]]
    val = prod(args[i] for i in setdiff(1:n, varidx))
    return _MA.operate!!(t, uav, val, var)
end

# Zero handling
_MA.operate!!(t::AddSub, z::_MA.Zero, a::Quantity) = create_expression(t, z, a)
_MA.operate!!(t::AddSub, z::_MA.Zero, x::UnitVariableRef) = create_expression(t, z, 1, x)
_MA.operate!!(t::AddSub, z::_MA.Zero, a::NumQuant, x::UnitVariableRef) = create_expression(t, z, a, x)
_MA.operate!!(t::AddSub, z::_MA.Zero, x::UnitVariableRef, a::NumQuant) = create_expression(t, z, a, x)
_MA.operate!!(t::AddSub, z::_MA.Zero, a::Quantity, x::VariableRef) = create_expression(t, z, a, x)
_MA.operate!!(t::AddSub, z::_MA.Zero, x::VariableRef, a::Quantity) = create_expression(t, z, a, x)


function _MA.operate!!(t::AddSub, zero::_MA.Zero, x, y, z, other_args...) 
    args = [x, y, z, other_args...]
    n = length(args)
    varidx = findall(t -> (typeof(t) <: UnitAffExpr) || (typeof(t) <: UnitVariableRef) || (typeof(t) <: VariableRef), args)
    var = args[varidx[1]]
    val = prod(args[i] for i in setdiff(1:n, varidx))
    return _MA.operate!!(t, zero, val, var)
end
