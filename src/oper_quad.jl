# Cover all operations that can lead to quadratic terms 
# involving units
#  1. UnitVariableRef * UnitVariableRef
#  2. UnitVariableRef * VariableRef
#  3. UnitVariableRef * UnitAffExpr
#  4. UnitVariableRef * AffExpr
#  5. UnitAffExpr * UnitAffExpr
#  6. UnitAffExpr * AffExpr
#  7. UnitAffExpr * VariableRef 
#  8. UnitVariableRef^2
#  9. UnitAffExpr^2
# 10. Quantity * QuadExpr
function Base.:*(lhs::UnitVariableRef, rhs::UnitVariableRef)
    xu = Unitful.Quantity(1, lhs.unit)
    yu = Unitful.Quantity(1, rhs.unit)
    return UnitExpression(lhs.variable * rhs.variable, Unitful.unit(xu * yu))
end

function Base.:*(lhs::UnitVariableRef, rhs::VariableRef)
    return UnitExpression(lhs.variable * rhs, Unitful.unit(lhs))
end
Base.:*(lhs::VariableRef, rhs::UnitVariableRef) = (*)(rhs, lhs)

function Base.:*(lhs::UnitVariableRef, rhs::UnitAffExpr)
    xu = Unitful.Quantity(1, lhs.unit)
    yu = Unitful.Quantity(1, rhs.unit)
    return UnitExpression(lhs.variable * rhs.expr, Unitful.unit(xu * yu))
end
Base.:*(lhs::UnitAffExpr, rhs::UnitVariableRef) = (*)(rhs, lhs)

function Base.:*(lhs::UnitVariableRef, rhs::AffExpr)
    return UnitExpression(lhs.variable * rhs, Unitful.unit(lhs))
end
Base.:*(lhs::AffExpr, rhs::UnitVariableRef) = (*)(rhs, lhs)

function Base.:*(lhs::UnitAffExpr, rhs::UnitAffExpr)
    xu = Unitful.Quantity(1, lhs.unit)
    yu = Unitful.Quantity(1, rhs.unit)
    return UnitExpression(lhs.expr * rhs.expr, Unitful.unit(xu * yu))
end

function Base.:*(lhs::UnitAffExpr, rhs::AffExpr)
    return UnitExpression(lhs.expr * rhs, Unitful.unit(lhs))
end
Base.:*(lhs::AffExpr, rhs::UnitAffExpr) = (*)(rhs, lhs)

function Base.:*(lhs::UnitAffExpr, rhs::VariableRef)
    return UnitExpression(lhs.expr * rhs, Unitful.unit(lhs))
end
Base.:*(lhs::VariableRef, rhs::UnitAffExpr) = (*)(rhs, lhs)

function Base.:^(lhs::UnitVariableRef, rhs::Integer)
    if rhs == 2
        return lhs * lhs
    elseif rhs == 1
        return lhs
    elseif rhs == 0
        return 1
    else
        error(
            "Only exponents of 0, 1, or 2 are currently supported. Are you " *
            "trying to build a nonlinear problem? Make sure you use " *
            "@NLconstraint/@NLobjective.",
        )
    end
end

function Base.:^(lhs::UnitAffExpr, rhs::Integer)
    if rhs == 2
        return lhs * lhs
    elseif rhs == 1
        return lhs
    elseif rhs == 0
        return 1
    else
        error(
            "Only exponents of 0, 1, or 2 are currently supported. Are you " *
            "trying to build a nonlinear problem? Make sure you use " *
            "@NLconstraint/@NLobjective.",
        )
    end
end

function Base.:*(lhs::Unitful.Quantity, rhs::QuadExpr)
    return UnitExpression(Unitful.ustrip(lhs) * rhs, Unitful.unit(lhs))
end
Base.:*(lhs::QuadExpr, rhs::Unitful.Quantity) = (*)(rhs, lhs)
