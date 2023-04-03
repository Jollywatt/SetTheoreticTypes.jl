module SetTheoreticTypes

export Kind, KindVar, ParametricKind, OrKind, AndKind, NotKind
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
	ParametricKind(var, body)

Parametric kind-type, analogous to `Core.UnionAll`.
"""
struct ParametricKind
	var
	body
end


"""
	OrKind(a, b)

Set-theoretic union kind-type, analogous to `Core.Union`.
"""
struct OrKind
	a
	b
	function OrKind(A, B)
		A ⊆ B && return B
		A ⊇ B && return A
		!A ⊆ B && return Top
		new(A, B)
	end
end

# distribute over or (like UnionAll distributing over Union)
# ParametricKind(var, A::OrKind) = ParametricKind(var, A.a) ∪ ParametricKind(var, A.b)

"""
	AndKind(a, b)

Set-theoretic intersection kind-type, dual to `OrKind`.
Has no analogoue in base Julia.
"""
struct AndKind
	a
	b
	function AndKind(A, B)
		A ⊆ B && return A
		A ⊇ B && return B
		A ⊆ !B && return Bottom
		new(A, B)
	end
end

"""
	NotKind(a)

Set-theoretic complement kind-type.
Has no analogoue in base Julia.
"""
struct NotKind
	a
	NotKind(A) = new(A)	
	NotKind(A::NotKind) = A.a
	NotKind(A::OrKind)  = AndKind(!A.a, !A.b)
	NotKind(A::AndKind) = OrKind(!A.a, !A.b)
end

isconcretekind(A::Kind) = A.isconcrete && !any(p -> p isa KindVar, A.parameters)
isconcretekind(A::ParametricKind) = false
isconcretekind(A::OrKind)  = false
isconcretekind(A::AndKind) = false
isconcretekind(A::NotKind) = false

const Kinds = Union{Kind,ParametricKind,OrKind,AndKind,NotKind}

const Top = Kind(:Top, nothing, [], false)
const Bottom = NotKind(Top)


include("utils.jl")
include("operations.jl")
include("relations.jl")
include("show.jl")


end # module SetTheoreticTypes
