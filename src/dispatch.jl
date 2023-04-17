struct KindInstance
	value
	kind
end

struct KindMethod
	fn
	signature
end

struct KindFunction
	name::Symbol
	methods::Vector{KindMethod}
end

kindof(k::KindInstance) = k.kind

function (K::Kinds)(value)
	isconcretekind(K) || error("can only instantiate concrete kinds")
	KindInstance(value, K)
end

function (f::KindFunction)(args...)
	argkind = TupleKind(kindof.(args)...)
	applicable = filter(f.methods) do method
		argkind ⊆ method.signature
	end

	isempty(applicable) && error("$(typeof(f)) $(f.name) has no method matching $argkind")
	length(applicable) > 1 && @warn "method ambiguity; choosing most recently defined" applicable

	method = last(applicable)

	ctx = IdDict()
	
	sig = method.signature
	params = KindVar[]
	while sig isa UnionAllKind
		push!(params, sig.var)
		sig = sig.body
	end

	@ctx argkind ⊆ sig
	
	method.fn(args..., (ctx[T].lb for T in params)...)
end
