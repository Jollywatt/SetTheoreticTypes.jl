function translate_parameter(expr, as_kindvar)
	@capture(expr, lb_⊆T_⊆ub_) ||
	@capture(expr, T_⊆ub_) ||
	@capture(expr, T_⊇lb_) ||
	@capture(expr, ⊆(ub_)) ||
	@capture(expr, ⊇(lb_)) ||
	return if as_kindvar
		expr isa Symbol || error("Cannot parse $expr as KindVar")
		expr => :(KindVar($(Meta.quot(expr))))
	else
		expr => nothing
	end

	isnothing(T) && (T = gensym())
	T => :(KindVar($(Meta.quot(T)), $(something(lb, Bottom)), $(something(ub, Top))))
end


function translate_method(expr)
	def = splitdef(expr)	
	argnames, argtypes = zip(map(def[:args]) do arg
		arg isa Symbol && return arg => Top
		@assert @capture(arg, a_ ∈ T_)
		a => T
	end...)

	sig = :(TupleKind($(argtypes...)))
	for param in def[:whereparams]
		name, var = translate_parameter(param, true)
		sig = quote
			let $name = $var
				UnionAllKind($name, $sig)
			end
		end
	end

	fnname = Meta.quot(def[:name])
	quote
		let
			signature = $sig
			method = KindMethod(signature) do $(argnames...)
				$(def[:body])
			end
			if !isdefined(@__MODULE__, $fnname)
				setglobal!(@__MODULE__, $fnname, KindFunction($fnname, []))
			end
			push!(getglobal(@__MODULE__, $fnname).methods, method)
		end
	end
end


function translate(expr)
	MacroTools.prewalk(expr) do node
		if @capture(node, A_ where Ts__)
			:(SetTheoreticTypes.@where $A $(Ts...))
		elseif @capture(node, A_[params__])
			new_params = translate_parameter.(params, false)
			names, vars = zip(new_params...)
			node = :($A[$(something.(vars, names)...)])
			for var in filter(!isnothing, vars)
				node = :( UnionAllKind($var, $node) )
			end
			node
		elseif @capture(node,
				abstract type A_[params__] ⊆ B_ end |
				abstract type A_[params__] end |
				abstract type A_ ⊆ B_ end |
				abstract type A_ end |
				struct A_[params__] ⊆ B_ end |
				struct A_[params__] end |
				struct A_ ⊆ B_ end |
				struct A_ end
			)
			name = Meta.quot(A)
			new_params = isnothing(params) ? [] : last.(translate_parameter.(params, true))
			isconcrete = node.head == :struct
			node = :(Kind($name, $(something(B, Top)), [$(new_params...)], $isconcrete))
			for var in new_params
				node = :( UnionAllKind($var, $node) )
			end
			:($A = $node)
		elseif node isa Expr && node.head ∈ [:function]
			translate_method(node)
		else
			node
		end
	end
end


macro where(body, var)
	name, T = translate_parameter(var, true)
	quote
		let $name = $T
			UnionAllKind($name, $body)
		end
	end |> esc
end
macro where(body, var, vars...)
	:(@where (@where $body $var) $(vars...))
end


macro stt(expr)
	esc(translate(longdef(expr)))
end