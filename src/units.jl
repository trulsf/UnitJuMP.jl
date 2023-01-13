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

function Base.zero(
    _::Type{UnitVariableRef{U}},
) where {N,D,A,U<:Unitful.Units{N,D,A}}
    return Unitful.Quantity{Float64,D,U}(0.0)
end

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

JuMP.name(x::UnitVariableRef) = JuMP.name(x.variable)

function JuMP.set_name(x::UnitVariableRef, s::String)
    return JuMP.set_name(x.variable, s)
end

function JuMP.set_start_value(x::UnitVariableRef, value::Unitful.Quantity)
    val = Unitful.uconvert(x.unit, value)
    return JuMP.set_start_value(x.variable, Unitful.ustrip(val))
end

function JuMP.set_start_value(x::UnitVariableRef, value::Real)
    return error("Start value for unit variable must be given with units")
end

function JuMP.start_value(x::UnitVariableRef)
    return Unitful.Quantity(JuMP.start_value(x.variable), x.unit)
end

JuMP.has_lower_bound(x::UnitVariableRef) = JuMP.has_lower_bound(x.variable)

function JuMP.lower_bound(x::UnitVariableRef)
    return Unitful.Quantity(JuMP.lower_bound(x.variable), x.unit)
end

function JuMP.set_lower_bound(x::UnitVariableRef, lower::Unitful.Quantity)
    val = Unitful.uconvert(x.unit, lower)
    return JuMP.set_lower_bound(x.variable, Unitful.ustrip(val))
end

function JuMP.set_lower_bound(x::UnitVariableRef, lower::Real)
    return error("Lower bound of unit variable must be given with units")
end

function JuMP.delete_lower_bound(x::UnitVariableRef)
    return JuMP.delete_lower_bound(x.variable)
end

JuMP.LowerBoundRef(x::UnitVariableRef) = JuMP.LowerBoundRef(x.variable)

JuMP.has_upper_bound(x::UnitVariableRef) = JuMP.has_upper_bound(x.variable)

function JuMP.upper_bound(x::UnitVariableRef)
    return Unitful.Quantity(JuMP.upper_bound(x.variable), x.unit)
end

function JuMP.set_upper_bound(x::UnitVariableRef, upper::Unitful.Quantity)
    val = Unitful.uconvert(x.unit, upper)
    return JuMP.set_upper_bound(x.variable, Unitful.ustrip(val))
end

function JuMP.set_upper_bound(x::UnitVariableRef, upper::Real)
    return error("Upper bound of unit variable must be given with units")
end

function JuMP.delete_upper_bound(x::UnitVariableRef)
    return JuMP.delete_upper_bound(x.variable)
end

JuMP.UpperBoundRef(x::UnitVariableRef) = JuMP.UpperBoundRef(x.variable)

JuMP.is_fixed(x::UnitVariableRef) = JuMP.is_fixed(x.variable)

function JuMP.fix_value(x::UnitVariableRef)
    return Unitful.Quantity(JuMP.fix_value(x.variable), x.unit)
end

function JuMP.fix(x::UnitVariableRef, value::Unitful.Quantity)
    val = Unitful.uconvert(x.unit, value)
    return fix(x.variable, Unitful.ustrip(val))
end

function JuMP.fix(x::UnitVariableRef, value::Real)
    return error("Fix value of unit value must be given with units")
end

JuMP.unfix(x::UnitVariableRef) = JuMP.unfix(x.variable)

JuMP.FixRef(x::UnitVariableRef) = JuMP.FixRef(x.variable)

JuMP.is_integer(x::UnitVariableRef) = JuMP.is_integer(x.variable)

JuMP.set_integer(x::UnitVariableRef) = JuMP.set_integer(x.variable)

JuMP.unset_integer(x::UnitVariableRef) = JuMP.unset_integer(x.variable)

JuMP.IntegerRef(x::UnitVariableRef) = JuMP.IntegerRef(x.variable)

JuMP.is_binary(x::UnitVariableRef) = JuMP.is_binary(x.variable)

JuMP.set_binary(x::UnitVariableRef) = JuMP.set_binary(x.variable)

JuMP.unset_binary(x::UnitVariableRef) = JuMP.unset_binary(x.variable)

JuMP.BinaryRef(x::UnitVariableRef) = JuMP.BinaryRef(x.variable)

###
### UnitExpression
###

"""
    UnitExpression(::JuMP.AbstractJuMPScalar, ::Unitful.Units)

A type that wraps an `AbstractJuMPScalar` with a `Uniful.Units`.
"""
struct UnitExpression{A<:JuMP.AbstractJuMPScalar,U<:Unitful.Units} <:
       JuMP.AbstractJuMPScalar
    expr::A
    unit::U
end

Base.show(io::IO, x::UnitExpression) = print(io, "$(x.expr) [$(x.unit)]")

Unitful.unit(x::UnitExpression) = x.unit

function Base.:(==)(x::UnitExpression, y::UnitExpression)
    return x.expr == y.expr && x.unit == y.unit
end

JuMP.moi_function(x::UnitExpression) = JuMP.moi_function(x.expr)

function JuMP.check_belongs_to_model(x::UnitExpression, model::AbstractModel)
    return JuMP.check_belongs_to_model(x.expr, model)
end

Unitful.uconvert(::U, x::UnitExpression{A,U}) where {A,U} = x

function Unitful.uconvert(unit::Unitful.Units, x::UnitExpression)
    factor = Unitful.ustrip(Unitful.uconvert(unit, Unitful.Quantity(1, x.unit)))
    return UnitExpression(factor * x.expr, unit)
end

JuMP.value(x::UnitExpression) = Unitful.Quantity(JuMP.value(x.expr), x.unit)

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

function JuMP.dual(c::UnitConstraintRef)
    return Unitful.Quantity(JuMP.dual(c.constraint), Unitful.unit(1 / c.unit))
end

function JuMP.shadow_price(c::UnitConstraintRef)
    return Unitful.Quantity(
        JuMP.shadow_price(c.constraint),
        Unitful.unit(1 / c.unit),
    )
end

function JuMP.build_constraint(
    _error::Function,
    expr::UnitExpression{A,U},
    set::MOI.AbstractScalarSet,
) where {A,U}
    return _UnitConstraint{U}(
        JuMP.build_constraint(_error, expr.expr, set),
        expr.unit,
    )
end

function JuMP.build_constraint(
    _error::Function,
    uexpr::UnitExpression,
    set::MOI.AbstractScalarSet,
    unit::Unitful.Units,
)
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
