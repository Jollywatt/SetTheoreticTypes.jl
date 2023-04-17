Base.:(==)(A::Kinds, B::Kinds) = A ⊆ B ⊆ A

#=
We want to write many methods of the form:

	issubkind!(ctx, A, B) = issubkind!(ctx, x, y) && ...

With the macro `@ctx`, this becomes:

	@ctx A ⊆ B = x ⊆ y && ...

which is a little easier.
=#

SimpleKind = Union{Kind}

function issubkind! end

@ctx A::SimpleKind       ⊆ B::UnionKind        = A ⊆ B.a || A ⊆ B.b
@ctx A::UnionKind        ⊆ B::SimpleKind       = A.a ⊆ B && A.b ⊆ B
@ctx A::UnionKind        ⊆ B::UnionKind        = A.a ⊆ B && A.b ⊆ B

@ctx A::IntersectionKind ⊆ B::SimpleKind       = A.a ⊆ B || A.b ⊆ B
@ctx A::SimpleKind       ⊆ B::IntersectionKind = A ⊆ B.a && A ⊆ B.b
@ctx A::IntersectionKind ⊆ B::IntersectionKind = A ⊆ B.a && A ⊆ B.b

@ctx A::UnionKind        ⊆ B::IntersectionKind = A ⊆ B.a && A ⊆ B.b
@ctx A::IntersectionKind ⊆ B::UnionKind        = A ⊆ B.a || A ⊆ B.b


# Derived from De Morgan’s laws
@ctx A::IntersectionKind ⊆ B::ComplementKind   = B.a ⊆ !A.a ∪ !A.b # <== A.a ∩ A.b ⊆ !B.a
@ctx A::ComplementKind   ⊆ B::IntersectionKind = !B.a ∪ !B.b ⊆ A.a # <== !A.a ⊆ B.a ∩ B.b
@ctx A::UnionKind        ⊆ B::ComplementKind   = B.a ⊆ !A.a ∩ !A.b # <== A.a ∪ A.b ⊆ !B.a
@ctx A::ComplementKind   ⊆ B::UnionKind        = !B.a ∩ !B.b ⊆ A.a # <== !A.a ⊆ B.a ∪ B.b


@ctx A::ComplementKind   ⊆ B::ComplementKind   = B.a ⊆ A.a # <== !A.a ⊆ !B.a
@ctx A::ComplementKind   ⊆ B::SimpleKind       = A === Bottom || B === Top # sus
function issubkind!(ctx, A::SimpleKind, B::ComplementKind)
	A !== Bottom === B && return false
	A === Top !== B && return false

	# α ∉ !B ==> α ∈ B
	isconcretekind(A) && A ⊈ B.a && return true

	# β ∉ A => A ⊆ !β
	isconcretekind(B.a) && B.a ⊈ A && return true

	# A ⊆ sup(A) && sup(A) ⊆ B ==> A ⊆ B
	@ctx superkind(A) ⊆ B && return true

	# !B ⊆ sup(!B) && A ⊆ !sup(!B) ==> A ⊆ B
	@ctx B.a isa Kind && A ⊆ !B.a.super && return true

	false
end


#= Parametric kinds =#

function tighten!(ctx, var; lb=nothing, ub=nothing)
	(old_lb, old_ub) = get(ctx, var, (var.lb, var.ub))

	!isnothing(lb) && (lb = @ctx old_lb ⊆ lb ? lb : old_lb)
	!isnothing(ub) && (ub = @ctx ub ⊆ old_ub ? ub : old_ub)

	ctx[var] = (lb = something(lb, old_lb), ub = something(ub, old_ub))
	true
end

getctx(ctx, A) = get(ctx, A, (lb = A.lb, ub = A.ub))

# A KindVar may be thought of as the set `setdiff(B.ub, B.lb)`.
# When variables are involved, `A ⊆ B` should be interpreted as:
# “is it POSSIBLE for A ⊆ B? If so, tighten variable constraints to guarantee it.”
@ctx A::Kinds   ⊆ B::KindVar = A ⊆ getctx(ctx, B).ub && tighten!(ctx, B; lb = A)
@ctx A::KindVar ⊆ B::Kinds   = getctx(ctx, A).lb ⊆ B && tighten!(ctx, A; ub = B)
@ctx A::KindVar ⊆ B::KindVar = getctx(ctx, A).ub ⊆ getctx(ctx, B).lb || getctx(ctx, A).lb ⊆ getctx(ctx, B).ub # Tighten? Which?

parametersagree!(ctx, a, b) = a === b
parametersagree!(ctx, a::Union{Kinds,KindVar}, b::Union{Kinds,KindVar}) = @ctx a ⊆ b

function issubkind!(ctx, A::Kind, B::Kind)
	(A === Bottom || B === Top) && return true
	(A === Top || B === Bottom) && return false

	A.name === B.name || return @ctx superkind(A) ⊆ B

	for (a, b) in zip(A.parameters, B.parameters)
		parametersagree!(ctx, a, b) && parametersagree!(ctx, b, a) || return false
	end
	true
end

@ctx function (A::TupleKind ⊆ B::TupleKind)
	length(A.kinds) === length(B.kinds) || return false

	for (a, b) in zip(A.kinds, B.kinds)
		parametersagree!(ctx, a, b) || return false
	end
	true
end


function issubkind!(ctx, A::Kinds, B::UnionAllKind)
	subctx = copy(ctx)
	tighten!(subctx, B.var)
	issubkind!(subctx, A, B.body)
end
function issubkind!(ctx, A::UnionAllKind, B::Kinds)
	subctx = copy(ctx)
	tighten!(subctx, A.var)
	if issubkind!(subctx, A.body, B)
		#TODO: think this through. Why does it work?
		filter(subctx) do (var, (lb, ub))
			lb == ub
		end |> isempty
	else
		false
	end

end
function issubkind!(ctx, A::UnionAllKind, B::UnionAllKind)
	subctx = copy(ctx)
	tighten!(subctx, A.var)
	tighten!(subctx, B.var)
	issubkind!(subctx, A.body, B.body)

end

issubkind!(ctx, A::UnionKind, B::UnionAllKind) = issubkind!(ctx, A.a, B) && issubkind!(ctx, A.b, B)
 