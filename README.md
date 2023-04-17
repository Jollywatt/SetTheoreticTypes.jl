


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

	think(x ∈ Smart) = "$(x.value) is thinking..."
	think(x ∈ !Smart) = "$(x.value) cannot think!" # complement type
end
```



Notably, _any_ non-concrete type may be subtyped, including intersections.

These set-theoretic types can have “instances”:
```julia
julia> think(Computer("Deepthought"))
"Deepthought is thinking..."

julia> think(Fruit(:Quince))
"Quince cannot think!"
```


However, the actual data type of an “instance” has no relationship to the set-theoretic type, which is merely a wrapper.
```julia
julia> Fruit(r"(pine)?apple"i).value |> typeof
Regex
```





## Theory

There is no formal type theory — this is a “figure it out as you go” kind of project! In particular, I don’t know if it is consistent.

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




However, there is a little more structure to it: every value belongs to exactly one concrete type.
These concrete types _partition_ the set of all values, `Top`, and we don’t care about sets which don’t respect this partition.
(E.g., there is no “type” containing some, but not all, `Int8` values.)
In particular, this means concrete types cannot have subtypes other than themselves and the empty set `!Top`, and that the intersection of distinct concrete types is always `!Top`.

```julia
@stt struct Alpha ⊆ A end
@stt struct Beta ⊆ B end
@assert Alpha ∩ Beta === !Top
```




Thus, intersection types are only interesting for abstract types.

I find it helpful to picture set-theoretic types as sets of equivalence classes, where values of the same concrete type are equivalent.
In this picture, concrete types are singleton sets, while abstract types are sets of arbitrary extent (possibly overlapping with other types). This makes the fact self-evident that no distinct concrete types may intersect.

As with Core Julia, parametric types are like indexed sets of types. Type parameters are invariant; they are merely part of the type’s name.
```julia
@stt struct Box[T ⊆ A] end 
@assert Box[Alpha] ⊆ Box
@assert Box[Alpha] ⊆ @stt Box[T] where T ⊆ A
@assert Box[Alpha] ⊈ Box[A]
```



The `where`-notation  `A[T] where L ⊆ T ⊆ U = A[T₁] ∪ A[T₂] ∪ ...` represents a union over all parameter values `T` for which `L ⊆ T ⊆ U`.

## Syntax and convenience macros

Because I’m not clever enough to overload Julia’s actual type system, set-theoretic versions of Core Julia’s type mechanisms must be given their own names and syntax.
Such a clean separation probably makes things clearer, though it means duplication of syntax, which I have chosen largely arbitrarily:

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

The macro `@stt` (**s**et-**t**heoretic **t**ypes) allows one to declare “types” and “methods” using familiar, declarative syntax.
For example, the block
```julia
@stt begin
	abstract type Animal end
	struct Cat ⊆ Animal end
	struct Box[T] end

	Box[Cat] ⊆ Box[T] where T ⊆ Animal

	pack(x ∈ T) where T = Box[T](x)
	unpack(x ∈ Box) = x.value
end
```



is equivalent to the following code which directly constructs “kinds” and “kind functions”:
```julia
quote
    Animal = Kind(:Animal, Top, [], false) # an abstract kind
    Cat = Kind(:Cat, Animal, [], true) # a concrete kind
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




You may notice that the gizmos of Core Julia’s type system
```julia
Type, TypeVar, UnionAll, Union, Tuple, typeof, supertype
```


have analogous “kind” versions
```julia
Kind, KindVar, UnionAllKind, UnionKind, TupleKind, kindof, superkind
```


alongside the additional `IntersectionKind` and `ComplementKind`.

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



The disadvantage is that if you introduce a new trait later on,
```julia
@stt abstract type IsAlive end
```



then you can’t really give this to existing types you don’t own.

Or can you?

Say we wanted to make `Mammal ∪ Bird ⊆ IsAlive` without changing the definitions of these animal types. That is set-theoretically equivalent to `!IsAlive ⊆ !(Mammal ∪ Bird)`, and we can indeed declare such a supertype (or at least I haven’t seen reason to disallow it):
```julia
@stt abstract type IsDead ⊆ !(Mammal ∪ Bird) end
IsAlive = !IsDead
```



We have, miraculously,
```julia
julia> Platypus ⊆ IsAlive
true
```



Perhaps this “trick” can be made ergonomic by allowing a syntax like
```julia
@stt abstract type IsAlive ⊇ Mammal ∪ Bird end
```


to mean the same thing.

The type system _appears_ to allow after-the-fact declaration of supertypes. Cool huh?