module SetTheoreticTypes

import Base: issubset

export Kind, KindVar, ParametricKind, OrKind, AndKind, NotKind
export Top, Bottom

export superkind

"""
	Kind(name, super, parameters, isconcrete)

Set-theoretic kind-type, analogue of `Core.Type`.
"""
struct Kind
	name::Symbol
	super
	parameters::Vector
	isconcrete::Bool
end

"""
	KindVar(name, lb, ub)

Kind-type variable, analogue of `Core.TypeVar`.
"""
struct KindVar
	name::Symbol
	lb
	ub
end
KindVar(name) = KindVar(name, Bottom, Top)

"""
	ParametricKind(var, body)

Parametric kind-type, analogue of `Core.UnionAll`.
"""
struct ParametricKind
	var
	body
end


"""
	OrKind(a, b)

Set-theoretic union kind-type, analogue of `Core.Union`.
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

"""
	AndKind(a, b)

Set-theoretic intersection kind-type, dual to `OrKind`.
Has no analogue in base Julia.
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
Has no analogue in base Julia.
"""
struct NotKind
	a
	function NotKind(A)
		A === Top && return Bottom
		A === Bottom && return Top
		new(A)	
	end
	NotKind(A::NotKind) = A.a
	NotKind(A::OrKind)  = AndKind(!A.a, !A.b)
	NotKind(A::AndKind) = OrKind(!A.a, !A.b)
end

const Top = Kind(:Top, nothing, [], false)
const Bottom = Kind(:Bottom, nothing, [], false)


include("operations.jl")
include("relations.jl")
include("show.jl")


end # module SetTheoreticTypes
