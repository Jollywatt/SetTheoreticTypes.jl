function translate(expr)
	MacroTools.prewalk(expr) do node
		if false
		elseif @capture(node, A_ where Ts__)
			:(@where $A $(Ts...))
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
			:($A = Kind($name, $(something(B, Top)), $new_params, $isconcrete))
		else
			node
		end
	end
end

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


macro where(body, var)
	name, T = translate_parameter(var, true)
	quote
		let $(esc(name)) = $T
			UnionAllKind($(esc(name)), $(esc(body)))
		end
	end
end
macro where(body, var, vars...)
	:(@where (@where $body $var) $(vars...)) |> esc
end


macro stt(expr)
	esc(translate(expr))
end