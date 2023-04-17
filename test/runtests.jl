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
	Each point (e.g., α, β, γ) is a concrete kind; non-concrete
	kinds (e.g., A, B, Top) are shown as sets. Concrete kinds
	cannot have strict subkinds (except Bottom, the empty set)
	and therefore can be thought of as points (or singleton sets)
	which contain only one kind: themselves.
	┌─────────────── Top ──────────────┐
	│  ┌────── A ────────┐             │
	│  │  ·α      ┌──────┼─── B ────┐  │
	│  │          │  ·γ  │          │  │
	│  └──────────┼──────┘    ·β    │  │
	│             └─────────────────┘  │
	└──────────────────────────────────┘
	Note that we usually think of concrete types as sets of
	point-like values or instances. Here, we are thinking of
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
	@test α ∪ β ⊆ A ∪ B

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

	@testset "kind variables" begin
		@test (X where X) == Any
		@test @where(X, X) == Top

		@test (X where X<:Real) == Real
		@test @where(X, X ⊆ Real′) == Real′

		@test (X where X>:Real) == Any
		@test @where(X, X ⊇ Real′) == Top

		@test Integer == Union{X,Y} where X<:Y where Y<:Integer
		@test Integer′ ⊆ @where(@where(X ∩ Y, X ⊆ Y), Y ⊆ Integer′)
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

		@test Pair{Int,Number} <: Pair{X,Y} where X <: Y where Y
		@test Pair′[Int′,Number′] ⊆ @where(@where(Pair′[X,Y], X ⊆ Y), Y)

		@test Integer == Union{X,Y,Z} where X <: Y where Y <: Z where Z <: Integer
		@test Integer′ == @where(@where(@where(X ∪ Y ∪ Z, X ⊆ Y), Y ⊆ Z), Z ⊆ Integer′)

		@test Pair{Complex{Int},Integer} <: Pair{Complex{Sub},Sup} where Sub<:Sup where Sup
		@test Pair′[Complex′[Int′],Integer′] ⊆ @where(@where(Pair′[Complex′[Sub],Sup], Sub ⊆ Sup), Sup)

	end

	@testset "intersections and complements" begin
		
		T, S = KindVar.([:T, :S])

		A = Kind(:A, Top, [], false)
		B = Kind(:B, Top, [], false)

		P = UnionAllKind(T, Kind(:P, Top, [T], false))
		Q = UnionAllKind(T, Kind(:Q, Top, [T], false))
		R = UnionAllKind(T, UnionAllKind(S, Kind(:R, Top, [T, S], false)))

		@test P[A] ∪ P[B] ⊆ UnionAllKind(T, P[T])
		@test P[A] ∩ P[B] ⊆ UnionAllKind(T, P[T])

		@test P[A] ∪ Q[B] ⊆ UnionAllKind(T, P[T] ∪ Q[T])
		@test P[A] ∩ Q[B] ⊈ UnionAllKind(T, P[T] ∩ Q[T])

		@test R[A,B] ⊈ UnionAllKind(T, R[T,T])

		@test (Pair{T,T} where T) <: Pair{T,S} where T where S
		@test UnionAllKind(T, R[T,T]) ⊆ UnionAllKind(T, UnionAllKind(S, R[T,S]))

		@test R[A,B] ⊈ UnionAllKind(T, R[T,T])

		# Ok, this one requires explanation:
		@test R[A,B] ⊈ !UnionAllKind(T, R[T,T])
		# We don’t expect R[A,B] ⊆ !(R[T,T] where T)
		# even though R[A,B] ⊈ R[T,T] where T
		# because R[A,B] is not a concrete kind, and
		# hence the intersection
		@test R[A,B] ∩ UnionAllKind(T, R[T,T]) !== Bottom
		# is not empty. Indeed, we can directly construct a kind
		Weird = Kind(:Weird, R[A,B] ∩ R[A,A], [], false)
		# which is a subset of this intersection:
		@test Weird ⊆ R[A,B]
		@test Weird ⊆ UnionAllKind(T, R[T,T])
		@test Weird ⊆ R[A,B] ∩ UnionAllKind(T, R[T,T])

		# This changes with concrete kinds, however.
		ρ = UnionAllKind(T, UnionAllKind(S, Kind(:ρ, Top, [T, S], true)))
		# Now, we have
		@test ρ[A,B] ⊆ !UnionAllKind(T, ρ[T,T])
		# because the intersection
		@test ρ[A,B] ∩ UnionAllKind(T, ρ[T,T]) === Bottom
		# is indeed empty.
	end
end


@testset "tuple kinds" begin

	Number′  = Kind(:Number,  Top,      [], false)
	Real′    = Kind(:Real,    Number′,  [], false)
	Integer′ = Kind(:Integer, Real′,    [], false)
	Signed′  = Kind(:Signed,  Integer′, [], false)
	Int′     = Kind(:Int,     Signed′,  [], true)
	Bool′    = Kind(:Bool,    Integer′, [], true)
	Complex′ = let T = KindVar(:T, Bottom, Real′)
		UnionAllKind(T, Kind(:Complex, Number′, [T], true))
	end

	T = KindVar(:T)
	
	@test Tuple{Int,Bool} <: Tuple{Real,Number}
	@test TupleKind(Int′,Bool′) ⊆ TupleKind(Real′,Number′)

	@test !(Tuple{Int,Number} <: Tuple{Real,Real})
	@test TupleKind(Int′,Number′) ⊈ TupleKind(Real′,Real′)

	@test Tuple{Bool,Complex{Bool}} <: Tuple{T,Complex{T}} where T
	@test TupleKind(Bool′,Complex′[Bool′]) ⊆ UnionAllKind(T, TupleKind(T, Complex′[T]))

	@test !(Tuple{Bool,Complex{Int}} <: Tuple{T,Complex{T}} where T)
	@test TupleKind(Bool′,Complex′[Int′]) ⊈ UnionAllKind(T, TupleKind(T, Complex′[T]))
end


@testset "methods and dispatch" begin
	@stt struct A end
	@stt f(x ∈ A) = A(x.value^2)
	@test f(A(10)) == A(100)

	@stt struct B end
	@stt f(x ∈ B) = B(x.value + 1)
	@test f(B(1)) == B(2)
	@test f(A(1)) == A(1)

	@stt f(x ∈ T, y ∈ T) where T = x.value == y.value
	@test f(A(1), A(1)) == true
	@test f(B(1), B(2)) == false

	@stt abstract type C[T] end
	@stt struct D[T] ⊆ C[T] end
	@stt g(x ∈ T, y ∈ C[T]) where T = T(x.value*y.value)
	@test g(A("Su"), D[A]("shi")) == A("Sushi")
end

nothing