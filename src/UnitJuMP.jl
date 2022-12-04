module UnitJuMP

using Reexport
@reexport using JuMP
@reexport using Unitful

import MutableArithmetics
_MA = MutableArithmetics

include("units.jl")
include("mutable_arithmetics.jl")
include("operators.jl")
include("ma_quad.jl")
include("oper_quad.jl")

export UnitVariableRef, UnitConstraintRef, UnitExpression

end
