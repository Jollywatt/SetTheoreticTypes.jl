superkind(A::Kind)  = A === Top ? Top : A.super
function superkinds(A::Kind)
	S = superkind(A)
	A === S ? (A,) : (A, superkinds(S)...)
end


function substitute(A::KindVar, (from, to)::Pair{KindVar})
	A === from && return to
	KindVar(A.name, substitute(A.lb, from => to), substitute(A.ub, from => to))
end
function substitute(A::Kind, (from, to)::Pair{KindVar})
	(A === Bottom || A === Top) && return A

	parameters = map(A.parameters) do p
		substitute(p, from => to)
	end

	Kind(A.name, substitute(A.super, from => to), parameters, A.isconcrete)
end
function substitute(A::UnionAllKind, (from, to)::Pair{KindVar})
	body = substitute(A.body, from => to)
	A.var === from && return body
	UnionAllKind(substitute(A.var, from => to), body)
end
substitute(A::IntersectionKind, sub) = IntersectionKind(substitute(A.a, sub), substitute(A.b, sub))
substitute(A::UnionKind, sub) = UnionKind(substitute(A.a, sub), substitute(A.b, sub))
substitute(A::ComplementKind, sub) = ComplementKind(substitute(A.a, sub))
substitute(A, _) = A


apply_kind(A) = A
apply_kind(A::UnionAllKind, B) = substitute(A, A.var => B)
apply_kind(A, B) = error("Cannot apply $B to kind $A: no free parameters.")
apply_kind(A, B, C...) = apply_kind(apply_kind(A, B), C...)



