###
### UnitVariableRef
###

struct _UnitVariable{U<:Unitful.Units} <: JuMP.AbstractVariable
    variable::JuMP.ScalarVariable
    unit::U
end

"""
    UnitVariableRef(::JuMP.VariableRef, ::Unitful.Units)

A type that wraps a `VariableRef` with a `Uniful.Units`.
"""
struct UnitVariableRef{U<:Unitful.Units} <: JuMP.AbstractVariableRef
    variable::JuMP.VariableRef
    unit::U
end

JuMP.owner_model(x::UnitVariableRef) = JuMP.owner_model(x.variable)

Unitful.unit(x::UnitVariableRef) = x.unit

Base.show(io::IO, x::UnitVariableRef) = print(io, "$(x.variable) [$(x.unit)]")

function JuMP.build_variable(
    ::Function,
    info::JuMP.VariableInfo,
    unit::U,
) where {U<:Unitful.Units}
    return _UnitVariable{U}(JuMP.ScalarVariable(info), unit)
end

function JuMP.add_variable(
    model::Model,
    x::_UnitVariable{U},
    name::String,
) where {U}
    variable = JuMP.add_variable(model, x.variable, name)
    return UnitVariableRef{U}(variable, x.unit)
end

function JuMP.value(x::UnitVariableRef)
    return Unitful.Quantity(JuMP.value(x.variable), x.unit)
end

###
### UnitAffExpr
###

"""
    UnitAffExpr(::JuMP.AffExpr, ::Unitful.Units)

A type that wraps an `AffExpr` with a `Uniful.Units`.
"""
struct UnitAffExpr{U<:Unitful.Units} <: JuMP.AbstractJuMPScalar
    expr::AffExpr
    unit::U
end

UnitAffExpr(u::Unitful.Units) = UnitAffExpr{typeof(u)}(AffExpr(), u)

Base.show(io::IO, x::UnitAffExpr) = print(io, "$(x.expr) [$(x.unit)]")

function Base.:(==)(x::UnitAffExpr, y::UnitAffExpr)
    return x.expr == y.expr && x.unit == y.unit
end

JuMP.moi_function(x::UnitAffExpr) = JuMP.moi_function(x.expr)

function JuMP.check_belongs_to_model(x::UnitAffExpr, model::AbstractModel)
    return JuMP.check_belongs_to_model(x.expr, model)
end

Unitful.uconvert(::U, x::UnitAffExpr{U}) where {U} = x

function Unitful.uconvert(unit::Unitful.Units, x::UnitAffExpr)
    expr = copy(x.expr)
    factor = Unitful.ustrip(Unitful.uconvert(unit, Unitful.Quantity(1, x.unit)))
    expr.constant *= factor
    for (k, v) in x.expr.terms
        expr.terms[k] = factor * v
    end
    return UnitAffExpr(expr, unit)
end

JuMP.value(x::UnitAffExpr) = Unitful.Quantity(JuMP.value(x.expr), x.unit)

###
### UnitConstraintRef
###

struct _UnitConstraint{U<:Unitful.Units} <: AbstractConstraint
    constraint::ScalarConstraint
    unit::U
end

"""
    UnitConstraintRef(::JuMP.ConstraintRef, ::Unitful.Units)

A type that wraps an `ConstraintRef` with a `Uniful.Units`.
"""
struct UnitConstraintRef{U<:Unitful.Units}
    constraint::ConstraintRef
    unit::U
end

Unitful.unit(c::UnitConstraintRef) = c.unit

function Base.show(io::IO, c::UnitConstraintRef)
    return print(io, "$(c.constraint) [$(c.unit)]")
end

function JuMP.check_belongs_to_model(c::_UnitConstraint, model::AbstractModel)
    return JuMP.check_belongs_to_model(c.constraint, model)
end

function JuMP.build_constraint(
    _error::Function,
    expr::UnitAffExpr{U},
    set::MOI.AbstractScalarSet,
) where {U}
    return _UnitConstraint{U}(
        JuMP.build_constraint(_error, expr.expr, set),
        expr.unit,
    )
end

function JuMP.build_constraint(
    _error::Function,
    uexpr::UnitAffExpr,
    set::MOI.AbstractScalarSet,
    unit::U,
) where {U<:Unitful.Units}
    return JuMP.build_constraint(_error, Unitful.uconvert(unit, uexpr), set)
end

function JuMP.add_constraint(
    model::Model,
    c::_UnitConstraint{U},
    name::String,
) where {U}
    constraint = JuMP.add_constraint(model, c.constraint, name)
    return UnitConstraintRef{U}(constraint, c.unit)
end
