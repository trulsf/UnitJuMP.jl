
# Following the approach in JuMP
# Must support interactions between the Following
# 1. Numbers
# 2. Quantities
# 3. UnitVariableRef
# 4. VariableRef
# 5. UnitAffExpr

# Unitful.Quantity/Number -- VariableRef/UnitVariableRef

# Use the Unitful.unit of the lhs when adding or subtracting different quantities
function Base.:+(lhs::Unitful.Quantity, rhs::UnitVariableRef)
    factor = Unitful.ustrip(
        Unitful.uconvert(Unitful.unit(lhs), Unitful.Quantity(1.0, rhs.u)),
    )
    return UnitAffExpr(
        Unitful.ustrip(lhs) + factor * rhs.vref,
        Unitful.unit(lhs),
    )
end

function Base.:+(lhs::UnitVariableRef, rhs::Unitful.Quantity)
    rhsval = Unitful.ustrip(Unitful.uconvert(lhs.u, rhs))
    return UnitAffExpr(lhs.vref + rhsval, lhs.u)
end

function Base.:*(lhs::Unitful.Quantity, rhs::VariableRef)
    return UnitAffExpr(Unitful.ustrip(lhs) * rhs, Unitful.unit(lhs))
end

function Base.:*(lhs::Number, rhs::UnitVariableRef)
    return UnitAffExpr(lhs * rhs.vref, rhs.u)
end

function Base.:*(lhs::Unitful.Quantity, rhs::UnitVariableRef)
    val = lhs * Unitful.Quantity(1.0, rhs.u)
    return UnitAffExpr(Unitful.ustrip(val) * rhs.vref, Unitful.unit(val))
end

Base.:-(lhs::UnitVariableRef) = UnitAffExpr(-lhs.vref, lhs.u)
Base.:-(lhs::Unitful.Quantity, rhs::UnitVariableRef) = (+)(lhs, -rhs)
Base.:-(lhs::UnitVariableRef, rhs::Unitful.Quantity) = (+)(lhs, -rhs)

Base.:*(lhs::UnitVariableRef, rhs::Number) = (*)(rhs, lhs)
Base.:*(lhs::VariableRef, rhs::Unitful.Quantity) = (*)(rhs, lhs)
Base.:*(lhs::UnitVariableRef, rhs::Unitful.Quantity) = (*)(rhs, lhs)

Base.:/(lhs::UnitVariableRef, rhs::Number) = (*)(1.0 / rhs, lhs)
Base.:/(lhs::VariableRef, rhs::Unitful.Quantity) = (*)(1.0 / rhs, lhs)
Base.:/(lhs::UnitVariableRef, rhs::Unitful.Quantity) = (*)(1.0 / rhs, lhs)

# UnitVariableRef -- UnitVariableRef
# Use the Unitful.unit of the lhs term
function Base.:+(lhs::UnitVariableRef, rhs::UnitVariableRef)
    factor =
        Unitful.ustrip(Unitful.uconvert(lhs.u, Unitful.Quantity(1.0, rhs.u)))
    return UnitAffExpr(lhs.vref + factor * rhs.vref, lhs.u)
end

Base.:-(lhs::UnitVariableRef, rhs::UnitVariableRef) = (+)(lhs, -rhs)

# Unitful.Quantity/Number -- UnitAffExpr
# Use the Unitful.unit of the lhs term
function Base.:+(lhs::Unitful.Quantity, rhs::UnitAffExpr)
    factor = Unitful.ustrip(
        Unitful.uconvert(Unitful.unit(lhs), Unitful.Quantity(1.0, rhs.u)),
    )
    return UnitAffExpr(
        Unitful.ustrip(lhs) + factor * rhs.expr,
        Unitful.unit(lhs),
    )
end

function Base.:+(lhs::UnitAffExpr, rhs::Unitful.Quantity)
    rhsval = Unitful.ustrip(Unitful.uconvert(lhs.u, rhs))
    return UnitAffExpr(lhs.expr + rhsval, lhs.u)
end

function Base.:*(lhs::Unitful.Quantity, rhs::UnitAffExpr)
    factor = lhs * Unitful.Quantity(1.0, rhs.u)
    return UnitAffExpr(Unitful.ustrip(factor) * rhs.expr, Unitful.unit(factor))
end

function Base.:*(lhs::Number, rhs::UnitAffExpr)
    return UnitAffExpr(lhs * rhs.expr, rhs.u)
end

Base.:-(lhs::UnitAffExpr) = UnitAffExpr(-lhs.expr, lhs.u)
Base.:-(lhs::Unitful.Quantity, rhs::UnitAffExpr) = (+)(lhs, -rhs)
Base.:-(lhs::UnitAffExpr, rhs::Unitful.Quantity) = (+)(lhs, -rhs)

Base.:*(lhs::UnitAffExpr, rhs::Unitful.Quantity) = (*)(rhs, lhs)
Base.:/(lhs::UnitAffExpr, rhs::Unitful.Quantity) = (*)(1.0 / rhs, lhs)
Base.:*(lhs::UnitAffExpr, rhs::Number) = (*)(rhs, lhs)
Base.:/(lhs::UnitAffExpr, rhs::Number) = (*)(1.0 / rhs, lhs)

# UnitVariableRef -- UnitAffExpr
# Use the Unitful.unit of the lhs term
function Base.:+(lhs::UnitVariableRef, rhs::UnitAffExpr)
    factor =
        Unitful.ustrip(Unitful.uconvert(lhs.u, Unitful.Quantity(1.0, rhs.u)))
    return UnitAffExpr(lhs.vref + factor * rhs.expr, lhs.u)
end

function Base.:+(lhs::UnitAffExpr, rhs::UnitVariableRef)
    factor =
        Unitful.ustrip(Unitful.uconvert(lhs.u, Unitful.Quantity(1.0, rhs.u)))
    return UnitAffExpr(lhs.expr + factor * rhs.vref, lhs.u)
end

Base.:-(lhs::UnitVariableRef, rhs::UnitAffExpr) = (+)(lhs, -rhs)
Base.:-(lhs::UnitAffExpr, rhs::UnitVariableRef) = (+)(lhs, -rhs)

# UnitAffExpr -- UnitAffExpr
# Use the Unitful.unit of the lhs term
function Base.:+(lhs::UnitAffExpr, rhs::UnitAffExpr)
    factor = Unitful.ustrip(Unitful.uconvert(lhs.u, Unitful.Quantity(1, rhs.u)))
    aff = JuMP.add_to_expression!(copy(lhs.expr), factor, rhs.expr)
    return UnitAffExpr(aff, lhs.u)
end

Base.:-(lhs::UnitAffExpr, rhs::UnitAffExpr) = (+)(lhs, -rhs)
