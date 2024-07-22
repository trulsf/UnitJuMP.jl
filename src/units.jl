
struct _UnitVariable{U<:Unitful.Units} <: JuMP.AbstractVariable
    variable::JuMP.ScalarVariable
    unit::U
end


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
    return Unitful.Quantity(1, x.unit) * variable
end

function Base.show(io::IO, x::GenericAffExpr{<:Unitful.Quantity{T,D,U}}) where {T,D,U}
    if ustrip(x.constant) != 0.0
        print(io, ustrip(x.constant))
        print(io, " + ")
    end
    for t in x.terms
        if ustrip(t.second) != 1.0
            print(io, " + ")
            print(io, Unitful.ustrip(t.second))
        end
        print(io, t.first)
    end
    print(io, " [")
    print(io, Unitful.unit(x.constant))
    print(io, "]")
end

struct _UnitConstraint{U<:Unitful.Units} <: AbstractConstraint
    constraint::ScalarConstraint
    unit::U
end


function JuMP.build_constraint(
    _error::Function,
    uexpr::GenericAffExpr{<:Unitful.Quantity},
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
