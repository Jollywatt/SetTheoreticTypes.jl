postwalk(f, e::Expr) = f(Expr(e.head, postwalk.(f, e.args)...))
postwalk(f, e) = f(e)


macro ctx(expr)
	transforms = Dict(
		:⊆ => (a, b) -> :( issubkind!(ctx, $a, $b) ),
		:⊇ => (a, b) -> :( issubkind!(ctx, $b, $a) ),
	)
	postwalk(expr) do n
		if n isa Expr && n.head == :call
			op, args... = n.args
			if op ∈ keys(transforms)
				transforms[op](args...)
			else
				n
			end
		else
			n
		end
	end |> esc
end
