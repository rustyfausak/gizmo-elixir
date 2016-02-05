defmodule Gizmo.Netstream.Vector do
	use Bitwise

	alias Gizmo.Netstream.Vector, as: Self
	alias Gizmo.Reader, as: Reader

	defstruct [
		:x,
		:y,
		:z
	]

	def read(data, max_value \\ 20) do
		{num_bits, data} = Reader.read_serialized_int(data, max_value)
		bias = bsl(1, num_bits + 1)
		max_bits = num_bits + 2
		IO.inspect "max_value #{max_value} num_bits #{num_bits} bias #{bias} max_bits #{max_bits}"
		{dx, data} = Reader.read_rev_int(data, max_bits)
		{dy, data} = Reader.read_rev_int(data, max_bits)
		{dz, data} = Reader.read_rev_int(data, max_bits)
		IO.inspect "dx #{dx} dy #{dy} dz #{dz}"
		{%Self{
			x: dx - bias,
			y: dy - bias,
			z: dz - bias
		}, data}
	end
end
