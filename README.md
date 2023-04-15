


# Set-theoretic types

_A toy abstract type system with intersections and complements in Julia_

[![Project Status: Concept – Minimal or no implementation has been done yet, or the repository is only intended to be a limited example, demo, or proof-of-concept.](https://www.repostatus.org/badges/latest/concept.svg)](https://www.repostatus.org/#concept)


Inspired by [this Discourse discussion](https://discourse.julialang.org/t/rfc-language-support-for-traits-yay-or-nay/93914/26) and [this speculative excerpt](https://youtu.be/Z2LtJUe1q8c?t=1772) of Jeff Bezanson’s 2017 JuliaCon talk, this module implements a few bits of a “set-theoretic type system” which exists separatly from Julia’s actual type system and serves as a proof of concept for intersection and complement types. **It does not extend Julia’s type system.**

```julia
@stt begin
	abstract type Smart end
	abstract type Organic end

	struct Computer ⊆ Smart end
	struct Fruit ⊆ Organic end
	struct Brain ⊆ Smart ∩ Organic end # intersection type

	think(x ∈ Smart) = "$x is thinking..."
	think(x ∈ !Smart) = "$x cannot think!" # complement type
end
```


```julia
julia> think(Computer("Deepthought"))
"Deepthought is thinking..."

julia> think(Fruit("Quince"))
"Quince cannot think!"
```




## Theory

There is no formal type theory (yet) — this was a fun “figure it out as you go” project…

Set-theoretic types can be thought of as sets of types, where abstract types are sets of arbitrary extent, and concrete types (leaf types which may be instantiated) are singleton sets containing only themselves and `!Top` (the empty set).

Any two abstract types have a non-empty intersection, unless otherwise declared:

```julia
@stt abstract type A end
@stt abstract type B end

@stt abstract type C ⊆ A ∩ !B end

A ∩ B, A ∩ !A, C ∩ B
```

```
(A ∩ B, !Top, !Top)
```





Two distinct _concrete_ types, however, can never intersect:

```julia
@stt struct Alpha ⊆ A end
@stt struct Beta ⊆ B end

Alpha ∩ Beta
```

```
!Top
```





As with Core Julia, parametric types are indexed sets of types; a type parameter is merely part of the type’s name. The only difference is the use of `[…]` in place of `{…}`.

```julia
@stt struct Box[T] end
```

```
Box[T] where T
```





The `where`-notation  `Box[T] where T = Box[T₁] ∪ Box[T₂] ∪ ...` is a union over all parameter values (a `UnionAll`).

## Details


Because I’m not clever enough to re-engineer Julia’s actual type system, analogous concepts to Julia’s types must be given their own names and syntax.
Such duplication probably makes things clearer, though it means a separate syntax is needed, which I chose (arbitrarily) to be:

| Julia types  | Set-theoretic “kind” types
|-------:|:-------
| `T<:S` | `T ⊆ S`
| `a isa T` | `a ∈ T`
| `f(x::T) = x` | `f(x ∈ T) = x`
| `Any`  | `Top`
| `A{T}` | `A[T]`
| `Tuple{A,B}` | `TupleKind(A,B)`
| `Union{A,B}` | `A ∪ B`
| – | `A ∩ B`
| – | `!A`
| `Union{}` | `!Top`

Under the hood, the mechanisms of Julia’s type system
```julia
Type, TypeVar, UnionAll, Union, Tuple, typeof, supertype
```


are reimplemented with different names
```julia
Kind, KindVar, UnionAllKind, UnionKind, TupleKind, kindof, superkind
```


alongside the additional `IntersectionKind` and `ComplementKind`, which have no equivalent in Core Julia.


```julia
@stt begin
	abstract type HasDuckBill end
	abstract type LaysEggs end
	
	abstract type Mammal end
	abstract type Bird end

	struct Platypus ⊆ HasDuckBill ∩ LaysEggs ∩ Mammal end
	struct CanadianGoose ⊆ HasDuckBill ∩ LaysEggs ∩ Bird end

	foo(x ∈ HasDuckBill ∩ LaysEggs) = "Platypus or Goose"
end
```




With the macro `@stt` (**s**et-**t**heoretic **t**ypes) the block above is equivalent to the following direct construction of `Kind` and `KindFunction` objects:

```julia
begin
    HasDuckBill = Kind(:HasDuckBill, Top, [], false)
    LaysEggs = Kind(:LaysEggs, Top, [], false)
    
	Mammal = Kind(:Mammal, Top, [], false)
    Bird = Kind(:Bird, Top, [], false)
    
	Platypus = Kind(:Platypus, HasDuckBill ∩ LaysEggs ∩ Mammal, [], true)
    CanadianGoose = Kind(:CanadianGoose, HasDuckBill ∩ LaysEggs ∩ Bird, [], true)
    
	foo = KindFunction(:foo, [
		KindMethod(TupleKind(HasDuckBill ∩ LaysEggs)) do x
			"Platypus or Goose"
		end
	])
end
```


```julia
perry = Platypus("Agent P.") # create an "instance" of a Kind
```

```
Platypus("Agent P.")
```


