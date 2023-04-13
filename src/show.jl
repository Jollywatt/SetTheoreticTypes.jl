struct DisplayWrapper
	showfn
	value
end
Base.show(io::IO, a::DisplayWrapper) = a.showfn(io, a.value)

toexpr(io, a) = a
function toexpr(io, K::Kind)
	name = K.name
	if isempty(K.parameters)
		name
	else
		:( $name[$(toexpr.(io, K.parameters)...)] )
	end
end
function toexpr(io, K::KindVar)
	expr = DisplayWrapper(K.name) do io, x
		printstyled(io, x, bold=true)
	end

	# check if variable bounds have already been seen; show name only
	K ∈ get(io, :kindvars, Set()) && return expr

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
function toexpr(io, K::UnionAllKind)
	# mark K.var as “seen” and don’t bother displaying its bounds again
	kindvars = get(io, :kindvars, Set{KindVar}()) ∪ Ref(K.var)
	subio = IOContext(io, :kindvars=>kindvars)
	:( $(toexpr(subio, K.body)) where $(toexpr(io, K.var)) )
end

# toexpr(io, K::UnionAllKind)   = :( UnionAllKind($(toexpr(io, K.var)), $(toexpr(io, K.body))) )
toexpr(io, K::UnionKind)        = :( $(toexpr(io, K.a)) ∪ $(toexpr(io, K.b)) )
toexpr(io, K::IntersectionKind) = :( $(toexpr(io, K.a)) ∩ $(toexpr(io, K.b)) )
toexpr(io, K::ComplementKind)   = :( !$(toexpr(io, K.a)) )


function Base.show(io::IO, K::Union{
	Kind,KindVar,UnionAllKind,UnionKind,IntersectionKind,ComplementKind,
	KindInstance,
	})
	Base.show_unquoted(io, toexpr(io, K))
end


function Base.show(io::IO, a::KindInstance)
	show(io, a.kind)
	print(io, "(", repr(a.value), ")")
end