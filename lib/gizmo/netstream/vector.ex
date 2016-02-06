defmodule Gizmo.Netstream.Vector do
	use Bitwise

	alias Gizmo.Netstream.Vector, as: Self
	alias Gizmo.Reader, as: Reader

	defstruct [
		:x,
		:y,
		:z
	]

	def read(data, max_value \\ 20) do # 20 or 19?
		{num_bits, data} = Reader.read_serialized_int(data, max_value)
		bias = bsl(1, num_bits + 1)
		max_bits = num_bits + 2
		# IO.inspect "max_value #{max_value} num_bits #{num_bits} bias #{bias} max_bits #{max_bits}"
		{dx, data} = Reader.read_rev_int(data, max_bits)
		{dy, data} = Reader.read_rev_int(data, max_bits)
		{dz, data} = Reader.read_rev_int(data, max_bits)
		{%Self{
			x: dx - bias,
			y: dy - bias,
			z: dz - bias
		}, data}
	end

	def read_bytewise(data) do
		x = 0
		y = 0
		z = 0
		<< bool :: size(1), data :: bits >> = data
		if bool == 1 do
			{x, data} = Reader.read_rev_int(data, 8)
		end
		<< bool :: size(1), data :: bits >> = data
		if bool == 1 do
			{y, data} = Reader.read_rev_int(data, 8)
		end
		<< bool :: size(1), data :: bits >> = data
		if bool == 1 do
			{z, data} = Reader.read_rev_int(data, 8)
		end
		{%Self{
			x: x,
			y: y,
			z: z
		}, data}
	end
end
