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
	Even though concrete kinds are “points”, they are sets of instances (values of that kind).
	┌─────────────── Top ──────────────┐
	│  ┌────── A ────────┐             │
	│  │  ·α      ┌──────┼─── B ────┐  │
	│  │          │  ·γ  │          │  │
	│  └──────────┼──────┘    ·β    │  │
	│             └─────────────────┘  │
	└──────────────────────────────────┘
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

	@testset "mirroring simple number types" begin
		Number′ = Kind(:Number, Top, [], false)
		Real′ = Kind(:Real, Number′, [], false)
		Integer′ = Kind(:Integer, Real′, [], false)

		Int′ = Kind(:Int, Integer′, [], true)
		Bool′ = Kind(:Bool, Integer′, [], true)
		Complex′ = let T = KindVar(:T, Bottom, Real′)
			ParametricKind(T, Kind(:Complex, Number′, [T], true))
		end

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
end

nothing