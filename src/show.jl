function Base.show(io::IO, K::Union{Kind,KindVar,ParametricKind,OrKind,AndKind,NotKind})
	Base.show_unquoted(io, toexpr(K))
end

struct DisplayWrapper
	showfn
	value
end
Base.show(io::IO, a::DisplayWrapper) = a.showfn(io, a.value)

toexpr(a) = a
function toexpr(K::Kind)
	name = K.name
	if isempty(K.parameters)
		name
	else
		:( $name[$(toexpr.(K.parameters)...)] )
	end
end
function toexpr(K::KindVar)
	expr = DisplayWrapper(K.name) do io, x
		printstyled(io, x, bold=true)
	end
	if (K.lb, K.ub) === (Bottom, Top)
		expr
	elseif K.lb === Bottom
		:( $expr ⊆ $(K.ub) )
	elseif K.ub === Top
		:( $expr ⊇ $(K.lb) )
	else
		:( $(K.lb) ⊆ $expr ⊆ $(K.ub) )
	end
end
toexpr(K::ParametricKind) = :( $(toexpr(K.body)) where $(toexpr(K.var)) )
toexpr(K::OrKind)  = :( $(toexpr(K.a)) ∪ $(toexpr(K.b)) )
toexpr(K::AndKind) = :( $(toexpr(K.a)) ∩ $(toexpr(K.b)) )
toexpr(K::NotKind) = :( !$(toexpr(K.a)) )