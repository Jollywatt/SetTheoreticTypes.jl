struct KindInstance
	value
	kind
end

struct KindMethod
	signature
	fn
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
	applicable = filter(f.methods) do method
		length(args) == length(method.signature) || return false
		for (arg, sig) ∈ zip(args, method.signature)
			arg ∈ sig || return false
		end
		true
	end

	isempty(applicable) && error("no method for $(f.name)$(args)")
	length(applicable) > 1 && @warn "method ambiguity; choosing most recently defined" applicable

	method = last(applicable)
	method.fn((arg.value for arg in args)...)
end

Base.in(k::KindInstance, K::Kinds) = k.kind ⊆ K