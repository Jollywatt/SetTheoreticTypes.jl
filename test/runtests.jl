using SetTheoreticTypes, Test

@testset "unions and intersections of abstract kinds" begin
	A = Kind(:A, Top, [], false)
	B = Kind(:B, Top, [], false)

	@test A ⊆ A ∪ B ⊇ B
	@test A ⊇ A ∩ B ⊆ B

	@test A ∩ B ⊆ A ∪ B
	@test A ∪ B ⊆ B ∪ A
	@test A ∩ B ⊆ B ∩ A

	@test A ∩ Bottom == Bottom
	@test A ∪ Top == Top
end

nothing