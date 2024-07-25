function strip_units(f::MOI.ScalarAffineFunction)
    return MOI.ScalarAffineFunction([MOI.ScalarAffineTerm(ustrip(t.coefficient), t.variable) for t in f.terms], ustrip(value(f.constant)))
end

function strip_units(f::MOI.LessThan)
    return MOI.LessThan(ustrip(f.upper))
end


struct UnitLessThanBridge{T} <: MOI.Bridges.Constraint.AbstractBridge
    constraint::MOI.ConstraintIndex{MOI.ScalarAffineFunction{Float64}, MOI.LessThan{Float64}}
end

function MOI.Bridges.Constraint.bridge_constraint(
    ::Type{UnitLessThanBridge{T}},
    model::MOI.ModelLike,
    f::MOI.ScalarAffineFunction{Q},
    s::MOI.LessThan{Q},
) where {T,Q<:Quantity}
    con = MOI.add_constraint(model, strip_units(f), strip_units(s))
    return UnitLessThanBridge{T}(con)
end

function MOI.supports_constraint(
    ::Type{UnitLessThanBridge{T}}, # Bridge to use.
    ::Type{MOI.ScalarAffineFunction{Q}}, # Function to rewrite.
    ::Type{MOI.LessThan{Q}}, # Set to rewrite.
) where {T, Q<:Quantity}
    return true
end

function MOI.Bridges.added_constrained_variable_types(::Type{UnitLessThanBridge{T}}) where T
    # The bridge does not create variables, return an empty list of tuples:
    return Tuple{Type}[]
end

function MOI.Bridges.added_constraint_types(::Type{UnitLessThanBridge{T}}) where T
    return Tuple{Type,Type}[
        # One element per F-in-S the bridge creates.
        (MOI.ScalarAffineFunction{Float64}, MOI.LessThan{Float64}),
    ]
end

struct UnitObjectiveBridge{T} <: MOI.Bridges.Objective.AbstractBridge end

function MOI.Bridges.Objective.supports_objective_function(
    ::Type{UnitObjectiveBridge{T}},
    ::Type{MOI.ScalarAffineFunction{Q}},
) where {T,Q<:Quantity}
    return true
end

MOI.Bridges.set_objective_function_type(::Type{UnitObjectiveBridge{T}}) where {T} = MOI.ScalarAffineFunction{Float64}

function MOI.Bridges.Objective.bridge_objective(
    ::Type{UnitObjectiveBridge{T}},
    model::MOI.ModelLike,
    f::MOI.ScalarAffineFunction{Q},
) where {T, Q<:Quantity}

    MOI.set(model, MOI.ObjectiveFunction{MOI.ScalarAffineFunction{Float64}}(), strip_units(f))
    return UnitObjectiveBridge{T}()
end

function MOI.Bridges.added_constrained_variable_types(
    ::Type{UnitObjectiveBridge{T}},
) where {T}
    return Tuple{Type}[]
end

function MOI.Bridges.added_constraint_types(::Type{UnitObjectiveBridge{T}}) where T
    return Tuple{Type,Type}[]
end

const UnitObjective{T,OT<:MOI.ModelLike} =
    MOI.Bridges.Objective.SingleBridgeOptimizer{UnitObjectiveBridge{T},OT}
