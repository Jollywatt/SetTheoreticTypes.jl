superkind(A::Kind) = A === Top ? Top : A.super

function parametersagree!(state, A, B::KindVar)
	B.lb ⊆ A ⊆ B.ub || return false
	if B ∈ keys(state)
		state[B] == A
	else
		state[B] = A
		true
	end
end
function parametersagree!(state, A::Kind, B::Kind)
	A.name === B.name && length(A.parameters) === length(B.parameters) || return false
	all(zip(A.parameters, B.parameters)) do (a, b)
		parametersagree!(state, a, b)
	end
end

function issubset(A::Kind, B::Kind)
	(A === Bottom || B === Top) && return true
	(B === Bottom || A === Top) && return false

	parametersagree!(IdDict(), A, B) || superkind(A) ⊆ B
end

function issubset(A::Kind, B::ParametricKind)
	# todo: is this correct?
	A ⊆ B.body
end


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

issubset(A::NotKind, B::Kind) = B === Top # sus
issubset(A::NotKind, B::NotKind) = B.a ⊆ A.a # <== !A.a ⊆ !B.a


# Derived from De Morgan’s laws
issubset(A::AndKind, B::NotKind) = B.a ⊆ !A.a ∪ !A.b # <== A.a ∩ A.b ⊆ !B.a
issubset(A::NotKind, B::AndKind) = !B.a ∪ !B.b ⊆ A.a # <== !A.a ⊆ B.a ∩ B.b
issubset(A::OrKind,  B::NotKind) = B.a ⊆ !A.a ∩ !A.b # <== A.a ∪ A.b ⊆ !B.a
issubset(A::NotKind, B::OrKind)  = !B.a ∩ !B.b ⊆ A.a # <== !A.a ⊆ B.a ∪ B.b


Base.:(==)(A::Kinds, B::Kinds) = A ⊆ B ⊆ A