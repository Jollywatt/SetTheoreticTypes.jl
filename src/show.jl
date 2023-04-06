struct DisplayWrapper
	showfn
	value
end
Base.show(io::IO, a::DisplayWrapper) = a.showfn(io, a.value)

toexpr(a) = a
function toexpr(K::Kind)
	name = K.name
	expr = if isempty(K.parameters)
		name
	else
		:( $name[$(toexpr.(K.parameters)...)] )
	end
	isconcretekind(K) || return expr
	DisplayWrapper(expr) do io, x
		printstyled(io, x, underline=true)
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
# toexpr(K::UnionAllKind) = :( $(toexpr(K.body)) where $(toexpr(K.var)) )
toexpr(K::UnionAllKind) = :( UnionAllKind($(toexpr(K.var)), $(toexpr(K.body))) )
toexpr(K::UnionKind) = :( $(toexpr(K.a)) ∪ $(toexpr(K.b)) )
toexpr(K::IntersectionKind) = :( $(toexpr(K.a)) ∩ $(toexpr(K.b)) )
toexpr(K::ComplementKind) = :( !$(toexpr(K.a)) )



function Base.show(io::IO, K::Union{
	Kind,KindVar,UnionAllKind,UnionKind,IntersectionKind,ComplementKind,
	KindInstance,
	})
	Base.show_unquoted(io, toexpr(K))
end


function Base.show(io::IO, a::KindInstance)
	show(io, a.kind)
	print(io, "(", repr(a.value), ")")
end