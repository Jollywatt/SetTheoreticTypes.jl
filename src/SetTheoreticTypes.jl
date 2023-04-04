module SetTheoreticTypes

export Kind, KindVar, UnionAllKind, UnionKind, IntersectionKind, ComplementKind
export Top, Bottom

export superkind, superkinds, isconcretekind

"""
	Kind(name, super, parameters, isconcrete)

Set-theoretic kind-type, analogous to `Core.Type`.
"""
struct Kind
	name::Symbol
	super
	parameters::Vector
	isconcrete::Bool
	Kind(name, ::Nothing, parameters, isconcrete) = new(name, nothing, parameters, isconcrete)
	function Kind(name, super, parameters, isconcrete)
		isconcretekind(super) && error("Concrete kinds cannot have subkinds")
		super === Bottom && error("$super cannot have subkinds")
		new(name, super, parameters, isconcrete)
	end
end

"""
	KindVar(name, lb, ub)

Kind-type variable, analogous to `Core.TypeVar`.
"""
struct KindVar
	name::Symbol
	lb
	ub
end
KindVar(name) = KindVar(name, Bottom, Top)

"""
	UnionAllKind(var, body)

Parametric kind-type, analogous to `Core.UnionAll`.
"""
struct UnionAllKind
	var::KindVar
	body
end


"""
	UnionKind(a, b)

Set-theoretic union kind-type, analogous to `Core.Union`.
"""
struct UnionKind
	a
	b
	function UnionKind(A, B)
		A ⊆ B && return B
		A ⊇ B && return A
		!A ⊆ B && return Top
		new(A, B)
	end
end

# distribute over or (like UnionAll distributing over Union)
# UnionAllKind(var, A::UnionKind) = UnionAllKind(var, A.a) ∪ UnionAllKind(var, A.b)

"""
	IntersectionKind(a, b)

Set-theoretic intersection kind-type, dual to `UnionKind`.
Has no analogoue in base Julia.
"""
struct IntersectionKind
	a
	b
	function IntersectionKind(A, B)
		A ⊆ B && return A
		A ⊇ B && return B
		A ⊆ !B && return Bottom
		new(A, B)
	end
end

"""
	ComplementKind(a)

Set-theoretic complement kind-type.
Has no analogoue in base Julia.
"""
struct ComplementKind
	a
	ComplementKind(A) = new(A)	
	ComplementKind(A::ComplementKind) = A.a
	ComplementKind(A::UnionKind) = IntersectionKind(!A.a, !A.b)
	ComplementKind(A::IntersectionKind) = UnionKind(!A.a, !A.b)
end

isconcretekind(A::Kind) = A.isconcrete && !any(p -> p isa KindVar, A.parameters)
isconcretekind(A::UnionAllKind) = false
isconcretekind(A::UnionKind) = false
isconcretekind(A::IntersectionKind) = false
isconcretekind(A::ComplementKind) = false

const Kinds = Union{Kind,UnionAllKind,UnionKind,IntersectionKind,ComplementKind}

const Top = Kind(:Top, nothing, [], false)
const Bottom = ComplementKind(Top)


include("utils.jl")
include("operations.jl")
include("relations.jl")
include("show.jl")


end # module SetTheoreticTypes
