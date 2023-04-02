using SetTheoreticTypes, Test

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

nothing