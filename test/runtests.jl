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
	Each point is a concrete kind; non-concrete kinds are subsets.
	Concrete kinds cannot have subkinds, and hence can be thought of
	as points or singleton sets which have only one subkind: themselves.
	┌─────────────── Top ──────────────┐
	│  ┌────── A ────────┐             │
	│  │  ·α      ┌──────┼─── B ────┐  │
	│  │          │  ·γ  │          │  │
	│  └──────────┼──────┘    ·β    │  │
	│             └─────────────────┘  │
	└──────────────────────────────────┘
	Note that concrete kinds may be thought of as sets of values,
	even though in these diagrams they appear as points.
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

	Number′ = Kind(:Number, Top, [], false)
	Real′ = Kind(:Real, Number′, [], false)
	Integer′ = Kind(:Integer, Real′, [], false)

	Int′ = Kind(:Int, Integer′, [], true)
	Bool′ = Kind(:Bool, Integer′, [], true)
	Complex′ = let T = KindVar(:T, Bottom, Real′)
		ParametricKind(T, Kind(:Complex, Number′, [T], true))
	end

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
			Complex′[Bool′ ∪ Int′] ⊆ ParametricKind(T, Complex′[T])
		end

		@test isconcretetype(Complex{Int})
		@test isconcretekind(Complex′[Int′])
	end

	@testset "single abstract parameter" begin

		abstract type Boxlike{T} end
		X = KindVar(:X)
		Boxlike′ = ParametricKind(X, Kind(:Boxlike, Top, [X], false))

		struct Box{T} <: Boxlike{T} end
		Box′ = ParametricKind(X, Kind(:Box, Boxlike′[X], [X], true))

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
		@test Box′[Cat′] ⊆ ParametricKind(Y, Box′[Y])

		@test !(Box{Box{Cat}} <: Box{Box})
		@test Box′[Box′[Cat′]] ⊈ Box′[Box′]
		
		@test Box{Box{Cat}} <: Box{Box{T}} where T
		@test let T = KindVar(:T)
			Box′[Box′[Cat′]] ⊆ ParametricKind(T, Box′[Box′[T]])
		end

		@test !(Box{Cat} <: Box{>:Animal})
		@test let T = KindVar(:T, Animal′, Top)
			Box′[Cat′] ⊈ ParametricKind(T, Box′[T])
		end
		
	end


	@testset "multiple parameters" begin
		
		T, D = KindVar.([:T, :D])

		AbstractArray′ = ParametricKind(T, ParametricKind(D, Kind(:AbstractArray, Top, [T,D], false)))
		DenseArray′ = ParametricKind(T, ParametricKind(D, Kind(:DenseArray, AbstractArray′[T,D], [T,D], false)))
		Array′ = ParametricKind(T, ParametricKind(D, Kind(:Array, DenseArray′[T,D], [T,D], false)))

		AbstractVector′ = ParametricKind(T, AbstractArray′[T,1])
		DenseVector′ = ParametricKind(T, DenseArray′[T,1])
		Vector′ = ParametricKind(T, Array′[T,1])

		@test Vector{Int} <: AbstractVector{Int} <: AbstractArray{Int,1}
		@test Vector′[Int′] ⊆ AbstractVector′[Int′] ⊆ AbstractArray′[Int′,1]

		@test Vector{Int} <: Array{T,1} where T
		@test Vector′[Int′] ⊆ ParametricKind(T, Array′[T,1])

		@test Union{Complex,Vector} <: Union{Complex{T},Vector{T}} where T
		@test Complex′ ∪ Vector′ ⊆ ParametricKind(T, Complex′[T] ∪ Vector′[T])

		A, B = KindVar.([:A, :B])

		Pair′ = ParametricKind(A, ParametricKind(B, Kind(:Pair, Top, [A, B], true)))

		@test !(Pair{Int,Bool} <: Pair{T,T} where T)
		@test Pair′[Int′,Bool′] ⊈ ParametricKind(T, Pair′[T,T])

		@test Union{Complex{Int},Vector{Bool}} <: Union{Complex{T},Vector{T}} where T
		@test Complex′[Int′] ∪ Vector′[Bool′] ⊆ ParametricKind(T, Complex′[T] ∪ Vector′[T])

		@test Union{Vector{Int},Vector{Bool}} <: Vector{<:Union{Int,Bool}}
		@test let T = KindVar(:T, Bottom, Int′ ∪ Bool′)
			Vector′[Int′] ∪ Vector′[Bool′] ⊆ ParametricKind(T, Vector′[T])
		end

	end

	@testset "intersections and complements" begin
		
		T = KindVar(:T)

		A = Kind(:A, Top, [], false)
		B = Kind(:B, Top, [], false)

		P = ParametricKind(T, Kind(:P, Top, [T], false))
		Q = ParametricKind(T, Kind(:Q, Top, [T], false))

		P2 = let T1 = KindVar(:T1), T2 = KindVar(:T2)
			ParametricKind(T1, ParametricKind(T2, Kind(:P2, Top, [T1, T2], false)))
		end


		@test P[A] ∪ Q[B] ⊆ ParametricKind(T, P[T] ∪ Q[T])
		@test_broken P[A] ∩ Q[B] ⊈ ParametricKind(T, P[T] ∩ Q[T])

	end
end


nothing