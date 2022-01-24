
# Following the approach in JuMP
# Must support interactions between the Following
# 1. Numbers
# 2. Quantities
# 3. UnitVariableRef
# 4. VariableRef
# 5. UnitAffExpr

# Quantity/Number -- VariableRef/UnitVariableRef

# Use the unit of the lhs when adding or subtracting different quantities
function Base.:+(lhs::Quantity, rhs::UnitVariableRef)
    factor = ustrip(uconvert(unit(lhs), Quantity(1.0, rhs.u)))
    return UnitAffExpr(ustrip(lhs) + factor * rhs.vref, unit(lhs))
end
function Base.:+(lhs::UnitVariableRef, rhs::Quantity)
    rhsval = ustrip(uconvert(lhs.u, rhs ))
    return UnitAffExpr(lhs.vref + rhsval, lhs.u)
end
function Base.:*(lhs::Quantity, rhs::VariableRef)
    return UnitAffExpr(ustrip(lhs) * rhs, unit(lhs))
end
function Base.:*(lhs::Number, rhs::UnitVariableRef)
    return UnitAffExpr(lhs * rhs.vref, rhs.u)
end
function Base.:*(lhs::Quantity, rhs::UnitVariableRef)
    val = lhs * Quantity(1.0, rhs.u)
    return UnitAffExpr(ustrip(val) * rhs.vref, unit(val))
end

Base.:-(lhs::UnitVariableRef) = UnitAffExpr(-lhs.vref, lhs.u) 
Base.:-(lhs::Quantity, rhs::UnitVariableRef) = (+)(lhs, -rhs)
Base.:-(lhs::UnitVariableRef, rhs::Quantity) = (+)(lhs, -rhs)

Base.:*(lhs::UnitVariableRef, rhs::Number) = (*)(rhs, lhs)
Base.:*(lhs::VariableRef, rhs::Quantity) = (*)(rhs, lhs)
Base.:*(lhs::UnitVariableRef, rhs::Quantity) = (*)(rhs, lhs)

Base.:/(lhs::UnitVariableRef, rhs::Number) = (*)(1.0 / rhs, lhs)
Base.:/(lhs::VariableRef, rhs::Quantity) = (*)(1.0 / rhs, lhs)
Base.:/(lhs::UnitVariableRef, rhs::Quantity) = (*)(1.0 / rhs, lhs)

# UnitVariableRef -- UnitVariableRef
# Use the unit of the lhs term
function Base.:+(lhs::UnitVariableRef, rhs::UnitVariableRef) 
    factor = ustrip(uconvert(lhs.u, Quantity(1.0, rhs.u)))
    return UnitAffExpr(lhs.vref + factor * rhs.vref, lhs.u)
end
Base.:-(lhs::UnitVariableRef, rhs::UnitVariableRef)  = (+)(lhs, -rhs)

# Quantity/Number -- UnitAffExpr
# Use the unit of the lhs term
function Base.:+(lhs::Quantity, rhs::UnitAffExpr)
    factor = ustrip(uconvert(unit(lhs), Quantity(1.0, rhs.u)))
    return UnitAffExpr(ustrip(lhs) + factor * rhs.expr, unit(lhs))
end
function Base.:+(lhs::UnitAffExpr, rhs::Quantity)
    rhsval = ustrip(uconvert(lhs.u, rhs))
    return UnitAffExpr(lhs.expr + rhsval, lhs.u)
end

function Base.:*(lhs::Quantity, rhs::UnitAffExpr)
    factor = lhs * Quantity(1.0, rhs.u)
    return UnitAffExpr(ustrip(factor) * rhs.expr, unit(factor))
end
function Base.:*(lhs::Number, rhs::UnitAffExpr)
    return UnitAffExpr(lhs * rhs.expr, rhs.u)
end

Base.:-(lhs::UnitAffExpr) = UnitAffExpr(-lhs.expr, lhs.u)
Base.:-(lhs::Quantity, rhs::UnitAffExpr) = (+)(lhs, -rhs)
Base.:-(lhs::UnitAffExpr, rhs::Quantity) = (+)(lhs, -rhs)

Base.:*(lhs::UnitAffExpr, rhs::Quantity) = (*)(rhs, lhs)
Base.:/(lhs::UnitAffExpr, rhs::Quantity) = (*)(1.0 / rhs, lhs)
Base.:*(lhs::UnitAffExpr, rhs::Number) = (*)(rhs, lhs)
Base.:/(lhs::UnitAffExpr, rhs::Number) = (*)(1.0 / rhs, lhs)

# UnitVariableRef -- UnitAffExpr
# Use the unit of the lhs term
function Base.:+(lhs::UnitVariableRef, rhs::UnitAffExpr) 
    factor = ustrip(uconvert(lhs.u, Quantity(1.0, rhs.u)))
    return UnitAffExpr(lhs.vref + factor * rhs.expr, lhs.u)
end
function Base.:+(lhs::UnitAffExpr, rhs::UnitVariableRef) 
    factor = ustrip(uconvert(lhs.u, Quantity(1.0, rhs.u)))
    return UnitAffExpr(lhs.expr + factor * rhs.vref, lhs.u)
end
Base.:-(lhs::UnitVariableRef, rhs::UnitAffExpr) = (+)(lhs, -rhs)
Base.:-(lhs::UnitAffExpr, rhs::UnitVariableRef) = (+)(lhs, -rhs)

# UnitAffExpr -- UnitAffExpr
# Use the unit of the lhs term
function Base.:+(lhs::UnitAffExpr, rhs::UnitAffExpr) 
    factor = ustrip(uconvert(lhs.u, Quantity(1, rhs.u)))
    aff = add_to_expression!(copy(lhs.expr), factor, rhs.expr)
    return UnitAffExpr(aff, lhs.u)
end
Base.:-(lhs::UnitAffExpr, rhs::UnitAffExpr) =  (+)(lhs, -rhs)

