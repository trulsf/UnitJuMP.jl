

struct UnitVariable{U <: Unitful.Units} <: JuMP.AbstractVariable
    v::JuMP.ScalarVariable
    u::U
end

struct UnitVariableRef{U <: Unitful.Units} <: JuMP.AbstractVariableRef 
    vref::JuMP.VariableRef
    u::U
end
JuMP.owner_model(uv::UnitVariableRef) = owner_model(uv.vref)
Unitful.unit(uv::UnitVariableRef) = uv.u

function Base.show(io::IO, uv::UnitVariableRef)
    print(io, uv.vref, " ", uv.u)
end

function JuMP.build_variable(_error::Function, info::JuMP.VariableInfo, u::U) where {U <: Unitful.Units} 
    return UnitVariable{U}(JuMP.ScalarVariable(info), u)
end

function JuMP.add_variable(m::Model, v::UnitVariable{U}, name::String) where {U}
    vref = JuMP.add_variable(m, v.v, name)
    return UnitVariableRef{U}(vref, v.u)
end

struct UnitAffExpr{U <: Unitful.Units} <: JuMP.AbstractJuMPScalar  
    expr::AffExpr
    u::U
end
UnitAffExpr(u::Unitful.Units) = UnitAffExpr{U}(AffExpr(), u)


function Base.show(io::IO, ua::UnitAffExpr)
    print(io, "$(ua.expr) [$(ua.u)]")
end

Base.:(==)(ua::UnitAffExpr, other::UnitAffExpr) = ua.expr == other.expr && ua.u == other.u

function JuMP.moi_function(ua::UnitAffExpr)
    return JuMP.moi_function(ua.expr)
end

struct UnitConstraint{U <: Unitful.Units} <: AbstractConstraint
    con::ScalarConstraint
    u::U
end

struct UnitConstraintRef{U <: Unitful.Units}
    cref::ConstraintRef
    u::U
end
Unitful.unit(uc::UnitConstraintRef) = uc.u

function Base.show(io::IO, uc::UnitConstraintRef)
    print(io, "$(uc.cref) [$(uc.u)]")
end

function JuMP.check_belongs_to_model(uc::UnitConstraint, model::AbstractModel)
    return JuMP.check_belongs_to_model(uc.con, model)
end

function JuMP.check_belongs_to_model(ue::UnitAffExpr, model::AbstractModel)
    return JuMP.check_belongs_to_model(ue.expr, model)
end

function Unitful.uconvert(unit::Unitful.Units, uexpr::UnitAffExpr)

    expr = copy(uexpr.expr)

    if unit == uexpr.u
        return UnitAffExpr(expr, unit)
    end     

    factor = ustrip(uconvert(unit, Quantity(1, uexpr.u))) 
    expr.constant *= factor

    for k in keys(uexpr.expr.terms)
        expr.terms[k] *= factor
    end

    return UnitAffExpr(expr, unit)
end

function JuMP.build_constraint(_error::Function, uexpr::UnitAffExpr{U}, set::MOI.AbstractScalarSet) where {U}
    return UnitConstraint{U}(build_constraint(_error, uexpr.expr, set), uexpr.u)
end

function JuMP.build_constraint(_error::Function, uexpr::UnitAffExpr, set::MOI.AbstractScalarSet, u::U) where {U <: Unitful.Units}
    uexpr = uconvert(u, uexpr)
    return UnitConstraint{U}(build_constraint(_error, uexpr.expr, set), uexpr.u)
end


function JuMP.add_constraint(m::Model, uc::UnitConstraint{U}, name::String) where {U}
    cref = JuMP.add_constraint(m, uc.con, name)
    return UnitConstraintRef{U}(cref, uc.u)
end


function JuMP.value(uref::UnitVariableRef)
    return Quantity(JuMP.value(uref.vref), uref.u)
end

function JuMP.value(ua::UnitAffExpr)
    return Quantity(JuMP.value(ua.expr), ua.u)
end
