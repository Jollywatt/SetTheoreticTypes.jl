module SetTheoreticTypes

export Kind, KindVar, ParametricKind, OrKind, AndKind, NotKind

export Top, Bottom

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
end

"""
	AndKind(a, b)

Set-theoretic intersection kind-type, dual to `OrKind`.
Has no analogue in base Julia.
"""
struct AndKind
	a
	b
end

"""
	NotKind(a)

Set-theoretic complement kind-type.
Has no analogue in base Julia.
"""
struct NotKind
	a
end

const Top = Kind(:Top, nothing, [], false)
const Bottom = Kind(:Bottom, nothing, [], false)


include("show.jl")


end # module SetTheoreticTypes
