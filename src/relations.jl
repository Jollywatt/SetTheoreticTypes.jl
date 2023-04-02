superkind(A::Kind) = A === Top ? Top : A.super

function matchparameter!(state, parameter, value)
	if parameter ∈ keys(state)
		state[parameter] == value
	else
		state[parameter] = value
		true
	end
end
parametersagree!(state, A, B::KindVar) = B.lb ⊆ A ⊆ B.ub && matchparameter!(state, A, B)
function parametersagree!(state, A::Kind, B::Kind)
	(A.name, length(A.parameters)) === (B.name, length(B.parameters)) || return false

	all(zip(A.parameters, B.parameters)) do (a, b)
		parametersagree!(state, a, b)
	end
end

function issubset(A::Kind, B::Kind)
	(A === Bottom || B === Top) && return true
	B === Bottom && return false

	if (A.name, length(A.parameters)) === (B.name, length(B.parameters))
		# check parameters agree
		parametersagree!(IdDict(), A, B)


	elseif superkind(A) === Top
		false
	else
		superkind(A) ⊆ B
	end
end

function issubset(A::Kind, B::ParametricKind)
	# todo: is this correct?
	A ⊆ B.body
end


issubset(A::Kinds,   B::OrKind)  = A ⊆ B.a || A ⊆ B.b
issubset(A::OrKind,  B::Kinds)   = A.a ⊆ B && A.b ⊆ B
issubset(A::OrKind,  B::OrKind)  = A.a ⊆ B && A.b ⊆ B

issubset(A::Kinds,   B::AndKind) = A ⊆ B.a && A ⊆ B.b
issubset(A::AndKind, B::Kinds)   = A.a ⊆ B || A.b ⊆ B
issubset(A::AndKind, B::AndKind) = A ⊆ B.a && A ⊆ B.b

issubset(A::AndKind, B::OrKind)  = A ⊆ B.a || A ⊆ B.b
issubset(A::OrKind,  B::AndKind) = A ⊆ B.a && A ⊆ B.b

Base.:(==)(A::Kinds, B::Kinds) = A ⊆ B ⊆ A