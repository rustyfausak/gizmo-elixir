defmodule Gizmo.Helper do
	def bitsize(int) do
		int
		|> :math.log2
		|> Float.ceil
		|> trunc
	end
end
