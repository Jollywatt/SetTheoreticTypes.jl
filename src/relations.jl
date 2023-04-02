Base.:(==)(A::Kinds, B::Kinds) = A ⊆ B ⊆ A

superkind(A::Kind) = A === Top ? Top : A.super


issubset(A::Kind,    B::OrKind)  = A ⊆ B.a || A ⊆ B.b
issubset(A::OrKind,  B::Kind)    = A.a ⊆ B && A.b ⊆ B
issubset(A::OrKind,  B::OrKind)  = A.a ⊆ B && A.b ⊆ B

issubset(A::AndKind, B::Kind)    = A.a ⊆ B || A.b ⊆ B
issubset(A::Kind,    B::AndKind) = A ⊆ B.a && A ⊆ B.b
issubset(A::AndKind, B::AndKind) = A ⊆ B.a && A ⊆ B.b

issubset(A::OrKind,  B::AndKind) = A ⊆ B.a && A ⊆ B.b
issubset(A::AndKind, B::OrKind)  = A ⊆ B.a || A ⊆ B.b


function issubset(A::Kind, B::NotKind)
	A !== Bottom === B && return false
	A === Top !== B && return false

	# α ∉ !B ==> α ∈ B
	isconcretekind(A) && A ⊈ B.a && return true

	# β ∉ A => A ⊆ !β
	isconcretekind(B.a) && B.a ⊈ A && return true

	# A ⊆ sup(A) && sup(A) ⊆ B ==> A ⊆ B
	A.super ⊆ B && return true

	# !B ⊆ sup(!B) && A ⊆ !sup(!B) ==> A ⊆ B
	B.a isa Kind && A ⊆ !B.a.super && return true

	false
end

issubset(A::NotKind, B::Kind) = A === Bottom || B === Top # sus
issubset(A::NotKind, B::NotKind) = B.a ⊆ A.a # <== !A.a ⊆ !B.a


# Derived from De Morgan’s laws
issubset(A::AndKind, B::NotKind) = B.a ⊆ !A.a ∪ !A.b # <== A.a ∩ A.b ⊆ !B.a
issubset(A::NotKind, B::AndKind) = !B.a ∪ !B.b ⊆ A.a # <== !A.a ⊆ B.a ∩ B.b
issubset(A::OrKind,  B::NotKind) = B.a ⊆ !A.a ∩ !A.b # <== A.a ∪ A.b ⊆ !B.a
issubset(A::NotKind, B::OrKind)  = !B.a ∩ !B.b ⊆ A.a # <== !A.a ⊆ B.a ∪ B.b




#= Parametric kinds =#

function iscompatible!(state, (key, val))
	if key ∈ keys(state)
		state[key] == val
	else
		state[key] = val
		true
	end
end

function parametersagree!(state, A, B::KindVar)
	B.lb ⊆ A ⊆ B.ub && iscompatible!(state, B => A)
end
function parametersagree!(state, A::KindVar, B::KindVar)
	A.lb == B.lb && A.ub == B.ub && iscompatible!(state, B => A)
end

function parametersagree!(state, A::Kind, B::Kind)
	A.name === B.name && length(A.parameters) === length(B.parameters) || return false
	for (a, b) in zip(A.parameters, B.parameters)
		parametersagree!(state, a, b) || return false
	end
	true
end
parametersagree!(state, A::T, B::T) where T = A == b
parametersagree!(state, A, B) = false

function issubset(A::Kind, B::Kind)
	(A === Bottom || B === Top) && return true
	(A === Top || B === Bottom) && return false

	parametersagree!(IdDict(), A, B) || superkind(A) ⊆ B
end

issubset(A::Kind, B::ParametricKind) = A ⊆ B.body
issubset(A::ParametricKind, B::Kind) = A.body ⊆ B
issubset(A::ParametricKind, B::ParametricKind) = A.body ⊆ B.body



