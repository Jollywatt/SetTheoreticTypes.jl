using SetTheoreticTypes
using Test

@testset "unions and intersections" begin

	A = Kind(:A, Top, [], false)
	B = Kind(:B, Top, [], false)

	@testset "simple abstract kinds" begin
		@test A ⊆ A

		@test A ⊆ A ∪ B ⊇ B
		@test A ⊇ A ∩ B ⊆ B

		@test A ∩ B ⊆ A ∪ B
		@test A ∪ B ⊆ B ∪ A
		@test A ∩ B ⊆ B ∩ A

		@test A ∩ Bottom === Bottom
		@test A ∪ Top === Top

		@test A ∪ A === A === A ∩ A
	end

	α = Kind(:α, A, [], true)
	β = Kind(:β, B, [], true)
	γ = Kind(:γ, A ∩ B, [], true)

	@testset "simple concrete kinds" begin
		@test α ∪ A === A
		@test B ∪ β === B

		@test α ∪ β == β ∪ α
		@test α ∩ β === Bottom
		@test γ ⊆ A ∩ B
		@test γ ⊆ A && γ ⊆ B

		@test α ∪ β ⊆ A ∪ B
		@test α ∪ β ∪ γ ⊆ A ∪ B
		@test α ∪ γ ⊆ A
		@test β ∪ γ ⊆ B
	end

end


@testset "complements" begin

	@test !Top === Bottom
	@test Top === !Bottom

	A = Kind(:A, Top, [], false)
	B = Kind(:B, Top, [], false)
	α = Kind(:α, A, [], true)
	β = Kind(:β, B, [], true)
	γ = Kind(:γ, A ∩ B, [], true)

	#= Kind-space diagram
	Each point is a concrete kind; non-concrete kinds are shown as sets.
	Concrete kinds cannot have subkinds, and hence can be thought of
	as points (or singleton sets) which contain only one kind: themselves.
	┌─────────────── Top ──────────────┐
	│  ┌────── A ────────┐             │
	│  │  ·α      ┌──────┼─── B ────┐  │
	│  │          │  ·γ  │          │  │
	│  └──────────┼──────┘    ·β    │  │
	│             └─────────────────┘  │
	└──────────────────────────────────┘
	Note that we usually think of both concrete and non-concrete types
	as sets of point-like values or instances. Here, we are thinking of
	non-concrete kinds as sets of point-like concrete kinds.
	=#

	@test !!A === A

	@test A ∪ !A === Top
	@test A ∩ !A === Bottom

	@test !A ⊆ !α

	@test α ⊈ !A
	@test α ⊆ !B
	@test B ⊆ !α
	@test γ ⊈ !A ∪ !B
	

	@test !(A ∪ B) == !A ∩ !B
	@test !(A ∩ B) == !A ∪ !B

	@test !A ∩ !B ⊆ !(α ∪ β)
	@test !(A ∩ B) ⊆ !α ∪ !β

	@test !(A ∩ B) ⊆ !γ


	#=
	┌─────────── Top ───────────────────┐
	│  ┌─── A ──┐                       │
	│  │ ·α     │    ┌─── C ─────────┐  │
	│  │ ┌─ B ──┼────┼───────┐       │  │
	│  │ │      │    │ ┌ D ┐ │ ┌ E ┐ │  │
	│  │ │  ·γ  │ ·β │ │·ε │ │ │·ζ │ │  │
	│  │ │      │    │ └───┘ │ └───┘ │  │
	│  │ │      │    │  ·η   │  ·δ   │  │
	│  │ └──────┼────┼───────┘       │  │
	│  └────────┘    └───────────────┘  │
	└───────────────────────────────────┘
	=#

	C = Kind(:C, !A, [], false)
	@test C ⊆ !A
	@test A ⊆ !C
	@test B ∩ C ⊆ !A

	@test A ∩ C === Bottom
	@test β ⊆ !(A ∪ C)

	@test C ⊆ !β
	@test β ⊈ C

	δ = Kind(:δ, C, [], true)
	D = Kind(:D, B ∩ C, [], false)
	E = Kind(:E, !B ∩ C, [], false)
	@test D ∪ C === C
	@test D ∩ C === D
	@test D ∩ E === Bottom
	@test A ∩ D === Bottom
	@test B ∩ E === Bottom

	@test D ⊆ (B ∪ E) ∩ C ⊆ !A
	@test !B ⊆ !D

	@test δ ⊆ C ∩ !E
	@test A ⊆ !δ

	ε = Kind(:ε, D, [], true)
	ζ = Kind(:ζ, E, [], true)
	η = Kind(:η, B ∩ C, [], true)

	@test η ⊈ D
	@test η ⊆ !A ∩ B ∩ C ∩ !D ∩ !E

end


@testset "parametric kinds" begin

	# Here we mirror some of Julia’s built-in types
	# so that each kind test can be sanity-checked
	# by pairing it with the corresponding type test.

	Number′  = Kind(:Number,  Top,      [], false)
	Real′    = Kind(:Real,    Number′,  [], false)
	Integer′ = Kind(:Integer, Real′,    [], false)
	Signed′  = Kind(:Signed,  Integer′, [], false)
	Int′     = Kind(:Int,     Signed′,  [], true)
	Bool′    = Kind(:Bool,    Integer′, [], true)
	Complex′ = let T = KindVar(:T, Bottom, Real′)
		UnionAllKind(T, Kind(:Complex, Number′, [T], true))
	end

	@test Int <: Signed <: Integer <: Real <: Number <: Any
	@test Int′ ⊆ Signed′ ⊆ Integer′ ⊆ Real′ ⊆ Number′ ⊆ Top

	@testset "mirroring simple number types" begin
		@test Int <: Number
		@test Int′ ⊆ Number′

		@test Union{Int,Real} === Real
		@test Int′ ∪ Real′ === Real′

		@test Complex{Int} <: Complex <: Number <: Any
		@test Complex′[Int′] ⊆ Complex′ ⊆ Number′ ⊆ Top

		@test !(Complex{Int} <: Complex{Real})
		@test Complex′[Int′] ⊈ Complex′[Real′]

		@test Complex{Union{Bool,Int}} <: Complex{<:Integer}
		@test let T = KindVar(:T, Bottom, Integer′)
			Complex′[Bool′ ∪ Int′] ⊆ UnionAllKind(T, Complex′[T])
		end

		@test isconcretetype(Complex{Int})
		@test isconcretekind(Complex′[Int′])
	end

	@testset "single abstract parameter" begin
		X = KindVar(:X)

		abstract type Boxlike{T} end
		Boxlike′ = UnionAllKind(X, Kind(:Boxlike, Top, [X], false))

		struct Box{T} <: Boxlike{T} end
		Box′ = UnionAllKind(X, Kind(:Box, Boxlike′[X], [X], true))

		abstract type Animal end
		Animal′ = Kind(:Animal, Top, [], false)

		struct Cat end
		Cat′ = Kind(:Cat, Animal′, [], true)

		@test Box′ ⊆ Boxlike′
		@test Box <: Boxlike

		@test Box′[Cat′] ⊆ Box′
		@test Box{Cat} <: Box

		@test Box{Cat} <: Boxlike{Cat}
		@test Box′[Cat′] ⊆ Boxlike′[Cat′]

		@test supertype(Box{Cat}) == Boxlike{Cat}
		@test superkind(Box′[Cat′]) == Boxlike′[Cat′]

		@test !(Box{Cat} <: Box{Animal})
		@test Box′[Cat′] ⊈ Box′[Animal′]

		Y = KindVar(:Y, Bottom, Animal′)
		@test Box′[Cat′] ⊆ UnionAllKind(Y, Box′[Y])

		@test !(Box{Box{Cat}} <: Box{Box})
		@test Box′[Box′[Cat′]] ⊈ Box′[Box′]
		
		@test Box{Box{Cat}} <: Box{Box{T}} where T
		@test let T = KindVar(:T)
			Box′[Box′[Cat′]] ⊆ UnionAllKind(T, Box′[Box′[T]])
		end

		@test !(Box{Cat} <: Box{>:Animal})
		@test let T = KindVar(:T, Animal′, Top)
			Box′[Cat′] ⊈ UnionAllKind(T, Box′[T])
		end
		
	end


	@testset "multiple parameters" begin
		
		T, D = KindVar.([:T, :D])

		AbstractArray′ = UnionAllKind(T, UnionAllKind(D, Kind(:AbstractArray, Top, [T,D], false)))
		DenseArray′    = UnionAllKind(T, UnionAllKind(D, Kind(:DenseArray, AbstractArray′[T,D], [T,D], false)))
		Array′         = UnionAllKind(T, UnionAllKind(D, Kind(:Array, DenseArray′[T,D], [T,D], false)))

		AbstractVector′ = UnionAllKind(T, AbstractArray′[T,1])
		DenseVector′    = UnionAllKind(T, DenseArray′[T,1])
		Vector′         = UnionAllKind(T, Array′[T,1])

		@test Vector{Int} <: AbstractVector{Int} <: AbstractArray{Int,1}
		@test Vector′[Int′] ⊆ AbstractVector′[Int′] ⊆ AbstractArray′[Int′,1]

		@test Vector{Int} <: Array{T,1} where T
		@test Vector′[Int′] ⊆ UnionAllKind(T, Array′[T,1])

		@test Union{Complex,Vector} <: Union{Complex{T},Vector{T}} where T
		@test Complex′ ∪ Vector′ ⊆ UnionAllKind(T, Complex′[T] ∪ Vector′[T])

		A, B = KindVar.([:A, :B])
		Pair′ = UnionAllKind(A, UnionAllKind(B, Kind(:Pair, Top, [A, B], true)))

		@test !(Pair{Int,Bool} <: Pair{T,T} where T)
		@test Pair′[Int′,Bool′] ⊈ UnionAllKind(T, Pair′[T,T])

		@test Union{Complex{Int},Vector{Bool}} <: Union{Complex{T},Vector{T}} where T
		@test Complex′[Int′] ∪ Vector′[Bool′] ⊆ UnionAllKind(T, Complex′[T] ∪ Vector′[T])

		@test Union{Vector{Int},Vector{Bool}} <: Vector{<:Union{Int,Bool}}
		@test let T = KindVar(:T, Bottom, Int′ ∪ Bool′)
			Vector′[Int′] ∪ Vector′[Bool′] ⊆ UnionAllKind(T, Vector′[T])
		end

	end

	@testset "intersections and complements" begin
		
		T, S = KindVar.([:T, :S])

		A = Kind(:A, Top, [], false)
		B = Kind(:B, Top, [], false)

		P = UnionAllKind(T, Kind(:P, Top, [T], false))
		Q = UnionAllKind(T, Kind(:Q, Top, [T], false))
		P2 = UnionAllKind(T, UnionAllKind(S, Kind(:P2, Top, [T, S], false)))

		@test P[A] ∪ P[B] ⊆ UnionAllKind(T, P[T])
		@test P[A] ∩ P[B] ⊆ UnionAllKind(T, P[T])

		@test P[A] ∪ Q[B] ⊆ UnionAllKind(T, P[T] ∪ Q[T])
		@test P[A] ∩ Q[B] ⊈ UnionAllKind(T, P[T] ∩ Q[T])

		@test P2[A,B] ⊈ UnionAllKind(T, P2[T,T])

		@test (Pair{T,T} where T) <: Pair{T,S} where T where S
		@test UnionAllKind(T, P2[T,T]) ⊆ UnionAllKind(T, UnionAllKind(S, P2[T,S]))

		@test P2[A,B] ⊈ UnionAllKind(T, P2[T,T])

		# Ok, this one requires explanation:
		@test P2[A,B] ⊈ !UnionAllKind(T, P2[T,T])
		# We don’t expect P2[A,B] ⊆ !(P2[T, T] where T)
		# because P2[A,B] is not a concrete kind, and
		# hence the intersection
		@test P2[A,B] ∩ UnionAllKind(T, P2[T,T]) !== Bottom
		# is not empty. Indeed, we can directly construct a kind
		Weird = Kind(:Weird, P2[A,B] ∩ P2[A,A], [], false)
		# which is a subset of this intersection:
		@test Weird ⊆ P2[A,B]
		@test Weird ⊆ UnionAllKind(T, P2[T,T])
		@test Weird ⊆ P2[A,B] ∩ UnionAllKind(T, P2[T,T])

		# This changes with concrete kinds, however.
		π2 = UnionAllKind(T, UnionAllKind(S, Kind(:π2, Top, [T, S], true)))
		# Now, we have
		@test π2[A,B] ⊆ !UnionAllKind(T, π2[T,T])
		# because the intersection
		@test π2[A,B] ∩ UnionAllKind(T, π2[T,T]) === Bottom
		# is indeed empty.
	end
end


nothing