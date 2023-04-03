superkind(A::Kind)  = A === Top ? Top : A.super
function superkinds(A::Kind)
	S = superkind(A)
	A === S ? (A,) : (A, superkinds(S)...)
end

substitute(A::KindVar, (from, to)::Pair{KindVar}) = A === from ? to : A
substitute(A, _) = A

function substitute(A::Kind, (from, to)::Pair{KindVar})
	(A === Bottom || A === Top) && return A

	parameters = map(A.parameters) do p
		substitute(p, from => to)
	end

	Kind(A.name, substitute(A.super, from => to), parameters, A.isconcrete)
end
function substitute(A::ParametricKind, (from, to)::Pair{KindVar})
	body = substitute(A.body, from => to)
	A.var === from ? body : ParametricKind(A.var, body)
end
substitute(A::AndKind, sub) = AndKind(substitute(A.a, sub), substitute(A.b, sub))
substitute(A::OrKind, sub) = OrKind(substitute(A.a, sub), substitute(A.b, sub))
substitute(A::NotKind, sub) = NotKind(substitute(A.a, sub))

apply_kind(A) = A
apply_kind(A::ParametricKind, B) = substitute(A, A.var => B)
apply_kind(A, B) = error("Cannot apply $B to kind $A: no free parameters.")
apply_kind(A, B, C...) = apply_kind(apply_kind(A, B), C...)







function Base.getindex(A::Kinds, B...)
	apply_kind(A, B...)
end

Base.issubset(A::Kinds, B::Kinds) = issubkind!(IdDict(), A, B)

Base.union(A::Union{Kinds,KindVar}, B::Union{Kinds,KindVar}) = OrKind(A, B)
Base.intersect(A::Union{Kinds,KindVar}, B::Union{Kinds,KindVar}) = AndKind(A, B)
Base.:!(A::Union{Kinds,KindVar}) = NotKind(A)