
JuMP._complex_convert_type(::Type{T}, ::Type{<:Unitful.Quantity{TT,D,U}}) where {T,TT,D,U} = Unitful.Quantity{T,D,U}

JuMP._complex_convert(::Type{T}, x::Unitful.Quantity{TT,D,U}) where {T,TT,D,U} = convert(Unitful.Quantity{T,D,U}, x)
