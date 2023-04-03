Base.:(==)(A::Kinds, B::Kinds) = A ⊆ B ⊆ A

#=
We want to write many methods of the form:

	issubkind!(ctx, A, B) = issubkind!(ctx, x, y) && ...

With the macro `@ctx`, this becomes:

	@ctx A ⊆ B = x ⊆ y && ...

which is a little easier.
=#

@ctx A::Kind    ⊆ B::OrKind  = A ⊆ B.a || A ⊆ B.b
@ctx A::OrKind  ⊆ B::Kind    = A.a ⊆ B && A.b ⊆ B
@ctx A::OrKind  ⊆ B::OrKind  = A.a ⊆ B && A.b ⊆ B

@ctx A::AndKind ⊆ B::Kind    = A.a ⊆ B || A.b ⊆ B
@ctx A::Kind    ⊆ B::AndKind = A ⊆ B.a && A ⊆ B.b
@ctx A::AndKind ⊆ B::AndKind = A ⊆ B.a && A ⊆ B.b

@ctx A::OrKind  ⊆ B::AndKind = A ⊆ B.a && A ⊆ B.b
@ctx A::AndKind ⊆ B::OrKind  = A ⊆ B.a || A ⊆ B.b


function issubkind!(ctx, A::Kind, B::NotKind)
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

@ctx A::NotKind ⊆ B::Kind = A === Bottom || B === Top # sus
@ctx A::NotKind ⊆ B::NotKind = B.a ⊆ A.a # <== !A.a ⊆ !B.a


# Derived from De Morgan’s laws
@ctx A::AndKind ⊆ B::NotKind = B.a ⊆ !A.a ∪ !A.b # <== A.a ∩ A.b ⊆ !B.a
@ctx A::NotKind ⊆ B::AndKind = !B.a ∪ !B.b ⊆ A.a # <== !A.a ⊆ B.a ∩ B.b
@ctx A::OrKind  ⊆ B::NotKind = B.a ⊆ !A.a ∩ !A.b # <== A.a ∪ A.b ⊆ !B.a
@ctx A::NotKind ⊆ B::OrKind  = !B.a ∩ !B.b ⊆ A.a # <== !A.a ⊆ B.a ∪ B.b




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

issubkind!(ctx, A::Kinds, B::ParametricKind) = issubkind!(copy(ctx), A, B.body)
issubkind!(ctx, A::ParametricKind, B::Kinds) = issubkind!(copy(ctx), A.body, B)
issubkind!(ctx, A::ParametricKind, B::ParametricKind) = issubkind!(copy(ctx), A.body, B.body)

issubkind!(ctx, A::OrKind, B::ParametricKind) = issubkind!(copy(ctx), A.a, B.body) && issubkind!(copy(ctx), A.b, B.body)
