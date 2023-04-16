


# Set-theoretic types

_A toy type system with intersections and complements in Julia_

[![Project Status: Concept – Minimal or no implementation has been done yet, or the repository is only intended to be a limited example, demo, or proof-of-concept.](https://www.repostatus.org/badges/latest/concept.svg)](https://www.repostatus.org/#concept)


Inspired by [this Discourse discussion](https://discourse.julialang.org/t/rfc-language-support-for-traits-yay-or-nay/93914/26) and [this speculative excerpt](https://youtu.be/Z2LtJUe1q8c?t=1772) of Jeff Bezanson’s 2017 JuliaCon talk, this module implements a few bits of a “set-theoretic type system”. **It does not extend Julia’s type system** but exists separately from it, serving as a proof of concept for intersection and complement types. 

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




These set-theoretic types can have “instances”, though the actual Julia data type of the instance has no relationship to the set-theoretic “type”, which is merely a label:

```julia
julia> think(Computer("Deepthought"))
"Deepthought is thinking..."

julia> think(Fruit(:Quince))
"Quince cannot think!"
```




## Theory

There is no formal type theory — this was a “figure it out as you go” kind of project!

Set-theoretic types may be thought of as sets of runtime values. In this picture, both concrete and abstract types are sets which may be combined with boolean operations such as `∪`, `∩` and `!`.

```julia
@stt abstract type A end
@stt abstract type B end
@stt abstract type C ⊆ A end
@stt abstract type D ⊆ A ∩ !B end
@assert A ∪ C === A
@assert A ∩ C === C
@assert D ⊆ A
@assert C ∪ D ⊆ A
```




However, there is a little more structure: concrete types _partition_ the set `Top` of all values, and we don’t care about sets which don’t respect this partition.
(E.g., there is no “type” containing some, but not all, `Int8` values.)
This means concrete types cannot have subtypes other than themselves and the empty set, `!Top`.
Another corollary is that the intersection of distinct concrete types is always `!Top`.

```julia
@stt struct Alpha ⊆ A end
@stt struct Beta ⊆ B end
@assert Alpha ∩ Beta === !Top
```




Thus, intersection types are only useful for abstract types.

I find it helpful to picture types under the equivalence relation induced by this partition: concrete types are singleton sets, while abstract types are sets of arbitrary extent (possibly overlapping with other types). The “elements” of these types are then _sets_ of possible values of the same concrete type.


As with Core Julia, parametric types are indexed sets of types. A type parameter is merely part of the type’s name. A syntactic difference is `[…]` in place of `{…}`, but otherwise there is no difference.

```julia
@stt struct Box[T ⊆ A] end 
@assert Box[Alpha] ⊆ Box
```




The `where`-notation  `Box[T] where T = Box[T₁] ∪ Box[T₂] ∪ ...` represents a union over all parameter values (a `UnionAll`).

## Syntax and convenience macros

Because I’m not clever enough to overload Julia’s actual type system, analogous set-theoretic versions of Julia’s type mechanisms must be given their own names and syntax.
Such a clean separation probably makes things clearer, though it means duplication of syntax, chosen largely arbitrarily:

| Julia types  | Set-theoretic “kind” types
|-------:|:-------
| `T<:S` | `T ⊆ S`
| `abstract type T <: S end` | `@stt abstract type T ⊆ S end`
| `struct T <: S end` | `@stt struct T ⊆ S end`
| `x isa T` | `x ∈ T`
| `f(x::T) = x` | `@stt f(x ∈ T) = x`
| `Any`  | `Top`
| `A{B}` | `A[B]`
| `A{T} where T` | `@stt A[B] where B`
| `Tuple{A,B}` | `TupleKind(A,B)`
| `Union{A,B}` | `A ∪ B`
| – | `A ∩ B`
| – | `!A`
| `Union{}` | `!Top`

The macro `@stt` (**s**et-**t**heoretic **t**ypes) allows one to declare “types” and “methods” using declarative syntax, but they may be constructed directly, too.

With the macro `@stt`, the block,
```julia
@stt begin
	abstract type Animal end
	struct Cat ⊆ Animal end
	struct Box[T] end

	Box[Cat] ⊆ Box[T] where T ⊆ Animal

	pack(x ∈ T) where T = Box[T]("box containing" => x)
	unpack(x ∈ Box[T]) where T = T(last(x))
end
```


```julia
julia> package = pack(Cat("Minka"))
Box[Cat]("box containing" => "Minka")

julia> unpack(package)
Cat("Minka")
```


is equivalent to the following direct construction of “kinds” and “kind functions”:
```julia
quote
    Animal = Kind(:Animal, Top, [], false) # abstract kind
    Cat = Kind(:Cat, Animal, [], true) # concrete kind
    Box = let T = KindVar(:T) # from `… where T`
    	UnionAllKind(T, Kind(:Box, Top, [T], true))
    end

    Box[Cat] ⊆ let T = KindVar(:T, !Top, Animal)
        UnionAllKind(T, Box[T])
    end

    pack = KindFunction(:pack, [
        KindMethod(let T = KindVar(:T); UnionAllKind(T, TupleKind(T)) end) do x, T
            Box[T](x)
        end
    ])

    unpack = KindFunction(:unpack, [
        KindMethod(let T = KindVar(:T); UnionAllKind(T, TupleKind(Box[T])) end) do x, T
            T(x)
        end
    ])
end
```




From this you can see that, under the hood, the mechanisms of Julia’s type system
```julia
Type, TypeVar, UnionAll, Union, Tuple, typeof, supertype
```


are reimplemented with different names
```julia
Kind, KindVar, UnionAllKind, UnionKind, TupleKind, kindof, superkind
```


alongside the additional `IntersectionKind` and `ComplementKind`, which have no equivalent in Core Julia.


## Traits

Traits? Kind-of...

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

