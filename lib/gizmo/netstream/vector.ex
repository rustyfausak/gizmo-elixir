defmodule Gizmo.Netstream.Vector do
	use Bitwise

	alias Gizmo.Netstream.Vector, as: Self
	alias Gizmo.Reader, as: Reader

	defstruct [
		:x,
		:y,
		:z
	]

	@doc """
	Read a vector. First read a serialized int. Then read that int plus 2 for
	each of X, Y, Z. Then subtract the bias from each of X, Y, Z.
	"""
	def read(data, max_value \\ 20) do # 20 or 19?
		{num_bits, data} = Reader.read_serialized_int(data, max_value)
		bias = bsl(1, num_bits + 1)
		max_bits = num_bits + 2
		{dx, data} = Reader.read_rev_int(data, max_bits)
		{dy, data} = Reader.read_rev_int(data, max_bits)
		{dz, data} = Reader.read_rev_int(data, max_bits)
		{%Self{
			x: dx - bias,
			y: dy - bias,
			z: dz - bias
		}, data}
	end

	@doc """
	Read a vector composed like this:

		bit [byte for X] bit [byte for Y] bit [byte for Z]

	Where the bits are signals on whether or not to read the byte.
	"""
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
