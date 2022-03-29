module UnitJuMP

using Reexport
@reexport using JuMP
@reexport using Unitful

import MutableArithmetics
_MA = MutableArithmetics

include("units.jl")
include("mutable_arithmetics.jl")
include("operators.jl")

export UnitVariableRef, UnitConstraintRef, UnitExpression

end
