Base.:(==)(A::Kinds, B::Kinds) = A ⊆ B ⊆ A

#=
We want to write many methods of the form:

	issubkind!(ctx, A, B) = issubkind!(ctx, x, y) && ...

With the macro `@ctx`, this becomes:

	@ctx A ⊆ B = x ⊆ y && ...

which is a little easier.
=#

@ctx A::Kind       ⊆ B::UnionKind  = A ⊆ B.a || A ⊆ B.b
@ctx A::UnionKind  ⊆ B::Kind       = A.a ⊆ B && A.b ⊆ B
@ctx A::UnionKind  ⊆ B::UnionKind  = A.a ⊆ B && A.b ⊆ B

@ctx A::IntersectionKind ⊆ B::Kind             = A.a ⊆ B || A.b ⊆ B
@ctx A::Kind             ⊆ B::IntersectionKind = A ⊆ B.a && A ⊆ B.b
@ctx A::IntersectionKind ⊆ B::IntersectionKind = A ⊆ B.a && A ⊆ B.b

@ctx A::UnionKind  ⊆ B::IntersectionKind = A ⊆ B.a && A ⊆ B.b
@ctx A::IntersectionKind ⊆ B::UnionKind  = A ⊆ B.a || A ⊆ B.b


function issubkind!(ctx, A::Kind, B::ComplementKind)
	A !== Bottom === B && return false
	A === Top !== B && return false

	# α ∉ !B ==> α ∈ B
	isconcretekind(A) && A ⊈ B.a && return true

	# β ∉ A => A ⊆ !β
	isconcretekind(B.a) && B.a ⊈ A && return true

	# A ⊆ sup(A) && sup(A) ⊆ B ==> A ⊆ B
	@ctx A.super ⊆ B && return true

	# !B ⊆ sup(!B) && A ⊆ !sup(!B) ==> A ⊆ B
	@ctx B.a isa Kind && A ⊆ !B.a.super && return true

	false
end

@ctx A::ComplementKind ⊆ B::Kind = A === Bottom || B === Top # sus
@ctx A::ComplementKind ⊆ B::ComplementKind = B.a ⊆ A.a # <== !A.a ⊆ !B.a


# Derived from De Morgan’s laws
@ctx A::IntersectionKind ⊆ B::ComplementKind   = B.a ⊆ !A.a ∪ !A.b # <== A.a ∩ A.b ⊆ !B.a
@ctx A::ComplementKind   ⊆ B::IntersectionKind = !B.a ∪ !B.b ⊆ A.a # <== !A.a ⊆ B.a ∩ B.b
@ctx A::UnionKind        ⊆ B::ComplementKind   = B.a ⊆ !A.a ∩ !A.b # <== A.a ∪ A.b ⊆ !B.a
@ctx A::ComplementKind   ⊆ B::UnionKind        = !B.a ∩ !B.b ⊆ A.a # <== !A.a ⊆ B.a ∪ B.b




#= Parametric kinds =#

function iscompatible!(ctx, (key, val))
	key ∈ keys(ctx) || (ctx[key] = val)
	ctx[key] == val
end

function parametersagree!(ctx, A, B::KindVar)
	@ctx B.lb ⊆ A ⊆ B.ub && iscompatible!(ctx, B => A)
end
function parametersagree!(ctx, A::KindVar, B::KindVar)
	@ctx A.lb ⊆ B.lb && A.ub ⊆ B.ub && iscompatible!(ctx, B => A)
end
function parametersagree!(ctx, A::Kind, B::Kind)
	A.name === B.name && length(A.parameters) === length(B.parameters) || return false
	for (a, b) in zip(A.parameters, B.parameters)
		parametersagree!(ctx, a, b) || return false
	end
	true
end
parametersagree!(ctx, A::T, B::T) where T = A == B
parametersagree!(ctx, A, B) = false


function issubkind!(ctx, A::Kind, B::Kind)
	(A === Bottom || B === Top) && return true
	(A === Top || B === Bottom) && return false

	parametersagree!(ctx, A, B) || superkind(A) ⊆ B
end

issubkind!(ctx, A::Kinds,        B::UnionAllKind) = issubkind!(copy(ctx), A, B.body)
issubkind!(ctx, A::UnionAllKind, B::Kinds)        = issubkind!(copy(ctx), A.body, B)
issubkind!(ctx, A::UnionAllKind, B::UnionAllKind) = issubkind!(copy(ctx), A.body, B.body)

issubkind!(ctx, A::UnionKind, B::UnionAllKind) = issubkind!(copy(ctx), A.a, B.body) && issubkind!(copy(ctx), A.b, B.body)
