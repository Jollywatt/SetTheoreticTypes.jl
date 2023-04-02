substitute(A::KindVar, (from, to)::Pair{KindVar}) = A === from ? to : A

function substitute(A::Kind, (from, to)::Pair{KindVar})
	(A === Bottom || A === Top) && return A

	parameters = map(A.parameters) do p
		substitute(p, from => to)
	end

	Kind(A.name, substitute(A.super, from => to), parameters, A.isconcrete)
end

function substitute(A::ParametricKind, (from, to)::Pair{KindVar})
	body = substitute(A.body, from => to)
	A.var === from ? body : ParametricKind(body, A.var)
end

apply_kind(A) = A
apply_kind(A::ParametricKind, B) = substitute(A, A.var => B)
apply_kind(A, B) = error("Cannot apply $B to kind $A: no free parameters.")
apply_kind(A, B, C...) = apply_kind(apply_kind(A, B), C...)


Kinds = Union{Kind,ParametricKind,OrKind,AndKind,NotKind}



isconcretekind(A::Kind) = A.isconcrete && !any(p -> p isa KindVar, A.parameters)
isconcretekind(A::AndKind) = false
isconcretekind(A::OrKind)  = false
isconcretekind(A::NotKind) = false




function Base.getindex(A::Kinds, B...)
	apply_kind(A, B...)
end

Base.union(A::Union{Kinds,KindVar}, B::Union{Kinds,KindVar}) = OrKind(A, B)
Base.intersect(A::Union{Kinds,KindVar}, B::Union{Kinds,KindVar}) = AndKind(A, B)
Base.:!(A::Union{Kinds,KindVar}) = NotKind(A)