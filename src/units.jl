

struct UnitVariable <: JuMP.AbstractVariable
    v::JuMP.ScalarVariable
    u::Unitful.Units
end

struct UnitVariableRef 
    vref::JuMP.VariableRef
    u::Unitful.Units
end
unit(uv::UnitVariableRef) = uv.u

function Base.show(io::IO, uv::UnitVariableRef)
    print(io, uv.vref, " ", uv.u)
end

function JuMP.build_variable(_error::Function, info::JuMP.VariableInfo, u::Unitful.Units)
    return UnitVariable(JuMP.ScalarVariable(info), u)
end

function JuMP.add_variable(m::Model, v::UnitVariable, name::String)
    vref = JuMP.add_variable(m, v.v, name)
    return UnitVariableRef(vref, v.u)
end

struct UnitAffExpr <: JuMP.AbstractJuMPScalar
    expr::AffExpr
    u::Unitful.Units
end

function Base.show(io::IO, ua::UnitAffExpr)
    print(io, ua.expr, " ", ua.u)
end

function JuMP.moi_function(ua::UnitAffExpr)
    return JuMP.moi_function(ua.expr)
end

struct UnitConstraint <: AbstractConstraint
    con::ScalarConstraint
    u::Unitful.Units
end

struct UnitConstraintRef
    cref::ConstraintRef
    u::Unitful.Units
end

unit(uc::UnitConstraintRef) = uc.u

function Base.show(io::IO, uc::UnitConstraintRef)
    print(io, "$(uc.cref) [$(uc.u)]")
end


function JuMP.check_belongs_to_model(uc::UnitConstraint, model::AbstractModel)
    return JuMP.check_belongs_to_model(uc.con, model)
end

function JuMP.check_belongs_to_model(ue::UnitAffExpr, model::AbstractModel)
    return JuMP.check_belongs_to_model(ue.expr, model)
end

function convert(uexpr::UnitAffExpr, unit::Unitful.Units)
    if unit == uexpr.u
        return uexpr
    end     

    factor = ustrip(uconvert(unit, Quantity(1, uexpr.u))) 
    uexpr.expr.constant *= factor

    for k in keys(uexpr.expr.terms)
        uexpr.expr.terms[k] *= factor
    end

    return UnitAffExpr(uexpr.expr, unit)
end

function JuMP.build_constraint(_error::Function, uexpr::UnitAffExpr, set::MOI.AbstractScalarSet; kwargs...)
    kwdict = Dict(kwargs)
    if :unit in keys(kwdict)
        uexpr = convert(uexpr, kwdict[:unit])
    end
    return UnitConstraint(build_constraint(_error, uexpr.expr, set), uexpr.u)
end

function JuMP.add_constraint(m::Model, uc::UnitConstraint, name::String)
    cref = JuMP.add_constraint(m, uc.con, name)
    return UnitConstraintRef(cref, uc.u)
end


function JuMP.value(uref::UnitVariableRef)
    return Quantity(JuMP.value(uref.vref), uref.u)
end


