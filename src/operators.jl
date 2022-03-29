
# Following the approach in JuMP
# Must support interactions between the Following
# 1. Numbers
# 2. Quantities
# 3. UnitVariableRef
# 4. VariableRef
# 5. UnitExpression

# Unitful.Quantity/Number -- VariableRef/UnitVariableRef

# Use the Unitful.unit of the lhs when adding or subtracting different quantities
function Base.:+(lhs::Unitful.Quantity, rhs::UnitVariableRef)
    factor = Unitful.ustrip(
        Unitful.uconvert(Unitful.unit(lhs), Unitful.Quantity(1.0, rhs.unit)),
    )
    return UnitExpression(
        Unitful.ustrip(lhs) + factor * rhs.variable,
        Unitful.unit(lhs),
    )
end

function Base.:+(lhs::UnitVariableRef, rhs::Unitful.Quantity)
    rhsval = Unitful.ustrip(Unitful.uconvert(lhs.unit, rhs))
    return UnitExpression(lhs.variable + rhsval, lhs.unit)
end

function Base.:*(lhs::Unitful.Quantity, rhs::VariableRef)
    return UnitExpression(Unitful.ustrip(lhs) * rhs, Unitful.unit(lhs))
end

function Base.:*(lhs::Number, rhs::UnitVariableRef)
    return UnitExpression(lhs * rhs.variable, rhs.unit)
end

function Base.:*(lhs::Unitful.Quantity, rhs::UnitVariableRef)
    val = lhs * Unitful.Quantity(1.0, rhs.unit)
    return UnitExpression(Unitful.ustrip(val) * rhs.variable, Unitful.unit(val))
end

Base.:-(lhs::UnitVariableRef) = UnitExpression(-lhs.variable, lhs.unit)
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
    factor = Unitful.ustrip(
        Unitful.uconvert(lhs.unit, Unitful.Quantity(1.0, rhs.unit)),
    )
    return UnitExpression(lhs.variable + factor * rhs.variable, lhs.unit)
end

Base.:-(lhs::UnitVariableRef, rhs::UnitVariableRef) = (+)(lhs, -rhs)

# Unitful.Quantity/Number -- UnitExpression
# Use the Unitful.unit of the lhs term
function Base.:+(lhs::Unitful.Quantity, rhs::UnitExpression)
    factor = Unitful.ustrip(
        Unitful.uconvert(Unitful.unit(lhs), Unitful.Quantity(1.0, rhs.unit)),
    )
    return UnitExpression(
        Unitful.ustrip(lhs) + factor * rhs.expr,
        Unitful.unit(lhs),
    )
end

function Base.:+(lhs::UnitExpression, rhs::Unitful.Quantity)
    rhsval = Unitful.ustrip(Unitful.uconvert(lhs.unit, rhs))
    return UnitExpression(lhs.expr + rhsval, lhs.unit)
end

function Base.:*(lhs::Unitful.Quantity, rhs::UnitExpression)
    factor = lhs * Unitful.Quantity(1.0, rhs.unit)
    return UnitExpression(
        Unitful.ustrip(factor) * rhs.expr,
        Unitful.unit(factor),
    )
end

function Base.:*(lhs::Number, rhs::UnitExpression)
    return UnitExpression(lhs * rhs.expr, rhs.unit)
end

Base.:-(lhs::UnitExpression) = UnitExpression(-lhs.expr, lhs.unit)
Base.:-(lhs::Unitful.Quantity, rhs::UnitExpression) = (+)(lhs, -rhs)
Base.:-(lhs::UnitExpression, rhs::Unitful.Quantity) = (+)(lhs, -rhs)

Base.:*(lhs::UnitExpression, rhs::Unitful.Quantity) = (*)(rhs, lhs)
Base.:/(lhs::UnitExpression, rhs::Unitful.Quantity) = (*)(1.0 / rhs, lhs)
Base.:*(lhs::UnitExpression, rhs::Number) = (*)(rhs, lhs)
Base.:/(lhs::UnitExpression, rhs::Number) = (*)(1.0 / rhs, lhs)

# UnitVariableRef -- UnitExpression
# Use the Unitful.unit of the lhs term
function Base.:+(lhs::UnitVariableRef, rhs::UnitExpression)
    factor = Unitful.ustrip(
        Unitful.uconvert(lhs.unit, Unitful.Quantity(1.0, rhs.unit)),
    )
    return UnitExpression(lhs.variable + factor * rhs.expr, lhs.unit)
end

function Base.:+(lhs::UnitExpression, rhs::UnitVariableRef)
    factor = Unitful.ustrip(
        Unitful.uconvert(lhs.unit, Unitful.Quantity(1.0, rhs.unit)),
    )
    return UnitExpression(lhs.expr + factor * rhs.variable, lhs.unit)
end

Base.:-(lhs::UnitVariableRef, rhs::UnitExpression) = (+)(lhs, -rhs)
Base.:-(lhs::UnitExpression, rhs::UnitVariableRef) = (+)(lhs, -rhs)

# UnitExpression -- UnitExpression
# Use the Unitful.unit of the lhs term
function Base.:+(lhs::UnitExpression, rhs::UnitExpression)
    factor = Unitful.ustrip(
        Unitful.uconvert(lhs.unit, Unitful.Quantity(1, rhs.unit)),
    )
    aff = JuMP.add_to_expression!(copy(lhs.expr), factor, rhs.expr)
    return UnitExpression(aff, lhs.unit)
end

Base.:-(lhs::UnitExpression, rhs::UnitExpression) = (+)(lhs, -rhs)
